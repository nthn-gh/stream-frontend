# 🔧 Supabase Setup Guide for STREAM

## Step 1: Create Supabase Account

1. Go to https://supabase.com
2. Click **"Start your project"** or **"Sign In"**
3. Sign up with GitHub, Google, or email
4. Verify your email if needed

---

## Step 2: Create New Project

1. Click **"New Project"** in your organization
2. Fill in project details:
   - **Name:** STREAM Therapist Dashboard
   - **Database Password:** Generate a strong password (save it!)
   - **Region:** Choose closest to you (e.g., US West, EU Central)
   - **Pricing Plan:** Free tier is fine for development
3. Click **"Create new project"**
4. Wait ~2 minutes for project to initialize

---

## Step 3: Get Your Credentials

Once your project is ready:

1. Go to **Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. You'll see:

   **Project URL:**
   ```
   https://xxxxxxxxxxxxx.supabase.co
   ```
   
   **Project API keys:**
   - `anon` `public` key (this is what you need)
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4eHh4eHh4eHh4eHgiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzOTU4ODcyNywiZXhwIjoxOTU1MTY0NzI3fQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. Copy both values

---

## Step 4: Update .env File

Open `c:\Users\Ethan\stream\stream-frontend\.env` and update:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4eHh4eHh4eHh4eHgiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzOTU4ODcyNywiZXhwIjoxOTU1MTY0NzI3fQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# App Configuration
VITE_APP_NAME=STREAM Therapist Dashboard
VITE_APP_VERSION=1.0.0
```

Replace the placeholder values with your actual URL and key.

---

## Step 5: Create Database Tables

Go to **SQL Editor** in Supabase dashboard and run this SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('therapist', 'patient', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Therapist profiles
CREATE TABLE public.therapist_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Patients
CREATE TABLE public.patients (
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

-- Exercises
CREATE TABLE public.exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('upper_body', 'lower_body', 'balance', 'flexibility')),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  thumbnail_url TEXT,
  instructions TEXT,
  duration_minutes INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercise plans
CREATE TABLE public.exercise_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  therapist_id UUID NOT NULL REFERENCES public.therapist_profiles(id),
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'draft')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Plan exercises (junction table)
CREATE TABLE public.plan_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES public.exercise_plans(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  sets INTEGER DEFAULT 3,
  reps INTEGER DEFAULT 10,
  duration_minutes INTEGER DEFAULT 10,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  special_instructions TEXT,
  "order" INTEGER DEFAULT 0
);

-- Sessions
CREATE TABLE public.sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  sets_completed INTEGER DEFAULT 0,
  reps_completed INTEGER DEFAULT 0,
  accuracy_percent DECIMAL(5,2) DEFAULT 0,
  form_quality TEXT CHECK (form_quality IN ('excellent', 'good', 'needs_work')),
  duration_minutes INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Progress metrics
CREATE TABLE public.progress_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  rom_degrees INTEGER DEFAULT 0,
  strength_score INTEGER DEFAULT 0,
  balance_score INTEGER DEFAULT 0,
  adherence_percent INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alerts
CREATE TABLE public.alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('missed_session', 'low_performance', 'technical_issue')),
  priority TEXT NOT NULL CHECK (priority IN ('high', 'moderate', 'low')),
  message TEXT NOT NULL,
  resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- Session notes
CREATE TABLE public.session_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  therapist_id UUID NOT NULL REFERENCES public.therapist_profiles(id),
  session_id UUID REFERENCES public.sessions(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapist_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_notes ENABLE ROW LEVEL SECURITY;

-- Create policies (therapists can read/write their data)
CREATE POLICY "Therapists can read all patients" ON public.patients
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Therapists can read all exercises" ON public.exercises
  FOR SELECT USING (auth.role() = 'authenticated');

-- Add more policies as needed for your security requirements
```

---

## Step 6: Add Sample Data (Optional)

Run this to add test data:

