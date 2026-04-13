<template>
  <div class="page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2">Assign Exercises</h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px;">Create and manage exercise plans for your patients</p>
      </div>
    </div>

    <!-- Step Indicator -->
    <BaseCard>
      <div class="step-indicator">
        <div v-for="(step, index) in steps" :key="index" class="step-item">
          <div class="step-content">
            <div 
              class="step-number"
              :class="{
                'active': currentStep === index,
                'complete': currentStep > index
              }"
            >
              {{ index + 1 }}
            </div>
            <span 
              class="step-label"
              :class="{ 'active': currentStep >= index }"
            >
              {{ step }}
            </span>
          </div>
          <div v-if="index < steps.length - 1" class="step-line" :class="{ 'complete': currentStep > index }"></div>
        </div>
      </div>
    </BaseCard>

    <!-- Step 1: Select Patient -->
    <BaseCard v-if="currentStep === 0">
      <h3 class="h3" style="margin-bottom: var(--space-4);">Select Patient</h3>
      
      <div class="search-input" style="margin-bottom: var(--space-4);">
        <Search :size="16" class="search-icon" />
        <input
          v-model="patientSearch"
          type="text"
          placeholder="Search patients by name..."
        />
      </div>

      <div class="patient-grid">
        <div
          v-for="patient in filteredPatients"
          :key="patient.id"
          class="patient-card"
          :class="{ 'selected': selectedPatient?.id === patient.id }"
          @click="selectPatient(patient)"
        >
          <div class="patient-avatar">{{ getInitials(patient.name) }}</div>
          <div class="patient-info">
            <div class="patient-name">{{ patient.name }}</div>
            <div class="patient-email">{{ patient.email }}</div>
            <BaseBadge :variant="patient.status === 'active' ? 'active' : 'neutral'" style="margin-top: var(--space-2);">
              {{ patient.status }}
            </BaseBadge>
          </div>
        </div>
      </div>

      <div class="step-actions">
        <button class="btn-primary" :disabled="!selectedPatient" @click="nextStep">
          Continue to Exercises
        </button>
      </div>
    </BaseCard>

    <!-- Step 2: Select Exercises -->
    <BaseCard v-if="currentStep === 1">
      <h3 class="h3" style="margin-bottom: var(--space-1);">Select Exercises</h3>
      <p style="color: var(--text-muted); margin-bottom: var(--space-4);">Choose exercises for {{ selectedPatient?.name }}</p>

      <!-- Filters -->
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
            <input v-model="filters.search" type="text" placeholder="Search exercises..." />
          </div>
        </div>
      </div>

      <!-- Exercise Grid -->
      <div class="exercise-grid">
        <div
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          class="exercise-card"
          :class="{ 'selected': isExerciseSelected(exercise.id) }"
        >
          <div class="exercise-header">
            <div class="exercise-info">
              <div class="exercise-name">{{ exercise.name }}</div>
              <p class="exercise-desc">{{ exercise.description }}</p>
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
            <BaseBadge 
              :variant="exercise.difficulty === 'easy' ? 'active' : exercise.difficulty === 'hard' ? 'danger' : 'warning'"
            >
              {{ exercise.difficulty }}
            </BaseBadge>
          </div>
        </div>
      </div>

      <!-- Selected Summary -->
      <div v-if="selectedExercises.length > 0" class="selected-summary">
        <h4 class="h4">Selected: {{ selectedExercises.length }} exercise(s)</h4>
        <div class="selected-tags">
          <span v-for="ex in selectedExercises" :key="ex.id" class="selected-tag">
            {{ ex.name }}
            <button @click="removeExercise(ex.id)" class="tag-remove">
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

    <!-- Step 3: Configure Plan -->
    <BaseCard v-if="currentStep === 2">
      <h3 class="h3" style="margin-bottom: var(--space-1);">Configure Plan</h3>
      <p style="color: var(--text-muted); margin-bottom: var(--space-4);">Set plan details and exercise parameters</p>

      <!-- Plan Details -->
      <div class="form-grid" style="margin-bottom: var(--space-6);">
        <div class="form-group">
          <label class="form-label">Plan Name</label>
          <input
            v-model="planForm.name"
            type="text"
            placeholder="e.g., Upper Body Recovery Week 1"
            class="form-input"
          />
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

      <!-- Exercise Configuration -->
      <h4 class="h4" style="margin-bottom: var(--space-3);">Exercise Details</h4>
      <div class="exercise-config-list">
        <div v-for="exercise in selectedExercises" :key="exercise.id" class="exercise-config-card">
          <h5 class="exercise-config-title">{{ exercise.name }}</h5>
          <div class="form-grid-small">
            <div class="form-group">
              <label class="form-label">Sets</label>
              <input
                v-model.number="exerciseConfig[exercise.id].sets"
                type="number"
                placeholder="3"
                min="1"
                class="form-input"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Reps</label>
              <input
                v-model.number="exerciseConfig[exercise.id].reps"
                type="number"
                placeholder="10"
                min="1"
                class="form-input"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Duration (min)</label>
              <input
                v-model.number="exerciseConfig[exercise.id].duration"
                type="number"
                placeholder="10"
                min="1"
                class="form-input"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Difficulty</label>
              <select v-model="exerciseConfig[exercise.id].difficulty" class="form-input">
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div class="step-actions">
        <button class="btn-ghost" @click="previousStep">Back</button>
        <button class="btn-primary" :disabled="!isValidPlan" @click="createPlan">
          Create Exercise Plan
        </button>
      </div>
    </BaseCard>

    <!-- Success State -->
    <BaseCard v-if="currentStep === 3">
      <div class="success-state">
        <div class="success-icon">
          <Check :size="40" />
        </div>
        <h2 class="h2" style="margin-bottom: var(--space-2);">Plan Created Successfully!</h2>
        <p style="color: var(--text-muted); margin-bottom: var(--space-6);">
          Exercise plan for {{ selectedPatient?.name }} has been created.
        </p>
        <div class="success-actions">
          <button class="btn-ghost" @click="resetForm">Create Another Plan</button>
          <button class="btn-primary" @click="$router.push('/patients')">View Patients</button>
        </div>
      </div>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Search, X, Check } from 'lucide-vue-next'
