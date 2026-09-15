-- ============================================================
-- Drop dead legacy columns from public.sessions
--
-- Context: accuracy_percent, date, sets_completed, form_quality, and
-- duration_minutes are pre-cutover columns from before the 2026-09-06
-- sessions/session_logs rewrite (see 20260906c_drop_exercise_sessions.sql).
-- No Android or Vue code path has written any of these five columns
-- since that rewrite landed.
--
-- Investigated before writing this migration, not assumed:
--   - 13 rows in public.sessions still carry non-null values in
--     accuracy_percent and/or date (checked via
--     WHERE accuracy_percent IS NOT NULL OR date IS NOT NULL).
--   - None of the 13 have a matching public.session_logs row (LEFT
--     JOIN on session_logs.session_id = sessions.id returned NULL
--     for all 13).
--   - Checked *why* before assuming that meant real data would be
--     lost: all 13 have status IN ('in_progress', 'paused') and
--     completed_at IS NULL -- none of them ever reached
--     SessionRepository.kt's completeSession(), which is the only
--     code path that has ever written a session_logs row. Their
--     legacy-column values are exactly what you'd expect from
--     abandoned/never-finished attempts, not real captured
--     performance: accuracy_percent is "0.00" for all 13,
--     sets_completed is 0 for all 13, form_quality is NULL for all
--     13, reps_completed is 0 for all 13, and duration_minutes is 0
--     for 11 of the 13 (the other 2 show 10, the exercise-library
--     default, not a measured value).
--   - Conclusion: there is no real data in these 13 rows worth
--     backfilling into session_logs. Synthesizing session_logs rows
--     for them would misrepresent abandoned attempts as completed
--     ones with a real (if poor) score, which they were not --
--     completeSession() was never reached for any of them. Drop-only
--     is correct; no backfill migration precedes this one.
--
--   - Vue-code note, not part of this migration: PatientProfileView.vue
--     currently reads session.date (unconditionally, every row) and
--     session.sets_completed (no fallback) in its Session History
--     tab. Neither has been written by any code since the 2026-09-06
--     rewrite, so both are already effectively dead for every session
--     created since then (the 13 rows above are the only ones where
--     they still hold anything). This migration does not touch that
--     Vue code -- flagged separately, not fixed here.
--
-- PRE-FLIGHT -- re-confirm immediately before running, not just once
-- during investigation:
--
--   -- expect 13 -- if this grew, stop and re-investigate the new
--   -- rows the same way (status/completed_at/reps_completed) before
--   -- proceeding
--   SELECT count(*) FROM public.sessions
--   WHERE accuracy_percent IS NOT NULL OR date IS NOT NULL
--      OR sets_completed IS NOT NULL OR form_quality IS NOT NULL
--      OR duration_minutes IS NOT NULL;
--
--   -- expect zero rows (re-confirm no session_logs match exists
--   -- before dropping -- if this returns rows now, stop)
--   SELECT s.id FROM public.sessions s
--   JOIN public.session_logs sl ON sl.session_id = s.id
--   WHERE s.accuracy_percent IS NOT NULL OR s.date IS NOT NULL;
--
--   -- total row count, for the post-flight comparison
--   SELECT count(*) FROM public.sessions;
-- ============================================================

BEGIN;

ALTER TABLE public.sessions
  DROP COLUMN IF EXISTS accuracy_percent,
  DROP COLUMN IF EXISTS date,
  DROP COLUMN IF EXISTS sets_completed,
  DROP COLUMN IF EXISTS form_quality,
  DROP COLUMN IF EXISTS duration_minutes;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   -- expect the same row count as the pre-flight total above --
--   -- this migration only drops columns, never rows
--   SELECT count(*) FROM public.sessions;
--
--   -- expect zero rows -- confirms all five columns are gone
--   SELECT column_name FROM information_schema.columns
--   WHERE table_schema = 'public' AND table_name = 'sessions'
--     AND column_name IN ('accuracy_percent', 'date', 'sets_completed',
--                          'form_quality', 'duration_minutes');
--
-- Then regenerate src/services/database.types.ts via the Supabase CLI
-- so it stops listing these columns (it will otherwise keep
-- describing columns that no longer exist until regenerated), and
-- rebuild/retest both apps:
--   - Android: ./gradlew :app:compileDebugKotlin -> BUILD SUCCESSFUL
--   - Vue: npm run type-check -> same baseline error count as before
--     (PatientProfileView.vue will start erroring on session.date /
--     session.sets_completed once the generated types drop them --
--     see the Vue-code note above; that's the expected trigger to go
--     fix that display code, not a sign this migration broke)
-- ============================================================

-- ============================================================
-- ROLLBACK: not possible as a simple inverse statement -- DROP COLUMN
-- is destructive. The 13 rows' now-dropped values were all
-- zero/default/abandoned-session placeholders (see investigation
-- above), so recovering them has no real value; if ever needed
-- anyway, restore requires a pre-drop backup or a Supabase
-- point-in-time restore.
-- ============================================================
