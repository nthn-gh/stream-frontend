-- ============================================================
-- Close self-service role escalation on public.users
--
-- DEPENDS ON 20260813_fix_users_rls_recursion.sql BEING APPLIED
-- FIRST. This migration's new WITH CHECK on users_update_own calls
-- public.is_admin(), which that earlier migration creates. Applying
-- this file against a database that hasn't run
-- 20260813_fix_users_rls_recursion.sql yet will fail with a missing-
-- function error on the CREATE POLICY statement below.
--
-- FILENAME ORDER: this file was renamed from
-- 20260813_close_role_escalation.sql to
-- 20260813b_close_role_escalation.sql specifically so filename-
-- lexical order matches the dependency order above. ASCII '_'
-- (0x5F) sorts before any lowercase letter, so
-- "20260813_fix_users_rls_recursion.sql" (underscore right after
-- the date) sorts before "20260813b_close_role_escalation.sql"
-- ('b' right after the date) -- A before B, correctly. Verified
-- character-by-character, not assumed.
--
-- Confirmed live facts this migration is built against (per your
-- pg_policies / pg_constraint output, not re-verified here):
--   - users_update_own: USING (auth.uid() = id),
--                        WITH CHECK (auth.uid() = id)
--     -- row ownership only, no column restriction. This is the hole.
--   - No BEFORE UPDATE trigger currently exists on public.users.
--   - users_role_check constrains role to
--     ('therapist','patient','admin') only -- doesn't restrict
--     transitions between those values.
--   - on_auth_user_created creates new rows with role defaulting
--     to 'patient'.
--   - Confirmed via adminStore.ts trace: no existing app flow
--     updates an existing user's role via UPDATE. Role is set once,
--     at creation -- either by an admin's INSERT (createTherapist),
--     or by the signing-up user's own upsert (the DO UPDATE branch,
--     since on_auth_user_created already created the row).
--
-- Design: a boolean role_claimed column, defaulting false on new
-- rows, backfilled true for every row that already existed before
-- this migration (so no current user is retroactively blocked). A
-- non-admin may change their own role exactly once, while
-- role_claimed is still false; a BEFORE UPDATE trigger flips it to
-- true atomically the moment role actually changes, closing the
-- window for good. See the "atomicity" note before step 4 below for
-- why this needs a trigger rather than relying on the client to also
-- set role_claimed itself.
--
-- Scope: touches public.users (new column, new trigger, rewritten
-- users_update_own only) and public.handle_new_user() (adds
-- role_claimed to its INSERT). Does NOT touch users_select_own,
-- users_insert_own, or any therapist_profiles policy -- explicitly
-- out of scope for this pass.
--
-- Known adjacent gap, NOT addressed here: users_insert_own (if it
-- has a similarly unrestricted shape) could let a user INSERT their
-- own row with role='admin' directly, bypassing this UPDATE-only
-- fix entirely, in the hypothetical case where on_auth_user_created
-- didn't already win the race and create the row first. Confirmed
-- out of scope for this migration per your last two messages; flag
-- only, no action taken.
--
-- PRE-FLIGHT -- run before executing:
--
--   SELECT column_name FROM information_schema.columns
--   WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'role_claimed';
--   -- expect zero rows (column must not already exist)
--
--   SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_update_own';
--   -- confirm this still matches the BEFORE state documented above
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1 & 2. New column + backfill.
--
-- ADD COLUMN ... DEFAULT false NOT NULL sets role_claimed = false
-- on every row that exists at the moment this statement runs,
-- including rows created moments ago. The very next statement in
-- this same transaction immediately flips ALL of those to true,
-- since anything that existed before this migration already has a
-- settled role. ALTER TABLE ADD COLUMN takes a lock that blocks
-- concurrent INSERTs into public.users for the duration of this
-- transaction, so no new signup can be interleaved between the ADD
-- COLUMN and the backfill UPDATE below -- any concurrent signup
-- queues behind the lock and only proceeds after this transaction
-- commits, meaning it correctly starts at role_claimed = false
-- (via the column default) and is never touched by the backfill.
-- ------------------------------------------------------------
ALTER TABLE public.users ADD COLUMN role_claimed boolean NOT NULL DEFAULT false;

UPDATE public.users SET role_claimed = true WHERE role_claimed = false;

-- ------------------------------------------------------------
-- 3. New rows should start unclaimed.
--
-- Modifying the existing handle_new_user() function in place
-- (CREATE OR REPLACE), rather than adding a second AFTER INSERT
-- trigger on auth.users, so there's exactly one trigger constructing
-- the new public.users row and no ambiguity about multi-trigger
-- firing order. role_claimed = false is already what the column
-- default would produce if omitted here -- included explicitly per
-- your instruction, and because relying on a well-chosen column
-- default is more fragile to a future schema change than saying it
-- outright at the one place this row is constructed.
--
-- Also added SET search_path = public, which the original
-- definition (stream-frontend/fix-database.sql:11-19) didn't have --
-- same SECURITY DEFINER hardening reasoning as is_admin() in the
-- other migration. This is an incidental improvement beyond what
-- was asked; flagging it rather than adding it silently.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, role_claimed)
  VALUES (NEW.id, NEW.email, 'patient', false)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 4. Atomicity: why a trigger, not just WITH CHECK.
