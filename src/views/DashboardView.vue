<template>
  <div class="dashboard">
    <!-- Add Patient Modal -->
    <AddPatientModal
      :isOpen="showAddPatientModal"
      :therapistId="authStore.therapistProfile?.id || ''"
      @close="showAddPatientModal = false"
      @patientAdded="handlePatientAdded"
    />

    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2">Good {{ timeOfDay }}, {{ therapistName }} 👋</h1>
        <p style="color: var(--text-muted); font-size: var(--font-size-sm); margin-top: var(--space-half)">
          Here's what's happening with your patients today.
        </p>
      </div>
      <AppButton variant="primary" @click="showAddPatientModal = true">+ Add Patient</AppButton>
    </div>

    <!-- Stat Cards -->
    <div class="stats-grid">
      <StatCard
        :value="String(stats.totalPatients)"
        label="Total Patients"
        gradient="var(--gradient-primary)"
        :trend="{ text: '↑ 2 this month', positive: true }"
      >
        <template #icon>
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            width="24"
            height="24"
          >
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        :value="String(stats.sessionsToday)"
        label="Sessions Today"
        gradient="var(--gradient-success)"
        :trend="{ text: '— No change', positive: true }"
      >
        <template #icon>
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            width="24"
            height="24"
          >
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        :value="String(stats.pendingReviews)"
        label="Pending Reviews"
        gradient="var(--gradient-warning)"
        :trend="{ text: '↑ 1 this week', positive: false }"
      >
        <template #icon>
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            width="24"
            height="24"
          >
            <path d="M9 11l3 3L22 4" />
            <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        :value="String(unreadCount)"
        label="Unread Alerts"
        gradient="var(--gradient-danger)"
        :trend="{ text: '— No change', positive: true }"
      >
        <template #icon>
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            width="24"
            height="24"
          >
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
        </template>
      </StatCard>
    </div>

    <!-- Main Content -->
    <div class="dashboard-body">
      <!-- Patients Table (left, 2/3 width) -->
      <div class="dashboard-main">
        <AppCard class="dash-card">
          <div class="table-header">
            <h2 class="h3">Active Patients</h2>
            <div class="table-controls">
              <input
                v-model="searchQuery"
                type="search"
                class="table-search"
                placeholder="Search patients..."
                @input="filterPatients"
              />
              <select v-model="statusFilter" class="table-select" @change="filterPatients">
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="needs_attention">Needs Attention</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
          </div>
          <table class="data-table">
            <thead>
              <tr>
                <th>PATIENT</th>
                <th>CONDITION</th>
                <th>LAST SESSION</th>
                <th>ADHERENCE</th>
                <th>STATUS</th>
                <th>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="isLoading">
                <td
                  colspan="6"
                  style="text-align: center; padding: var(--space-8); color: var(--text-muted)"
                >
                  Loading patients...
                </td>
              </tr>
              <tr v-else-if="paginatedPatients.length === 0">
                <td
                  colspan="6"
                  style="text-align: center; padding: var(--space-8); color: var(--text-muted)"
                >
                  No patients found
                </td>
              </tr>
              <tr
                v-else
                v-for="patient in paginatedPatients"
                :key="patient.id"
                @click="viewPatient(patient.id)"
              >
                <td>
                  <div class="patient-cell">
                    <div v-if="patient.avatar_url" class="patient-avatar-img">
                      <img :src="patient.avatar_url" :alt="patient.name" />
                    </div>
                    <div v-else class="patient-avatar">{{ getInitials(patient.name) }}</div>
                    <div>
                      <div class="patient-name">{{ patient.name }}</div>
                      <div class="patient-email">{{ patient.email }}</div>
                    </div>
                  </div>
                </td>
                <td>{{ patient.condition }}</td>
                <td style="color: var(--text-muted)">{{ formatDate(patient.last_session) }}</td>
                <td><AdherenceBar :value="patient.adherence_rate" /></td>
                <td>
                  <AppBadge :variant="getStatusVariant(patient.status)">{{
                    formatStatus(patient.status)
                  }}</AppBadge>
                </td>
                <td>
                  <AppButton variant="secondary" class="btn-ghost" @click.stop="viewPatient(patient.id)">View</AppButton>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-if="totalPages > 1" class="table-footer">
            <span class="caption" style="color: var(--text-secondary)">
              Showing {{ (currentPage - 1) * perPage + 1 }} to
              {{ Math.min(currentPage * perPage, filteredPatients.length) }} of
              {{ filteredPatients.length }} patients
            </span>
            <div class="pagination">
              <AppButton variant="secondary" class="btn-ghost" :disabled="currentPage === 1" @click="currentPage--">
                Previous
              </AppButton>
              <AppButton
                variant="secondary"
                class="btn-ghost"
                :disabled="currentPage >= totalPages"
                @click="currentPage++"
              >
                Next
              </AppButton>
            </div>
          </div>
        </AppCard>
      </div>

      <!-- Right Panel (1/3 width) -->
      <div class="dashboard-aside">
        <!-- Quick Actions -->
        <AppCard class="dash-card">
          <h3 class="h4" style="margin-bottom: var(--space-3)">Quick Actions</h3>
          <div class="quick-actions">
            <AppButton variant="secondary" class="quick-action-btn" @click="addPatient">+ Add New Patient</AppButton>
            <AppButton variant="secondary" class="quick-action-btn" @click="$router.push('/assign-exercise')">
              📋 Assign Exercise
            </AppButton>
            <AppButton variant="secondary" class="quick-action-btn" @click="$router.push('/reports')">
              📊 Generate Report
            </AppButton>
            <AppButton variant="secondary" class="quick-action-btn" @click="$router.push('/alerts')">
              🔔 View Alerts
            </AppButton>
          </div>
        </AppCard>

        <!-- Recent Alerts -->
        <AppCard class="dash-card">
          <div class="card-row-header">
            <h3 class="h4">Recent Alerts</h3>
            <RouterLink to="/alerts" class="text-link">View All</RouterLink>
          </div>
          <div class="alert-list">
            <div
              v-if="recentAlerts.length === 0"
              style="
                text-align: center;
                padding: var(--space-4);
                color: var(--text-muted);
                font-size: var(--font-size-sm);
              "
            >
              No recent alerts
            </div>
            <div
              v-else
              v-for="alert in recentAlerts"
              :key="alert.id"
              class="alert-row"
              :style="{ borderLeftColor: alert.color }"
            >
              <div class="alert-text">{{ alert.text }}</div>
              <div class="alert-sub">{{ alert.patient }} · {{ alert.time }}</div>
            </div>
          </div>
        </AppCard>

        <!-- Today's Sessions -->
        <AppCard class="dash-card">
          <h3 class="h4" style="margin-bottom: var(--space-3)">Today's Sessions</h3>
          <div class="session-list">
            <div
              v-if="todaySessions.length === 0"
              style="
                text-align: center;
                padding: var(--space-4);
                color: var(--text-muted);
                font-size: var(--font-size-sm);
              "
            >
              No sessions scheduled
            </div>
            <div v-else v-for="session in todaySessions" :key="session.id" class="session-row">
              <div class="session-avatar">{{ session.initials }}</div>
              <div class="session-info">
                <div class="session-name">{{ session.name }}</div>
                <div class="session-time">{{ session.time }}</div>
              </div>
              <span class="session-dot" :class="{ 'dot--active': session.active }"></span>
            </div>
          </div>
        </AppCard>

        <!-- Adherence Overview -->
        <AppCard class="dash-card">
          <h3 class="h4" style="margin-bottom: var(--space-3)">Patient Adherence Overview</h3>
          <div class="adherence-stats">
            <div class="adherence-stat-row">
              <span class="caption" style="color: var(--text-secondary)"
                >High Adherence (≥75%)</span
              >
              <AppBadge variant="success">{{ adherenceStats.high }}</AppBadge>
            </div>
            <div class="adherence-stat-row">
              <span class="caption" style="color: var(--text-secondary)">Moderate (50-74%)</span>
              <AppBadge variant="warning">{{ adherenceStats.moderate }}</AppBadge>
            </div>
            <div class="adherence-stat-row">
              <span class="caption" style="color: var(--text-secondary)">Low Adherence (<50%)</span>
              <AppBadge variant="error">{{ adherenceStats.low }}</AppBadge>
            </div>
          </div>
        </AppCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/services/supabase'
