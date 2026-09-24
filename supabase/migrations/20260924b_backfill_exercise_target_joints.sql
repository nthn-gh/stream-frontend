-- ============================================================
-- Backfill public.exercises.target_joints
--
-- Context: android-app-audit.md (Phase 9) found target_joints was
-- NULL on all 10 catalog rows, so the Android app's
-- ExerciseSessionViewModel.resolveExerciseType() ran entirely on
-- exercise-name substring matching against 9 hardcoded keywords.
-- Auditing each of the 10 exercises against what RepCounter/
-- JointAngleCalculator can actually measure (grepped the whole ml/
-- package: zero mentions of knee/ankle/leg/foot/neck anywhere outside
-- the keyword list itself -- no lower-body or neck landmark is ever
-- extracted) found the keyword list was actively routing
-- untrackable exercises to a wrong default (ELBOW_FLEXION) rather
-- than an honest "not tracked" state. Confirmed live against
-- plan_exercises that this is not just a latent risk: Ankle
-- Dorsiflexion (3 assignments) and Balance Training (1 assignment)
-- were being actively mis-scored against an elbow angle for real
-- assigned patients at the time of this migration.
--
-- This migration only backfills data for the 6 rows that map to a
-- real, trackable joint -- it does not itself change scoring
-- behavior. See the STREAM commit that rewrites
-- resolveExerciseType() to key off this column (with name-matching
-- kept only as a fallback for rows that still lack target_joints).
--
-- Elbow Extension / Shoulder Flexion already resolved correctly
-- under the old keyword matching (their names contain the matching
-- keyword) -- backfilled here anyway so target_joints becomes the
-- authoritative signal for every row, not just the previously-broken
-- ones.
--
-- Balance Training and Standing Balance are deliberately NOT
-- backfilled with a joint name. Balance/postural stability isn't a
-- joint-angle measurement at all -- tagging them with a joint just to
-- fill the column would be exactly the kind of dishonest metadata
-- this audit has been rooting out elsewhere (see the therapist
-- preferences and patient settings fixes). resolveExerciseType()
-- routes these to the "not tracked" state via category = 'balance'
-- instead, kept as its own explicit branch.
--
-- Additive data backfill on an existing nullable column -- no schema
-- change, no data at risk.
-- ============================================================

BEGIN;

UPDATE public.exercises SET target_joints = ARRAY['elbow']    WHERE name = 'Elbow Extension';
UPDATE public.exercises SET target_joints = ARRAY['shoulder'] WHERE name = 'Shoulder Flexion';
UPDATE public.exercises SET target_joints = ARRAY['ankle']    WHERE name = 'Ankle Dorsiflexion';
UPDATE public.exercises SET target_joints = ARRAY['knee']     WHERE name = 'Knee Extension';
UPDATE public.exercises SET target_joints = ARRAY['neck']     WHERE name = 'Neck Rotation';
-- Balance Training / Standing Balance: left NULL, deliberately. See above.

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   -- expect 6 rows with a non-null target_joints, 4 rows (the two
--   -- balance exercises) with NULL
--   SELECT name, category, target_joints FROM public.exercises ORDER BY name, id;
--
--   -- expect zero -- no row should have an empty (non-null) array,
--   -- only a real joint name or NULL
--   SELECT count(*) FROM public.exercises
--   WHERE target_joints IS NOT NULL AND cardinality(target_joints) = 0;
-- ============================================================

-- ============================================================
-- ROLLBACK: UPDATE public.exercises SET target_joints = NULL
-- WHERE name IN ('Elbow Extension', 'Shoulder Flexion',
-- 'Ankle Dorsiflexion', 'Knee Extension', 'Neck Rotation');
-- -- safe, reverts to the pre-migration NULL state. No data at risk
-- -- either way -- this is catalog metadata, not patient data.
-- ============================================================
