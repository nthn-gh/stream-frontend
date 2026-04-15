<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="h2">Assign Exercise Plan</h1>
        <p class="page-subtitle">Create a real Supabase-backed plan that the Android patient app can load immediately.</p>
      </div>
    </div>

    <BaseCard>
      <div class="step-indicator">
        <div v-for="(step, index) in steps" :key="step" class="step-item">
          <div class="step-number" :class="{ active: currentStep === index, complete: currentStep > index }">
            {{ index + 1 }}
          </div>
          <span class="step-label" :class="{ active: currentStep >= index }">{{ step }}</span>
        </div>
      </div>
    </BaseCard>

    <BaseCard v-if="isBootstrapping" class="state-card">
      <p class="state-title">Loading assignment data</p>
      <p class="state-copy">Fetching patients and exercise library from Supabase.</p>
    </BaseCard>

    <BaseCard v-else-if="bootstrapError" class="state-card">
      <p class="state-title">Unable to load assignment data</p>
      <p class="state-copy">{{ bootstrapError }}</p>
      <button class="btn-secondary" @click="initialize">Retry</button>
    </BaseCard>

    <template v-else>
      <BaseCard v-if="currentStep === 0">
        <div class="section-header">
          <div>
            <h3 class="h3">Select Patient</h3>
            <p class="section-copy">The plan will be written against the selected patient profile.</p>
          </div>
        </div>

        <div class="search-input">
          <Search :size="16" class="search-icon" />
          <input v-model.trim="patientSearch" type="text" placeholder="Search patients by name or email" />
        </div>

        <div v-if="filteredPatients.length === 0" class="empty-state">
          <p class="state-title">No patients found</p>
          <p class="state-copy">Try clearing the search or create the patient account first.</p>
        </div>

        <div v-else class="patient-grid">
          <button
            v-for="patient in filteredPatients"
            :key="patient.id"
            type="button"
            class="patient-card"
            :class="{ selected: selectedPatient?.id === patient.id }"
            @click="selectPatient(patient)"
          >
            <div class="patient-avatar">{{ getInitials(patient.name) }}</div>
            <div class="patient-info">
              <div class="patient-name">{{ patient.name }}</div>
              <div class="patient-email">{{ patient.email }}</div>
              <div class="patient-meta">{{ patient.condition || 'No condition recorded' }}</div>
            </div>
          </button>
        </div>

        <div v-if="selectedPatient" class="selection-note" :class="{ warning: !selectedPatient.user_id }">
          <p>
            Assigning to {{ selectedPatient.name }}
            <span v-if="selectedPatient.user_id">
              with a linked patient app account.
            </span>
            <span v-else>
              but this patient is missing a linked patient app account, so Android cannot resolve the profile.
            </span>
          </p>
        </div>

        <div class="step-actions">
          <button class="btn-primary" :disabled="!selectedPatient" @click="nextStep">Continue to Exercises</button>
        </div>
      </BaseCard>

      <BaseCard v-if="currentStep === 1">
        <div class="section-header">
          <div>
            <h3 class="h3">Select Exercises</h3>
            <p class="section-copy">Choose one or more exercises for {{ selectedPatient?.name }}.</p>
          </div>
        </div>

        <div class="filters-row">
          <div class="filter-group">
            <label class="filter-label">Category</label>
            <select v-model="filters.category" class="table-select">
              <option value="all">All Categories</option>
              <option value="upper_body">Upper Body</option>
              <option value="lower_body">Lower Body</option>
              <option value="balance">Balance</option>
              <option value="flexibility">Flexibility</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Difficulty</label>
            <select v-model="filters.difficulty" class="table-select">
              <option value="">All Levels</option>
              <option value="easy">Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Search</label>
            <div class="search-input">
              <Search :size="16" class="search-icon" />
              <input v-model.trim="filters.search" type="text" placeholder="Search exercises..." />
            </div>
          </div>
        </div>

        <div v-if="filteredExercises.length === 0" class="empty-state">
          <p class="state-title">No exercises match these filters</p>
          <p class="state-copy">Adjust the filters or load the exercise library again.</p>
        </div>

        <div v-else class="exercise-grid">
          <div
            v-for="exercise in filteredExercises"
            :key="exercise.id"
            class="exercise-card"
            :class="{ selected: isExerciseSelected(exercise.id) }"
          >
            <div class="exercise-header">
              <div class="exercise-info">
                <div class="exercise-name">{{ exercise.name }}</div>
                <p class="exercise-desc">{{ exercise.description || 'No description provided.' }}</p>
              </div>
              <input
                type="checkbox"
                :checked="isExerciseSelected(exercise.id)"
                @change="toggleExercise(exercise)"
                class="exercise-checkbox"
              />
            </div>
            <div class="exercise-badges">
              <BaseBadge variant="info">{{ exercise.category?.replace('_', ' ') }}</BaseBadge>
              <BaseBadge :variant="exercise.difficulty === 'easy' ? 'active' : exercise.difficulty === 'hard' ? 'danger' : 'warning'">
                {{ exercise.difficulty }}
              </BaseBadge>
            </div>
          </div>
        </div>

        <div v-if="selectedExercises.length > 0" class="selected-summary">
          <h4 class="h4">Selected: {{ selectedExercises.length }} exercise(s)</h4>
          <div class="selected-tags">
            <span v-for="exercise in selectedExercises" :key="exercise.id" class="selected-tag">
              {{ exercise.name }}
              <button type="button" class="tag-remove" @click="removeExercise(exercise.id)">
                <X :size="14" />
              </button>
            </span>
          </div>
        </div>

        <div class="step-actions">
          <button class="btn-ghost" @click="previousStep">Back</button>
          <button class="btn-primary" :disabled="selectedExercises.length === 0" @click="nextStep">
            Continue to Plan Details
          </button>
        </div>
      </BaseCard>

      <BaseCard v-if="currentStep === 2">
        <div class="section-header">
          <div>
            <h3 class="h3">Configure Plan</h3>
            <p class="section-copy">
              Saving writes the plan, plan exercises, compatibility `sessions`, and a best-effort `plan_updated` notification.
            </p>
          </div>
        </div>

        <div class="form-grid">
          <div class="form-group">
            <label class="form-label">Plan Name</label>
            <input v-model.trim="planForm.name" type="text" class="form-input" placeholder="Stroke Recovery Week 1" />
          </div>

          <div class="form-group">
            <label class="form-label">Start Date</label>
            <input v-model="planForm.startDate" type="date" class="form-input" />
          </div>

          <div class="form-group">
            <label class="form-label">End Date</label>
            <input v-model="planForm.endDate" type="date" class="form-input" />
          </div>
        </div>

        <div class="exercise-config-list">
          <div v-for="exercise in selectedExercises" :key="exercise.id" class="exercise-config-card">
            <div class="config-header">
              <div>
                <h5 class="exercise-config-title">{{ exercise.name }}</h5>
                <p class="exercise-desc">Plan row will use this exercise in the selected order.</p>
              </div>
            </div>

            <div class="form-grid-small">
              <div class="form-group">
                <label class="form-label">Sets</label>
                <input v-model.number="exerciseConfig[exercise.id]!.sets" type="number" min="1" class="form-input" />
              </div>

              <div class="form-group">
                <label class="form-label">Reps</label>
                <input v-model.number="exerciseConfig[exercise.id]!.reps" type="number" min="1" class="form-input" />
              </div>

              <div class="form-group">
                <label class="form-label">Duration (seconds)</label>
                <input v-model.number="exerciseConfig[exercise.id]!.durationSeconds" type="number" min="1" class="form-input" />
              </div>

              <div class="form-group">
                <label class="form-label">Difficulty</label>
                <select v-model="exerciseConfig[exercise.id]!.difficulty" class="form-input">
                  <option value="easy">Easy</option>
                  <option value="medium">Medium</option>
                  <option value="hard">Hard</option>
                </select>
              </div>

              <div class="form-group">
                <label class="form-label">ROM Min</label>
                <input v-model.number="exerciseConfig[exercise.id]!.romMinDegrees" type="number" min="0" class="form-input" />
              </div>

              <div class="form-group">
                <label class="form-label">ROM Max</label>
                <input v-model.number="exerciseConfig[exercise.id]!.romMaxDegrees" type="number" min="0" class="form-input" />
              </div>
            </div>

            <div class="form-group instructions-group">
              <label class="form-label">Special Instructions</label>
              <textarea
                v-model.trim="exerciseConfig[exercise.id]!.specialInstructions"
                rows="3"
                class="form-textarea"
                placeholder="Breathing cues, posture reminders, or pain precautions"
              ></textarea>
            </div>
          </div>
        </div>

        <div v-if="assignmentError" class="message-box error">
          <p class="message-title">Assignment failed</p>
          <p>{{ assignmentError }}</p>
        </div>

        <div v-if="assignmentLog.length > 0" class="message-box info">
          <p class="message-title">Assignment log</p>
          <ul class="log-list">
            <li v-for="entry in assignmentLog" :key="entry">{{ entry }}</li>
          </ul>
        </div>

        <div class="step-actions">
          <button class="btn-ghost" :disabled="isCreating" @click="previousStep">Back</button>
          <button class="btn-primary" :disabled="!isValidPlan || isCreating" @click="createPlan">
            {{ isCreating ? 'Saving Plan...' : 'Create Exercise Plan' }}
          </button>
        </div>
      </BaseCard>

      <BaseCard v-if="currentStep === 3">
        <div class="success-state">
          <div class="success-icon">
            <Check :size="40" />
          </div>
          <h2 class="h2">Plan Created Successfully</h2>
          <p class="state-copy">
            The plan was saved for {{ selectedPatient?.name }} and should be available to the linked Android patient account.
          </p>
          <div v-if="assignmentLog.length > 0" class="message-box info">
            <p class="message-title">Write log</p>
            <ul class="log-list">
              <li v-for="entry in assignmentLog" :key="entry">{{ entry }}</li>
            </ul>
          </div>
          <div class="success-actions">
            <button class="btn-ghost" @click="resetForm">Create Another Plan</button>
            <button class="btn-primary" @click="$router.push(`/patients/${selectedPatient?.id}`)">View Patient</button>
          </div>
        </div>
      </BaseCard>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Search, X, Check } from 'lucide-vue-next'
