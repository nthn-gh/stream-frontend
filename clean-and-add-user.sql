-- Clean Up and Add Your User
-- Run this in Supabase SQL Editor

-- Step 1: Delete all existing records (clean slate)
DELETE FROM public.therapist_profiles;
DELETE FROM public.users;

-- Step 2: Add YOUR specific user (the one that's logging in)
INSERT INTO public.users (id, email, role)
VALUES (
  'af4aea64-c22e-4925-809a-6b294b8fd748',
  (SELECT email FROM auth.users WHERE id = 'af4aea64-c22e-4925-809a-6b294b8fd748'),
  'therapist'
);

-- Step 3: Create YOUR therapist profile
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
VALUES (
  'af4aea64-c22e-4925-809a-6b294b8fd748',
  'Dr. Test',
  'STREAM Clinic'
);

-- Step 4: Verify it worked (should show your user)
SELECT 
  u.id,
  u.email, 
  u.role, 
  tp.name as therapist_name,
  tp.clinic_name
FROM public.users u
LEFT JOIN public.therapist_profiles tp ON tp.user_id = u.id;
