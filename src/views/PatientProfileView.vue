<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="h2">Patient Profile</h1>
        <p class="page-subtitle">View real plans, sessions, progress, and clinical notes from Supabase.</p>
      </div>

      <div class="header-actions">
        <button class="btn-secondary" @click="router.push('/patients')">Back</button>
        <button class="btn-secondary" @click="openNoteModal">Add Clinical Note</button>
        <button class="btn-primary" @click="router.push(`/assign-exercise?patientId=${patientId}`)">Assign Exercise</button>
      </div>
    </div>

    <BaseCard v-if="isLoading" class="state-card">
      <p class="state-text">Loading patient details...</p>
    </BaseCard>

    <BaseCard v-else-if="loadError" class="state-card">
      <p class="state-title">Unable to load this patient</p>
      <p class="state-text">{{ loadError }}</p>
      <button class="btn-secondary" @click="loadPatientDetail">Retry</button>
    </BaseCard>

    <template v-else-if="patient">
      <BaseCard>
        <div class="profile-header">
          <div class="profile-avatar">{{ getInitials(patient.name) }}</div>

          <div class="profile-copy">
            <h2 class="h2">{{ patient.name }}</h2>
            <p class="profile-meta">{{ patient.email }}</p>
            <div class="badge-row">
              <BaseBadge :variant="patient.status === 'active' ? 'active' : patient.status === 'needs_attention' ? 'warning' : 'neutral'">
                {{ formatStatus(patient.status || 'inactive') }}
              </BaseBadge>
              <BaseBadge variant="info">{{ patient.condition || 'No condition recorded' }}</BaseBadge>
            </div>
          </div>

          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-label">Adherence</div>
              <div class="stat-value">{{ patient.adherence_rate ?? 0 }}%</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Sessions</div>
              <div class="stat-value">{{ patient.total_sessions ?? patientSessions.length }}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Average Accuracy</div>
              <div class="stat-value">{{ formatPercent(patient.avg_accuracy) }}</div>
            </div>
          </div>
        </div>
      </BaseCard>

      <div class="tabs">
        <button v-for="tab in tabs" :key="tab.id" class="tab-button" :class="{ 'tab-button--active': activeTab === tab.id }" @click="activeTab = tab.id">
          {{ tab.label }}
        </button>
      </div>

      <div v-if="activeTab === 'overview'" class="overview-grid">
        <BaseCard>
          <h3 class="h3">Patient Snapshot</h3>
          <div class="detail-grid">
            <div class="detail-item">
              <span class="detail-label">Age</span>
              <span class="detail-value">{{ patient.age ?? 'N/A' }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Stroke Type</span>
              <span class="detail-value">{{ patient.stroke_type || 'N/A' }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Enrolled</span>
              <span class="detail-value">{{ formatDate(patient.enrolled_date) }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Last Session</span>
              <span class="detail-value">{{ formatDate(patient.last_session) }}</span>
            </div>
          </div>
        </BaseCard>

        <BaseCard>
          <div class="card-header">
            <div>
              <h3 class="h3">ROM Progress</h3>
              <p class="card-copy">Based on `progress_metrics.rom_degrees`.</p>
            </div>
          </div>
          <div v-if="romChartData.labels.length" class="chart-wrap">
            <Line :data="romChartData" :options="lineChartOptions" />
          </div>
          <div v-else class="empty-card">No ROM metrics recorded yet.</div>
        </BaseCard>

        <BaseCard>
          <div class="card-header">
            <div>
              <h3 class="h3">Recent Session Accuracy</h3>
              <p class="card-copy">Pulled from recorded sessions.</p>
            </div>
          </div>
          <div v-if="accuracyChartData.labels.length" class="chart-wrap">
            <Bar :data="accuracyChartData" :options="barChartOptions" />
          </div>
          <div v-else class="empty-card">No session accuracy data recorded yet.</div>
        </BaseCard>

        <BaseCard>
          <h3 class="h3">Active Plan Exercises</h3>
          <div v-if="activePlanExercises.length" class="list-stack">
            <article v-for="exercise in activePlanExercises" :key="exercise.planExerciseId" class="list-card">
              <div class="list-card-head">
                <div>
                  <h4 class="list-title">{{ exercise.name }}</h4>
                  <p class="list-meta">
                    {{ exercise.sets }} sets x {{ exercise.reps }} reps · {{ formatDuration(exercise.duration_seconds) }}
                  </p>
                  <p class="list-meta">ROM: {{ formatRom(exercise.rom_min_degrees, exercise.rom_max_degrees) }}</p>
                  <p class="list-meta">Plan: {{ exercise.planName }}</p>
                  <p v-if="exercise.special_instructions" class="list-copy">{{ exercise.special_instructions }}</p>
                </div>
                <BaseBadge :variant="exercise.planStatus === 'completed' ? 'info' : 'active'">
                  {{ formatStatus(exercise.planStatus) }}
                </BaseBadge>
              </div>
            </article>
          </div>
          <div v-else class="empty-card">No active exercises assigned.</div>
        </BaseCard>
      </div>

      <BaseCard v-if="activeTab === 'sessions'">
        <div class="card-header">
          <div>
            <h3 class="h3">Session History</h3>
            <p class="card-copy">Loaded from `sessions` and `session_logs`.</p>
          </div>
        </div>

        <div v-if="patientSessions.length" class="list-stack">
          <article v-for="session in patientSessions" :key="session.id" class="session-card">
            <div class="session-header">
              <div>
                <h4 class="list-title">{{ session.exercise?.name || 'Session' }}</h4>
                <p class="list-meta">
                  {{ formatDate(session.date) }} · {{ formatStatus(session.status || 'completed') }} ·
                  {{ formatDuration(session.duration_seconds ?? (session.duration_minutes ?? 0) * 60) }}
                </p>
                <p class="list-meta">
                  Sets {{ session.sets_completed ?? 0 }} · Reps {{ session.reps_completed ?? 0 }} · Accuracy {{ formatPercent(session.accuracy_percent) }}
                </p>
                <p v-if="session.started_at || session.completed_at" class="list-meta">
                  {{ formatDateTime(session.started_at) }} to {{ formatDateTime(session.completed_at) }}
                </p>
                <p v-if="session.notes" class="list-copy">{{ session.notes }}</p>
              </div>
              <BaseBadge :variant="session.status === 'completed' ? 'active' : session.status === 'paused' ? 'warning' : 'info'">
                {{ formatStatus(session.status || 'completed') }}
              </BaseBadge>
            </div>

            <div v-if="session.session_logs?.length" class="log-list">
              <div v-for="log in session.session_logs" :key="log.id" class="log-row">
                <div>
                  <div class="log-title">{{ log.exercise?.name || session.exercise?.name || 'Exercise log' }}</div>
                  <div class="log-meta">
                    Reps {{ log.reps_completed ?? 0 }} · Accuracy {{ formatPercent(log.accuracy_score) }} · ROM {{ formatDecimal(log.range_of_motion) }} deg
                  </div>
                </div>
                <div class="log-note">{{ log.notes || 'No log notes' }}</div>
              </div>
            </div>
          </article>
        </div>
        <div v-else class="empty-card">No sessions recorded for this patient yet.</div>
      </BaseCard>

      <BaseCard v-if="activeTab === 'progress'">
        <div class="card-header">
          <div>
            <h3 class="h3">Progress Metrics</h3>
            <p class="card-copy">Tracked from `progress_metrics`.</p>
          </div>
        </div>

        <div v-if="progressChartData.labels.length" class="chart-wrap chart-wrap--tall">
          <Line :data="progressChartData" :options="lineChartOptions" />
        </div>

        <div v-if="patientProgress.length" class="metrics-table">
          <div class="metrics-row metrics-row--header">
            <span>Date</span>
            <span>ROM</span>
            <span>Strength</span>
            <span>Balance</span>
            <span>Adherence</span>
          </div>
          <div v-for="metric in orderedProgress" :key="metric.id" class="metrics-row">
            <span>{{ formatDate(metric.date) }}</span>
            <span>{{ metric.rom_degrees ?? 0 }} deg</span>
            <span>{{ metric.strength_score ?? 0 }}</span>
            <span>{{ metric.balance_score ?? 0 }}</span>
            <span>{{ metric.adherence_percent ?? 0 }}%</span>
          </div>
        </div>
        <div v-else class="empty-card">No progress metrics recorded yet.</div>
      </BaseCard>

      <BaseCard v-if="activeTab === 'notes'">
        <div class="card-header">
          <div>
            <h3 class="h3">Clinical Notes</h3>
            <p class="card-copy">Therapist-authored entries saved to `session_notes`.</p>
          </div>
          <button class="btn-primary" @click="openNoteModal">Add Clinical Note</button>
        </div>

        <div v-if="patientNotes.length" class="list-stack">
          <article v-for="note in patientNotes" :key="note.id" class="list-card">
            <div class="list-card-head">
              <div>
                <h4 class="list-title">{{ note.therapist?.name || 'Therapist' }}</h4>
                <p class="list-meta">{{ formatDateTime(note.created_at) }}</p>
                <p v-if="note.session_id" class="list-meta">Linked session: {{ note.session_id }}</p>
              </div>
            </div>
            <p class="list-copy">{{ note.note }}</p>
          </article>
        </div>
        <div v-else class="empty-card">No clinical notes have been added yet.</div>
      </BaseCard>

      <BaseCard v-if="activeTab === 'plans'">
        <div class="card-header">
          <div>
            <h3 class="h3">Exercise Plans</h3>
            <p class="card-copy">Real plan metadata with ROM-aware plan exercise configuration.</p>
          </div>
          <button class="btn-primary" @click="router.push(`/assign-exercise?patientId=${patientId}`)">Assign New</button>
        </div>

        <div v-if="exercisePlans.length" class="list-stack">
          <article v-for="plan in exercisePlans" :key="plan.id" class="list-card">
            <div class="list-card-head">
              <div>
                <h4 class="list-title">{{ plan.name }}</h4>
                <p class="list-meta">{{ formatDate(plan.start_date) }} to {{ formatDate(plan.end_date) }}</p>
              </div>
              <BaseBadge :variant="plan.status === 'completed' ? 'info' : plan.status === 'draft' ? 'warning' : 'active'">
                {{ formatStatus(plan.status || 'active') }}
              </BaseBadge>
            </div>

            <div v-if="plan.plan_exercises.length" class="plan-list">
              <div v-for="entry in orderedPlanExercises(plan.plan_exercises)" :key="entry.id" class="plan-row">
                <div>
                  <div class="log-title">{{ entry.exercise?.name || 'Exercise' }}</div>
                  <div class="log-meta">
                    {{ entry.sets ?? 0 }} sets x {{ entry.reps ?? 0 }} reps · {{ formatDuration(entry.duration_seconds ?? (entry.duration_minutes ?? 0) * 60) }}
                  </div>
                  <div class="log-meta">ROM: {{ formatRom(entry.rom_min_degrees, entry.rom_max_degrees) }}</div>
                  <div class="log-meta">Difficulty: {{ formatStatus(entry.difficulty || entry.exercise?.difficulty || 'medium') }}</div>
                  <p v-if="entry.special_instructions" class="list-copy">{{ entry.special_instructions }}</p>
                </div>
              </div>
            </div>
            <div v-else class="empty-card">This plan has no exercises yet.</div>
          </article>
        </div>
        <div v-else class="empty-card">No plans assigned to this patient yet.</div>
      </BaseCard>
    </template>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="isNoteModalOpen" class="modal-overlay" @click.self="closeNoteModal">
          <div class="modal-card">
            <div class="modal-header">
              <div>
                <h3 class="h3">Add Clinical Note</h3>
                <p class="card-copy">Save a therapist note directly to `session_notes`.</p>
              </div>
              <button class="icon-btn" @click="closeNoteModal" aria-label="Close note modal">×</button>
            </div>

            <div class="modal-body">
              <div class="form-group">
                <label class="form-label" for="note-session">Link to session (optional)</label>
                <select id="note-session" v-model="noteForm.sessionId" class="form-input">
                  <option value="">No linked session</option>
                  <option v-for="session in patientSessions" :key="session.id" :value="session.id">
                    {{ formatDate(session.date) }} · {{ session.exercise?.name || 'Session' }}
                  </option>
                </select>
              </div>

              <div class="form-group">
                <label class="form-label" for="note-body">Clinical note</label>
                <textarea id="note-body" v-model.trim="noteForm.note" class="form-textarea" rows="6"></textarea>
              </div>

              <p v-if="noteError" class="status-message status-message--error">{{ noteError }}</p>
            </div>

            <div class="modal-footer">
              <button class="btn-secondary" :disabled="isSavingNote" @click="closeNoteModal">Cancel</button>
              <button class="btn-primary" :disabled="isSavingNote" @click="saveNote">
                {{ isSavingNote ? 'Saving...' : 'Save Note' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { Bar, Line } from 'vue-chartjs'
import {
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  Filler,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Tooltip,
} from 'chart.js'
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import BaseBadge from '@/components/shared/BaseBadge.vue'
import BaseCard from '@/components/shared/BaseCard.vue'
import { useExerciseStore } from '@/stores/exerciseStore'
import { usePatientStore } from '@/stores/patientStore'
import type { PlanExerciseWithExercise } from '@/types'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Legend, Tooltip, Filler)

const route = useRoute()
const router = useRouter()
const patientStore = usePatientStore()
const exerciseStore = useExerciseStore()

const patientId = String(route.params.id)
const activeTab = ref<'overview' | 'sessions' | 'progress' | 'notes' | 'plans'>('overview')
const isLoading = ref(true)
const loadError = ref('')
const isNoteModalOpen = ref(false)
const isSavingNote = ref(false)
const noteError = ref('')

const noteForm = reactive({
  note: '',
  sessionId: '',
})

const tabs = [
  { id: 'overview', label: 'Overview' },
  { id: 'sessions', label: 'Sessions' },
  { id: 'progress', label: 'Progress' },
  { id: 'notes', label: 'Clinical Notes' },
  { id: 'plans', label: 'Exercise Plans' },
] as const

const patient = computed(() => patientStore.selectedPatient)
const patientSessions = computed(() => patientStore.patientSessions)
const patientProgress = computed(() => patientStore.patientProgress)
const patientNotes = computed(() => patientStore.patientNotes)
const exercisePlans = computed(() => exerciseStore.exercisePlans)

const orderedProgress = computed(() => [...patientProgress.value].reverse())

const activePlanExercises = computed(() => {
  return exercisePlans.value
    .filter((plan) => (plan.status ?? 'active') === 'active')
    .flatMap((plan) =>
      plan.plan_exercises.map((entry) => ({
        duration_seconds: entry.duration_seconds ?? (entry.duration_minutes ?? 0) * 60,
        name: entry.exercise?.name || 'Exercise',
        planExerciseId: entry.id,
        planName: plan.name,
        planStatus: plan.status ?? 'active',
        reps: entry.reps ?? 0,
        rom_max_degrees: entry.rom_max_degrees,
        rom_min_degrees: entry.rom_min_degrees,
        sets: entry.sets ?? 0,
        special_instructions: entry.special_instructions,
      })),
    )
})

const romChartData = computed(() => ({
  labels: orderedProgress.value.map((metric) => formatShortDate(metric.date)),
  datasets: [
    {
      label: 'ROM Degrees',
      data: orderedProgress.value.map((metric) => metric.rom_degrees ?? 0),
      borderColor: '#2563eb',
      backgroundColor: 'rgba(37, 99, 235, 0.12)',
      tension: 0.3,
      fill: true,
    },
  ],
}))

const accuracyChartData = computed(() => {
  const recentSessions = [...patientSessions.value].slice(0, 6).reverse()
  return {
    labels: recentSessions.map((session) => formatShortDate(session.date)),
    datasets: [
      {
        label: 'Accuracy %',
        data: recentSessions.map((session) => Number(session.accuracy_percent ?? 0)),
        backgroundColor: '#14b8a6',
        borderRadius: 10,
      },
    ],
  }
})

const progressChartData = computed(() => ({
  labels: orderedProgress.value.map((metric) => formatShortDate(metric.date)),
  datasets: [
    {
      label: 'ROM',
      data: orderedProgress.value.map((metric) => metric.rom_degrees ?? 0),
      borderColor: '#2563eb',
      backgroundColor: 'rgba(37, 99, 235, 0.08)',
      tension: 0.3,
    },
    {
      label: 'Strength',
      data: orderedProgress.value.map((metric) => metric.strength_score ?? 0),
      borderColor: '#f97316',
      backgroundColor: 'rgba(249, 115, 22, 0.08)',
      tension: 0.3,
    },
    {
      label: 'Balance',
      data: orderedProgress.value.map((metric) => metric.balance_score ?? 0),
      borderColor: '#14b8a6',
      backgroundColor: 'rgba(20, 184, 166, 0.08)',
      tension: 0.3,
    },
  ],
}))

const lineChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom' as const,
    },
  },
}

const barChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom' as const,
    },
  },
  scales: {
    y: {
      min: 0,
      max: 100,
    },
  },
}