import { usePatientStore } from '@/stores/patientStore'
import { useExerciseStore } from '@/stores/exerciseStore'
import { useAuthStore } from '@/stores/authStore'
import BaseCard from '@/components/shared/BaseCard.vue'
import BaseBadge from '@/components/shared/BaseBadge.vue'
import type { Exercise, ExerciseDifficulty, Patient } from '@/types'

const router = useRouter()
const patientStore = usePatientStore()
const exerciseStore = useExerciseStore()
const authStore = useAuthStore()

const steps = ['Select Patient', 'Choose Exercises', 'Configure Plan', 'Complete']
const currentStep = ref(0)
const patientSearch = ref('')
const selectedPatient = ref<Patient | null>(null)
const selectedExercises = ref<Exercise[]>([])
const isCreating = ref(false)
const bootstrapError = ref('')
const isBootstrapping = ref(true)
const assignmentError = ref('')
const assignmentLog = ref<string[]>([])
const createdPlanId = ref('')

const filters = reactive({
  category: 'all',
  difficulty: '',
  search: '',
})

const planForm = reactive({
  name: '',
  startDate: '',
  endDate: '',
})

const exerciseConfig = reactive<
  Record<
    string,
    {
      difficulty: ExerciseDifficulty
      durationSeconds: number
      reps: number
      romMaxDegrees: number | null
      romMinDegrees: number | null
      sets: number
      specialInstructions: string
    }
  >