--
-- RLS policies can only ALLOW or DENY a write as the client
-- submitted it -- they cannot add columns to the client's own SET
-- list. Neither Android's UserRow payload nor Vue's register()
-- payload ever includes role_claimed, so if flipping it were left
-- to the client, it would simply never happen: role_claimed would
-- stay false forever, and a non-admin could re-run their own upsert
-- indefinitely, each time still passing an "unclaimed" check --
-- unlimited re-claims, not the intended one-time claim. Requiring
-- the client to remember to set role_claimed itself would also be a
-- silent bypass if it ever forgot to.
--
-- A BEFORE UPDATE trigger avoids this: it mutates NEW.role_claimed
-- as part of the SAME statement that changes role, so the two
-- either both happen or neither does -- no separate round trip, no
-- window for a crash/interruption to leave role changed but the
-- flag unset. This does NOT create a read/write race against the
-- WITH CHECK clause's own read of role_claimed (via
-- role_unclaimed() below): that function's SELECT reads the
-- persisted, pre-statement state of the row (the new tuple this
-- trigger builds isn't written to the heap until AFTER WITH CHECK
-- passes), so the first claim always correctly sees role_claimed =
-- false and is allowed through, while the trigger's mutation is
-- what makes role_claimed = true durable and visible to every
-- subsequent, separate statement from then on.
--
-- No SECURITY DEFINER needed here (unlike is_admin()/
-- role_unclaimed()) -- this trigger only mutates the in-memory
-- NEW/OLD record of the row already being written; it doesn't query
-- any table, so RLS doesn't come into it.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_role_claimed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    NEW.role_claimed := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_users_role_change ON public.users;
CREATE TRIGGER before_users_role_change
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.mark_role_claimed();

-- Helper, same reasoning/pattern as is_admin(): SECURITY DEFINER so
-- reading role_claimed from inside a users policy doesn't re-trigger
-- users' own RLS (which would reintroduce the exact recursion class
-- fixed in 20260813_fix_users_rls_recursion.sql).
CREATE OR REPLACE FUNCTION public.role_unclaimed()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role_claimed = false
  );
$$;

GRANT EXECUTE ON FUNCTION public.role_unclaimed() TO PUBLIC;

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND (
    public.is_admin()
    OR public.role_unclaimed()
  )
);

COMMIT;

-- ============================================================
-- BEFORE / AFTER -- users_update_own
--
-- BEFORE (confirmed live, unchanged from what you pasted):
--   USING:      auth.uid() = id
--   WITH CHECK: auth.uid() = id
--
-- AFTER (this migration):
--   USING:      auth.uid() = id
--   WITH CHECK: auth.uid() = id
--               AND (public.is_admin() OR public.role_unclaimed())
--
-- USING is unchanged -- row visibility for the purposes of "which
-- rows can this UPDATE target" is still identity-only; the new
-- restriction is entirely in WITH CHECK, which gates whether the
-- resulting NEW row is acceptable.
-- ============================================================

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_update_own';
--   -- with_check should now include is_admin() OR role_unclaimed()
--
--   SELECT id, role, role_claimed FROM public.users LIMIT 20;
--   -- every pre-existing row should show role_claimed = true
--
--   SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.users'::regclass AND NOT tgisinternal;
--   -- should list before_users_role_change
--
-- Then re-test: (a) a fresh signup can still self-claim its role
-- once, (b) attempting to change role a second time on that same
-- account via the same upsert path is now rejected, (c) an admin
-- can still change another user's role if that's ever exercised
-- (currently no app flow does, per the adminStore.ts trace above).
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration):
--
--   DROP TRIGGER IF EXISTS before_users_role_change ON public.users;
--   DROP FUNCTION IF EXISTS public.mark_role_claimed();
--   DROP FUNCTION IF EXISTS public.role_unclaimed();
--   DROP POLICY IF EXISTS "users_update_own" ON public.users;
--   CREATE POLICY "users_update_own" ON public.users FOR UPDATE
--     USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
--   ALTER TABLE public.users DROP COLUMN IF EXISTS role_claimed;
--   -- handle_new_user() can be left as-is (role_claimed column gone
--   -- means the INSERT's role_claimed value has nowhere to go once
--   -- the column is dropped) -- if rolling back, also revert
--   -- handle_new_user() to its original fix-database.sql:11-19 form.
--
-- Note: rolling back re-opens the self-escalation hole this
-- migration closes. Only useful if role_claimed/the new trigger
-- causes an unrelated problem.
-- ============================================================
