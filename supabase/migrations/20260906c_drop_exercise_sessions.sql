-- ============================================================
-- Drop the vestigial public.exercise_sessions table
--
-- Context: the write path this table originally served was
-- SessionRepository.kt's saveSession()/getRecentSessions()/
-- getSessionsThisWeek(), which inserted into and queried
-- "exercise_sessions" directly. Today's SessionRepository.kt rewrite
-- (landed in commit ec947d2 on the STREAM repo) replaced all of that
-- with the "sessions" + "session_logs" two-table model
-- (startSession/pauseSession/resumeSession/completeSession/
-- getCompletedExerciseIdsToday) -- exercise_sessions is no longer
-- touched by any Android code path.
--
-- Confirmed via direct grep, not assumed:
--   - Android: ExerciseSession.kt is now just
--     `typealias ExerciseSession = SessionHistoryItem`, marked
--     @Deprecated, and that typealias itself has zero references
--     anywhere else in app/src.
--   - Vue: "exercise_sessions" appears only inside the generated
--     src/services/database.types.ts (schema reflection, not
--     application code) -- zero .from('exercise_sessions') calls or
--     any other live reference anywhere in src/.
--
-- PRE-FLIGHT -- run before executing, both of these should already
-- have been checked once (see conversation) but re-confirm they still
-- hold immediately before applying:
--
--   -- (a) no other table's FK points at this one (a non-empty result
--   -- means something still depends on it and this migration is not
--   -- safe to run as written)
--   SELECT conname, conrelid::regclass AS referencing_table, pg_get_constraintdef(oid) AS definition
--   FROM pg_constraint
--   WHERE confrelid = 'public.exercise_sessions'::regclass AND contype = 'f';
--   -- expect zero rows
--
--   -- (b) know what you're actually deleting -- non-zero here means
--   -- this migration destroys real data, not just an empty leftover
--   -- table. Not a blocker by itself, but confirm that's intended
--   -- (e.g. take a manual backup/export first) before proceeding.
--   SELECT count(*) FROM public.exercise_sessions;
-- ============================================================

BEGIN;

DROP TABLE IF EXISTS public.exercise_sessions;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT to_regclass('public.exercise_sessions');
--   -- expect NULL
--
-- Then rebuild/retest both apps to confirm nothing broke (this
-- migration's whole premise is that nothing should):
--   - Android: ./gradlew :app:compileDebugKotlin -> BUILD SUCCESSFUL
--   - Vue: npm run type-check -> same baseline error count as before
--   - Regenerate src/services/database.types.ts via the Supabase CLI
--     so it stops listing exercise_sessions (it will otherwise keep
--     describing a table that no longer exists until regenerated).
-- ============================================================

-- ============================================================
-- ROLLBACK: not possible as a simple inverse statement -- DROP TABLE
-- is destructive. Recovering requires either a pre-drop backup/export
-- of the table's data and definition, or restoring from a Supabase
-- point-in-time backup if the project has one enabled. Take that
-- backup BEFORE running this migration if post-flight (b) showed any
-- rows.
-- ============================================================
