-- ============================================================
-- STREAM database schema snapshot (public schema)
-- Snapshot date: 2026-10-14 (UTC)
-- REFERENCE ONLY, NOT A MIGRATION: do not run this file. It describes what is live;
-- the migrations in supabase/migrations/ are what is applied.
-- Generated from read-only catalog queries (pg_class, pg_attribute, pg_constraint,
-- pg_indexes, pg_policies, pg_get_functiondef, pg_get_triggerdef) through
-- `supabase db query --linked` inside BEGIN; SET TRANSACTION READ ONLY; ... ROLLBACK;
-- (`supabase db dump` needs Docker, which is not installed on the machine used).
-- No row data is in this file, only definitions.
--
-- Server: PostgreSQL 17.6 on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 15.2.0, 64-bit; TimeZone UTC
-- Extensions: pg_stat_statements 1.11, pgcrypto 1.3, plpgsql 1.0, supabase_vault 0.3.1, uuid-ossp 1.1
-- ============================================================

-- ------------------------------------------------------------
-- TABLES (columns, constraints), row level security, privileges
-- ------------------------------------------------------------

-- table public.alerts  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.alerts (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  patient_id uuid NOT NULL,
  type text NOT NULL,
  priority text NOT NULL,
  message text NOT NULL,
  resolved boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  resolved_at timestamp with time zone,
  CONSTRAINT alerts_priority_check CHECK ((priority = ANY (ARRAY['high'::text, 'moderate'::text, 'low'::text]))),
  CONSTRAINT alerts_type_check CHECK ((type = ANY (ARRAY['missed_session'::text, 'low_performance'::text, 'technical_issue'::text]))),
  CONSTRAINT alerts_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  CONSTRAINT alerts_pkey PRIMARY KEY (id)
);

-- table public.exercise_plans  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.exercise_plans (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  patient_id uuid NOT NULL,
  therapist_id uuid NOT NULL,
  name text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT exercise_plans_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'draft'::text]))),
  CONSTRAINT exercise_plans_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  CONSTRAINT exercise_plans_therapist_id_fkey FOREIGN KEY (therapist_id) REFERENCES therapist_profiles(id),
  CONSTRAINT exercise_plans_pkey PRIMARY KEY (id)
);

-- table public.exercises  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.exercises (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  name text NOT NULL,
  description text,
  category text NOT NULL,
  difficulty text NOT NULL,
  thumbnail_url text,
  instructions text,
  duration_minutes integer DEFAULT 10,
  created_at timestamp with time zone DEFAULT now(),
  target_joints text[],
  video_url text,
  duration_seconds integer DEFAULT 0,
  CONSTRAINT exercises_category_check CHECK ((category = ANY (ARRAY['upper_body'::text, 'lower_body'::text, 'balance'::text, 'flexibility'::text]))),
  CONSTRAINT exercises_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text]))),
  CONSTRAINT exercises_pkey PRIMARY KEY (id)
);

