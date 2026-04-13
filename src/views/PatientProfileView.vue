<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="h2">Patient Profile</h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px">
          Detailed patient information and progress
        </p>
      </div>
      <div style="display: flex; gap: var(--space-2)">
        <button class="btn-ghost" @click="router.push('/patients')">Back to Patients</button>
        <button class="btn-primary" @click="router.push(`/assign-exercise?patientId=${route.params.id}`)">
          Assign Exercise
        </button>
      </div>
    </div>

    <BaseCard v-if="patient">
      <div class="profile-header">
        <div class="profile-avatar-large">{{ getInitials(patient.name) }}</div>
        <div class="profile-info">
          <h2 class="h2" style="margin-bottom: 4px">{{ patient.name }}</h2>
          <p style="color: var(--text-muted); margin-bottom: var(--space-2)">{{ patient.email }}</p>
          <BaseBadge :variant="getStatusVariant(patient.status)">{{ formatStatus(patient.status) }}</BaseBadge>
        </div>
        <div class="profile-stats">
          <div class="stat-item">
            <div class="stat-label">ADHERENCE</div>
            <div class="stat-value">{{ patient.adherence_rate ?? 0 }}%</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">SESSIONS</div>
            <div class="stat-value">{{ patient.total_sessions ?? patientSessions.length }}</div>
          </div>
          <div class="stat-item">
            <div class="stat-label">LAST VISIT</div>
            <div class="stat-value caption">{{ formatDate(patient.last_session) }}</div>
          </div>
        </div>
      </div>
    </BaseCard>

    <BaseCard v-else-if="loadError">
      <div class="empty-state">
        <p class="h4">Unable to load this patient</p>
        <p style="color: var(--text-muted)">{{ loadError }}</p>
      </div>
    </BaseCard>

    <div class="tabs-container">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="tab-button"
        :class="{ 'tab-button--active': activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        {{ tab.label }}
      </button>
    </div>

    <div class="tab-content" v-if="patient">
      <div v-if="activeTab === 'overview'" class="profile-grid">
        <div class="profile-column">
          <BaseCard>
            <h3 class="h3" style="margin-bottom: var(--space-4)">Patient Details</h3>
            <div class="detail-list">
              <div class="detail-item">
                <div class="detail-label">CONDITION</div>
                <div class="detail-value">{{ patient.condition }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">AGE</div>
                <div class="detail-value">{{ patient.age ?? 'N/A' }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">ENROLLED DATE</div>
                <div class="detail-value">{{ formatDate(patient.enrolled_date) }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">STROKE TYPE</div>
                <div class="detail-value">{{ patient.stroke_type || 'N/A' }}</div>
              </div>
            </div>
          </BaseCard>

          <BaseCard>
            <h3 class="h3" style="margin-bottom: var(--space-4)">Current Exercises</h3>
            <div v-if="currentExercises.length === 0" class="empty-list">No assigned exercises yet.</div>
            <div v-else class="exercise-list">
              <div v-for="exercise in currentExercises" :key="exercise.planExerciseId" class="exercise-list-item">
                <div>
                  <div class="exercise-list-name">{{ exercise.name }}</div>
                  <div class="exercise-list-meta">
                    {{ exercise.sets }} sets x {{ exercise.reps }} reps · {{ exercise.duration_minutes }} min
                  </div>
                  <div class="exercise-list-subtle">{{ exercise.planName }}</div>
                  <div v-if="exercise.special_instructions" class="exercise-list-notes">
                    {{ exercise.special_instructions }}
                  </div>
                </div>
                <BaseBadge :variant="getPlanStatusVariant(exercise.planStatus)">
                  {{ formatStatus(exercise.planStatus) }}
                </BaseBadge>
              </div>
            </div>
          </BaseCard>
        </div>

        <div class="profile-column">
          <BaseCard>
            <h3 class="h3" style="margin-bottom: var(--space-4)">Latest Progress Snapshot</h3>
            <div v-if="latestMetric" class="stats-list">
              <div class="stat-row">
                <span class="stat-row-label">ROM</span>
                <span class="stat-row-value">{{ latestMetric.rom_degrees ?? 0 }} deg</span>
              </div>
              <div class="stat-row">
                <span class="stat-row-label">Strength</span>
                <span class="stat-row-value">{{ latestMetric.strength_score ?? 0 }}</span>
              </div>
              <div class="stat-row">
                <span class="stat-row-label">Balance</span>
                <span class="stat-row-value">{{ latestMetric.balance_score ?? 0 }}</span>
              </div>
              <div class="stat-row">
                <span class="stat-row-label">Metric Date</span>
                <span class="stat-row-value">{{ formatDate(latestMetric.date) }}</span>
              </div>
            </div>
            <div v-else class="empty-list">No progress metrics available yet.</div>
          </BaseCard>

          <BaseCard>
            <h3 class="h3" style="margin-bottom: var(--space-4)">Recent Sessions</h3>
            <div v-if="recentSessions.length === 0" class="empty-list">No sessions recorded yet.</div>
            <div v-else class="history-list">
              <div v-for="session in recentSessions" :key="session.id" class="history-item">
                <div class="history-date">{{ formatDate(session.date) }}</div>
                <div class="history-details">
                  <div class="history-title">{{ session.exercise?.name || 'Exercise session' }}</div>
                  <div class="history-meta">
                    <span>{{ session.duration_minutes ?? 0 }} min</span>
                    <span>·</span>
                    <span>{{ session.accuracy_percent ?? 0 }}% accuracy</span>
                    <span>·</span>
                    <span>{{ session.sets_completed ?? 0 }} sets / {{ session.reps_completed ?? 0 }} reps</span>
                  </div>
                </div>
                <BaseBadge variant="info">{{ session.form_quality || 'Recorded' }}</BaseBadge>
              </div>
            </div>
          </BaseCard>
        </div>
      </div>

      <div v-if="activeTab === 'history'">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-4)">Session History</h3>
          <div v-if="patientSessions.length === 0" class="empty-list">No session history available.</div>
          <div v-else class="history-list">
            <div v-for="session in patientSessions" :key="session.id" class="history-item history-item--full">
              <div class="history-date">{{ formatDate(session.date) }}</div>
              <div class="history-details">
                <div class="history-title">{{ session.exercise?.name || 'Exercise session' }}</div>
                <div class="history-meta">
                  <span>{{ session.duration_minutes ?? 0 }} min</span>
                  <span>·</span>
                  <span>{{ session.accuracy_percent ?? 0 }}% accuracy</span>
                  <span>·</span>
                  <span>{{ session.sets_completed ?? 0 }} sets / {{ session.reps_completed ?? 0 }} reps</span>
                </div>
                <div v-if="session.notes" class="history-notes">{{ session.notes }}</div>
              </div>
              <BaseBadge :variant="session.form_quality === 'needs_work' ? 'warning' : 'active'">
                {{ session.form_quality || 'Recorded' }}
              </BaseBadge>
            </div>
          </div>
        </BaseCard>
      </div>

      <div v-if="activeTab === 'progress'">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-4)">Progress Metrics</h3>
          <div v-if="patientProgress.length === 0" class="empty-list">No progress metrics available.</div>
          <div v-else class="metrics-table">
            <div class="metrics-row metrics-row--header">
              <span>Date</span>
              <span>ROM</span>
              <span>Strength</span>
              <span>Balance</span>
              <span>Adherence</span>
            </div>
            <div v-for="metric in patientProgress" :key="metric.id" class="metrics-row">
              <span>{{ formatDate(metric.date) }}</span>
              <span>{{ metric.rom_degrees ?? 0 }} deg</span>
              <span>{{ metric.strength_score ?? 0 }}</span>
              <span>{{ metric.balance_score ?? 0 }}</span>
              <span>{{ metric.adherence_percent ?? 0 }}%</span>
            </div>
          </div>
        </BaseCard>
      </div>

      <div v-if="activeTab === 'notes'">
        <BaseCard>
          <div class="notes-header">
            <h3 class="h3">Clinical Notes</h3>
          </div>

          <div class="note-editor">
            <textarea
              v-model="newNote"
              class="note-textarea"
              rows="4"
              placeholder="Add a therapist note for this patient"
            ></textarea>
            <button class="btn-primary" :disabled="isSavingNote || !newNote.trim()" @click="saveNote">
              {{ isSavingNote ? 'Saving...' : 'Add Note' }}
            </button>
          </div>

          <div v-if="patientNotes.length === 0" class="empty-list">No notes recorded yet.</div>
          <div v-else class="notes-list">
            <div v-for="note in patientNotes" :key="note.id" class="note-item">
              <div class="note-header">
                <div>
                  <div class="note-author-name">{{ note.therapist?.name || 'Therapist' }}</div>
                  <div class="note-date">{{ formatDateTime(note.created_at) }}</div>
                </div>
              </div>
              <div class="note-content">{{ note.note }}</div>
            </div>
          </div>
        </BaseCard>
      </div>

      <div v-if="activeTab === 'exercises'">
        <BaseCard>
          <div class="notes-header">
            <h3 class="h3">Exercise Plans</h3>
            <button class="btn-primary" @click="router.push(`/assign-exercise?patientId=${route.params.id}`)">
              Assign New
            </button>
          </div>

          <div v-if="exercisePlans.length === 0" class="empty-list">No exercise plans assigned yet.</div>
          <div v-else class="plans-list">
            <div v-for="plan in exercisePlans" :key="plan.id" class="plan-card">
              <div class="plan-card-header">
                <div>
                  <h4 class="exercise-card-title">{{ plan.name }}</h4>
                  <p class="exercise-card-category">
                    {{ formatDate(plan.start_date) }} to {{ formatDate(plan.end_date) }}
                  </p>
                </div>
                <BaseBadge :variant="getPlanStatusVariant(plan.status)">{{ formatStatus(plan.status) }}</BaseBadge>
              </div>

              <div v-if="plan.plan_exercises.length === 0" class="empty-list">No exercises in this plan.</div>
              <div v-else class="exercise-plan-items">
                <div v-for="item in orderedPlanExercises(plan.plan_exercises)" :key="item.id" class="exercise-plan-item">
                  <div>
                    <div class="exercise-list-name">{{ item.exercise?.name || 'Exercise' }}</div>
                    <div class="exercise-list-meta">
                      {{ item.sets ?? 0 }} sets x {{ item.reps ?? 0 }} reps · {{ item.duration_minutes ?? 0 }} min
                    </div>
                    <div class="exercise-list-subtle">Difficulty: {{ item.difficulty || item.exercise?.difficulty || 'N/A' }}</div>
                    <div v-if="item.special_instructions" class="exercise-list-notes">
                      {{ item.special_instructions }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import BaseBadge from '@/components/shared/BaseBadge.vue'
import BaseCard from '@/components/shared/BaseCard.vue'
import { useExerciseStore } from '@/stores/exerciseStore'
import { usePatientStore } from '@/stores/patientStore'
import type { PlanExerciseWithExercise } from '@/types'

const route = useRoute()
const router = useRouter()
const patientStore = usePatientStore()
const exerciseStore = useExerciseStore()

const activeTab = ref('overview')
const isSavingNote = ref(false)
const newNote = ref('')

const tabs = [
  { id: 'overview', label: 'Overview' },
  { id: 'history', label: 'Session History' },
  { id: 'progress', label: 'Progress' },
  { id: 'notes', label: 'Clinical Notes' },
  { id: 'exercises', label: 'Exercise Plans' },
]

const patient = computed(() => patientStore.selectedPatient)
const patientSessions = computed(() => patientStore.patientSessions)
const patientProgress = computed(() => patientStore.patientProgress)
const patientNotes = computed(() => patientStore.patientNotes)
const exercisePlans = computed(() => exerciseStore.exercisePlans)
const loadError = computed(() => patientStore.error || exerciseStore.error)

const latestMetric = computed(() => patientProgress.value[0] ?? null)
const recentSessions = computed(() => patientSessions.value.slice(0, 5))
const currentExercises = computed(() => {
  return exercisePlans.value
    .filter((plan) => (plan.status ?? 'active') === 'active')
    .flatMap((plan) =>
      plan.plan_exercises.map((exercise) => ({
        difficulty: exercise.difficulty || exercise.exercise?.difficulty || 'medium',
        duration_minutes: exercise.duration_minutes ?? exercise.exercise?.duration_minutes ?? 0,
        name: exercise.exercise?.name || 'Exercise',
        planExerciseId: exercise.id,
        planName: plan.name,
        planStatus: plan.status ?? 'active',
        reps: exercise.reps ?? 0,
        sets: exercise.sets ?? 0,
        special_instructions: exercise.special_instructions,
      })),
    )
})

function getInitials(name: string) {
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

function formatDate(date?: string | null) {
  if (!date) return 'N/A'
  return new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

function formatDateTime(date?: string | null) {
  if (!date) return 'N/A'
  return new Date(date).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function formatStatus(status?: string | null) {
  if (!status) return 'Unknown'
  return status
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

function getStatusVariant(status?: string | null): 'active' | 'warning' | 'danger' | 'info' | 'neutral' {
  if (status === 'active') return 'active'
  if (status === 'needs_attention') return 'warning'
  return 'neutral'
}

function getPlanStatusVariant(status?: string | null): 'active' | 'warning' | 'danger' | 'info' | 'neutral' {
  if (status === 'completed') return 'info'
  if (status === 'draft') return 'warning'
  return 'active'
}

function orderedPlanExercises(planExercises: PlanExerciseWithExercise[]) {
  return [...planExercises].sort((left, right) => (left.order ?? 0) - (right.order ?? 0))
}

async function loadPatientDetail() {
  const patientId = String(route.params.id)
  const patientRecord = await patientStore.fetchPatientById(patientId)

  if (!patientRecord) {
    return
  }

  await Promise.all([
    patientStore.fetchPatientSessions(patientId),
    patientStore.fetchPatientProgress(patientId),
    patientStore.fetchPatientNotes(patientId),
    exerciseStore.fetchPatientPlans(patientId),
  ])
}

async function saveNote() {
  if (!newNote.value.trim()) {
    return
  }

  isSavingNote.value = true

  try {
    const result = await patientStore.addNote(String(route.params.id), newNote.value.trim())
    if (result.success) {
      newNote.value = ''
    }
  } finally {
    isSavingNote.value = false
  }
}

onMounted(async () => {
  await loadPatientDetail()
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

.btn-primary,
.btn-ghost {
  height: 40px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.btn-primary {
  background: var(--gradient-primary);
  color: white;
  border: none;
}

.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  color: var(--text-primary);
}

.profile-header {
  display: flex;
  gap: var(--space-4);
  align-items: center;
}

.profile-avatar-large {
  width: 80px;
  height: 80px;
  border-radius: var(--radius-lg);
  background: var(--gradient-primary);
  color: white;
  font-size: 24px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.profile-info {
  flex: 1;
}

.profile-stats {
  display: flex;
  gap: var(--space-6);
}

.stat-item {
  text-align: right;
}

.stat-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
}

.tabs-container {
  display: flex;
  gap: var(--space-2);
  border-bottom: 1px solid var(--border);
}

.tab-button {
  padding: var(--space-3) var(--space-4);
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  color: var(--text-secondary);
  cursor: pointer;
  font-weight: 600;
}

.tab-button--active {
  color: var(--primary);
  border-bottom-color: var(--primary);
}

.profile-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--gap);
}

.profile-column {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.detail-list,
.stats-list,
.notes-list,
.plans-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.detail-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-muted);
}

.detail-value,
.stat-row-value,
.exercise-list-name,
.history-title {
  color: var(--text-primary);
}

.exercise-list,
.history-list,
.exercise-plan-items {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.exercise-list-item,
.history-item,
.note-item,
.plan-card,
.exercise-plan-item {
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: var(--space-3);
}

.exercise-list-item,
.history-item,
.plan-card-header,
.notes-header {
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
  align-items: flex-start;
}

.exercise-list-meta,
.exercise-list-subtle,
.history-meta,
.note-date,
.exercise-card-category,
.history-notes,
.exercise-list-notes {
  color: var(--text-muted);
  font-size: 13px;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  gap: var(--space-2);
}

.stat-row-label {
  color: var(--text-muted);
}

.metrics-table {
  display: flex;
  flex-direction: column;
  gap: 1px;
  border-radius: var(--radius-sm);
  overflow: hidden;
  border: 1px solid var(--border);
}

.metrics-row {
  display: grid;
  grid-template-columns: 1.2fr repeat(4, 1fr);
  gap: var(--space-2);
  padding: var(--space-3);
  background: var(--bg-card);
}

.metrics-row--header {
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  background: var(--bg-hover);
  color: var(--text-muted);
}

.note-editor {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  margin: var(--space-4) 0;
}

.note-textarea {
  width: 100%;
  min-height: 112px;
  padding: var(--space-3);
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  background: var(--bg-input);
  color: var(--text-primary);
  resize: vertical;
  font: inherit;
}

.note-content {
  color: var(--text-primary);
  line-height: 1.5;
}

.empty-list,
.empty-state {
  padding: var(--space-5);
  border: 1px dashed var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-muted);
  text-align: center;
}

@media (max-width: 960px) {
  .page-header,
  .profile-header,
  .profile-stats,
  .profile-grid,
  .metrics-row {
    grid-template-columns: 1fr;
    flex-direction: column;
  }
}
</style>