import { usePatientStore } from '@/stores/patientStore'
import { useExerciseStore } from '@/stores/exerciseStore'
import { useAuthStore } from '@/stores/authStore'
import BaseCard from '@/components/shared/BaseCard.vue'
import BaseBadge from '@/components/shared/BaseBadge.vue'
import type { Patient, Exercise } from '@/types'

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

const filters = reactive({
  category: 'all',
  difficulty: '',
  search: ''
})

const planForm = reactive({
  name: '',
  startDate: new Date().toISOString().split('T')[0],
  endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
})

const exerciseConfig = reactive<Record<string, any>>({})

const filteredPatients = computed(() => {
  if (!patientSearch.value) return patientStore.patients
  return patientStore.patients.filter(p =>
    p.name.toLowerCase().includes(patientSearch.value.toLowerCase())
  )
})

const filteredExercises = computed(() => {
  let exercises = exerciseStore.library

  if (filters.category !== 'all') {
    exercises = exercises.filter(e => e.category === filters.category)
  }

  if (filters.difficulty) {
    exercises = exercises.filter(e => e.difficulty === filters.difficulty)
  }

  if (filters.search) {
    exercises = exercises.filter(e =>
      e.name.toLowerCase().includes(filters.search.toLowerCase())
    )
  }

  return exercises
})

const isValidPlan = computed(() => {
  return planForm.name && planForm.startDate && planForm.endDate && selectedExercises.value.length > 0
})

function getInitials(name: string) {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
}

function selectPatient(patient: Patient) {
  selectedPatient.value = patient
}

function isExerciseSelected(id: string) {
  return selectedExercises.value.some(e => e.id === id)
}

function toggleExercise(exercise: Exercise) {
  if (isExerciseSelected(exercise.id)) {
    selectedExercises.value = selectedExercises.value.filter(e => e.id !== exercise.id)
    delete exerciseConfig[exercise.id]
  } else {
    selectedExercises.value.push(exercise)
    exerciseConfig[exercise.id] = {
      sets: 3,
      reps: 10,
      duration: 10,
      difficulty: exercise.difficulty
    }
  }
}

function removeExercise(id: string) {
  selectedExercises.value = selectedExercises.value.filter(e => e.id !== id)
  delete exerciseConfig[id]
}

function nextStep() {
  currentStep.value++
}

function previousStep() {
  currentStep.value--
}

