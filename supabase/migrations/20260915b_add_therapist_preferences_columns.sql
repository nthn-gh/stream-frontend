-- ============================================================
-- Add date_format/time_format/session_reminders_enabled to
-- public.therapist_profiles
--
-- Context: SettingsView.vue's Preferences tab has a real, working
-- Theme control (persisted to localStorage via useTheme.ts -- real,
-- but per-browser, not per-therapist) sitting next to a Date Format
-- and Time Format control that was, until this change, entirely
-- fake (setTimeout + console.log, nothing persisted anywhere).
--
-- therapist_profiles already carries the precedent for "therapist
-- preference that should follow them across devices" --
-- email_alerts/in_app_alerts/weekly_summary are exactly that, real
-- and DB-backed on this same table, wired through
-- authStore.updateProfile(). date_format/time_format get the same
-- treatment rather than a client-side-only store, so a therapist
-- switching between a clinic desktop and a laptop sees the same
-- values either place -- the same reasoning theme itself doesn't
-- currently get (it's real but localStorage-only; not touched here,
-- out of scope).
--
-- session_reminders_enabled: the Notifications tab's "Session
-- Reminders" toggle ("Get reminders about upcoming patient sessions")
-- was initially going to reuse the existing weekly_summary column --
-- the only one of the three existing notification columns left
-- unclaimed by the other two toggles. Caught before applying: a
-- weekly digest email and per-session reminders are genuinely
-- different things a therapist might want independently, and
-- persisting one under the other's column would make the toggle lie
-- about what it does even though the save itself works. Added its
-- own column instead of relabeling the UI to match weekly_summary,
-- since the two concepts are real and distinct. weekly_summary
-- itself is left as-is -- it predates this change and has no UI
-- surface in this codebase today; not this migration's concern.
--
-- Additive, non-destructive: three nullable-with-default columns, no
-- data at risk. No pre-flight investigation needed the way the
-- sessions column drop required -- there's nothing to lose here, only
-- something to check after.
-- ============================================================

BEGIN;

ALTER TABLE public.therapist_profiles
  ADD COLUMN IF NOT EXISTS date_format text NOT NULL DEFAULT 'MM/DD/YYYY',
  ADD COLUMN IF NOT EXISTS time_format text NOT NULL DEFAULT '12h',
  ADD COLUMN IF NOT EXISTS session_reminders_enabled boolean NOT NULL DEFAULT true;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   -- expect all three columns, defaults applied to every existing row
--   SELECT column_name, column_default, is_nullable
--   FROM information_schema.columns
--   WHERE table_schema = 'public' AND table_name = 'therapist_profiles'
--     AND column_name IN ('date_format', 'time_format', 'session_reminders_enabled');
--
--   -- expect zero -- every row should have picked up the default,
--   -- none should be null
--   SELECT count(*) FROM public.therapist_profiles
--   WHERE date_format IS NULL OR time_format IS NULL
--      OR session_reminders_enabled IS NULL;
--
-- Then regenerate src/services/database.types.ts via the Supabase CLI
-- so it picks up the three new columns.
-- ============================================================

-- ============================================================
-- ROLLBACK: DROP COLUMN IF EXISTS date_format, time_format,
-- session_reminders_enabled on public.therapist_profiles -- safe, no
-- data of consequence to lose (defaults only, unless a therapist has
-- since saved real preferences through the new Preferences/
-- Notifications tabs, in which case treat it the same as any other
-- real user data before dropping).
-- ============================================================