import { useAuthStore } from '@/stores/authStore'
import { usePatientStore } from '@/stores/patientStore'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'
import AppCard from '@/components/shared/AppCard.vue'
import AppBadge from '@/components/shared/AppBadge.vue'
import AppButton from '@/components/shared/AppButton.vue'
import AdherenceBar from '@/components/shared/AdherenceBar.vue'
import StatCard from '@/components/shared/StatCard.vue'
import AddPatientModal from '@/components/modals/AddPatientModal.vue'

const router = useRouter()
const authStore = useAuthStore()
const patientStore = usePatientStore()
const alertStore = useAlertStore()

const { therapistProfile } = storeToRefs(authStore)
const { patients, isLoading } = storeToRefs(patientStore)
const { alerts, unreadCount } = storeToRefs(alertStore)

const sessionsTodayCount = ref(0)
const showAddPatientModal = ref(false)
const searchQuery = ref('')
const statusFilter = ref('all')
const currentPage = ref(1)
const perPage = 8

const timeOfDay = computed(() => {
  const hour = new Date().getHours()
  if (hour < 12) return 'morning'
  if (hour < 18) return 'afternoon'
  return 'evening'
})

const therapistName = computed(() => {
  const fullName = therapistProfile.value?.name || 'Dr. Test'
  const parts = fullName.split(' ')
  return parts.length > 1 ? parts[parts.length - 1] : parts[0]
})