async function createPlan() {
  // Create plan logic here
  isCreating.value = true
  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 1000))
  isCreating.value = false
  nextStep()
}

function resetForm() {
  currentStep.value = 0
  selectedPatient.value = null
  selectedExercises.value = []
  planForm.name = ''
  Object.keys(exerciseConfig).forEach(key => delete exerciseConfig[key])
}

onMounted(async () => {
  await patientStore.fetchPatients()
  await exerciseStore.fetchExercises()
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
  margin-bottom: var(--space-2);
}

/* Step Indicator */
.step-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-4);
}

.step-item {
  display: flex;
  align-items: center;
}

.step-content {
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
  transition: all 0.2s;
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
  transition: color 0.2s;
}

.step-label.active {
  color: var(--text-primary);
}

.step-line {
  width: 96px;
  height: 2px;
  background: var(--border);
  margin: 0 var(--space-4);
  transition: background 0.2s;
}

.step-line.complete {
  background: var(--success);
}

/* Patient Selection */
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
  height: 36px;
  padding: 0 var(--space-3) 0 calc(var(--space-3) * 2 + 16px);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  outline: none;
}

.search-input input:focus {
  border-color: var(--border-focus);
}

.patient-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--gap);
  margin-bottom: var(--space-4);
}

.patient-card {
  display: flex;
  gap: var(--space-3);
  padding: var(--space-4);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.15s;
}

.patient-card:hover {
  border-color: var(--primary);
  box-shadow: var(--shadow-elevated);
}

.patient-card.selected {
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

.patient-info {
  flex: 1;
  min-width: 0;
}

.patient-name {
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
}

.patient-email {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 2px;
}

/* Filters */
.filters-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: var(--gap);
  margin-bottom: var(--space-4);
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.filter-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.table-select {
  height: 36px;
  padding: 0 var(--space-3);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  font-family: inherit;
  outline: none;
}

.table-select:focus {
  border-color: var(--border-focus);
}

/* Exercise Grid */
.exercise-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--gap);
  margin-bottom: var(--space-4);
}

.exercise-card {
  padding: var(--space-4);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  transition: all 0.15s;
}

.exercise-card.selected {
  border-color: var(--primary);
  background: var(--primary-light);
}

.exercise-header {
  display: flex;
  gap: var(--space-3);
  margin-bottom: var(--space-3);
}

.exercise-info {
  flex: 1;
  min-width: 0;
}

.exercise-name {
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
  margin-bottom: 4px;
}

.exercise-desc {
  font-size: 13px;
  color: var(--text-secondary);
}

.exercise-checkbox {
  width: 20px;
  height: 20px;
  border-radius: 4px;
  cursor: pointer;
  flex-shrink: 0;
  margin-top: 2px;
}

.exercise-badges {
  display: flex;
  gap: var(--space-2);
}

/* Selected Summary */
.selected-summary {
  padding: var(--space-4);
  background: var(--bg-hover);
  border-radius: var(--radius-md);
  margin-bottom: var(--space-4);
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
  font-size: 13px;
  color: var(--text-primary);
}

.tag-remove {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-muted);
  padding: 0;
  display: flex;
  align-items: center;
  transition: color 0.15s;
}

.tag-remove:hover {
  color: #EF4444;
}

/* Form Styles */
.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--gap);
}

.form-grid-small {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: var(--gap);
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.form-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.form-input {
  height: 36px;
  padding: 0 var(--space-3);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  font-family: inherit;
  outline: none;
}

.form-input:focus {
  border-color: var(--border-focus);
}

.exercise-config-list {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
  margin-bottom: var(--space-4);
}

.exercise-config-card {
  padding: var(--space-4);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
}

.exercise-config-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: var(--space-3);
}

/* Step Actions */
.step-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-4);
}

.btn-primary {
  background: var(--gradient-primary);
  color: white;
  border: none;
  cursor: pointer;
  height: 40px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  transition: opacity 0.15s;
}

.btn-primary:hover {
  opacity: 0.9;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  cursor: pointer;
  height: 40px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  color: var(--primary);
  font-weight: 600;
  transition: background 0.15s, border-color 0.15s;
}

.btn-ghost:hover {
  background: var(--primary-light);
  border-color: var(--primary);
}

/* Success State */
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

.success-actions {
  display: flex;
  justify-content: center;
  gap: var(--space-2);
}
</style>