function getInitials(name: string) {
  return name
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

function formatStatus(value: string) {
  return value
    .split('_')
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(' ')
}

function formatDate(value?: string | null) {
  if (!value) {
    return 'N/A'
  }

  return new Date(value).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

function formatShortDate(value?: string | null) {
  if (!value) {
    return 'N/A'
  }

  return new Date(value).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  })
}

function formatDateTime(value?: string | null) {
  if (!value) {
    return 'N/A'
  }

  return new Date(value).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function formatDuration(totalSeconds: number) {
  if (!totalSeconds) {
    return '0 sec'
  }

  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60

  if (!minutes) {
    return `${seconds} sec`
  }

  if (!seconds) {
    return `${minutes} min`
  }

  return `${minutes} min ${seconds} sec`
}

function formatPercent(value?: number | string | null) {
  return `${Math.round(Number(value ?? 0))}%`
}

function formatDecimal(value?: number | string | null) {
  return Number(value ?? 0).toFixed(1)
}

function formatRom(min?: number | null, max?: number | null) {
  if (min == null && max == null) {
    return 'Not specified'
  }

  if (min != null && max != null) {
    return `${min} to ${max} deg`
  }

  if (min != null) {
    return `Min ${min} deg`
  }

  return `Max ${max} deg`
}

function orderedPlanExercises(planExercises: PlanExerciseWithExercise[]) {
  return [...planExercises].sort((left, right) => (left.order ?? 0) - (right.order ?? 0))
}

function openNoteModal() {
  noteError.value = ''
  isNoteModalOpen.value = true
}

function closeNoteModal() {
  if (!isSavingNote.value) {
    isNoteModalOpen.value = false
    noteForm.note = ''
    noteForm.sessionId = ''
    noteError.value = ''
  }
}

async function saveNote() {
  noteError.value = ''

  if (!noteForm.note.trim()) {
    noteError.value = 'Clinical note text is required.'
    return
  }

  isSavingNote.value = true

  try {
    const result = await patientStore.addNote(patientId, noteForm.note.trim(), noteForm.sessionId || null)

    if (!result.success) {
      throw new Error(result.error ?? 'Unable to save note.')
    }

    closeNoteModal()
  } catch (error: any) {
    noteError.value = error.message || 'Unable to save note.'
  } finally {
    isSavingNote.value = false
  }
}

async function loadPatientDetail() {
  isLoading.value = true
  loadError.value = ''

  try {
    const record = await patientStore.fetchPatientById(patientId)

    if (!record) {
      throw new Error(patientStore.error || 'Patient not found.')
    }

    await Promise.all([
      patientStore.fetchPatientSessions(patientId),
      patientStore.fetchPatientProgress(patientId),
      patientStore.fetchPatientNotes(patientId),
      exerciseStore.fetchPatientPlans(patientId),
    ])

    if (patientStore.error || exerciseStore.error) {
      throw new Error(patientStore.error || exerciseStore.error || 'Unable to load patient details.')
    }
  } catch (error: any) {
    loadError.value = error.message || 'Unable to load patient details.'
  } finally {
    isLoading.value = false
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

.page-header,
.header-actions,
.card-header,
.list-card-head,
.modal-header,
.modal-footer {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.header-actions {
  align-items: center;
}

.page-subtitle,
.profile-meta,
.card-copy,
.state-text,
.list-meta,
.log-meta,
.empty-card,
.list-copy {
  color: var(--text-muted);
  font-size: 14px;
}

.state-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: flex-start;
}

.state-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
}

.profile-header {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  gap: 20px;
  align-items: center;
}

.profile-avatar {
  width: 88px;
  height: 88px;
  border-radius: 24px;
  background: var(--gradient-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
}

.profile-copy {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.badge-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.stat-card {
  min-width: 120px;
  padding: 14px 16px;
  border-radius: 16px;
  background: var(--bg-hover);
}

.stat-label {
  color: var(--text-muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.stat-value {
  margin-top: 8px;
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 700;
}

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tab-button {
  height: 40px;
  padding: 0 16px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-secondary);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.tab-button--active {
  border-color: var(--primary);
  background: var(--primary-light);
  color: var(--primary);
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--gap);
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  margin-top: 18px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: 16px;
}

.detail-label {
  color: var(--text-muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.detail-value,
.list-title,
.log-title {
  color: var(--text-primary);
  font-size: 15px;
  font-weight: 700;
}

.chart-wrap {
  height: 280px;
  margin-top: 18px;
}

.chart-wrap--tall {
  height: 320px;
}

.list-stack,
.plan-list,
.log-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-top: 18px;
}

.list-card,
.session-card,
.plan-row,
.log-row {
  padding: 16px;
  border-radius: 18px;
  border: 1px solid var(--border);
  background: var(--bg-card);
}

.session-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.log-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(220px, 320px);
  gap: 14px;
  background: var(--bg-hover);
}

.log-note {
  color: var(--text-primary);
  font-size: 14px;
}

.metrics-table {
  display: flex;
  flex-direction: column;
  gap: 1px;
  margin-top: 18px;
  border: 1px solid var(--border);
  border-radius: 16px;
  overflow: hidden;
}

.metrics-row {
  display: grid;
  grid-template-columns: 1.3fr repeat(4, 1fr);
  gap: 12px;
  padding: 14px 16px;
  background: var(--bg-card);
}

.metrics-row--header {
  background: var(--bg-hover);
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.empty-card {
  margin-top: 18px;
  padding: 18px;
  border: 1px dashed var(--border);
  border-radius: 16px;
  text-align: center;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.form-input,
.form-textarea {
  width: 100%;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--bg-input);
  color: var(--text-primary);
  font: inherit;
}

.form-input {
  height: 44px;
  padding: 0 14px;
}

.form-textarea {
  padding: 12px 14px;
  resize: vertical;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-light);
}

.btn-primary,
.btn-secondary,
.icon-btn {
  height: 42px;
  padding: 0 18px;
  border-radius: 12px;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.btn-primary {
  border: none;
  background: var(--gradient-primary);
  color: white;
}

.btn-secondary {
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-primary);
}

.icon-btn {
  width: 42px;
  padding: 0;
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-primary);
}

.btn-primary:disabled,
.btn-secondary:disabled,
.icon-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.status-message {
  padding: 12px 14px;
  border-radius: 12px;
  font-size: 13px;
}

.status-message--error {
  background: rgba(239, 68, 68, 0.08);
  color: #b91c1c;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(6px);
}

.modal-card {
  width: min(640px, 100%);
  border-radius: 20px;
  border: 1px solid var(--border);
  background: var(--bg-card);
  box-shadow: var(--shadow-elevated);
}

.modal-header,
.modal-footer {
  padding: 20px 24px;
}

.modal-header {
  border-bottom: 1px solid var(--border);
}

.modal-footer {
  border-top: 1px solid var(--border);
  justify-content: flex-end;
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 24px;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

@media (max-width: 1080px) {
  .overview-grid,
  .profile-header,
  .stats-grid,
  .detail-grid,
  .log-row,
  .metrics-row {
    grid-template-columns: 1fr;
  }

  .profile-header {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