>({})

const filteredPatients = computed(() => {
  if (!patientSearch.value) return patientStore.patients
  const query = patientSearch.value.toLowerCase()
  return patientStore.patients.filter(
    (patient) =>
      patient.name.toLowerCase().includes(query) ||
      patient.email.toLowerCase().includes(query) ||
      (patient.condition || '').toLowerCase().includes(query),
  )
})

const filteredExercises = computed(() => {
  let exercises = exerciseStore.library

  if (filters.category !== 'all') {
    exercises = exercises.filter((exercise) => exercise.category === filters.category)
  }

  if (filters.difficulty) {
    exercises = exercises.filter((exercise) => exercise.difficulty === filters.difficulty)
  }

  if (filters.search) {
    const query = filters.search.toLowerCase()
    exercises = exercises.filter(
      (exercise) =>
        exercise.name.toLowerCase().includes(query) ||
        (exercise.description || '').toLowerCase().includes(query),
    )
  }

  return exercises
})

const isValidPlan = computed(() => {
  return Boolean(
    selectedPatient.value &&
      selectedPatient.value.user_id &&
      planForm.name &&
      planForm.startDate &&
      planForm.endDate &&
      selectedExercises.value.length > 0,
  )
})

function isoDate(date: Date) {
  return date.toISOString().split('T')[0] || ''
}

