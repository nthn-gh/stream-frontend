-- ============================================================
-- Deduplicate public.exercises and make names unique
--
-- STATUS: NOT APPLIED. Written 2026-10-21 for review; apply by hand.
--
-- Context: the catalog has 10 rows but only 7 distinct names. Three names
-- exist twice (two seed scripts were both run on 2026-03-30: 19:41:15 and
-- 21:07:53). Read-only investigation (2026-10-21, each query inside
-- BEGIN; SET TRANSACTION READ ONLY; ... ROLLBACK;) found:
--
--   name               id        created   plan_ex  sessions  logs  instructions
--   Ankle Dorsiflexion ad26ad46  19:41:15     2        13      0     yes     <- KEEP
--   Ankle Dorsiflexion 79bb09ba  21:07:53     1         1      0     no      <- re-point, delete
--   Elbow Extension    4d3491e5  19:41:15     0         0      0     yes     <- delete (text copied)
--   Elbow Extension    143d5922  21:07:53     1         8      1     no      <- KEEP
--   Shoulder Flexion   86f4a712  19:41:15     0         0      0     yes     <- KEEP
--   Shoulder Flexion   c02bf4e1  21:07:53     0         0      0     no      <- delete
--
--   (full ids are in the PRE-FLIGHT block below)
--
-- Rule applied (approved): keep the referenced row; if both are referenced
-- keep the oldest and re-point the other's references to it. Elbow Extension:
-- the kept row is the referenced one (143d5922), which has no instructions,
-- so instructions and description are copied onto it from the row being
-- deleted (4d3491e5) before that row goes.
--
-- Left alone on purpose: Balance Training and Standing Balance (different
-- names; same description, both "not tracked"). Merging them is a separate
-- decision. Knee Extension and Neck Rotation are single rows.
--
-- Only three tables reference exercises(id) (checked in pg_constraint and
-- information_schema): plan_exercises (ON DELETE CASCADE, so rows MUST be
-- re-pointed before any delete), sessions, session_logs. No unique
-- constraint on them involves exercise_id, no plan contains both Ankle
-- rows, and the only triggers are AFTER UPDATE OF status on sessions and
-- AFTER INSERT on session_logs, neither fires on an exercise_id update.
-- No client inserts into exercises (read-only through RLS), so the unique
-- index cannot break an insert path.
--
-- What this migration does, in one transaction:
--   0. locks the four tables (SHARE ROW EXCLUSIVE: reads continue, writes wait)
--   1. PRE-FLIGHT: aborts unless the picture is exactly the one above
--   2. copies the rows it will change into two locked-down backup tables
--      (RLS on, no policies, no grants to anon/authenticated)
--   3. re-points plan_exercises / sessions / session_logs to the kept ids
--   4. copies instructions + description onto the kept Elbow Extension row
--   5. deletes the three duplicate rows
--   6. creates the unique index on lower(name)
--   7. POST-FLIGHT: aborts (rolls everything back) unless the result is exactly
--      7 exercises, no reference lost, every count as expected
--
-- After applying: regenerate database.types.ts. The two backup tables will
-- show up in the generated types while they exist; drop them first (last
-- lines of the ROLLBACK section) if you do not want them there.
-- ============================================================

BEGIN;

LOCK TABLE public.exercises, public.plan_exercises, public.sessions, public.session_logs
  IN SHARE ROW EXCLUSIVE MODE;

-- ------------------------------------------------------------
-- 1. PRE-FLIGHT -- raises (and so aborts the whole migration) if anything differs
-- ------------------------------------------------------------
DO $preflight$
DECLARE
  expected CONSTANT jsonb := jsonb_build_array(
    -- id, lower(name), plan_exercises, sessions, session_logs
    jsonb_build_array('ad26ad46-c263-4d8f-a8ce-71cec1a4bb05', 'ankle dorsiflexion', 2, 13, 0),
    jsonb_build_array('79bb09ba-6c40-454c-89b5-f69974f66277', 'ankle dorsiflexion', 1,  1, 0),
    jsonb_build_array('4d3491e5-c227-4b24-ba4a-eb6722f6eaa8', 'elbow extension',    0,  0, 0),
    jsonb_build_array('143d5922-5ab2-4492-a889-157ba3feabac', 'elbow extension',    1,  8, 1),
    jsonb_build_array('86f4a712-3427-4f8f-a2cf-844f79b08beb', 'shoulder flexion',   0,  0, 0),
    jsonb_build_array('c02bf4e1-f8bb-4851-8130-21d09623ba8b', 'shoulder flexion',   0,  0, 0)
  );
  e jsonb;
  r record;
  fk_count int;
