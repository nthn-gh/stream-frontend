-- ============================================================
-- Fix: "infinite recursion detected in policy for relation users"
--
-- Root cause: the four "Admins can ..." policies on `users`
-- evaluate auth.uid() IN (SELECT id FROM users WHERE role='admin')
-- -- a subquery against the SAME table the policy protects.
-- Resolving that subquery re-applies `users`' own RLS, which
-- re-evaluates the same policies, which re-queries `users` again,
-- and Postgres's recursion guard raises the named error.
--
-- The four "Admins can ..." policies on `therapist_profiles` query
-- `users` too (not `therapist_profiles` itself, so not literally
-- self-referencing) -- but reading `users` from anywhere still
-- triggers `users`' own RLS, so they hit the identical error today
-- as a side effect of the same root cause. Fixed here too, per your
-- diagnosis in this conversation.
--
-- Policy names and original USING clauses sourced from
-- stream-frontend/src/stores/adminStore.ts:1-50, which documents
-- (and is almost certainly the source of) the exact live policies.
--
-- PRE-FLIGHT -- run before executing, to confirm live names/shape
-- match what this migration assumes:
--
--   SELECT tablename, policyname, cmd, roles, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('users', 'therapist_profiles')
--     AND policyname LIKE 'Admins can %'
--   ORDER BY tablename, policyname;
--
-- Untouched by this migration: users_select_own, users_insert_own,
-- users_update_own, and every non-admin therapist_profiles policy --
-- none of these self-reference and none are part of this bug.
--
-- Does NOT touch patients / exercise_plans / plan_exercises --
-- separate migration, separate bug (see 20260813_rls_cleanup.sql).
--
-- RE-VERIFIED against facts confirmed since this file was first
-- drafted: on_auth_user_created is confirmed live on auth.users; no
-- BEFORE UPDATE trigger exists on public.users; users_role_check
-- constrains valid role values only (doesn't affect RLS evaluation
-- or recursion). None of these change anything below -- this
-- migration's content is unchanged from the original draft. It also
-- does not reference or depend on the role_claimed column added by
-- 20260813_close_role_escalation.sql -- safe to apply on its own,
-- before that migration exists.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- Helper function: bypasses RLS for its own internal lookup via
-- SECURITY DEFINER, so calling it from a `users`/`therapist_profiles`
-- policy no longer re-triggers `users`' RLS.
--
-- SET search_path = public pins the schema resolution so a caller
-- can't hijack which `users`/`auth` the function resolves against
-- via a session-level search_path change -- standard hardening for
-- SECURITY DEFINER functions, not optional here.
--
-- EXECUTE is granted broadly (PUBLIC) rather than restricted to
-- `authenticated`, because the four `users`/`therapist_profiles`
-- admin policies this feeds are themselves scoped to role {public}
-- (per your report last turn), meaning anon-role requests evaluate
-- them too. Restricting EXECUTE to `authenticated` would turn a
-- clean "not admin, denied" result into a hard
-- "permission denied for function is_admin" error for anon
-- requests instead. The function has no side effects and only
-- reveals the CALLING user's own admin status, so a broad EXECUTE
-- grant carries no privilege-escalation risk.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO PUBLIC;

-- ------------------------------------------------------------
-- users -- replace the four self-referencing admin policies
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Admins can select users" ON public.users;
CREATE POLICY "Admins can select users"
ON public.users FOR SELECT
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
CREATE POLICY "Admins can insert users"
ON public.users FOR INSERT
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update users" ON public.users;
CREATE POLICY "Admins can update users"
ON public.users FOR UPDATE
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
CREATE POLICY "Admins can delete users"
ON public.users FOR DELETE
USING (public.is_admin());

-- ------------------------------------------------------------
-- therapist_profiles -- same fix, same reasoning (queries `users`,
-- which triggers `users`' RLS, which was the actual recursive part)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Admins can select therapist_profiles" ON public.therapist_profiles;
CREATE POLICY "Admins can select therapist_profiles"
ON public.therapist_profiles FOR SELECT
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can insert therapist_profiles" ON public.therapist_profiles;
CREATE POLICY "Admins can insert therapist_profiles"
ON public.therapist_profiles FOR INSERT
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update therapist_profiles" ON public.therapist_profiles;
CREATE POLICY "Admins can update therapist_profiles"
ON public.therapist_profiles FOR UPDATE
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete therapist_profiles" ON public.therapist_profiles;
CREATE POLICY "Admins can delete therapist_profiles"
ON public.therapist_profiles FOR DELETE
USING (public.is_admin());

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT tablename, policyname, cmd, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('users', 'therapist_profiles')
--   ORDER BY tablename, policyname;
--
-- Every "Admins can ..." row's qual/with_check should now read
-- `is_admin()` (or `public.is_admin()`), not a SELECT subquery.
-- Then re-attempt the therapist signup flow that produced the
-- original error.
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration). Restores the
-- exact original policies from stream-frontend/src/stores/
-- adminStore.ts:1-50:
--
--   DROP POLICY IF EXISTS "Admins can select users" ON public.users;
--   CREATE POLICY "Admins can select users" ON public.users FOR SELECT
--     USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
--   DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
--   CREATE POLICY "Admins can insert users" ON public.users FOR INSERT
--     WITH CHECK (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
--   DROP POLICY IF EXISTS "Admins can update users" ON public.users;
--   CREATE POLICY "Admins can update users" ON public.users FOR UPDATE
--     USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
--   DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
--   CREATE POLICY "Admins can delete users" ON public.users FOR DELETE
--     USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
--   -- (same pattern for the four therapist_profiles policies)
--   DROP FUNCTION IF EXISTS public.is_admin();
--
-- Note: rolling back re-introduces the recursion bug. This is only
-- useful if the new function/policies cause an unrelated problem.
-- ============================================================

-- ============================================================
-- DIAGNOSTIC QUERIES (for future reference -- not executed as part
-- of this migration). Use these to check for the same self-
-- referencing-subquery pattern on any OTHER table, if this class of
-- bug is ever suspected again.

-- Direct self-reference: a policy on table X whose expression
-- selects FROM X.
--
--   SELECT tablename, policyname, cmd, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND (
--       qual ILIKE '%FROM ' || tablename || '%'
--       OR qual ILIKE '%FROM public.' || tablename || '%'
--       OR with_check ILIKE '%FROM ' || tablename || '%'
--       OR with_check ILIKE '%FROM public.' || tablename || '%'
--     );

-- Cross-table reference to `users` specifically -- the table that
-- actually had the recursive bug, so anything else querying it
-- inherited the same failure mode until this migration's fix.
-- Surfaces every table beyond therapist_profiles that might have
-- the same "admin check via a users subquery" pattern.
--
--   SELECT tablename, policyname, cmd, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename <> 'users'
--     AND (qual ILIKE '%FROM users%' OR with_check ILIKE '%FROM users%');
-- ============================================================
