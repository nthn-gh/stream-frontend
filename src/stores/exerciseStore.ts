import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase'
import { useAuthStore } from '@/stores/authStore'
import type {
  Exercise,
  ExerciseAssignmentDraft,
  ExercisePlanWithExercises,
  ExercisePlanStatus,
  ExerciseDifficulty,
} from '@/types'

type PlanExerciseInput = {
  difficulty: ExerciseDifficulty
  duration_seconds: number
  exercise_id: string
  order: number
  reps: number
  rom_max_degrees?: number | null
  rom_min_degrees?: number | null
  sets: number
  special_instructions?: string | null
}

export const useExerciseStore = defineStore('exercise', () => {
  const library = ref<Exercise[]>([])
  const assignedPlan = ref<ExerciseAssignmentDraft[]>([])
  const exercisePlans = ref<ExercisePlanWithExercises[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  function getTherapistId() {
    const authStore = useAuthStore()
    return authStore.therapistProfile?.id ?? null
  }

  async function fetchExercises(filters?: {
    category?: Exercise['category'] | 'all'
    difficulty?: Exercise['difficulty'] | ''
    search?: string
  }) {
    isLoading.value = true
    error.value = null

    try {
      let query = supabase.from('exercises').select('*').order('name', { ascending: true })

      if (filters?.category && filters.category !== 'all') {
        query = query.eq('category', filters.category)
      }

      if (filters?.difficulty) {
        query = query.eq('difficulty', filters.difficulty)
      }

      if (filters?.search) {
        query = query.ilike('name', `%${filters.search}%`)
      }

      const { data, error: fetchError } = await query

      if (fetchError) {
        throw fetchError
      }

      library.value = (data ?? []) as Exercise[]
      return library.value
    } catch (err: any) {
      library.value = []
      error.value = err.message || 'Unable to load exercise library'
      return []
    } finally {
      isLoading.value = false
    }
  }

  function addToPlan(
    exercise: Exercise,
    defaults?: Partial<Omit<ExerciseAssignmentDraft, 'client_id' | 'exercise_id'>>,
  ) {
    assignedPlan.value.push({
      client_id: crypto.randomUUID(),
      exercise_id: exercise.id,
      sets: defaults?.sets ?? 3,
      reps: defaults?.reps ?? 10,
      duration_seconds:
        defaults?.duration_seconds ?? exercise.duration_seconds ?? (exercise.duration_minutes ?? 10) * 60,
      difficulty: defaults?.difficulty ?? exercise.difficulty,
      rom_min_degrees: defaults?.rom_min_degrees ?? null,
      rom_max_degrees: defaults?.rom_max_degrees ?? null,
      special_instructions: defaults?.special_instructions ?? null,
    })
  }

  function removePlanExercise(clientId: string) {
    assignedPlan.value = assignedPlan.value.filter((exercise) => exercise.client_id !== clientId)
  }

  function updatePlanExercise(clientId: string, updates: Partial<ExerciseAssignmentDraft>) {
    assignedPlan.value = assignedPlan.value.map((exercise) =>
      exercise.client_id === clientId ? { ...exercise, ...updates } : exercise,
    )
  }

  function clearPlan() {
    assignedPlan.value = []
  }

  async function createExercisePlan(
    planData: {
      patient_id: string
      name: string
      start_date: string
      end_date: string
      status?: ExercisePlanStatus | null
    },
    exercises: PlanExerciseInput[],
  ) {
    isLoading.value = true
    error.value = null

    try {
      const therapistId = getTherapistId()

      if (!therapistId) {
        throw new Error('Therapist profile is not loaded.')
      }

      if (exercises.length === 0) {
        throw new Error('Select at least one exercise before creating a plan.')
      }

      const { error: patientScopeError } = await supabase
        .from('patients')
        .update({
          therapist_id: therapistId,
          updated_at: new Date().toISOString(),
        })
        .eq('id', planData.patient_id)

      if (patientScopeError) {
        throw patientScopeError
      }

      const { data: plan, error: planError } = await supabase
        .from('exercise_plans')
        .insert({
          patient_id: planData.patient_id,
          therapist_id: therapistId,
          name: planData.name,
          start_date: planData.start_date,
          end_date: planData.end_date,
          status: planData.status ?? 'active',
        })
        .select('*')
        .single()

      if (planError) {
        throw planError
      }

      const { error: exercisesError } = await supabase.from('plan_exercises').insert(
        exercises.map((exercise, index) => ({
          plan_id: plan.id,
          exercise_id: exercise.exercise_id,
          sets: exercise.sets,
          reps: exercise.reps,
          duration_minutes: Math.max(1, Math.round(exercise.duration_seconds / 60)),
          duration_seconds: exercise.duration_seconds,
          difficulty: exercise.difficulty,
          special_instructions: exercise.special_instructions ?? null,
          rom_min_degrees: exercise.rom_min_degrees ?? null,
          rom_max_degrees: exercise.rom_max_degrees ?? null,
          order: exercise.order ?? index,
        })),
      )

      if (exercisesError) {
        throw exercisesError
      }

      await fetchPatientPlans(planData.patient_id)
      clearPlan()

      return { success: true as const, plan }
    } catch (err: any) {
      error.value = err.message || 'Unable to create exercise plan'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function submitPlan(patientId: string, _therapistId: string, startDate: string, endDate: string, name?: string) {
    return createExercisePlan(
      {
        patient_id: patientId,
        name: name || `Exercise Plan ${new Date().toLocaleDateString()}`,
        start_date: startDate,
        end_date: endDate,
        status: 'active',
      },
      assignedPlan.value.map((exercise, index) => ({
        exercise_id: exercise.exercise_id,
        sets: exercise.sets,
        reps: exercise.reps,
        duration_seconds: exercise.duration_seconds,
        difficulty: exercise.difficulty,
        special_instructions: exercise.special_instructions,
        rom_min_degrees: exercise.rom_min_degrees,
        rom_max_degrees: exercise.rom_max_degrees,
        order: index,
      })),
    )
  }

  async function fetchPatientPlans(patientId: string) {
    isLoading.value = true
    error.value = null

    try {
      const therapistId = getTherapistId()

      if (!therapistId) {
        exercisePlans.value = []
        return []
      }

      const { data, error: fetchError } = await supabase
        .from('exercise_plans')
        .select(
          `
            id,
            patient_id,
            therapist_id,
            name,
            start_date,
            end_date,
            status,
            created_at,
            updated_at,
            plan_exercises:plan_exercises(
              id,
              plan_id,
              exercise_id,
              sets,
              reps,
              duration_minutes,
              duration_seconds,
              difficulty,
              special_instructions,
              order,
              rom_min_degrees,
              rom_max_degrees,
              exercise:exercises(
                id,
                name,
                description,
                category,
                difficulty,
                thumbnail_url,
                instructions,
                duration_minutes,
                duration_seconds,
                target_joints,
                video_url,
                created_at
              )
            )
          `,
        )
        .eq('patient_id', patientId)
        .eq('therapist_id', therapistId)
        .order('start_date', { ascending: false })
        .order('created_at', { ascending: false })

      if (fetchError) {
        throw fetchError
      }

      exercisePlans.value = (data ?? []) as unknown as ExercisePlanWithExercises[]
      return exercisePlans.value
    } catch (err: any) {
      exercisePlans.value = []
      error.value = err.message || 'Unable to load exercise plans'
      return []
    } finally {
      isLoading.value = false
    }
  }

  return {
    library,
    assignedPlan,
    exercisePlans,
    isLoading,
    error,
    fetchExercises,
    addToPlan,
    removePlanExercise,
    updatePlanExercise,
    clearPlan,
    submitPlan,
    fetchPatientPlans,
    createExercisePlan,
  }
})