-- table public.messages  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.messages (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  sender_id uuid NOT NULL,
  receiver_id uuid NOT NULL,
  content text NOT NULL,
  read_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES users(id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES users(id),
  CONSTRAINT messages_pkey PRIMARY KEY (id)
);

-- table public.notifications  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.notifications (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  user_id uuid NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_type_check CHECK ((type = ANY (ARRAY['session_reminder'::text, 'therapist_message'::text, 'plan_updated'::text, 'achievement'::text]))),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

-- table public.patients  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.patients (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  user_id uuid,
  name text NOT NULL,
  email text NOT NULL,
  avatar_url text,
  age integer,
  stroke_type text,
  condition text,
  enrolled_date date DEFAULT CURRENT_DATE,
  status text DEFAULT 'active'::text,
  last_session date,
  adherence_rate integer DEFAULT 0,
  total_sessions integer DEFAULT 0,
  avg_accuracy numeric(5,2) DEFAULT 0,
  current_streak integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  therapist_id uuid,
  claim_code text,
  reminders_enabled boolean DEFAULT true NOT NULL,
  session_summaries_enabled boolean DEFAULT true NOT NULL,
  therapist_messages_enabled boolean DEFAULT true NOT NULL,
  weekly_reports_enabled boolean DEFAULT false NOT NULL,
  haptic_feedback_enabled boolean DEFAULT true NOT NULL,
  voice_guidance_enabled boolean DEFAULT false NOT NULL,
  high_contrast_enabled boolean DEFAULT false NOT NULL,
  large_text_enabled boolean DEFAULT false NOT NULL,
  CONSTRAINT patients_status_check CHECK ((status = ANY (ARRAY['active'::text, 'needs_attention'::text, 'inactive'::text]))),
  CONSTRAINT patients_therapist_id_fkey FOREIGN KEY (therapist_id) REFERENCES therapist_profiles(id) ON DELETE SET NULL,
  CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT patients_pkey PRIMARY KEY (id),
  CONSTRAINT patients_claim_code_key UNIQUE (claim_code),
  CONSTRAINT patients_user_id_key UNIQUE (user_id)
);

-- table public.plan_exercises  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.plan_exercises (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  plan_id uuid NOT NULL,
  exercise_id uuid NOT NULL,
  sets integer DEFAULT 3,
  reps integer DEFAULT 10,
  duration_minutes integer DEFAULT 10,
  difficulty text,
  special_instructions text,
  order integer DEFAULT 0,
  rom_min_degrees integer,
  rom_max_degrees integer,
  duration_seconds integer DEFAULT 0,
  CONSTRAINT plan_exercises_difficulty_check CHECK ((difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text]))),
  CONSTRAINT plan_exercises_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
  CONSTRAINT plan_exercises_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES exercise_plans(id) ON DELETE CASCADE,
  CONSTRAINT plan_exercises_pkey PRIMARY KEY (id)
);

-- table public.progress_metrics  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.progress_metrics (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  patient_id uuid NOT NULL,
  date date DEFAULT CURRENT_DATE NOT NULL,
  rom_degrees integer DEFAULT 0,
  strength_score integer DEFAULT 0,
  balance_score integer DEFAULT 0,
  adherence_percent integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT progress_metrics_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  CONSTRAINT progress_metrics_pkey PRIMARY KEY (id)
);

-- table public.session_logs  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
--   comment: Per-exercise result log for a session. One row per exercise per session. This is the authoritative source for reps, accuracy, and ROM data.
CREATE TABLE public.session_logs (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  session_id uuid NOT NULL,
  exercise_id uuid NOT NULL,
  reps_completed integer DEFAULT 0,
  accuracy_score numeric DEFAULT 0,
  range_of_motion numeric DEFAULT 0,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT session_logs_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES exercises(id),
  CONSTRAINT session_logs_session_id_fkey FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  CONSTRAINT session_logs_pkey PRIMARY KEY (id)
);

-- table public.session_notes  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.session_notes (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  patient_id uuid NOT NULL,
  therapist_id uuid NOT NULL,
  session_id uuid,
  note text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT session_notes_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  CONSTRAINT session_notes_session_id_fkey FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  CONSTRAINT session_notes_therapist_id_fkey FOREIGN KEY (therapist_id) REFERENCES therapist_profiles(id),
  CONSTRAINT session_notes_pkey PRIMARY KEY (id)
);

-- table public.sessions  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.sessions (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  patient_id uuid NOT NULL,
  exercise_id uuid,
  reps_completed integer DEFAULT 0,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  plan_id uuid,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  status text,
  duration_seconds integer DEFAULT 0,
  CONSTRAINT sessions_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'paused'::text, 'cancelled'::text]))),
  CONSTRAINT sessions_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES exercises(id),
  CONSTRAINT sessions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  CONSTRAINT sessions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES exercise_plans(id) ON DELETE SET NULL,
  CONSTRAINT sessions_pkey PRIMARY KEY (id)
);

