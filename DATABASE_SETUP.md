# 🗄️ Database Setup - Step by Step Guide

## Current Status
✅ Your Supabase credentials are working  
✅ You can authenticate with email/password  
❌ Missing `public.users` table and trigger  

---

## 📋 Quick Setup (Copy-Paste This SQL)

### Step 1: Open Supabase SQL Editor

1. Go to https://supabase.com
2. Click on your project: **STREAM Therapist Dashboard**
3. In the left sidebar, click **SQL Editor** (or Database → SQL Editor)
4. Click **"New query"**

### Step 2: Copy and Run This SQL

**Copy ALL of this and paste into the SQL editor, then click "Run":**

```sql
-- ===================================
-- STREAM Database Setup - Complete
-- ===================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create users table (links to auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('therapist', 'patient', 'admin')) DEFAULT 'patient',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. Create policy for users
CREATE POLICY IF NOT EXISTS "Users can view own data" 
ON public.users
FOR SELECT 
USING (auth.uid() = id);

-- 5. Create therapist profiles table
CREATE TABLE IF NOT EXISTS public.therapist_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
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

-- 6. Enable RLS on therapist profiles
ALTER TABLE public.therapist_profiles ENABLE ROW LEVEL SECURITY;

-- 7. Create policy for therapist profiles
CREATE POLICY IF NOT EXISTS "Therapists can view own profile" 
ON public.therapist_profiles
FOR SELECT 
USING (auth.uid() = user_id);

-- 8. Create function to auto-create user records
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (NEW.id, NEW.email, 'patient')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create trigger for automatic user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 10. Add existing auth users to public.users as therapists
INSERT INTO public.users (id, email, role)
SELECT id, email, 'therapist'
FROM auth.users
ON CONFLICT (id) DO UPDATE SET role = 'therapist';

-- 11. Create therapist profiles for existing users
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
SELECT 
  u.id, 
  'Dr. ' || COALESCE(SPLIT_PART(u.email, '@', 1), 'Therapist'),
  'STREAM Clinic'
FROM public.users u
WHERE u.role = 'therapist'
  AND NOT EXISTS (
    SELECT 1 FROM public.therapist_profiles tp WHERE tp.user_id = u.id
  );

-- 12. Create patients table (optional but recommended)
CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  avatar_url TEXT,
  age INTEGER,
  stroke_type TEXT,
  condition TEXT,
  enrolled_date DATE DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'needs_attention', 'inactive')),
  last_session DATE,
  adherence_rate INTEGER DEFAULT 0,
  total_sessions INTEGER DEFAULT 0,
  avg_accuracy DECIMAL(5,2) DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Therapists can view all patients" 
ON public.patients
FOR SELECT 
USING (auth.role() = 'authenticated');

-- 13. Add sample patients for testing
INSERT INTO public.patients (name, email, age, stroke_type, condition, adherence_rate, total_sessions, avg_accuracy, current_streak, status, last_session) VALUES
  ('John Doe', 'john.doe@example.com', 65, 'Ischemic', 'Right-side weakness', 85, 24, 78.50, 12, 'active', CURRENT_DATE - INTERVAL '1 day'),
  ('Jane Smith', 'jane.smith@example.com', 58, 'Hemorrhagic', 'Left-side weakness', 72, 18, 65.30, 8, 'active', CURRENT_DATE - INTERVAL '2 days'),
  ('Bob Johnson', 'bob.johnson@example.com', 71, 'Ischemic', 'Balance issues', 45, 10, 52.10, 3, 'needs_attention', CURRENT_DATE - INTERVAL '5 days'),
  ('Sarah Williams', 'sarah.w@example.com', 62, 'Ischemic', 'Speech difficulties', 91, 32, 88.20, 18, 'active', CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Database setup complete!';
  RAISE NOTICE '✅ Users table created with auto-sync trigger';
  RAISE NOTICE '✅ Therapist profiles table created';
  RAISE NOTICE '✅ Sample patients added';
  RAISE NOTICE '🎉 You can now log in to the app!';
END $$;
```

### Step 3: Verify Success

After running the SQL, you should see:
- ✅ "Success. No rows returned"
- ✅ Green checkmark icon
- ✅ Notice messages in the output

### Step 4: Check Tables

1. Go to **Table Editor** in Supabase
2. You should see these tables:
   - ✅ `users` (with your email and role = 'therapist')
   - ✅ `therapist_profiles` (with your profile)
   - ✅ `patients` (with 4 sample patients)

---

## 🧪 Test Login

1. Go back to your app: http://localhost:5173/login
2. Log in with your Supabase credentials
3. You should be redirected to `/dashboard`
4. You'll see:
   - Your name in the top right
   - 4 sample patients in the table
   - Stats cards

---

## 🔍 Verify Your Account

To check your account was set up correctly, run this in SQL Editor:

```sql
-- Check your user record
SELECT u.*, tp.name, tp.clinic_name
FROM public.users u
LEFT JOIN public.therapist_profiles tp ON tp.user_id = u.id
WHERE u.email = 'your-email@example.com';  -- Replace with your email
```

You should see:
- `role`: therapist
- `name`: Dr. YourName
- `clinic_name`: STREAM Clinic

---

## 🚨 Troubleshooting

### Issue: "relation 'public.users' already exists"
**Solution:** Table already exists, that's fine! The SQL uses `IF NOT EXISTS`

### Issue: Still getting "User record not found"
**Solution:** Check if the INSERT worked:
```sql
SELECT * FROM public.users WHERE email = 'your-email@example.com';
```

If empty, manually insert:
```sql
INSERT INTO public.users (id, email, role)
SELECT id, email, 'therapist'
FROM auth.users
WHERE email = 'your-email@example.com';
```

### Issue: "Could not find policy"
**Solution:** RLS policies are optional. The app will still work.

---

## ✅ After Setup Checklist

- [ ] SQL executed without errors
- [ ] `users` table exists
- [ ] `therapist_profiles` table exists
- [ ] `patients` table exists (optional)
- [ ] Your user has role = 'therapist'
- [ ] You can log in successfully
- [ ] Dashboard shows sample patients

---

## 🎯 What This SQL Does

1. **Creates the `users` table** - Stores user roles (therapist/patient/admin)
2. **Creates auto-sync trigger** - New signups automatically get a user record
3. **Adds you as a therapist** - Sets your existing account to 'therapist' role
4. **Creates therapist profile** - Adds your profile information
5. **Adds sample data** - 4 test patients so you can see the dashboard working
6. **Sets up security** - Row Level Security policies for data protection

---

**Ready?** Copy the SQL from Step 2 and run it in Supabase SQL Editor!
