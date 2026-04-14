-- STREAM Supabase RLS policies
-- Run this in the Supabase SQL editor for the shared therapist/patient backend.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapist_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_exercises ENABLE ROW LEVEL SECURITY;

-- Users
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Users can insert own data" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;

CREATE POLICY "Users can view own data"
ON public.users
FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can insert own data"
ON public.users
FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own data"
ON public.users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Therapist profiles
DROP POLICY IF EXISTS "Therapists can view own profile" ON public.therapist_profiles;
DROP POLICY IF EXISTS "Therapists can insert own profile" ON public.therapist_profiles;
DROP POLICY IF EXISTS "Therapists can update own profile" ON public.therapist_profiles;

CREATE POLICY "Therapists can view own profile"
ON public.therapist_profiles
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Therapists can insert own profile"
ON public.therapist_profiles
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Therapists can update own profile"
ON public.therapist_profiles
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Exercise plans
DROP POLICY IF EXISTS "Patients can view own exercise plans" ON public.exercise_plans;
DROP POLICY IF EXISTS "Assigned therapists can manage exercise plans" ON public.exercise_plans;

CREATE POLICY "Patients can view own exercise plans"
ON public.exercise_plans
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.patients
    WHERE patients.id = exercise_plans.patient_id
      AND patients.user_id = auth.uid()
  )
);

CREATE POLICY "Assigned therapists can manage exercise plans"
ON public.exercise_plans
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.therapist_profiles
    WHERE therapist_profiles.id = exercise_plans.therapist_id
      AND therapist_profiles.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.therapist_profiles
    WHERE therapist_profiles.id = exercise_plans.therapist_id
      AND therapist_profiles.user_id = auth.uid()
  )
);

-- Plan exercises
DROP POLICY IF EXISTS "Patients can view own plan exercises" ON public.plan_exercises;
DROP POLICY IF EXISTS "Assigned therapists can manage own plan exercises" ON public.plan_exercises;

CREATE POLICY "Patients can view own plan exercises"
ON public.plan_exercises
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.exercise_plans
    JOIN public.patients ON patients.id = exercise_plans.patient_id
    WHERE exercise_plans.id = plan_exercises.plan_id
      AND patients.user_id = auth.uid()
  )
);

CREATE POLICY "Assigned therapists can manage own plan exercises"
ON public.plan_exercises
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.exercise_plans
    JOIN public.therapist_profiles ON therapist_profiles.id = exercise_plans.therapist_id
    WHERE exercise_plans.id = plan_exercises.plan_id
      AND therapist_profiles.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.exercise_plans
    JOIN public.therapist_profiles ON therapist_profiles.id = exercise_plans.therapist_id
    WHERE exercise_plans.id = plan_exercises.plan_id
      AND therapist_profiles.user_id = auth.uid()
  )
);

SELECT 'STREAM exercise plan RLS policies updated successfully.' AS message;
