-- ============================================================
-- RLS cleanup: patients / exercise_plans / plan_exercises
-- Removes leftover permissive policies (auth.role() = 'authenticated',
-- no ownership check) that coexist with correctly owner-scoped
-- policies on the same tables. Since Postgres RLS policies for the
-- same command are OR'd together, the permissive ones currently
-- grant broad access regardless of the scoped ones.
--
-- PRE-FLIGHT — run this and compare against the DROP statements
-- below before executing. The policy names used here are taken
-- verbatim from your reported live pg_policies output; if the live
-- name differs even slightly, DROP POLICY IF EXISTS will silently
-- no-op and the permissive policy will remain in place.
--
--   SELECT tablename, policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('patients', 'exercise_plans', 'plan_exercises')
--   ORDER BY tablename, policyname;
--
-- See the accompanying chat message for an open question this
-- pre-flight should also resolve: whether "Therapists can update
-- own plans" / "Therapists can update plan exercises" (UPDATE-only
-- permissive policies defined in stream-frontend/setup-exercise-
-- tables.sql:67-69,84-86) are also live. If they are, this migration
-- as scoped does NOT remove them — see the note below.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- patients
-- ------------------------------------------------------------
-- Drop the permissive "any authenticated user can read any patient"
-- policy. Untouched: patients_self_select, patients_self_update,
-- "Patient can insert own profile", patients_therapist_r (already
-- correctly scoped to therapist_id = the caller's therapist_profiles.id).
DROP POLICY IF EXISTS "Therapists can read all patients" ON public.patients;

-- Replace the access the dropped policy provided for *unassigned*
-- patients only: any authenticated therapist may still see a patient
-- with therapist_id IS NULL (so they can find and claim it). Once
-- therapist_id is set, only patients_therapist_r applies going
-- forward — this policy's own USING clause stops matching as soon
-- as therapist_id is non-null.
--
-- Scoped to accounts that actually have a therapist_profiles row,
-- not just any authenticated user, matching the pattern
-- patients_therapist_r uses (confirm exact equivalence against its
-- live USING expression in the pre-flight query above — this repo's
-- committed SQL never defined patients' policies, so this mirrors
-- the pattern documented in RLS_PREP_FINDINGS.md §1 rather than a
-- byte-for-byte copy of a source file).
CREATE POLICY "patients_therapist_unassigned_r"
ON public.patients
FOR SELECT
TO authenticated
USING (
  therapist_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.therapist_profiles
    WHERE therapist_profiles.user_id = auth.uid()
  )
);

-- ------------------------------------------------------------
-- exercise_plans
-- ------------------------------------------------------------
-- Coverage check performed before writing this (see chat message):
-- exercise_plans_therapist_w is a FOR ALL policy, so it already
-- grants the owning therapist SELECT/INSERT/UPDATE/DELETE on their
-- own plans. exercise_plans_patient_r already grants the owning
-- patient SELECT. Dropping the two SELECT/INSERT permissive
-- policies below removes only the "any authenticated user" surface,
-- not any legitimate access.
--
-- OPEN GAP: stream-frontend/setup-exercise-tables.sql:67-69 also
-- defines a permissive UPDATE policy, "Therapists can update own
-- plans" (USING (auth.role() = 'authenticated')), which was NOT
-- included in your list of policies to drop. If it is present in
-- the live pre-flight query above, this migration will NOT remove
-- it and a permissive UPDATE hole will remain on exercise_plans.
DROP POLICY IF EXISTS "Therapists can create plans" ON public.exercise_plans;
DROP POLICY IF EXISTS "Therapists can view plans" ON public.exercise_plans;

