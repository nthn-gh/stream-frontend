-- ============================================================
-- Fix regression introduced by 20260813b_close_role_escalation.sql
--
-- DOES NOT EDIT that file -- it is already applied to production.
-- This is a follow-up correction layered on top of it.
--
-- REGRESSION FOUND (while testing the SettingsView.vue persistence
-- fix): users_update_own's WITH CHECK, as written in
-- 20260813b_close_role_escalation.sql:191-201, is:
--
--   WITH CHECK (
--     auth.uid() = id
--     AND (public.is_admin() OR public.role_unclaimed())
--   )
--
-- This gates EVERY UPDATE to public.users, not just ones that change
-- `role` -- WITH CHECK has no built-in "only if this column changed"
-- concept, and this expression doesn't add one. `role_unclaimed()` is
-- false for any account past its one-time role claim (i.e. virtually
-- every real, active user), and `is_admin()` is false for a normal
-- therapist/patient. Net effect: a completely benign update that
-- never touches `role` at all -- e.g. authStore.updateProfile()'s
-- `users.full_name` write, or an email change -- is rejected with
-- "new row violates row-level security policy for table users" for
-- every non-admin, already-claimed account. Confirmed by tracing the
-- policy logic directly, not by observed error alone.
--
-- MECHANISM CONFIRMED BEFORE WRITING THIS: a CREATE POLICY expression
-- is not a trigger body -- there is no OLD/NEW pseudo-record syntax
-- available in it. USING (for UPDATE) binds bare column references to
-- the existing/targeted row; WITH CHECK binds them to the proposed
-- new row. Only one row is in scope per clause, so a single boolean
-- expression cannot directly compare a column's old value against its
-- new value. The only way to get the old value into a WITH CHECK
-- expression is a helper function that independently queries the
-- persisted row -- which is exactly the trick 20260813b already
-- relies on for role_unclaimed(): per that file's own reasoning
-- (lines 141-150), the new tuple an UPDATE is building is not written
-- to the heap until AFTER WITH CHECK passes, so a SELECT issued from
-- inside the check (via a SECURITY DEFINER function, same reasoning
-- as is_admin()/role_unclaimed() -- avoids re-triggering users' own
-- RLS and the exact recursion class fixed in
-- 20260813_fix_users_rls_recursion.sql) necessarily reads the OLD,
-- persisted value, while a bare `role` reference in the surrounding
-- WITH CHECK expression resolves to the NEW value being written.
-- Combining the two is how this simulates an OLD-vs-NEW comparison
-- that plain policy syntax can't express directly.
--
-- Scope: touches public.users only (new helper function, rewritten
-- users_update_own only). Does not touch is_admin(), role_unclaimed(),
-- the role_claimed column/trigger, or any therapist_profiles policy --
-- all of that is correct as-is and untouched.
--
-- PRE-FLIGHT -- run before executing, to confirm the live policy
-- still matches what this migration assumes it's correcting:
--
--   SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_update_own';
--   -- expect with_check = auth.uid() = id AND (is_admin() OR role_unclaimed())
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- Helper function: returns the CALLING user's own persisted `role`
-- value, i.e. the pre-update value at the time this is evaluated
-- from inside users_update_own's WITH CHECK (see mechanism note
-- above for why this reads OLD, not NEW).
--
-- SECURITY DEFINER + SET search_path = public: same hardening and
-- same reason as is_admin()/role_unclaimed() -- calling this from a
-- `users` policy must not re-trigger `users`' own RLS.
--
-- EXECUTE granted broadly (PUBLIC), matching is_admin()/
-- role_unclaimed()'s existing precedent -- this WITH CHECK must
-- evaluate cleanly for every caller users_update_own applies to, and
-- the function only reveals the CALLING user's own role, so a broad
-- EXECUTE grant carries no privilege-escalation risk.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.stored_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.stored_role() TO PUBLIC;

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND (
    role = public.stored_role()
    OR public.is_admin()
    OR public.role_unclaimed()
  )
);

COMMIT;

-- ============================================================
-- BEFORE / AFTER -- users_update_own
--
-- BEFORE (20260813b_close_role_escalation.sql, confirmed live):
--   WITH CHECK: auth.uid() = id
--               AND (is_admin() OR role_unclaimed())
--
-- AFTER (this migration):
--   WITH CHECK: auth.uid() = id
--               AND (role = stored_role() OR is_admin() OR role_unclaimed())
--
-- USING is unchanged. The added `role = stored_role()` clause is what
-- lets a non-role-changing update through regardless of claim status.
-- ============================================================

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_update_own';
--   -- with_check should now include `role = stored_role()`
--
-- Then re-test all four scenarios:
--   (a) active, already-claimed therapist updates only full_name -> succeeds
--   (b) that same account tries to set role = 'admin' -> still rejected
--   (c) a fresh signup (role_claimed = false) claims its role -> still succeeds
--   (d) an admin account updates another user's role -> still succeeds
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration). Restores the
-- exact 20260813b_close_role_escalation.sql state (regression and
-- all -- only use this if stored_role() itself causes an unrelated
-- problem):
--
--   DROP POLICY IF EXISTS "users_update_own" ON public.users;
--   CREATE POLICY "users_update_own"
--   ON public.users FOR UPDATE
--   USING (auth.uid() = id)
--   WITH CHECK (
--     auth.uid() = id
--     AND (public.is_admin() OR public.role_unclaimed())
--   );
--   DROP FUNCTION IF EXISTS public.stored_role();
-- ============================================================