function appendLog(message: string) {
  assignmentLog.value = [...assignmentLog.value, `${new Date().toLocaleTimeString()}: ${message}`]
}

function getInitials(name: string) {
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

function selectPatient(patient: Patient) {
  selectedPatient.value = patient
  appendLog(`Selected patient ${patient.name}`)
  if (!planForm.name) {
    planForm.name = `${patient.name} Recovery Plan`
  }
}

function isExerciseSelected(id: string) {
  return selectedExercises.value.some((exercise) => exercise.id === id)
}

function toggleExercise(exercise: Exercise) {
  if (isExerciseSelected(exercise.id)) {
    removeExercise(exercise.id)
    return
  }

  selectedExercises.value.push(exercise)
  exerciseConfig[exercise.id] = {
    sets: 3,
    reps: 10,
    durationSeconds: exercise.duration_seconds || Math.max(60, (exercise.duration_minutes || 10) * 60),
    difficulty: exercise.difficulty,
    romMinDegrees: null,
    romMaxDegrees: null,
    specialInstructions: '',
  }
  appendLog(`Queued ${exercise.name}`)
}

function ensureConfig(exerciseId: string) {
  const config = exerciseConfig[exerciseId]
  if (!config) {
    throw new Error(`Exercise configuration is missing for ${exerciseId}`)
  }
  return config
}

function removeExercise(id: string) {
  const removedExercise = selectedExercises.value.find((exercise) => exercise.id === id)
  selectedExercises.value = selectedExercises.value.filter((exercise) => exercise.id !== id)
  delete exerciseConfig[id]
  appendLog(`Removed ${removedExercise?.name || 'exercise'} from the plan draft`)
}

function nextStep() {
  currentStep.value += 1
}

function previousStep() {
  currentStep.value -= 1
}

async function initialize() {
  isBootstrapping.value = true
  bootstrapError.value = ''

  try {
    await Promise.all([patientStore.fetchPatients(), exerciseStore.fetchExercises()])
    appendLog(`Loaded ${patientStore.patients.length} patients and ${exerciseStore.library.length} exercises`)
  } catch (error: any) {
    bootstrapError.value = error.message || patientStore.error || exerciseStore.error || 'Unable to load assignment data.'
  } finally {
    if (patientStore.error || exerciseStore.error) {
      bootstrapError.value =
        bootstrapError.value || patientStore.error || exerciseStore.error || 'Unable to load assignment data.'
    }
    isBootstrapping.value = false
  }
}

async function createPlan() {
  assignmentError.value = ''
  createdPlanId.value = ''
  assignmentLog.value = []

  if (!selectedPatient.value) {
    assignmentError.value = 'Select a patient before creating the plan.'
    return
  }

  if (!selectedPatient.value.user_id) {
    assignmentError.value =
      'This patient record is missing a linked patient app account, so Android cannot match the logged-in patient to this plan.'
    appendLog('Blocked assignment because the selected patient has no linked patient app account')
    return
  }

  if (!authStore.therapistProfile?.id) {
    assignmentError.value = 'Therapist profile is not loaded.'
    appendLog('Blocked assignment because therapist profile is missing')
    return
  }

  if (new Date(planForm.endDate) < new Date(planForm.startDate)) {
    assignmentError.value = 'End date cannot be earlier than the start date.'
    appendLog('Blocked assignment because plan dates are invalid')
    return
  }

  isCreating.value = true

  try {
    appendLog(`Saving plan for ${selectedPatient.value.name}`)
    appendLog('Using the linked patient app account so Android can resolve the same profile')

    exerciseStore.clearPlan()

    selectedExercises.value.forEach((exercise) => {
      const config = ensureConfig(exercise.id)
      exerciseStore.addToPlan(exercise, {
        sets: config.sets,
        reps: config.reps,
        duration_seconds: config.durationSeconds,
        difficulty: config.difficulty,
        rom_min_degrees: config.romMinDegrees,
        rom_max_degrees: config.romMaxDegrees,
        special_instructions: config.specialInstructions || null,
      })
      appendLog(`Prepared ${exercise.name}`)
    })

    const result = await exerciseStore.submitPlan(
      selectedPatient.value.id,
      authStore.therapistProfile.id,
      planForm.startDate,
      planForm.endDate,
      planForm.name,
    )

    if (!result.success) {
      throw new Error(result.error || exerciseStore.error || 'Supabase rejected the plan insert.')
    }

    createdPlanId.value = result.plan.id
    appendLog('Created the exercise plan and assigned exercises')
    if (result.compatibilitySessionsCreated > 0) {
      appendLog(`Created ${result.compatibilitySessionsCreated} compatibility session row(s) for the Android app`)
    } else if (result.compatibilitySessionsWarning) {
      appendLog(result.compatibilitySessionsWarning)
    }
    if (result.notificationCreated) {
      appendLog('Created the patient notification')
    } else if (result.notificationWarning) {
      appendLog(result.notificationWarning)
    }
    console.info('[AssignExerciseView] Plan created', {
      patientName: selectedPatient.value.name,
      planId: result.plan.id,
      exerciseNames: selectedExercises.value.map((exercise) => exercise.name),
      compatibilitySessionsCreated: result.compatibilitySessionsCreated,
      compatibilitySessionsWarning: result.compatibilitySessionsWarning,
      notificationCreated: result.notificationCreated,
      notificationWarning: result.notificationWarning,
      therapistId: authStore.therapistProfile.id,
    })

    currentStep.value = 3
  } catch (error: any) {
    assignmentError.value = error.message || 'Failed to create exercise plan.'
    appendLog(`Create plan failed: ${assignmentError.value}`)
    console.error('[AssignExerciseView] Failed to create plan', {
      error,
      patientName: selectedPatient.value.name,
      therapistId: authStore.therapistProfile.id,
    })
  } finally {
    isCreating.value = false
  }
}

function resetForm() {
  currentStep.value = 0
  selectedPatient.value = null
  selectedExercises.value = []
  assignmentError.value = ''
  assignmentLog.value = []
  createdPlanId.value = ''
  planForm.name = ''
  planForm.startDate = isoDate(new Date())
  planForm.endDate = isoDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
  Object.keys(exerciseConfig).forEach((key) => delete exerciseConfig[key])
  exerciseStore.clearPlan()
}

onMounted(async () => {
  planForm.startDate = isoDate(new Date())
  planForm.endDate = isoDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
  await initialize()
})
</script>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.page-subtitle,
.section-copy,
.state-copy,
.patient-email,
.patient-meta,
.exercise-desc {
  color: var(--text-muted);
  font-size: 14px;
}

.step-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-4);
  flex-wrap: wrap;
}

