# 🔧 Fix: "Cannot coerce the result to a single JSON object" Error

## Problem
When trying to log in, you get the error:
```
Cannot coerce the result to a single JSON object
```

## Root Cause
The `public.users` table doesn't exist or doesn't have a matching record for your auth user.

---

## ✅ I've Fixed the Code

Changed `.single()` to `.maybeSingle()` in three places in `authStore.ts`:
- Login function (line 38)
- Fetch profile function (line 85)
- Check auth function (line 154)

This prevents the error and shows a helpful message instead.

---

## 🚀 Quick Fix: Setup Database

### Run this SQL in Supabase SQL Editor:

```sql
-- 1. Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('therapist', 'patient', 'admin')) DEFAULT 'patient',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- 2. Create auto-trigger for new signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (NEW.id, NEW.email, 'patient');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3. Add existing auth users to public.users
INSERT INTO public.users (id, email, role)
SELECT id, email, 'therapist'
FROM auth.users
ON CONFLICT (id) DO UPDATE SET role = 'therapist';

-- 4. Create therapist_profiles table
CREATE TABLE IF NOT EXISTS public.therapist_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  clinic_name TEXT,
  license_number TEXT,
  avatar_url TEXT,
  email_alerts BOOLEAN DEFAULT true,
  in_app_alerts BOOLEAN DEFAULT true,
  weekly_summary BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.therapist_profiles ENABLE ROW LEVEL SECURITY;

-- 5. Create therapist profile for existing users
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
SELECT id, 'Dr. ' || split_part(email, '@', 1), 'STREAM Clinic'
FROM public.users
WHERE role = 'therapist'
ON CONFLICT DO NOTHING;
```

### Then Try Logging In Again!

Your test credentials should work now.

---

## Test Login

If you created a user in Supabase Auth with:
- **Email:** therapist@example.com
- **Password:** (whatever you set)

It should now work! The SQL above will:
1. Create the users table
2. Auto-add your existing auth user to it as a therapist
3. Create a therapist profile for you
4. Set up automatic creation for future signups

---

**Status:** ✅ Code fixed to handle missing records gracefully  
**Next:** Run the SQL above in Supabase SQL Editor