-- ------------------------------------------------------------
-- plan_exercises
-- ------------------------------------------------------------
-- Same coverage check: plan_exercises_therapist_w (FOR ALL) already
-- grants the owning therapist SELECT/INSERT/UPDATE/DELETE via the
-- exercise_plans -> therapist_profiles join; plan_exercises_read
-- already grants the read access the dropped SELECT policy provided
-- to whichever parties it's scoped to.
--
-- OPEN GAP, same as above: stream-frontend/setup-exercise-
-- tables.sql:84-86 also defines a permissive UPDATE policy,
-- "Therapists can update plan exercises" — not included in your
-- drop list. Check the pre-flight query for its presence.
--
-- NAME MISMATCH NOTE: the committed setup-exercise-tables.sql names
-- these policies "Therapists can view plan exercises" / "Therapists
-- can insert plan exercises" (with "plan" in the name) but you
-- reported the live names as "Therapists can view exercises" /
-- "Therapists can insert exercises" (without "plan"). Using your
-- reported live names below, since that's what you read directly
-- from pg_policies -- but this mismatch is exactly the kind of typo
-- that makes DROP POLICY IF EXISTS silently no-op, so the pre-flight
-- query above is not optional for this table.
DROP POLICY IF EXISTS "Therapists can insert exercises" ON public.plan_exercises;
DROP POLICY IF EXISTS "Therapists can view exercises" ON public.plan_exercises;

COMMIT;

-- ============================================================
-- POST-FLIGHT — run after applying, to confirm the end state:
--
--   SELECT tablename, policyname, cmd, roles, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('patients', 'exercise_plans', 'plan_exercises')
--   ORDER BY tablename, policyname;
--
-- Expected remaining policies:
--   patients:        patients_self_select, patients_self_update,
--                     "Patient can insert own profile",
--                     patients_therapist_r,
--                     patients_therapist_unassigned_r (new)
--   exercise_plans:   exercise_plans_patient_r, exercise_plans_therapist_w
--                     (plus "Therapists can update own plans" if it
--                     turns out to be live -- see OPEN GAP note above)
--   plan_exercises:   plan_exercises_read, plan_exercises_therapist_w
--                     (plus "Therapists can update plan exercises" if
--                     it turns out to be live -- see OPEN GAP note above)
-- ============================================================

-- ============================================================
-- ROLLBACK (manual — not part of this migration).
-- patients: no exact rollback available. This repo's committed SQL
-- never defined a policy for `patients` at all (it must have been
-- authored directly in the Supabase dashboard), so I have no source
-- text to reconstruct "Therapists can read all patients" verbatim.
-- If you need to revert, you'll need to recreate it from memory/
-- dashboard history, or from this approximation of what a policy
-- named that way most likely was, based on the same pattern used
-- for exercise_plans/plan_exercises below:
--
--   CREATE POLICY "Therapists can read all patients"
--   ON public.patients FOR SELECT
--   USING (auth.role() = 'authenticated');
--
-- exercise_plans / plan_exercises: exact original text, from
-- stream-frontend/setup-exercise-tables.sql:59-65,76-82:
--
--   CREATE POLICY "Therapists can view all plans"
--   ON public.exercise_plans FOR SELECT
--   USING (auth.role() = 'authenticated');
--
--   CREATE POLICY "Therapists can create plans"
--   ON public.exercise_plans FOR INSERT
--   WITH CHECK (auth.role() = 'authenticated');
--
--   CREATE POLICY "Therapists can view plan exercises"
--   ON public.plan_exercises FOR SELECT
--   USING (auth.role() = 'authenticated');
--
--   CREATE POLICY "Therapists can insert plan exercises"
--   ON public.plan_exercises FOR INSERT
--   WITH CHECK (auth.role() = 'authenticated');
--
-- (Note the committed file's policy name for exercise_plans's SELECT
-- policy is "Therapists can view all plans", not "Therapists can
-- view plans" -- another small name drift between the committed SQL
-- and what you read live. Use whichever name your pre-flight query
-- actually shows if you ever need to roll back.)
--
-- To undo the new patients_therapist_unassigned_r policy:
--   DROP POLICY IF EXISTS "patients_therapist_unassigned_r" ON public.patients;
-- ============================================================