.step-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.step-number {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: var(--bg-hover);
  color: var(--text-muted);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
}

.step-number.active {
  background: var(--gradient-primary);
  color: white;
}

.step-number.complete {
  background: var(--gradient-success);
  color: white;
}

.step-label {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-muted);
}

.step-label.active {
  color: var(--text-primary);
}

.section-header {
  margin-bottom: var(--space-4);
}

.state-card,
.empty-state {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  align-items: flex-start;
}

.state-title {
  color: var(--text-primary);
  font-size: 18px;
  font-weight: 700;
}

.search-input {
  position: relative;
  width: 100%;
}

.search-icon {
  position: absolute;
  left: var(--space-3);
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-muted);
  pointer-events: none;
}

.search-input input {
  width: 100%;
  height: 40px;
  padding: 0 var(--space-3) 0 calc(var(--space-3) * 2 + 16px);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  outline: none;
}

.patient-grid,
.exercise-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--gap);
  margin-top: var(--space-4);
}

.patient-card,
.exercise-card,
.exercise-config-card {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: var(--bg-card);
}

.patient-card {
  display: flex;
  gap: var(--space-3);
  padding: var(--space-4);
  cursor: pointer;
  text-align: left;
}

.patient-card.selected,
.exercise-card.selected {
  border-color: var(--primary);
  background: var(--primary-light);
}

