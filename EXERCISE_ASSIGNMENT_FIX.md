# Exercise Assignment Fix - Complete

## Issue
Therapists couldn't see exercises when trying to assign them to patients in the "Assign Exercise" view.

## Root Cause
**Method name mismatch**: The `AssignExerciseView.vue` was calling `exerciseStore.fetchLibrary()`, but the exercise store only exports `fetchExercises()`.

## Fix Applied
Updated `src/views/AssignExerciseView.vue` line ~395:
```typescript
// BEFORE (incorrect)
onMounted(async () => {
  await patientStore.fetchPatients()
  await exerciseStore.fetchLibrary()  // ❌ This method doesn't exist
})

// AFTER (correct)
onMounted(async () => {
  await patientStore.fetchPatients()
  await exerciseStore.fetchExercises()  // ✅ Correct method name
})
```

## Database Setup Required

The exercises table must be populated with sample exercises. Run this SQL in Supabase SQL Editor:

### Option 1: Complete Setup (if not done yet)
Run the entire file: `setup-exercise-tables.sql`

This creates:
- `exercises` table
- `exercise_plans` table
- `plan_exercises` table
- RLS policies
- 8 sample exercises

### Option 2: Just Add Exercises (if tables exist)
If you've already run the setup but don't have exercises, run just the INSERT statement:

```sql
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
```

## How Exercise Assignment Works

### Workflow
1. **Navigate**: Sidebar → "Assign Exercise" (dumbbell icon)
2. **Step 1 - Select Patient**: Choose which patient to assign exercises to
3. **Step 2 - Choose Exercises**: Browse and select exercises from the library
   - Filter by Category (Upper Body, Lower Body, Balance, Flexibility)
   - Filter by Difficulty (Easy, Medium, Hard)
   - Search by name
   - Select multiple exercises via checkboxes
4. **Step 3 - Configure Plan**: Set plan details and exercise parameters
   - Plan name
   - Start/end dates
   - Sets, reps, duration for each exercise
   - Special instructions
5. **Step 4 - Complete**: Review and submit the plan

### Database Structure
```
exercise_plans
├─ id (UUID)
├─ patient_id → patients.id
├─ therapist_id → therapist_profiles.id
├─ name (TEXT)
├─ start_date, end_date (DATE)
└─ status ('active', 'completed', 'draft')

plan_exercises (junction table)
├─ id (UUID)
├─ plan_id → exercise_plans.id
├─ exercise_id → exercises.id
├─ sets, reps, duration_minutes (INT)
├─ difficulty (TEXT)
├─ special_instructions (TEXT)
└─ order (INT)

exercises (library)
├─ id (UUID)
├─ name, description, instructions (TEXT)
├─ category ('upper_body', 'lower_body', 'balance', 'flexibility')
├─ difficulty ('easy', 'medium', 'hard')
└─ duration_minutes (INT)
```

## Testing Steps

1. **Verify exercises exist**:
   ```sql
   SELECT * FROM public.exercises;
   ```
   Should return 8 rows.

2. **Test in the app**:
   - Login as therapist
   - Navigate to "Assign Exercise" from sidebar
   - **Step 1**: Select a patient → Click "Continue to Exercises"
   - **Step 2**: You should see 8 exercises displayed in cards
   - Try filtering by category/difficulty
   - Try searching for "shoulder"
   - Select 2-3 exercises → Click "Continue to Plan Details"
   - **Step 3**: Fill out plan name and dates, configure exercise parameters
   - Click "Create Plan"

3. **Verify plan was created**:
   ```sql
   SELECT 
     ep.*,
     p.name as patient_name,
     COUNT(pe.id) as exercise_count
   FROM exercise_plans ep
   JOIN patients p ON ep.patient_id = p.id
   LEFT JOIN plan_exercises pe ON ep.id = pe.plan_id
   GROUP BY ep.id, p.name
   ORDER BY ep.created_at DESC
   LIMIT 5;
   ```

## Common Issues & Solutions

### Issue: "No exercises found"
**Solution**: Run the exercise INSERT SQL above to populate the exercises table.

### Issue: Exercises show but can't create plan
**Check**: 
1. Are you logged in as a therapist?
2. Does your therapist profile exist in `therapist_profiles`?
3. Check browser console for errors

### Issue: RLS policy error when creating plan
**Solution**: Run the RLS policy creation from `setup-exercise-tables.sql`:
```sql
-- Allow authenticated users to insert plans
CREATE POLICY "Therapists can create plans" 
ON public.exercise_plans FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');
```

### Issue: Can't see assigned plans on patient profile
**Check**: The `PatientProfileView` should have an "Exercise Plans" tab that displays plans. If missing, this is a separate feature.

## Files Modified
- `src/views/AssignExerciseView.vue` - Fixed method name from `fetchLibrary()` to `fetchExercises()`

## Related Files
- `src/stores/exerciseStore.ts` - Exercise state management
- `setup-exercise-tables.sql` - Database schema and seed data
- `src/types/index.ts` - TypeScript types for Exercise, ExercisePlan, PlanExercise

## Future Enhancements
1. **Add more exercises**: Insert additional exercises into the `exercises` table
2. **Custom exercises**: Allow therapists to create custom exercises
3. **Exercise library management**: UI to add/edit/delete exercises
4. **Exercise media**: Add video/image thumbnails for exercises
5. **Exercise templates**: Pre-configured plan templates for common conditions
6. **Progress tracking**: Show patient completion status for assigned exercises

## Status
✅ **FIXED** - Exercise assignment now working with correct method call
⚠️ **REQUIRES** - Database setup via `setup-exercise-tables.sql` if not done