-- table public.therapist_profiles  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.therapist_profiles (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  user_id uuid NOT NULL,
  name text NOT NULL,
  clinic_name text,
  license_number text,
  avatar_url text,
  email_alerts boolean DEFAULT true,
  in_app_alerts boolean DEFAULT true,
  weekly_summary boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  is_active boolean DEFAULT true NOT NULL,
  date_format text DEFAULT 'MM/DD/YYYY'::text NOT NULL,
  time_format text DEFAULT '12h'::text NOT NULL,
  session_reminders_enabled boolean DEFAULT true NOT NULL,
  CONSTRAINT therapist_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT therapist_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT therapist_profiles_user_id_key UNIQUE (user_id)
);

-- table public.users  [row level security: ON]
--   privileges (relacl): {postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}
CREATE TABLE public.users (
  id uuid NOT NULL,
  email text NOT NULL,
  role text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  full_name text,
  role_claimed boolean DEFAULT false NOT NULL,
  CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['therapist'::text, 'patient'::text, 'admin'::text]))),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_email_key UNIQUE (email)
);

-- ------------------------------------------------------------
-- INDEXES
-- ------------------------------------------------------------
CREATE UNIQUE INDEX alerts_pkey ON public.alerts USING btree (id);
CREATE UNIQUE INDEX exercise_plans_pkey ON public.exercise_plans USING btree (id);
CREATE UNIQUE INDEX exercises_pkey ON public.exercises USING btree (id);
CREATE UNIQUE INDEX messages_pkey ON public.messages USING btree (id);
CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);
CREATE INDEX idx_patients_therapist_id ON public.patients USING btree (therapist_id);
CREATE UNIQUE INDEX patients_claim_code_key ON public.patients USING btree (claim_code);
CREATE UNIQUE INDEX patients_pkey ON public.patients USING btree (id);
CREATE UNIQUE INDEX patients_user_id_key ON public.patients USING btree (user_id);
CREATE UNIQUE INDEX plan_exercises_pkey ON public.plan_exercises USING btree (id);
CREATE UNIQUE INDEX progress_metrics_pkey ON public.progress_metrics USING btree (id);
CREATE INDEX idx_session_logs_exercise_id ON public.session_logs USING btree (exercise_id);
CREATE INDEX idx_session_logs_session_exercise ON public.session_logs USING btree (session_id, exercise_id);
CREATE INDEX idx_session_logs_session_id ON public.session_logs USING btree (session_id);
CREATE UNIQUE INDEX session_logs_pkey ON public.session_logs USING btree (id);
CREATE UNIQUE INDEX session_notes_pkey ON public.session_notes USING btree (id);
CREATE UNIQUE INDEX sessions_pkey ON public.sessions USING btree (id);
CREATE UNIQUE INDEX therapist_profiles_pkey ON public.therapist_profiles USING btree (id);
CREATE UNIQUE INDEX therapist_profiles_user_id_key ON public.therapist_profiles USING btree (user_id);
CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);
CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY POLICIES
-- ------------------------------------------------------------
CREATE POLICY "alerts_insert_service" ON public.alerts AS PERMISSIVE FOR INSERT TO service_role
  WITH CHECK (true)
;
CREATE POLICY "alerts_therapist_select" ON public.alerts AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT p.id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "alerts_therapist_update" ON public.alerts AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((patient_id IN ( SELECT p.id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "exercise_plans_therapist_w" ON public.exercise_plans AS PERMISSIVE FOR ALL TO authenticated
  USING ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
  WITH CHECK ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
;
CREATE POLICY "exercise_plans_patient_r" ON public.exercise_plans AS PERMISSIVE FOR SELECT TO authenticated
  USING (((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))) OR (therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid())))))
;
CREATE POLICY "Anyone can view exercises" ON public.exercises AS PERMISSIVE FOR SELECT TO public
  USING ((auth.role() = 'authenticated'::text))
