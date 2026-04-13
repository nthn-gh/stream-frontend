-- Update test@pt.com to Therapist Account
-- Run this in Supabase SQL Editor

-- Update user role to therapist
UPDATE public.users 
SET role = 'therapist'
WHERE email = 'test@pt.com';

-- Check if therapist profile exists, if not create it
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
SELECT 
  id,
  'Dr. ' || SPLIT_PART(email, '@', 1),
  'STREAM Clinic'
FROM public.users
WHERE email = 'test@pt.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.therapist_profiles WHERE user_id = public.users.id
  );

-- Verify the update
SELECT 
  u.email, 
  u.role, 
  tp.name as therapist_name,
  tp.clinic_name
FROM public.users u
LEFT JOIN public.therapist_profiles tp ON tp.user_id = u.id
WHERE u.email = 'test@pt.com';
