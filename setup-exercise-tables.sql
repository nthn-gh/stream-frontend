-- Setup Exercise Plans Tables
-- Run this in Supabase SQL Editor

-- 1. Create exercises table
CREATE TABLE IF NOT EXISTS public.exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('upper_body', 'lower_body', 'balance', 'flexibility')),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  thumbnail_url TEXT,
  instructions TEXT,
  duration_minutes INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create exercise_plans table
CREATE TABLE IF NOT EXISTS public.exercise_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  therapist_id UUID NOT NULL REFERENCES public.therapist_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'draft')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create plan_exercises table (junction table)
CREATE TABLE IF NOT EXISTS public.plan_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.exercise_plans(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  sets INTEGER DEFAULT 3,
  reps INTEGER DEFAULT 10,
  duration_minutes INTEGER DEFAULT 10,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  special_instructions TEXT,
  "order" INTEGER DEFAULT 0
);

-- 4. Enable RLS
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_exercises ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for exercises (all authenticated users can read)
DROP POLICY IF EXISTS "Anyone can view exercises" ON public.exercises;
CREATE POLICY "Anyone can view exercises" 
ON public.exercises FOR SELECT 
USING (auth.role() = 'authenticated');

-- 6. RLS Policies for exercise_plans
DROP POLICY IF EXISTS "Therapists can view all plans" ON public.exercise_plans;
DROP POLICY IF EXISTS "Therapists can create plans" ON public.exercise_plans;
DROP POLICY IF EXISTS "Therapists can update own plans" ON public.exercise_plans;

CREATE POLICY "Therapists can view all plans" 
ON public.exercise_plans FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Therapists can create plans" 
ON public.exercise_plans FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Therapists can update own plans" 
ON public.exercise_plans FOR UPDATE 
USING (auth.role() = 'authenticated');

-- 7. RLS Policies for plan_exercises
DROP POLICY IF EXISTS "Therapists can view plan exercises" ON public.plan_exercises;
DROP POLICY IF EXISTS "Therapists can insert plan exercises" ON public.plan_exercises;
DROP POLICY IF EXISTS "Therapists can update plan exercises" ON public.plan_exercises;

CREATE POLICY "Therapists can view plan exercises" 
ON public.plan_exercises FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Therapists can insert plan exercises" 
ON public.plan_exercises FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Therapists can update plan exercises" 
ON public.plan_exercises FOR UPDATE 
USING (auth.role() = 'authenticated');

-- 8. Insert sample exercises
INSERT INTO public.exercises (name, description, category, difficulty, instructions) VALUES
  ('Shoulder Flexion', 'Raise arm forward and upward to improve shoulder range of motion', 'upper_body', 'easy', 'Stand with feet shoulder-width apart. Slowly raise your arm forward and up as high as comfortable. Hold for 2 seconds, then lower slowly.'),
  ('Elbow Extension', 'Straighten arm at elbow joint to improve arm strength', 'upper_body', 'medium', 'Sit or stand with good posture. Start with elbow bent at 90 degrees. Slowly straighten your arm completely. Hold for 2 seconds, then return to starting position.'),
  ('Wrist Rotation', 'Rotate wrist to improve mobility and flexibility', 'upper_body', 'easy', 'Extend arm in front of you. Slowly rotate your wrist in circles, first clockwise then counterclockwise.'),
  ('Ankle Dorsiflexion', 'Pull toes toward shin to improve ankle mobility', 'lower_body', 'easy', 'Sit with leg extended. Slowly pull your toes up toward your shin. Hold for 5 seconds, then relax.'),
  ('Knee Extension', 'Straighten leg to strengthen quadriceps', 'lower_body', 'medium', 'Sit in a chair. Slowly straighten your knee, lifting your foot off the ground. Hold for 5 seconds, then lower slowly.'),
  ('Seated Balance', 'Practice balance while seated', 'balance', 'easy', 'Sit on the edge of a stable chair. Lift one foot slightly off the ground and hold for 10 seconds. Switch feet.'),
  ('Standing Balance', 'Stand on one leg to improve balance', 'balance', 'medium', 'Stand near a wall for support. Lift one foot off the ground and balance for 10-30 seconds. Switch feet.'),
  ('Neck Rotation', 'Gentle neck stretches to improve flexibility', 'flexibility', 'easy', 'Sit or stand comfortably. Slowly turn your head to look over your shoulder. Hold for 5 seconds, then turn to the other side.')
ON CONFLICT DO NOTHING;

-- Success message
SELECT 
  'Exercise tables created successfully!' as message,
  (SELECT COUNT(*) FROM public.exercises) as exercise_count;