;
CREATE POLICY "Therapists can read all exercises" ON public.exercises AS PERMISSIVE FOR SELECT TO public
  USING ((auth.role() = 'authenticated'::text))
;
CREATE POLICY "exercises_read_all" ON public.exercises AS PERMISSIVE FOR SELECT TO authenticated
  USING (true)
;
CREATE POLICY "Users can send messages" ON public.messages AS PERMISSIVE FOR INSERT TO public
  WITH CHECK ((auth.uid() = sender_id))
;
CREATE POLICY "messages_insert" ON public.messages AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((sender_id = auth.uid()))
;
CREATE POLICY "Users can read their own messages" ON public.messages AS PERMISSIVE FOR SELECT TO public
  USING (((auth.uid() = sender_id) OR (auth.uid() = receiver_id)))
;
CREATE POLICY "messages_select" ON public.messages AS PERMISSIVE FOR SELECT TO authenticated
  USING (((sender_id = auth.uid()) OR (receiver_id = auth.uid())))
;
CREATE POLICY "messages_update" ON public.messages AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((receiver_id = auth.uid()))
;
CREATE POLICY "notifications_insert_s" ON public.notifications AS PERMISSIVE FOR INSERT TO service_role
  WITH CHECK (true)
;
CREATE POLICY "notifications_therapist_insert" ON public.notifications AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((user_id IN ( SELECT p.user_id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE ((tp.user_id = auth.uid()) AND (p.user_id IS NOT NULL)))))
;
CREATE POLICY "Users can read their own notifications" ON public.notifications AS PERMISSIVE FOR SELECT TO public
  USING (((auth.uid())::text = ( SELECT (users.id)::text AS id
   FROM users
  WHERE (users.id = notifications.user_id))))
;
CREATE POLICY "notifications_select" ON public.notifications AS PERMISSIVE FOR SELECT TO authenticated
  USING ((user_id = auth.uid()))
;
CREATE POLICY "Users can update their own notifications" ON public.notifications AS PERMISSIVE FOR UPDATE TO public
  USING (((auth.uid())::text = ( SELECT (users.id)::text AS id
   FROM users
  WHERE (users.id = notifications.user_id))))
;
CREATE POLICY "notifications_update" ON public.notifications AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((user_id = auth.uid()))
;
CREATE POLICY "Patient can insert own profile" ON public.patients AS PERMISSIVE FOR INSERT TO public
  WITH CHECK ((auth.uid() = user_id))
;
CREATE POLICY "patients_therapist_insert" ON public.patients AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
;
CREATE POLICY "Patient can read own profile" ON public.patients AS PERMISSIVE FOR SELECT TO public
  USING ((auth.uid() = user_id))
;
CREATE POLICY "patients_self_link_r" ON public.patients AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id IS NULL) AND (email = (auth.jwt() ->> 'email'::text))))
;
CREATE POLICY "patients_self_select" ON public.patients AS PERMISSIVE FOR SELECT TO authenticated
  USING ((user_id = auth.uid()))
;
CREATE POLICY "patients_therapist_r" ON public.patients AS PERMISSIVE FOR SELECT TO authenticated
  USING ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
;
CREATE POLICY "patients_therapist_unassigned_r" ON public.patients AS PERMISSIVE FOR SELECT TO authenticated
  USING (((therapist_id IS NULL) AND (EXISTS ( SELECT 1
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid())))))
;
CREATE POLICY "Patient can update own profile" ON public.patients AS PERMISSIVE FOR UPDATE TO public
  USING ((auth.uid() = user_id))
;
CREATE POLICY "patients_self_link_u" ON public.patients AS PERMISSIVE FOR UPDATE TO authenticated
  USING (((user_id IS NULL) AND (email = (auth.jwt() ->> 'email'::text))))
  WITH CHECK ((user_id = auth.uid()))