BEGIN
  IF (SELECT count(*) FROM public.exercises) <> 10 THEN
    RAISE EXCEPTION 'pre-flight: expected 10 exercises, found %', (SELECT count(*) FROM public.exercises);
  END IF;

  -- the only duplicate-name groups are exactly the three expected ones
  IF (SELECT string_agg(n, ',' ORDER BY n) FROM (
        SELECT lower(name) AS n FROM public.exercises GROUP BY lower(name) HAVING count(*) > 1) d)
     IS DISTINCT FROM 'ankle dorsiflexion,elbow extension,shoulder flexion' THEN
    RAISE EXCEPTION 'pre-flight: duplicate-name groups are not the three approved ones';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'exercises'
               AND indexname = 'exercises_name_lower_key') THEN
    RAISE EXCEPTION 'pre-flight: exercises_name_lower_key already exists';
  END IF;

  -- nothing else may reference exercises(id): exactly the three known foreign keys
  SELECT count(*) INTO fk_count FROM pg_constraint
   WHERE contype = 'f' AND confrelid = 'public.exercises'::regclass;
  IF fk_count <> 3 OR (SELECT count(*) FROM pg_constraint
        WHERE contype = 'f' AND confrelid = 'public.exercises'::regclass
          AND conrelid IN ('public.plan_exercises'::regclass, 'public.sessions'::regclass,
                           'public.session_logs'::regclass)) <> 3 THEN
    RAISE EXCEPTION 'pre-flight: expected exactly 3 foreign keys (plan_exercises, sessions, session_logs) to exercises, found %', fk_count;
  END IF;

  -- every approved row exists with the expected name and reference counts
  FOR e IN SELECT * FROM jsonb_array_elements(expected) LOOP
    SELECT x.id, lower(x.name) AS lname,
           (SELECT count(*) FROM public.plan_exercises p WHERE p.exercise_id = x.id) AS pe,
           (SELECT count(*) FROM public.sessions s WHERE s.exercise_id = x.id) AS se,
           (SELECT count(*) FROM public.session_logs l WHERE l.exercise_id = x.id) AS lg
      INTO r
      FROM public.exercises x WHERE x.id = (e ->> 0)::uuid;
    IF r.id IS NULL THEN
      RAISE EXCEPTION 'pre-flight: exercise % is missing', e ->> 0;
    END IF;
    IF r.lname <> (e ->> 1) OR r.pe <> (e ->> 2)::int OR r.se <> (e ->> 3)::int OR r.lg <> (e ->> 4)::int THEN
      RAISE EXCEPTION 'pre-flight: exercise % differs from the approved picture (name %, plan_exercises %, sessions %, session_logs %; expected %)',
        e ->> 0, r.lname, r.pe, r.se, r.lg, e;
    END IF;
  END LOOP;

  -- the Elbow text merge assumes the kept row has no instructions and the
  -- deleted row has some
  IF (SELECT instructions FROM public.exercises WHERE id = '143d5922-5ab2-4492-a889-157ba3feabac') IS NOT NULL THEN
    RAISE EXCEPTION 'pre-flight: kept Elbow Extension row already has instructions';
  END IF;
  IF (SELECT instructions FROM public.exercises WHERE id = '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8') IS NULL THEN
    RAISE EXCEPTION 'pre-flight: the Elbow Extension row to delete has no instructions to copy';
  END IF;

  -- the two untouched balance rows are still there
  IF (SELECT count(*) FROM public.exercises
       WHERE id IN ('a620e1c6-e030-4e56-b480-4f282df1dff1', '28fa63c5-6040-48c2-b140-3627aaf4d648')) <> 2 THEN
    RAISE EXCEPTION 'pre-flight: Balance Training / Standing Balance rows not as approved';
  END IF;
