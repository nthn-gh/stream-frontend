-- ============================================================
-- Add 8 settings columns to public.patients
--
-- Context: the Android patient app's SettingsScreen.kt (8 toggles:
-- Exercise Reminders, Session Summaries, Therapist Messages, Weekly
-- Reports, Haptic Feedback, Voice Guidance, High Contrast, Large
-- Text) and ProfileScreen.kt's "App Settings" section (a duplicate,
-- partial copy of 3 of those 8) were both local `remember {
-- mutableStateOf() }` state with zero persistence -- every toggle
-- reset to its hardcoded default on next app launch. Same category
-- of bug as the web portal's SettingsView.vue fix
-- (20260915b_add_therapist_preferences_columns.sql): a control that
-- looks saved but isn't.
--
-- public.patients had none of these columns and no separate
-- preferences table existed either -- confirmed live via PostgREST
-- (every candidate column name 400'd with 42703 "column does not
-- exist", cross-checked against a deliberately-fake negative-control
-- column name that also 400'd, and against known-real columns like
-- id/name/status that returned 200). So, unlike the web portal fix,
-- none of the 8 had a partial win to build on -- all 8 are new.
--
-- Naming: every column is `<thing>_enabled`, matching the
-- session_reminders_enabled precedent on therapist_profiles, so the
-- convention doesn't have to be rediscovered next time.
--
-- Haptic Feedback and Voice Guidance are conceptually device-local
-- (closer to "reduce motion" than to a clinical preference, the way
-- SettingsView.vue's Theme control is real but localStorage-only,
-- per-browser). They are deliberately NOT treated that way here --
-- there is no existing local-persistence pattern in this Android app
-- (no DataStore/SharedPreferences usage anywhere) to build on, so
-- real device-local storage would be new infrastructure rather than
-- reuse, and this app requires login regardless so "survives
-- offline/no-account" doesn't buy anything. They're stored as
-- ordinary server-synced patients columns instead, same as the other
-- six. This is a deliberate simplification, not an oversight -- if a
-- future session wants true per-device haptics/voice-guidance
-- (e.g. because a patient wants them off on one device but on
-- another), that needs a new DataStore-backed local layer, not a
-- change to these columns.
--
-- Defaults match each toggle's current fake-UI default exactly, so
-- no existing patient sees a behavior change the moment this ships:
-- true for Exercise Reminders, Session Summaries, Therapist
-- Messages, Haptic Feedback; false for Weekly Reports, Voice
-- Guidance, High Contrast, Large Text.
--
-- Additive, non-destructive: eight NOT NULL columns with defaults,
-- no data at risk, no existing column touched.
-- ============================================================

BEGIN;

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS reminders_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS session_summaries_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS therapist_messages_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS weekly_reports_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS haptic_feedback_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS voice_guidance_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS high_contrast_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS large_text_enabled boolean NOT NULL DEFAULT false;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   -- expect all eight columns, defaults applied to every existing row
--   SELECT column_name, column_default, is_nullable
--   FROM information_schema.columns
--   WHERE table_schema = 'public' AND table_name = 'patients'
--     AND column_name IN (
--       'reminders_enabled', 'session_summaries_enabled',
--       'therapist_messages_enabled', 'weekly_reports_enabled',
--       'haptic_feedback_enabled', 'voice_guidance_enabled',
--       'high_contrast_enabled', 'large_text_enabled'
--     );
--
--   -- expect zero -- every row should have picked up its default,
--   -- none should be null
--   SELECT count(*) FROM public.patients
--   WHERE reminders_enabled IS NULL OR session_summaries_enabled IS NULL
--      OR therapist_messages_enabled IS NULL OR weekly_reports_enabled IS NULL
--      OR haptic_feedback_enabled IS NULL OR voice_guidance_enabled IS NULL
--      OR high_contrast_enabled IS NULL OR large_text_enabled IS NULL;
--
-- Then regenerate src/services/database.types.ts via the Supabase CLI
-- so the web portal's types pick up the eight new columns too (same
-- `patients` table, shared by both apps).
-- ============================================================

-- ============================================================
-- ROLLBACK: DROP COLUMN IF EXISTS reminders_enabled,
-- session_summaries_enabled, therapist_messages_enabled,
-- weekly_reports_enabled, haptic_feedback_enabled,
-- voice_guidance_enabled, high_contrast_enabled, large_text_enabled
-- on public.patients -- safe, no data of consequence to lose
-- (defaults only, unless a patient has since changed a real setting
-- through the new SettingsScreen, in which case treat it the same as
-- any other real user data before dropping).
-- ============================================================