;
CREATE POLICY "patients_self_update" ON public.patients AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()))
;
CREATE POLICY "plan_exercises_therapist_w" ON public.plan_exercises AS PERMISSIVE FOR ALL TO authenticated
  USING ((plan_id IN ( SELECT exercise_plans.id
   FROM exercise_plans
  WHERE (exercise_plans.therapist_id IN ( SELECT therapist_profiles.id
           FROM therapist_profiles
          WHERE (therapist_profiles.user_id = auth.uid()))))))
;
CREATE POLICY "plan_exercises_read" ON public.plan_exercises AS PERMISSIVE FOR SELECT TO authenticated
  USING ((plan_id IN ( SELECT ep.id
   FROM exercise_plans ep
  WHERE ((ep.patient_id IN ( SELECT patients.id
           FROM patients
          WHERE (patients.user_id = auth.uid()))) OR (ep.therapist_id IN ( SELECT therapist_profiles.id
           FROM therapist_profiles
          WHERE (therapist_profiles.user_id = auth.uid())))))))
;
CREATE POLICY "progress_metrics_patient_r" ON public.progress_metrics AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))))
;
CREATE POLICY "progress_metrics_therapist_r" ON public.progress_metrics AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT p.id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "session_logs_patient_insert" ON public.session_logs AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((session_id IN ( SELECT s.id
   FROM (sessions s
     JOIN patients p ON ((p.id = s.patient_id)))
  WHERE (p.user_id = auth.uid()))))
;
CREATE POLICY "session_logs_patient_select" ON public.session_logs AS PERMISSIVE FOR SELECT TO authenticated
  USING ((session_id IN ( SELECT s.id
   FROM (sessions s
     JOIN patients p ON ((p.id = s.patient_id)))
  WHERE (p.user_id = auth.uid()))))
;
CREATE POLICY "session_logs_therapist_select" ON public.session_logs AS PERMISSIVE FOR SELECT TO authenticated
  USING ((session_id IN ( SELECT s.id
   FROM ((sessions s
     JOIN patients p ON ((p.id = s.patient_id)))
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "session_notes_therapist_w" ON public.session_notes AS PERMISSIVE FOR ALL TO authenticated
  USING ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
  WITH CHECK ((therapist_id IN ( SELECT therapist_profiles.id
   FROM therapist_profiles
  WHERE (therapist_profiles.user_id = auth.uid()))))
;
CREATE POLICY "session_notes_patient_r" ON public.session_notes AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))))
;
CREATE POLICY "sessions_patient_insert" ON public.sessions AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))))
;
CREATE POLICY "sessions_therapist_insert" ON public.sessions AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((patient_id IN ( SELECT p.id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "sessions_patient_select" ON public.sessions AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))))
;
CREATE POLICY "sessions_therapist_r" ON public.sessions AS PERMISSIVE FOR SELECT TO authenticated
  USING ((patient_id IN ( SELECT p.id
   FROM (patients p
     JOIN therapist_profiles tp ON ((tp.id = p.therapist_id)))
  WHERE (tp.user_id = auth.uid()))))
;
CREATE POLICY "sessions_patient_update" ON public.sessions AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((patient_id IN ( SELECT patients.id
   FROM patients
  WHERE (patients.user_id = auth.uid()))))
;
CREATE POLICY "Admins can delete therapist_profiles" ON public.therapist_profiles AS PERMISSIVE FOR DELETE TO public
  USING (is_admin())
;
CREATE POLICY "Admins can insert therapist_profiles" ON public.therapist_profiles AS PERMISSIVE FOR INSERT TO public
  WITH CHECK (is_admin())
;
CREATE POLICY "therapist_profiles_insert_own" ON public.therapist_profiles AS PERMISSIVE FOR INSERT TO public
  WITH CHECK ((auth.uid() = user_id))
;
CREATE POLICY "Admins can select therapist_profiles" ON public.therapist_profiles AS PERMISSIVE FOR SELECT TO public
  USING (is_admin())