const stats = computed(() => {
  const totalPatients = patients.value.length
  const pendingReviews = patients.value.filter((p) => p.status === 'needs_attention').length

  return {
    totalPatients,
    sessionsToday: sessionsTodayCount.value,
    pendingReviews,
  }
})

const recentAlerts = computed(() => {
  return alerts.value
    .filter((a) => !a.resolved)
    .slice(0, 3)
    .map((alert) => ({
      id: alert.id,
      text: alert.message,
      patient: alert.patient?.name || 'Unknown',
      time: formatTimestamp(alert.created_at),
      color:
        alert.priority === 'high' ? 'var(--error)' : alert.priority === 'medium' ? 'var(--warning)' : 'var(--info)',
    }))
})

const todaySessions = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return patients.value
    .filter((p) => p.last_session && new Date(p.last_session).toISOString().split('T')[0] === today)
    .slice(0, 4)
    .map((p) => ({
      id: p.id,
      name: p.name,
      initials: getInitials(p.name),
      time: '9:00 AM',
      active: true,
    }))
})

const adherenceStats = computed(() => {
  const high = patients.value.filter((p) => p.adherence_rate >= 75).length
  const moderate = patients.value.filter(
    (p) => p.adherence_rate >= 50 && p.adherence_rate < 75,
  ).length
  const low = patients.value.filter((p) => p.adherence_rate < 50).length

  return { high, moderate, low }
})

const filteredPatients = computed(() => {
  let result = patients.value

  if (statusFilter.value !== 'all') {
    result = result.filter((p) => p.status === statusFilter.value)
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(
      (p) => p.name.toLowerCase().includes(query) || p.email.toLowerCase().includes(query),
    )
  }

  return result
})

const totalPages = computed(() => Math.ceil(filteredPatients.value.length / perPage))

const paginatedPatients = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredPatients.value.slice(start, start + perPage)
})

const filterPatients = () => {
  currentPage.value = 1
}

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

