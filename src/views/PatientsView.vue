<template>
  <div class="page">
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
        <h1 class="h2">Patients</h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px;">Manage and monitor all your patients</p>
      </div>
      <div class="header-actions">
        <button class="btn-secondary" @click="showAddPatientModal = true">
          <UserPlus :size="16" />
          <span>Add Patient</span>
        </button>
        <button class="btn-primary" @click="router.push('/assign-exercise')">
          <Plus :size="16" />
          <span>Assign Exercise</span>
        </button>
      </div>
    </div>

    <!-- Content -->
    <BaseCard>
      <!-- Toolbar -->
      <div class="table-header">
        <h3 class="h3">Patient List</h3>
        <div class="table-controls">
          <div class="search-input">
            <Search :size="16" class="search-icon" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search by name or email..."
              @input="filterPatients"
            />
          </div>
          <select
            v-model="statusFilter"
            class="table-select"
            @change="filterPatients"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="needs_attention">Needs Attention</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredPatients.length === 0" class="empty-state-inline">
        <Users :size="48" style="color: var(--text-muted);" />
        <p style="color: var(--text-secondary); margin-top: var(--space-2);">No patients found</p>
      </div>

      <!-- Table -->
      <div v-else>
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
            <tr v-for="patient in paginatedPatients" :key="patient.id" @click="viewPatient(patient.id)">
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
              <td><BaseBadge :variant="getStatusVariant(patient.status)">{{ formatStatus(patient.status) }}</BaseBadge></td>
              <td>
                <button class="btn-ghost btn-sm" @click.stop="viewPatient(patient.id)">View</button>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="table-footer">
          <span class="caption" style="color: var(--text-secondary);">
            Showing {{ ((currentPage - 1) * perPage) + 1 }} to {{ Math.min(currentPage * perPage, filteredPatients.length) }} of {{ filteredPatients.length }} patients
          </span>
          <div class="pagination">
            <button 
              class="btn-ghost btn-sm" 
              :disabled="currentPage === 1" 
              @click="currentPage--"
            >
              Previous
            </button>
            <button 
              class="btn-ghost btn-sm" 
              :disabled="currentPage >= totalPages" 
              @click="currentPage++"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Search, Users, Plus, UserPlus } from 'lucide-vue-next'
import { usePatientStore } from '@/stores/patientStore'
import { useAuthStore } from '@/stores/authStore'
import { storeToRefs } from 'pinia'
import BaseCard from '@/components/shared/BaseCard.vue'
import BaseBadge from '@/components/shared/BaseBadge.vue'
import AdherenceBar from '@/components/shared/AdherenceBar.vue'
import AddPatientModal from '@/components/modals/AddPatientModal.vue'

const router = useRouter()
const route = useRoute()
const patientStore = usePatientStore()
const authStore = useAuthStore()

const { patients, isLoading } = storeToRefs(patientStore)

const showAddPatientModal = ref(false)
const searchQuery = ref((route.query.search as string) || '')
const statusFilter = ref((route.query.status as string) || 'all')
const currentPage = ref(1)
const perPage = 10

const filteredPatients = computed(() => {
  let result = patients.value

  if (statusFilter.value !== 'all') {
    result = result.filter((p) => p.status === statusFilter.value)
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(
      (p) =>
        p.name.toLowerCase().includes(query) ||
        p.email.toLowerCase().includes(query) ||
        p.condition.toLowerCase().includes(query),
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
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  })
}

const formatStatus = (status: string) => {
  return status.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')
}

const getStatusVariant = (status: string): 'active' | 'warning' | 'danger' | 'info' | 'neutral' => {
  if (status === 'active') return 'active'
  if (status === 'needs_attention') return 'warning'
  return 'neutral'
}

const viewPatient = (id: string) => {
  router.push(`/patients/${id}`)
}

const handlePatientAdded = async () => {
  // Refresh the patient list after adding a new patient
  await patientStore.fetchPatients()
  currentPage.value = 1 // Reset to first page
}

onMounted(async () => {
  await patientStore.fetchPatients()
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

.header-actions {
  display: flex;
  gap: var(--space-2);
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
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.btn-primary:hover {
  opacity: 0.9;
}

.btn-secondary {
  background: white;
  color: var(--primary);
  border: 1px solid var(--primary);
  cursor: pointer;
  height: 40px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.btn-secondary:hover {
  background: var(--primary-light);
}

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

.search-input {
  position: relative;
  width: 240px;
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

.loading-state {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state-inline {
  text-align: center;
  padding: var(--space-12) var(--space-4);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  text-align: left;
  font-size: 12px;
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
  font-size: 12px;
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
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.patient-email {
  font-size: 12px;
  color: var(--text-muted);
}

.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  cursor: pointer;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 13px;
  color: var(--primary);
  font-weight: 600;
  transition: background 0.15s, border-color 0.15s;
}

.btn-ghost:hover {
  background: var(--primary-light);
  border-color: var(--primary);
}

.btn-sm {
  height: 32px;
}

.btn-ghost:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
</style>