;
CREATE POLICY "therapist_profiles_select_own" ON public.therapist_profiles AS PERMISSIVE FOR SELECT TO public
  USING ((auth.uid() = user_id))
;
CREATE POLICY "Admins can update therapist_profiles" ON public.therapist_profiles AS PERMISSIVE FOR UPDATE TO public
  USING (is_admin())
;
CREATE POLICY "therapist_profiles_update_own" ON public.therapist_profiles AS PERMISSIVE FOR UPDATE TO public
  USING ((auth.uid() = user_id))
  WITH CHECK ((auth.uid() = user_id))
;
CREATE POLICY "Admins can delete users" ON public.users AS PERMISSIVE FOR DELETE TO public
  USING (is_admin())
;
CREATE POLICY "Admins can insert users" ON public.users AS PERMISSIVE FOR INSERT TO public
  WITH CHECK (is_admin())
;
CREATE POLICY "users_insert_own" ON public.users AS PERMISSIVE FOR INSERT TO public
  WITH CHECK ((auth.uid() = id))
;
CREATE POLICY "Admins can select users" ON public.users AS PERMISSIVE FOR SELECT TO public
  USING (is_admin())
;
CREATE POLICY "users_select_own" ON public.users AS PERMISSIVE FOR SELECT TO public
  USING ((auth.uid() = id))
;
CREATE POLICY "Admins can update users" ON public.users AS PERMISSIVE FOR UPDATE TO public
  USING (is_admin())
;
CREATE POLICY "users_update_own" ON public.users AS PERMISSIVE FOR UPDATE TO public
  USING ((auth.uid() = id))
  WITH CHECK (((auth.uid() = id) AND ((role = stored_role()) OR is_admin() OR role_unclaimed())))
;

-- ------------------------------------------------------------
-- FUNCTIONS (definition, owner, privileges)
-- ------------------------------------------------------------

