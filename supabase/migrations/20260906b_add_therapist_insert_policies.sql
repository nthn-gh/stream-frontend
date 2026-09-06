-- ============================================================
-- Add therapist-scoped INSERT policies for sessions and notifications
--
-- Context: the Assign Exercise flow (exerciseStore.ts createExercisePlan,
-- around the "compatibility session" pre-seeding and plan_updated
-- notification steps) runs under the therapist's own authenticated
-- session (VITE_SUPABASE_ANON_KEY + the therapist's JWT, see
-- services/supabase.ts) -- not service_role. Two inserts in that flow
-- write rows keyed to the PATIENT, not the therapist's own auth.uid():
--
--   1. supabase.from('sessions').insert(sessionRows) -- patient_id is
--      planData.patient_id, a patients.id the therapist owns but does
--      not themselves equal.
--   2. supabase.from('notifications').insert({ user_id: patientRecord.user_id, ... })
--      -- user_id is the PATIENT's auth uid, looked up via patients.user_id.
--
-- Both currently fail client-side (errors surfaced as "Android
-- compatibility sessions were skipped because the sessions table does
-- not allow this insert yet." and "the patient notification could not
-- be created."), because neither public.sessions nor public.notifications
-- has an INSERT policy that authorizes a THERAPIST to write a row on
-- behalf of a patient they own -- only the patient's own auth.uid()
-- (sessions_patient_insert) and service_role (notifications_insert_s)
-- are covered today. This is the same shape of gap as
-- 20260906_add_patient_claim_code.sql's linking problem: an action
-- that has to be performed by one party (therapist) on a row identified
-- by another party's id (patient), with no policy written for that
-- direction.
--
-- Scope: two new, additive INSERT policies. Does not touch, replace,
-- or widen any existing policy on either table --
-- sessions_patient_insert and notifications_insert_s are left exactly
-- as they are. Does not touch any other table, function, or the
-- already-applied 20260906_add_patient_claim_code.sql.
--
-- Multiple permissive policies for the same command on the same table
-- are OR'd together by Postgres RLS -- a row is allowed through if it
-- satisfies ANY applicable policy's WITH CHECK, not all of them. That
-- only holds for the default PERMISSIVE policy type (as opposed to
-- `AS RESTRICTIVE`, which is instead AND'd in and would need this to
-- be merged into the existing policy). Pre-flight below confirms
-- sessions_patient_insert is PERMISSIVE before relying on that.
--
-- "Owns" is defined the same way both times: a patients row whose
-- therapist_id points at a therapist_profiles row whose user_id is the
-- calling auth.uid() (patients.therapist_id -> therapist_profiles.id,
-- therapist_profiles.user_id -> auth.uid() -- confirmed against
-- database.types.ts's Relationships metadata, not assumed).
--
-- notifications_therapist_insert additionally requires p.user_id IS NOT
-- NULL: an unclaimed patient (no linked auth user yet, see
-- 20260906_add_patient_claim_code.sql) has no notifications recipient
-- to write to, so a NULL user_id must not be allowed through as an
-- unrestricted "insert a notification for nobody" row.
--
-- PRE-FLIGHT -- run before executing:
--
--   -- (a) confirm neither new policy name already exists
--   SELECT policyname, tablename FROM pg_policies
--   WHERE schemaname = 'public' AND policyname IN
--     ('sessions_therapist_insert', 'notifications_therapist_insert');
--   -- expect zero rows
--
--   -- (b) confirm what's actually live on both tables today, and that
--   -- sessions_patient_insert (if present) is PERMISSIVE, not RESTRICTIVE
--   SELECT policyname, permissive, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'sessions' AND cmd = 'INSERT';
--
--   SELECT policyname, permissive, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'notifications' AND cmd = 'INSERT';
--
--   -- (c) confirm RLS is actually enabled on both (a policy with RLS
--   -- disabled on the table is a no-op review point, not a blocker,
--   -- but worth knowing going in)
--   SELECT relname, relrowsecurity FROM pg_class
--   WHERE relname IN ('sessions', 'notifications') AND relnamespace = 'public'::regnamespace;
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- sessions: let a therapist insert a session row for a patient they
-- own. Idempotent DROP/CREATE pairing matches this repo's existing
-- migration convention (e.g. 20260905_fix_role_check_regression.sql)
-- for safe re-runs; pre-flight (a) already confirms this isn't
-- masking an unexpected pre-existing policy of the same name.
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "sessions_therapist_insert" ON public.sessions;
CREATE POLICY "sessions_therapist_insert"
ON public.sessions
FOR INSERT
TO authenticated
WITH CHECK (
  patient_id IN (
    SELECT p.id FROM public.patients p
    JOIN public.therapist_profiles tp ON tp.id = p.therapist_id
    WHERE tp.user_id = auth.uid()
  )
);

-- ------------------------------------------------------------
-- notifications: let a therapist create a notification addressed to
-- a patient they own. p.user_id IS NOT NULL excludes unclaimed
-- patients (see header) -- there is no valid recipient to write for
-- those yet. This is additive alongside notifications_insert_s
-- (service_role); that policy is untouched and, since service_role
-- carries BYPASSRLS in Supabase regardless of policy content, this
-- new policy has no effect on service_role's access either way.
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "notifications_therapist_insert" ON public.notifications;
CREATE POLICY "notifications_therapist_insert"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  user_id IN (
    SELECT p.user_id FROM public.patients p
    JOIN public.therapist_profiles tp ON tp.id = p.therapist_id
    WHERE tp.user_id = auth.uid() AND p.user_id IS NOT NULL
  )
);

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT policyname, tablename, permissive, cmd, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND policyname IN
--     ('sessions_therapist_insert', 'notifications_therapist_insert');
--   -- expect both rows present, permissive = PERMISSIVE, cmd = INSERT
--
--   -- confirm sessions_patient_insert (and notifications_insert_s) are
--   -- still present and unchanged from the pre-flight (b) snapshot
--   SELECT policyname, permissive, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename IN ('sessions', 'notifications')
--   ORDER BY tablename, policyname;
--
-- Manual functional test, from the Assign Exercise flow:
--   1. As a therapist, assign an exercise plan to a patient you own.
--      Confirm no "Android compatibility sessions were skipped" or
--      "patient notification could not be created" warning appears,
--      and compatibilitySessionsCreated / notificationCreated in the
--      returned result are non-zero / true.
--   2. Confirm the inserted sessions rows have status = 'paused' and
--      patient_id = the assigned patient, and that the patient's
--      Android app can see and resume them.
--   3. Confirm exactly one notifications row was created, user_id
--      equal to that patient's linked auth uid, type = 'plan_updated'.
--   4. Negative test: attempt the same insert shape (via SQL or a
--      forged request) for a patient NOT owned by the calling
--      therapist -- confirm it is still rejected.
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration):
--
--   DROP POLICY IF EXISTS "sessions_therapist_insert" ON public.sessions;
--   DROP POLICY IF EXISTS "notifications_therapist_insert" ON public.notifications;
-- ============================================================