```sql
-- Insert a test therapist user (you'll need to sign up first through the app)
-- After signing up, run this to set the role:
UPDATE public.users SET role = 'therapist' WHERE email = 'your-email@example.com';

-- Insert sample exercises
INSERT INTO public.exercises (name, description, category, difficulty, instructions) VALUES
  ('Shoulder Flexion', 'Raise arm forward and upward', 'upper_body', 'easy', 'Stand with feet shoulder-width apart...'),
  ('Elbow Extension', 'Straighten arm at elbow joint', 'upper_body', 'medium', 'Sit or stand with good posture...'),
  ('Ankle Dorsiflexion', 'Pull toes toward shin', 'lower_body', 'easy', 'Sit with leg extended...'),
  ('Balance Training', 'Stand on one leg', 'balance', 'medium', 'Stand near a wall for support...');

-- Insert sample patients (adjust as needed)
INSERT INTO public.patients (name, email, age, stroke_type, condition, adherence_rate, total_sessions, avg_accuracy, current_streak) VALUES
  ('John Doe', 'john@example.com', 65, 'Ischemic', 'Right-side weakness', 85, 24, 78.5, 12),
  ('Jane Smith', 'jane@example.com', 58, 'Hemorrhagic', 'Left-side weakness', 72, 18, 65.3, 8),
  ('Bob Johnson', 'bob@example.com', 71, 'Ischemic', 'Balance issues', 45, 10, 52.1, 3);

-- Insert sample alert
INSERT INTO public.alerts (patient_id, type, priority, message) 
SELECT id, 'missed_session', 'moderate', 'Patient missed scheduled session on ' || CURRENT_DATE 
FROM public.patients LIMIT 1;
```

---

## Step 7: Enable Realtime (for Alerts)

1. Go to **Database** → **Replication** in Supabase dashboard
2. Find the `alerts` table
3. Toggle **"Enable Realtime"**
4. This allows real-time subscription to alert changes

---

## Step 8: Test Your Setup

1. Restart your dev server:
   ```bash
   npm run dev
   ```

2. Open http://localhost:5173

3. You should see the login page without errors

---

## Step 9: Create Your First User

### Option A: Using Supabase Dashboard
1. Go to **Authentication** → **Users** in Supabase
2. Click **"Add user"**
3. Enter email and password
4. Click **"Create user"**

### Option B: Sign up through the app
1. (If you implement signup) Use the signup form
2. Check your email for verification
3. Verify your account

### Set User Role
After creating a user, run this SQL:
```sql
-- Set user as therapist
UPDATE public.users 
SET role = 'therapist' 
WHERE email = 'your-email@example.com';

-- Create therapist profile
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
SELECT id, 'Dr. Your Name', 'Your Clinic'
FROM public.users
WHERE email = 'your-email@example.com';
```

---

## ✅ Verification Checklist

- [ ] Supabase project created
- [ ] `.env` file updated with URL and anon key
- [ ] All database tables created
- [ ] Sample data inserted (optional)
- [ ] Realtime enabled for alerts table
- [ ] Test user created with 'therapist' role
- [ ] Therapist profile created
- [ ] Dev server running without errors
- [ ] Can access login page

---

## 🚨 Troubleshooting

### Error: "Invalid supabaseUrl"
- Check `.env` file has correct URL (should start with `https://`)
- Restart dev server after updating `.env`

### Error: "Invalid API key"
- Verify you copied the **anon** key, not the service_role key
- Check for extra spaces or line breaks

### Can't login
- Make sure user role is set to 'therapist' in database
- Check therapist_profiles table has an entry
- Verify email is confirmed in Supabase auth

### Tables not showing up
- Run the SQL in **SQL Editor**, not in a SQL client
- Check for syntax errors in the SQL output
- Refresh the **Table Editor** page

---

## 🎯 Next Steps After Setup

1. Login with your test account
2. Explore the dashboard
3. Add more sample patients
4. Test the alert system
5. Customize the application for your needs

---

**Need help?** Check Supabase docs: https://supabase.com/docs