END
$preflight$;

-- remember the totals so POST-FLIGHT can prove no reference was lost
CREATE TEMP TABLE _dedupe_pre ON COMMIT DROP AS
SELECT (SELECT count(*) FROM public.plan_exercises) AS plan_exercises,
       (SELECT count(*) FROM public.sessions)       AS sessions,
       (SELECT count(*) FROM public.session_logs)   AS session_logs;

-- ------------------------------------------------------------
-- 2. BACKUPS (kept after the migration so it can be undone; drop them
--    by hand once you are satisfied). Locked down: RLS on, no policies,
--    no privileges for anon / authenticated, so the REST API cannot read them.
-- ------------------------------------------------------------
CREATE TABLE public.exercises_dedupe_backup_20261021 AS
SELECT 'deleted'::text AS reason, e.* FROM public.exercises e
 WHERE e.id IN ('79bb09ba-6c40-454c-89b5-f69974f66277',
                '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8',
                'c02bf4e1-f8bb-4851-8130-21d09623ba8b')
UNION ALL
SELECT 'kept_before_update'::text, e.* FROM public.exercises e
 WHERE e.id = '143d5922-5ab2-4492-a889-157ba3feabac';

CREATE TABLE public.exercise_repoint_backup_20261021 (
  table_name      text NOT NULL,
  row_id          uuid NOT NULL,
  old_exercise_id uuid NOT NULL,
  new_exercise_id uuid NOT NULL
);

ALTER TABLE public.exercises_dedupe_backup_20261021 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_repoint_backup_20261021 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.exercises_dedupe_backup_20261021 FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.exercise_repoint_backup_20261021 FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------
-- 3. RE-POINT references from the duplicates to the kept row
--    (only Ankle Dorsiflexion has any: 1 plan_exercises row, 1 session;
--    the session_logs statement matches 0 rows and is there for completeness)
-- ------------------------------------------------------------
INSERT INTO public.exercise_repoint_backup_20261021 (table_name, row_id, old_exercise_id, new_exercise_id)
SELECT 'plan_exercises', id, exercise_id, 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
  FROM public.plan_exercises WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277'
UNION ALL
SELECT 'sessions', id, exercise_id, 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
  FROM public.sessions WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277'
UNION ALL
SELECT 'session_logs', id, exercise_id, 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
  FROM public.session_logs WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277';

UPDATE public.plan_exercises SET exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
 WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277';
UPDATE public.sessions SET exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
 WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277';
UPDATE public.session_logs SET exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05'
 WHERE exercise_id = '79bb09ba-6c40-454c-89b5-f69974f66277';

-- ------------------------------------------------------------
-- 4. ELBOW EXTENSION: carry the text of the row being deleted onto the kept row
-- ------------------------------------------------------------
UPDATE public.exercises k
   SET instructions = d.instructions,
       description  = d.description
  FROM public.exercises d
 WHERE k.id = '143d5922-5ab2-4492-a889-157ba3feabac'
   AND d.id = '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8';

-- ------------------------------------------------------------
-- 5. DELETE the three duplicates (nothing references them any more, so the
--    ON DELETE CASCADE on plan_exercises has nothing to remove)
-- ------------------------------------------------------------
DELETE FROM public.exercises
 WHERE id IN ('79bb09ba-6c40-454c-89b5-f69974f66277',
              '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8',
              'c02bf4e1-f8bb-4851-8130-21d09623ba8b');

-- ------------------------------------------------------------
-- 6. NAMES ARE UNIQUE, case-insensitively
-- ------------------------------------------------------------
CREATE UNIQUE INDEX exercises_name_lower_key ON public.exercises (lower(name));