-- claim_patient_record(p_email text, p_code text)  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.claim_patient_record(p_email text, p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_patient_id uuid;
BEGIN
  IF p_email IS DISTINCT FROM (auth.jwt() ->> 'email') THEN
    RETURN NULL;
  END IF;

  UPDATE public.patients
  SET user_id = auth.uid()
  WHERE email = p_email
    AND claim_code = p_code
    AND user_id IS NULL
  RETURNING id INTO v_patient_id;

  RETURN v_patient_id;
END;
$function$;

-- create_low_accuracy_alert(p_patient_id uuid, p_threshold numeric)  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.create_low_accuracy_alert(p_patient_id uuid, p_threshold numeric DEFAULT 60)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_recent_avg  numeric;
  v_open_alert  uuid;
BEGIN
  -- Average accuracy of the last 3 logs for this patient
  SELECT COALESCE(ROUND(AVG(sl.accuracy_score), 2), 0)
  INTO   v_recent_avg
  FROM (
    SELECT sl.accuracy_score
    FROM   public.session_logs sl
    JOIN   public.sessions s ON s.id = sl.session_id
    WHERE  s.patient_id = p_patient_id
    ORDER  BY sl.created_at DESC
    LIMIT  3
  ) sl;

  -- Only create alert if below threshold
  IF v_recent_avg < p_threshold THEN
    -- Check for an already-open (unresolved) low_performance alert
    SELECT id INTO v_open_alert
    FROM   public.alerts
    WHERE  patient_id = p_patient_id
      AND  type       = 'low_performance'
      AND  resolved   = false
    LIMIT  1;

    -- Only insert if no open alert exists (avoids duplicate spam)
    IF v_open_alert IS NULL THEN
      INSERT INTO public.alerts (
        patient_id,
        type,
        priority,
        message,
        resolved,
        created_at
      )
      VALUES (
        p_patient_id,
        'low_performance',
        CASE
          WHEN v_recent_avg < 40 THEN 'high'
          WHEN v_recent_avg < 50 THEN 'moderate'
          ELSE 'low'
        END,
        'Patient accuracy has dropped to ' || v_recent_avg ||
          '% (last 3 exercises). Review exercise plan or schedule a check-in.',
        false,
        now()
      );
    END IF;
  END IF;
END;
$function$;

-- create_missed_session_alerts()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.create_missed_session_alerts()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  rec           RECORD;
  v_open_alert  uuid;
BEGIN
  -- Find patients with an active plan where yesterday had no session
  FOR rec IN
    SELECT DISTINCT p.id AS patient_id
    FROM   public.patients p
    JOIN   public.exercise_plans ep
           ON  ep.patient_id = p.id
           AND ep.status     = 'active'
           AND ep.start_date <= CURRENT_DATE - 1
           AND ep.end_date   >= CURRENT_DATE - 1
    WHERE  p.status = 'active'
      AND  NOT EXISTS (
        SELECT 1
        FROM   public.sessions s
        WHERE  s.patient_id        = p.id
          AND  s.status            = 'completed'
          AND  s.completed_at::date = CURRENT_DATE - 1
      )
  LOOP
    -- Avoid duplicate open missed_session alerts
    SELECT id INTO v_open_alert
    FROM   public.alerts
    WHERE  patient_id = rec.patient_id
      AND  type       = 'missed_session'
      AND  resolved   = false
      AND  created_at::date = CURRENT_DATE
    LIMIT  1;

    IF v_open_alert IS NULL THEN
      INSERT INTO public.alerts (
        patient_id,
        type,
        priority,
        message,
        resolved,
        created_at
      )
      VALUES (
        rec.patient_id,
        'missed_session',
        'moderate',
        'Patient did not complete any sessions on ' ||
          TO_CHAR(CURRENT_DATE - 1, 'Mon DD, YYYY') || '.',
        false,
        now()
      );
    END IF;
  END LOOP;
END;
$function$;

-- get_my_therapist()  owner: postgres  acl: {postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.get_my_therapist()
 RETURNS TABLE(user_id uuid, full_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    tp.user_id,
    COALESCE(NULLIF(btrim(u.full_name), ''), tp.name) AS full_name
  FROM public.patients p
  JOIN public.therapist_profiles tp ON tp.id = p.therapist_id
  JOIN public.users u ON u.id = tp.user_id
  WHERE p.user_id = auth.uid()
  LIMIT 1;
$function$;

-- handle_new_user()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.users (id, email, role, role_claimed)
  VALUES (NEW.id, NEW.email, 'patient', false)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$function$;

-- is_admin()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
$function$;

-- mark_role_claimed()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.mark_role_claimed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    NEW.role_claimed := true;
  END IF;
  RETURN NEW;
END;
$function$;

-- recalculate_patient_stats(p_patient_id uuid)  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.recalculate_patient_stats(p_patient_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_total_sessions  integer;
  v_avg_accuracy    numeric;
  v_last_session    date;
  v_streak          integer := 0;
  v_check_date      date    := CURRENT_DATE;
  v_enrolled_date   date;
  v_has_session     boolean;
  v_adherence_rate  integer;
BEGIN
  -- Total completed sessions
  SELECT COUNT(DISTINCT s.id)
  INTO   v_total_sessions
  FROM   public.sessions s
  WHERE  s.patient_id = p_patient_id
    AND  s.status = 'completed';

  -- Average accuracy across all session_logs for this patient
  SELECT COALESCE(ROUND(AVG(sl.accuracy_score), 2), 0)
  INTO   v_avg_accuracy
  FROM   public.session_logs sl
  JOIN   public.sessions s ON s.id = sl.session_id
  WHERE  s.patient_id = p_patient_id
    AND  s.status = 'completed';

  -- Date of most recent completed session
  SELECT MAX(s.completed_at::date)
  INTO   v_last_session
  FROM   public.sessions s
  WHERE  s.patient_id = p_patient_id
    AND  s.status = 'completed';

  -- Current streak: walk backwards from today until a gap day is found
  v_check_date := CURRENT_DATE;
  LOOP
    SELECT EXISTS (
      SELECT 1
      FROM   public.sessions s
      WHERE  s.patient_id        = p_patient_id
        AND  s.status            = 'completed'
        AND  s.completed_at::date = v_check_date
    ) INTO v_has_session;

    EXIT WHEN NOT v_has_session;
    v_streak     := v_streak + 1;
    v_check_date := v_check_date - INTERVAL '1 day';
  END LOOP;

  -- Enrolled date for adherence denominator
  SELECT COALESCE(enrolled_date, CURRENT_DATE)
  INTO   v_enrolled_date
  FROM   public.patients
  WHERE  id = p_patient_id;

  -- Adherence: sessions completed / days enrolled × 100, capped at 100
  v_adherence_rate := LEAST(
    100,
    CASE
      WHEN (CURRENT_DATE - v_enrolled_date) = 0 THEN 0
      ELSE ROUND(
        (v_total_sessions::numeric
          / GREATEST((CURRENT_DATE - v_enrolled_date), 1)
        ) * 100
      )
    END
  )::integer;

  -- Write all stats back to patients row
  UPDATE public.patients
  SET
    total_sessions = v_total_sessions,
    avg_accuracy   = v_avg_accuracy,
    last_session   = v_last_session,
    current_streak = v_streak,
    adherence_rate = v_adherence_rate,
    updated_at     = now()
  WHERE id = p_patient_id;
END;
$function$;

-- role_unclaimed()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.role_unclaimed()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role_claimed = false
  );
$function$;

-- stored_role()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.stored_role()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT role FROM public.users WHERE id = auth.uid();
$function$;

-- trg_fn_after_session_log_insert()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.trg_fn_after_session_log_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_patient_id uuid;
BEGIN
  -- Resolve patient_id from the parent session
  SELECT patient_id
  INTO   v_patient_id
  FROM   public.sessions
  WHERE  id = NEW.session_id;

  IF v_patient_id IS NOT NULL THEN
    PERFORM public.recalculate_patient_stats(v_patient_id);
    PERFORM public.create_low_accuracy_alert(v_patient_id);
  END IF;

  RETURN NEW;
END;
$function$;

-- trg_fn_after_session_status_update()  owner: postgres  acl: {=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
CREATE OR REPLACE FUNCTION public.trg_fn_after_session_status_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'completed' AND
    (OLD.status IS DISTINCT FROM 'completed') THEN
    PERFORM public.recalculate_patient_stats(NEW.patient_id);
  END IF;
  RETURN NEW;
END;
$function$;

-- ------------------------------------------------------------
-- TRIGGERS
-- ------------------------------------------------------------
-- session_logs.trg_after_session_log_insert enabled=O
CREATE TRIGGER trg_after_session_log_insert AFTER INSERT ON public.session_logs FOR EACH ROW EXECUTE FUNCTION trg_fn_after_session_log_insert();
-- sessions.trg_after_session_status_update enabled=O
CREATE TRIGGER trg_after_session_status_update AFTER UPDATE OF status ON public.sessions FOR EACH ROW EXECUTE FUNCTION trg_fn_after_session_status_update();
-- users.before_users_role_change enabled=O
CREATE TRIGGER before_users_role_change BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION mark_role_claimed();

-- REALTIME PUBLICATIONS (tables published)
-- supabase_realtime: public.messages
-- supabase_realtime_messages_publication: realtime.messages_2026_10_02
-- supabase_realtime_messages_publication: realtime.messages_2026_10_03
-- supabase_realtime_messages_publication: realtime.messages_2026_10_04
-- supabase_realtime_messages_publication: realtime.messages_2026_10_05
-- supabase_realtime_messages_publication: realtime.messages_2026_10_06
-- supabase_realtime_messages_publication: realtime.messages_2026_10_07
-- supabase_realtime_messages_publication: realtime.messages_2026_10_08