const formatDate = (date?: string) => {
  if (!date) return 'No sessions'
  return new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const formatTimestamp = (timestamp: string) => {
  const date = new Date(timestamp)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffHours < 1) return 'Just now'
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const formatStatus = (status: string) => {
  return status
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}

const getStatusVariant = (status: string): 'success' | 'warning' | 'error' | 'info' | 'neutral' => {
  if (status === 'active') return 'success'
  if (status === 'needs_attention') return 'warning'
  return 'neutral'
}

const viewPatient = (id: string) => {
  router.push(`/patients/${id}`)
}

const handlePatientAdded = async () => {
  // Refresh the patient list and alerts after adding a new patient
  await patientStore.fetchPatients()
  await alertStore.fetchAlerts({ resolved: false })
}

onMounted(async () => {
  await patientStore.fetchPatients()
  await alertStore.fetchAlerts({ resolved: false })

  const patientIds = patients.value.map((p) => p.id)
  if (patientIds.length > 0) {
    const todayStart = new Date()
    todayStart.setHours(0, 0, 0, 0)
    const { count } = await supabase
      .from('sessions')
      .select('id', { count: 'exact', head: true })
      .in('patient_id', patientIds)
      .gte('started_at', todayStart.toISOString())
    sessionsTodayCount.value = count ?? 0
  }
})
</script>

<style scoped>
/* AppCard's own template hardcodes bg-white/border-slate-200/shadow-md
   (Tailwind utilities, no dark-mode handling at all -- unlike the
   var(--bg-card) etc. system every other surface in this file uses).
   Overriding just those three properties keeps AppCard's own padding/
   radius/hover behavior intact while correcting the one real
   functional regression (cards staying white in dark mode); scoped
   attribute selector specificity beats the plain utility classes. */
.dash-card {
  background: var(--bg-card);
  border-color: var(--border);
  box-shadow: var(--shadow-card);
}

.dashboard {
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
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--gap);
}
.dashboard-body {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: var(--gap);
  align-items: start;
}
.dashboard-main {
  min-width: 0;
}
.dashboard-aside {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

/* Table */
.table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-4);
}
.table-controls {
  display: flex;
  gap: var(--space-2);
}
.table-search,
.table-select {
  height: 36px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 0 var(--space-3);
  font: inherit;
  font-size: var(--font-size-sm);
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
}
.table-search {
  width: 180px;
}
.table-search:focus,
.table-select:focus {
  border-color: var(--border-focus);
}
.data-table {
  width: 100%;
  border-collapse: collapse;
}
.data-table th {
  text-align: left;
  font-size: var(--font-size-xs);
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-muted);
  padding: var(--space-2) var(--space-4);
  background: var(--bg-hover);
  border-bottom: 1px solid var(--border);
}
.data-table td {
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--border);
  vertical-align: middle;
}
.data-table tbody tr {
  transition: background 0.12s;
  cursor: pointer;
}
.data-table tbody tr:hover {
  background: var(--bg-table-row-hover);
}
.data-table tbody tr:last-child td {
  border-bottom: none;
}
.patient-cell {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}
.patient-avatar {
  width: 34px;
  height: 34px;
  border-radius: var(--radius-pill);
  background: var(--gradient-primary);
  color: white;
  font-size: var(--font-size-xs);
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.patient-avatar-img {
  width: 34px;
  height: 34px;
  border-radius: var(--radius-pill);
  overflow: hidden;
  flex-shrink: 0;
}
.patient-avatar-img img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.patient-name {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--text-primary);
}
.patient-email {
  font-size: var(--font-size-xs);
  color: var(--text-muted);
}
.table-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: var(--space-4);
  margin-top: var(--space-4);
  border-top: 1px solid var(--border);
}
.pagination {
  display: flex;
  gap: var(--space-2);
}

/* Buttons */
/* .btn-primary removed: the header "+ Add Patient" button now renders
   via AppButton's own native primary variant (already token-driven,
   see AppButton.vue), so this hand-rolled rule had no remaining
   consumer. .btn-ghost/.quick-action-btn are kept: AppButton has no
   variant matching either bespoke look, so both still apply their
   full original styling on top of <AppButton variant="secondary">
   via the class passthrough below, overriding its default look. */
.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  cursor: pointer;
  height: 32px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: var(--font-size-sm);
  color: var(--primary);
  font-weight: 600;
  transition:
    background 0.15s,
    border-color 0.15s;
}
.btn-ghost:hover {
  background: var(--primary-light);
  border-color: var(--primary);
}
.btn-ghost:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Quick Actions */
.quick-actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.quick-action-btn {
  width: 100%;
  height: 40px;
  text-align: left;
  background: var(--primary-light);
  color: var(--primary);
  border: none;
  cursor: pointer;
  border-radius: var(--radius-sm);
  padding: 0 var(--space-4);
  font: inherit;
  font-size: var(--font-size-sm);
  font-weight: 600;
  transition:
    background 0.15s,
    color 0.15s;
}
.quick-action-btn:hover {
  background: var(--gradient-primary);
  color: white;
}

/* Alerts */
.card-row-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-3);
}
.text-link {
  font-size: var(--font-size-sm);
  color: var(--text-link);
  font-weight: 500;
  text-decoration: none;
}
.text-link:hover {
  text-decoration: underline;
}
.alert-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.alert-row {
  border-left: 3px solid;
  padding: var(--space-2) var(--space-3);
  border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
  background: var(--bg-hover);
}
.alert-text {
  font-size: var(--font-size-sm);
  font-weight: 500;
  color: var(--text-primary);
}
.alert-sub {
  font-size: var(--font-size-xs);
  color: var(--text-muted);
  margin-top: var(--space-half);
}

/* Sessions */
.session-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.session-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2) 0;
}
.session-avatar {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-pill);
  background: var(--gradient-primary);
  color: white;
  font-size: var(--font-size-xs);
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.session-name {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--text-primary);
}
.session-time {
  font-size: var(--font-size-xs);
  color: var(--text-muted);
}
.session-info {
  flex: 1;
}
.session-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--border);
}
.dot--active {
  background: var(--success);
}

/* Adherence Stats */
.adherence-stats {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.adherence-stat-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
