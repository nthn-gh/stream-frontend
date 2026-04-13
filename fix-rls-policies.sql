-- Fix RLS Policies for Registration
-- Run this in Supabase SQL Editor

-- 1. Drop existing policies
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Therapists can view own profile" ON public.therapist_profiles;

-- 2. Create policies for users table
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
USING (auth.uid() = id);

-- 3. Create policies for therapist_profiles
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
USING (auth.uid() = user_id);

-- Success!
SELECT 'RLS policies updated successfully!' as message;