-- ------------------------------------------------------------
-- 7. POST-FLIGHT -- raises (rolling everything back) unless the result is as approved
-- ------------------------------------------------------------
DO $postflight$
DECLARE
  pre record;
BEGIN
  SELECT * INTO pre FROM _dedupe_pre;

  IF (SELECT count(*) FROM public.exercises) <> 7 THEN
    RAISE EXCEPTION 'post-flight: expected 7 exercises, found %', (SELECT count(*) FROM public.exercises);
  END IF;
  IF EXISTS (SELECT 1 FROM public.exercises GROUP BY lower(name) HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'post-flight: duplicate names remain';
  END IF;
  IF EXISTS (SELECT 1 FROM public.exercises
              WHERE id IN ('79bb09ba-6c40-454c-89b5-f69974f66277',
                           '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8',
                           'c02bf4e1-f8bb-4851-8130-21d09623ba8b')) THEN
    RAISE EXCEPTION 'post-flight: a duplicate row survived';
  END IF;
  IF (SELECT count(*) FROM public.exercises
       WHERE id IN ('ad26ad46-c263-4d8f-a8ce-71cec1a4bb05', '143d5922-5ab2-4492-a889-157ba3feabac',
                    '86f4a712-3427-4f8f-a2cf-844f79b08beb', 'a620e1c6-e030-4e56-b480-4f282df1dff1',
                    '28fa63c5-6040-48c2-b140-3627aaf4d648', '8e494f76-c589-4bd4-9589-e529c54b5b37',
                    '9e8b1f2b-5f16-4bfb-b312-6283cb7b834a')) <> 7 THEN
    RAISE EXCEPTION 'post-flight: the seven expected rows are not exactly the ones left';
  END IF;

  -- no reference lost, none left dangling
  IF (SELECT count(*) FROM public.plan_exercises) <> pre.plan_exercises
     OR (SELECT count(*) FROM public.sessions) <> pre.sessions
     OR (SELECT count(*) FROM public.session_logs) <> pre.session_logs THEN
    RAISE EXCEPTION 'post-flight: a plan_exercises / sessions / session_logs row was lost';
  END IF;

  -- Ankle took over the other row's references: 2+1 plan_exercises, 13+1 sessions
  IF (SELECT count(*) FROM public.plan_exercises WHERE exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05') <> 3
     OR (SELECT count(*) FROM public.sessions WHERE exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05') <> 14
     OR (SELECT count(*) FROM public.session_logs WHERE exercise_id = 'ad26ad46-c263-4d8f-a8ce-71cec1a4bb05') <> 0 THEN
    RAISE EXCEPTION 'post-flight: Ankle Dorsiflexion reference counts are not 3 / 14 / 0';
  END IF;
  -- Elbow kept row unchanged in references: 1 / 8 / 1
  IF (SELECT count(*) FROM public.plan_exercises WHERE exercise_id = '143d5922-5ab2-4492-a889-157ba3feabac') <> 1
     OR (SELECT count(*) FROM public.sessions WHERE exercise_id = '143d5922-5ab2-4492-a889-157ba3feabac') <> 8
     OR (SELECT count(*) FROM public.session_logs WHERE exercise_id = '143d5922-5ab2-4492-a889-157ba3feabac') <> 1 THEN
    RAISE EXCEPTION 'post-flight: Elbow Extension reference counts are not 1 / 8 / 1';
  END IF;
  -- Elbow text merged
  IF (SELECT instructions FROM public.exercises WHERE id = '143d5922-5ab2-4492-a889-157ba3feabac') IS NULL
     OR (SELECT description FROM public.exercises WHERE id = '143d5922-5ab2-4492-a889-157ba3feabac')
        IS DISTINCT FROM (SELECT description FROM public.exercises_dedupe_backup_20261021
                           WHERE id = '4d3491e5-c227-4b24-ba4a-eb6722f6eaa8') THEN
    RAISE EXCEPTION 'post-flight: Elbow Extension text was not merged';
  END IF;

  -- the re-point log holds exactly the 2 rows moved (1 plan_exercises + 1 session)
  IF (SELECT count(*) FROM public.exercise_repoint_backup_20261021) <> 2 THEN
    RAISE EXCEPTION 'post-flight: expected 2 re-pointed rows in the log, found %',
      (SELECT count(*) FROM public.exercise_repoint_backup_20261021);
  END IF;

  -- the unique index exists and is usable
  IF NOT EXISTS (SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
                  WHERE c.relname = 'exercises_name_lower_key' AND i.indisunique AND i.indisvalid) THEN
    RAISE EXCEPTION 'post-flight: exercises_name_lower_key is missing or invalid';
  END IF;

  -- the backup tables are not reachable over the REST API
  IF has_table_privilege('anon', 'public.exercises_dedupe_backup_20261021', 'SELECT')
     OR has_table_privilege('authenticated', 'public.exercises_dedupe_backup_20261021', 'SELECT')
     OR has_table_privilege('anon', 'public.exercise_repoint_backup_20261021', 'SELECT')
     OR has_table_privilege('authenticated', 'public.exercise_repoint_backup_20261021', 'SELECT') THEN
    RAISE EXCEPTION 'post-flight: a backup table is readable by anon / authenticated';
  END IF;
END
$postflight$;

COMMIT;

-- ============================================================
-- AFTER APPLYING -- optional manual checks (read-only):
--
--   SELECT name, id,
--          (SELECT count(*) FROM plan_exercises p WHERE p.exercise_id = e.id) AS plan_ex,
--          (SELECT count(*) FROM sessions s WHERE s.exercise_id = e.id) AS sessions,
--          (SELECT count(*) FROM session_logs l WHERE l.exercise_id = e.id) AS logs
--   FROM exercises e ORDER BY lower(name);
--   -- expect 7 rows: Ankle 3/14/0, Elbow 1/8/1, Balance Training 1/1/0, the rest 0/0/0
--
-- Then regenerate src/types/database.types.ts as usual.
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration). Run as the DB owner, in
-- one transaction, only while the two backup tables still exist:
--
--   BEGIN;
--   DROP INDEX public.exercises_name_lower_key;
--
--   -- bring the three deleted rows back with their original ids and values
--   INSERT INTO public.exercises (id, name, description, category, difficulty, thumbnail_url,
--                                 instructions, duration_minutes, created_at, target_joints,
--                                 video_url, duration_seconds)
--   SELECT id, name, description, category, difficulty, thumbnail_url, instructions,
--          duration_minutes, created_at, target_joints, video_url, duration_seconds
--   FROM public.exercises_dedupe_backup_20261021 WHERE reason = 'deleted';
--
--   -- point the 2 moved rows back at the restored Ankle duplicate
--   UPDATE public.plan_exercises t SET exercise_id = b.old_exercise_id
--     FROM public.exercise_repoint_backup_20261021 b
--    WHERE b.table_name = 'plan_exercises' AND t.id = b.row_id;
--   UPDATE public.sessions t SET exercise_id = b.old_exercise_id
--     FROM public.exercise_repoint_backup_20261021 b
--    WHERE b.table_name = 'sessions' AND t.id = b.row_id;
--   UPDATE public.session_logs t SET exercise_id = b.old_exercise_id
--     FROM public.exercise_repoint_backup_20261021 b
--    WHERE b.table_name = 'session_logs' AND t.id = b.row_id;
--
--   -- put the kept Elbow Extension row's text back
--   UPDATE public.exercises k SET instructions = b.instructions, description = b.description
--     FROM public.exercises_dedupe_backup_20261021 b
--    WHERE b.reason = 'kept_before_update' AND k.id = b.id;
--
--   -- verify: 10 exercises again, Ankle 2/13/0 + 1/1/0, Elbow kept row 1/8/1
--   SELECT count(*) FROM public.exercises;   -- expect 10
--   COMMIT;
--
--   -- when you no longer need the way back:
--   DROP TABLE public.exercises_dedupe_backup_20261021;
--   DROP TABLE public.exercise_repoint_backup_20261021;
-- ============================================================
