-- ============================================================
-- Add public.get_my_therapist() RPC
--
-- Context: the STREAM Android patient "Message Therapist" screen
-- needs the assigned therapist's auth user id (messages.receiver_id
-- references users(id)) and a display name. The app currently does
--
--   select user_id from therapist_profiles where id = <patients.therapist_id>
--
-- and that lookup cannot work for a patient. Confirmed live (as the
-- `authenticated` role with a simulated patient JWT):
--
--   * therapist_profiles has only owner/admin policies
--     (therapist_profiles_select_own: auth.uid() = user_id, and
--     is_admin()). No policy lets a patient read their therapist's
--     profile, so the lookup returns 0 rows (1 row as DB owner).
--   * users likewise only exposes the caller's own row
--     (users_select_own), so the therapist's name is hidden too.
--
-- Rather than widen SELECT on therapist_profiles/users (which would
-- expose every therapist's license number, clinic, alert settings
-- etc. to every patient, and every user's email/role to everyone),
-- this adds a narrow SECURITY DEFINER function as the ONLY door: it
-- returns exactly two columns (user_id, full_name) for exactly one
-- therapist -- the caller's own. Same pattern and reasoning as
-- claim_patient_record() / is_admin() in earlier migrations
-- (SECURITY DEFINER + SET search_path = public).
--
-- Chain: auth.uid() -> patients.user_id
--        -> patients.therapist_id = therapist_profiles.id
--        -> therapist_profiles.user_id = users.id
--
-- Returns zero rows when the caller has no patients row, the patient
-- has no therapist assigned (therapist_id IS NULL), or the caller is
-- anon (auth.uid() IS NULL, which also matches nothing). The app maps
-- "zero rows" to NotAssigned/Unavailable using its own patients row.
--
-- full_name: users.full_name is nullable and IS NULL for the
-- existing therapist accounts (e.g. "Dr. Test"), while
-- therapist_profiles.name is NOT NULL and holds the name they
-- registered with. So we return users.full_name when it is non-blank
-- and fall back to therapist_profiles.name.
--
-- patients.user_id and therapist_profiles.user_id are both UNIQUE
-- and therapist_profiles.user_id is NOT NULL with an FK to users, so
-- the joins yield at most one row; LIMIT 1 is a belt-and-braces guard.
--
-- Privileges: default privileges in this project grant EXECUTE on new
-- functions to PUBLIC and, explicitly, to anon/authenticated/
-- service_role. We REVOKE from PUBLIC and anon, and GRANT only to
-- authenticated. (service_role keeps its default grant.)
--
-- PRE-FLIGHT -- confirm the function doesn't already exist:
--
--   SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
--   WHERE n.nspname = 'public' AND proname = 'get_my_therapist';
--   -- expect zero rows
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_my_therapist()
RETURNS TABLE (user_id uuid, full_name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.user_id,
    COALESCE(NULLIF(btrim(u.full_name), ''), tp.name) AS full_name
  FROM public.patients p
  JOIN public.therapist_profiles tp ON tp.id = p.therapist_id
  JOIN public.users u ON u.id = tp.user_id
  WHERE p.user_id = auth.uid()
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_therapist() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_therapist() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_therapist() TO authenticated;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying (DB owner):
--
--   -- 1. exists, SECURITY DEFINER, pinned search_path, STABLE
--   SELECT p.proname, p.prosecdef, p.provolatile, p.proconfig
--   FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
--   WHERE n.nspname = 'public' AND p.proname = 'get_my_therapist';
--   -- expect: prosecdef = true, provolatile = 's', proconfig = {search_path=public}
--
--   -- 2. privileges: no PUBLIC, no anon
--   SELECT has_function_privilege('anon',          'public.get_my_therapist()', 'EXECUTE') AS anon_can,
--          has_function_privilege('authenticated', 'public.get_my_therapist()', 'EXECUTE') AS authed_can;
--   -- expect: anon_can = false, authed_can = true
--   SELECT proacl FROM pg_proc WHERE proname = 'get_my_therapist';
--   -- expect: no "=X/postgres" (PUBLIC) and no "anon=X/postgres" entry
--
--   -- 3. assigned patient (Bob Johnson) gets exactly his therapist
--   BEGIN;
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims',
--     '{"sub":"8b7a7f04-9e0b-4bb8-b9da-f1587a848eb4","role":"authenticated"}', true);
--   SELECT * FROM public.get_my_therapist();
--   -- expect exactly 1 row: a7414d01-f028-43e1-8c3c-8c4042818e2b, "Dr. Test"
--   ROLLBACK;
--
--   -- 4. unassigned patient (Full Patient, therapist_id IS NULL) gets 0 rows
--   BEGIN;
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims',
--     '{"sub":"7a258b0d-7294-4e0e-918d-85768b007849","role":"authenticated"}', true);
--   SELECT count(*) FROM public.get_my_therapist();
--   -- expect 0
--   ROLLBACK;
--
--   -- 5. a therapist (no patients row) gets 0 rows -- no leakage
--   BEGIN;
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims',
--     '{"sub":"a7414d01-f028-43e1-8c3c-8c4042818e2b","role":"authenticated"}', true);
--   SELECT count(*) FROM public.get_my_therapist();
--   -- expect 0
--   ROLLBACK;
--
--   -- 6. a different assigned patient ("test") gets only THEIR therapist
--   BEGIN;
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims',
--     '{"sub":"10d8fe13-2c61-479b-b862-a528165291e6","role":"authenticated"}', true);
--   SELECT * FROM public.get_my_therapist();
--   -- expect exactly 1 row: 9f7efa92-0e2f-4bc5-a667-3a46d847472e, "Test final"
--   ROLLBACK;
--
--   -- 7. anon cannot execute
--   BEGIN;
--   SET LOCAL ROLE anon;
--   SELECT * FROM public.get_my_therapist();
--   -- expect: ERROR permission denied for function get_my_therapist
--   ROLLBACK;
--
--   -- 8. the table policies are unchanged (still no patient read of therapist_profiles)
--   BEGIN;
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims',
--     '{"sub":"8b7a7f04-9e0b-4bb8-b9da-f1587a848eb4","role":"authenticated"}', true);
--   SELECT count(*) FROM public.therapist_profiles;
--   -- expect 0
--   ROLLBACK;
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration):
--
--   DROP FUNCTION IF EXISTS public.get_my_therapist();
-- ============================================================
