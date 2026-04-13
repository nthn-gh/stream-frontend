-- Simple Database Setup (no conflicts)
-- Run this in Supabase SQL Editor

-- Step 1: Add unique constraint to therapist_profiles
ALTER TABLE public.therapist_profiles 
ADD CONSTRAINT IF NOT EXISTS therapist_profiles_user_id_key UNIQUE (user_id);

-- Step 2: Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (NEW.id, NEW.email, 'patient')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Add existing auth users as therapists
INSERT INTO public.users (id, email, role)
SELECT id, email, 'therapist' FROM auth.users
ON CONFLICT (id) DO UPDATE SET role = 'therapist';

-- Step 4: Create therapist profiles (with constraint now in place)
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
SELECT 
  id, 
  'Dr. ' || SPLIT_PART(email, '@', 1), 
  'STREAM Clinic'
FROM public.users 
WHERE role = 'therapist'
  AND NOT EXISTS (
    SELECT 1 FROM public.therapist_profiles WHERE user_id = public.users.id
  );

-- Step 5: Verify your account
SELECT 
  u.email, 
  u.role, 
  tp.name as therapist_name,
  tp.clinic_name
FROM public.users u
LEFT JOIN public.therapist_profiles tp ON tp.user_id = u.id
WHERE u.email LIKE '%@%';  -- Shows all users