.patient-avatar {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  background: var(--gradient-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  flex-shrink: 0;
}

.patient-info,
.exercise-info {
  min-width: 0;
}

.patient-name,
.exercise-name,
.exercise-config-title,
.message-title {
  color: var(--text-primary);
  font-size: 14px;
  font-weight: 600;
}

.selection-note,
.selected-summary,
.message-box {
  margin-top: var(--space-4);
  padding: var(--space-4);
  border-radius: var(--radius-md);
  border: 1px solid var(--border);
  background: var(--bg-hover);
}

.selection-note.warning {
  border-color: #f59e0b;
  background: rgba(245, 158, 11, 0.12);
}

.filters-row,
.form-grid,
.form-grid-small {
  display: grid;
  gap: var(--gap);
}

.filters-row {
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
}

.form-grid {
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  margin-bottom: var(--space-6);
}

.form-grid-small {
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
}

.filter-group,
.form-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.filter-label,
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.table-select,
.form-input,
.form-textarea {
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-input);
  color: var(--text-primary);
  font-size: 14px;
  font-family: inherit;
  outline: none;
}

.table-select,
.form-input {
  height: 40px;
  padding: 0 var(--space-3);
}

.form-textarea {
  padding: var(--space-3);
  resize: vertical;
}

.exercise-card {
  padding: var(--space-4);
}

.exercise-header,
.config-header {
  display: flex;
  gap: var(--space-3);
  justify-content: space-between;
}

.exercise-badges {
  display: flex;
  gap: var(--space-2);
  margin-top: var(--space-3);
}

.selected-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.selected-tag {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
}

.tag-remove {
  background: none;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
}

.exercise-config-list {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.exercise-config-card {
  padding: var(--space-4);
}

.instructions-group {
  margin-top: var(--space-3);
}

.message-box.info {
  background: rgba(59, 130, 246, 0.08);
  border-color: rgba(59, 130, 246, 0.3);
}

.message-box.error {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.3);
  color: #991b1b;
}

.log-list {
  margin: var(--space-2) 0 0 var(--space-4);
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.step-actions,
.success-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-4);
}

.btn-primary,
.btn-ghost,
.btn-secondary {
  cursor: pointer;
  height: 40px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
}

.btn-primary {
  background: var(--gradient-primary);
  color: white;
  border: none;
}

.btn-ghost,
.btn-secondary {
  background: none;
  border: 1px solid var(--border);
  color: var(--primary);
}

.btn-primary:disabled,
.btn-ghost:disabled,
.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.success-state {
  text-align: center;
  padding: var(--space-8) var(--space-4);
}

.success-icon {
  width: 80px;
  height: 80px;
  border-radius: var(--radius-md);
  background: var(--status-active-bg);
  color: var(--success);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto var(--space-4);
}

.success-details {
  margin-top: var(--space-3);
}

@media (max-width: 768px) {
  .patient-grid,
  .exercise-grid,
  .filters-row,
  .form-grid,
  .form-grid-small {
    grid-template-columns: 1fr;
  }
}
</style>
