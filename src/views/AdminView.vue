<template>
  <div class="page">
    <!-- Add Therapist Modal -->
    <AddTherapistModal
      :isOpen="showAddModal"
      @close="showAddModal = false"
      @created="handleTherapistCreated"
    />

    <!-- Edit Therapist Modal -->
    <AppModal
      v-model="showEditModal"
      class="dash-modal"
      title="Edit Therapist"
      :closable="!isEditing"
    >
      <div class="form-grid">
        <div class="form-group">
          <label class="input-label">Full Name <span class="required">*</span></label>
          <input v-model="editForm.name" type="text" placeholder="Dr. Jane Smith" :class="['input-field', { 'input-error': editErrors.name }]" />
          <p v-if="editErrors.name" class="error-message">{{ editErrors.name }}</p>
        </div>
        <div class="form-group">
          <label class="input-label">Email</label>
          <input v-model="editForm.email" type="email" placeholder="therapist@clinic.com" :class="['input-field', { 'input-error': editErrors.email }]" />
          <p v-if="editErrors.email" class="error-message">{{ editErrors.email }}</p>
        </div>
      </div>
      <div class="form-grid">
        <div class="form-group">
          <label class="input-label">Clinic Name</label>
          <input v-model="editForm.clinicName" type="text" placeholder="City Rehab Center" class="input-field" />
        </div>
        <div class="form-group">
          <label class="input-label">License Number</label>
          <input v-model="editForm.licenseNumber" type="text" placeholder="PT-12345" class="input-field" />
        </div>
      </div>
      <div v-if="editError" class="submit-error">{{ editError }}</div>
      <template #footer>
        <AppButton variant="secondary" class="btn-secondary" :disabled="isEditing" @click="closeEditModal">Cancel</AppButton>
        <AppButton variant="primary" :disabled="isEditing" @click="handleEditSubmit">
          <span v-if="isEditing" class="spinner-inline"></span>
          {{ isEditing ? 'Saving...' : 'Save Changes' }}
        </AppButton>
      </template>
    </AppModal>

    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2">Admin Panel</h1>
        <p style="color: var(--text-muted); font-size: var(--font-size-sm); margin-top: var(--space-half);">Manage therapists and monitor platform activity</p>
      </div>
      <div class="header-actions">
        <AppButton variant="primary" class="btn-icon-gap" @click="showAddModal = true">
          <UserPlus :size="16" />
          <span>Add Therapist</span>
        </AppButton>
      </div>
    </div>

    <!-- Stats Bar -->
    <div class="stats-grid">
      <StatCard
        :value="String(adminStore.stats.totalTherapists)"
        label="Total Therapists"
        gradient="var(--gradient-primary)"
      >
        <template #icon>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
          </svg>
        </template>
      </StatCard>

      <StatCard
        :value="String(adminStore.stats.totalPatients)"
        label="Total Patients"
        gradient="linear-gradient(135deg, var(--purple), var(--purple-dark))"
      >
        <template #icon>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
        </template>
      </StatCard>

      <StatCard
        :value="String(adminStore.stats.totalActiveSessions)"
        label="Active Sessions"
        gradient="var(--gradient-success)"
      >
        <template #icon>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
          </svg>
        </template>
      </StatCard>
    </div>

    <!-- Therapist Table -->
    <AppCard class="dash-card">
      <div class="table-header">
        <h3 class="h3">Therapist Management</h3>
        <div class="table-controls">
          <div class="search-input">
            <Search :size="16" class="search-icon" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search by name or email..."
            />
          </div>
          <select v-model="statusFilter" class="table-select">
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="adminStore.isLoading" class="loading-state">
        <div class="spinner"></div>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredTherapists.length === 0" class="empty-state-inline">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: var(--text-muted)">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
        </svg>
        <p style="color: var(--text-secondary); margin-top: var(--space-2)">No therapists found</p>
      </div>

      <!-- Table -->
      <div v-else>
        <table class="data-table">
          <thead>
            <tr>
              <th>THERAPIST</th>
              <th>CLINIC</th>
              <th>LICENSE</th>
              <th>STATUS</th>
              <th>ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="therapist in paginatedTherapists" :key="therapist.id">
              <td>
                <div class="therapist-cell">
                  <div class="therapist-avatar">{{ getInitials(therapist.name) }}</div>
                  <div>
                    <div class="therapist-name">{{ therapist.name }}</div>
                    <div class="therapist-email">{{ therapist.email }}</div>
                  </div>
                </div>
              </td>
              <td style="color: var(--text-secondary)">{{ therapist.clinic_name || '—' }}</td>
              <td style="color: var(--text-secondary)">{{ therapist.license_number || '—' }}</td>
              <td>
                <AppBadge :variant="therapist.is_active ? 'success' : 'neutral'">
                  {{ therapist.is_active ? 'Active' : 'Inactive' }}
                </AppBadge>
              </td>
              <td>
                <div class="action-buttons">
                  <AppButton variant="secondary" class="btn-ghost btn-sm" @click.stop="openEditModal(therapist)">Edit</AppButton>
                  <AppButton
                    v-if="therapist.is_active"
                    variant="secondary"
                    class="btn-danger btn-sm"
                    :disabled="adminStore.isLoading"
                    @click.stop="handleDeactivate(therapist)"
                  >
                    Deactivate
                  </AppButton>
                  <AppButton
                    v-else
                    variant="secondary"
                    class="btn-reactivate btn-sm"
                    :disabled="adminStore.isLoading"
                    @click.stop="handleReactivate(therapist)"
                  >
                    Reactivate
                  </AppButton>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="table-footer">
          <span class="caption" style="color: var(--text-secondary)">
            Showing {{ (currentPage - 1) * perPage + 1 }} to {{ Math.min(currentPage * perPage, filteredTherapists.length) }} of {{ filteredTherapists.length }} therapists
          </span>
          <div class="pagination">
            <AppButton variant="secondary" class="btn-ghost btn-sm" :disabled="currentPage === 1" @click="currentPage--">Previous</AppButton>
            <AppButton variant="secondary" class="btn-ghost btn-sm" :disabled="currentPage >= totalPages" @click="currentPage++">Next</AppButton>
          </div>
        </div>
      </div>
    </AppCard>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { Search, UserPlus } from 'lucide-vue-next'
import { useAdminStore } from '@/stores/adminStore'
import type { TherapistWithUser } from '@/stores/adminStore'
import AppCard from '@/components/shared/AppCard.vue'
import AppBadge from '@/components/shared/AppBadge.vue'
import AppButton from '@/components/shared/AppButton.vue'
import AppModal from '@/components/shared/AppModal.vue'
import StatCard from '@/components/shared/StatCard.vue'
import AddTherapistModal from '@/components/modals/AddTherapistModal.vue'

const adminStore = useAdminStore()

const showAddModal = ref(false)
const showEditModal = ref(false)
const editTarget = ref<TherapistWithUser | null>(null)
const isEditing = ref(false)
const editError = ref('')

const searchQuery = ref('')
const statusFilter = ref('all')
const currentPage = ref(1)
const perPage = 10

const editForm = reactive({
  name: '',
  email: '',
  clinicName: '',
  licenseNumber: '',
})

const editErrors = reactive({
  name: '',
  email: '',
})

const filteredTherapists = computed(() => {
  let result = adminStore.therapists

  if (statusFilter.value === 'active') {
    result = result.filter((t) => t.is_active)
  } else if (statusFilter.value === 'inactive') {
    result = result.filter((t) => !t.is_active)
  }

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.email.toLowerCase().includes(q) ||
        (t.clinic_name ?? '').toLowerCase().includes(q),
    )
  }

  return result
})

const totalPages = computed(() => Math.ceil(filteredTherapists.value.length / perPage))

const paginatedTherapists = computed(() => {
  const start = (currentPage.value - 1) * perPage
  return filteredTherapists.value.slice(start, start + perPage)
})

function getInitials(name: string) {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

function openEditModal(therapist: TherapistWithUser) {
  editTarget.value = therapist
  editForm.name = therapist.name
  editForm.email = therapist.email
  editForm.clinicName = therapist.clinic_name ?? ''
  editForm.licenseNumber = therapist.license_number ?? ''
  editErrors.name = ''
  editErrors.email = ''
  editError.value = ''
  showEditModal.value = true
}

function closeEditModal() {
  if (!isEditing.value) {
    showEditModal.value = false
    editTarget.value = null
  }
}

function validateEditForm(): boolean {
  let valid = true
  editErrors.name = ''
  editErrors.email = ''

  if (!editForm.name.trim()) {
    editErrors.name = 'Full name is required'
    valid = false
  }
  if (editForm.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(editForm.email)) {
    editErrors.email = 'Please enter a valid email address'
    valid = false
  }

  return valid
}

async function handleEditSubmit() {
  if (!editTarget.value || !validateEditForm()) return

  isEditing.value = true
  editError.value = ''

  try {
    const result = await adminStore.updateTherapist(editTarget.value.id, {
      name: editForm.name,
      email: editForm.email,
      clinicName: editForm.clinicName,
      licenseNumber: editForm.licenseNumber,
    })

    if (!result.success) {
      editError.value = result.error ?? 'Failed to update therapist'
      return
    }

    showEditModal.value = false
    editTarget.value = null
  } finally {
    isEditing.value = false
  }
}

async function handleDeactivate(therapist: TherapistWithUser) {
  if (!confirm(`Deactivate ${therapist.name}? They will no longer be able to log in.`)) return
  await adminStore.deactivateTherapist(therapist.id)
}

async function handleReactivate(therapist: TherapistWithUser) {
  await adminStore.reactivateTherapist(therapist.id)
}

async function handleTherapistCreated() {
  await adminStore.fetchStats()
}

onMounted(async () => {
  await Promise.all([adminStore.fetchTherapists(), adminStore.fetchStats()])
})
</script>

<style scoped>
/* AppCard/AppModal both hardcode bg-white/border-slate-200 with no
   dark-mode handling (same gap as DashboardView.vue's .dash-card) --
   overriding just background/border/shadow, leaving their own
   padding/radius/hover behavior as the family's native sizing. */
.dash-card {
  background: var(--bg-card);
  border-color: var(--border);
  box-shadow: var(--shadow-card);
}
.dash-modal :deep(.bg-white) {
  background: var(--bg-card);
}
.dash-modal :deep(.border-slate-200) {
  border-color: var(--border);
}
.dash-modal :deep(.text-slate-900) {
  color: var(--text-primary);
}

.btn-icon-gap {
  gap: var(--space-2);
}

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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--gap);
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
  font-size: var(--font-size-sm);
  outline: none;
  font-family: inherit;
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
  font-size: var(--font-size-sm);
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
  min-height: 300px;
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
}

.data-table tbody tr:hover {
  background: var(--bg-table-row-hover);
}

.data-table tbody tr:last-child td {
  border-bottom: none;
}

.therapist-cell {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.therapist-avatar {
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

.therapist-name {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--text-primary);
}

.therapist-email {
  font-size: var(--font-size-xs);
  color: var(--text-muted);
}

.action-buttons {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  cursor: pointer;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: var(--font-size-sm);
  color: var(--primary);
  font-weight: 600;
  transition: background 0.15s, border-color 0.15s;
}

.btn-ghost:hover:not(:disabled) {
  background: var(--primary-light);
  border-color: var(--primary);
}

.btn-danger {
  background: none;
  border: 1px solid var(--error);
  cursor: pointer;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: var(--font-size-sm);
  color: var(--error);
  font-weight: 600;
  transition: background 0.15s;
}

.btn-danger:hover:not(:disabled) {
  background: var(--status-danger-bg);
}

.btn-reactivate {
  background: none;
  border: 1px solid var(--success);
  cursor: pointer;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: var(--font-size-sm);
  color: var(--success);
  font-weight: 600;
  transition: background 0.15s;
}

.btn-reactivate:hover:not(:disabled) {
  background: rgba(16, 185, 129, 0.08);
}

.btn-sm {
  height: 32px;
}

.btn-ghost:disabled,
.btn-danger:disabled,
.btn-reactivate:disabled {
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

/* Edit Modal shared styles -- backdrop/card/header/close-button/body/
   footer chrome removed: AppModal now owns all of that (see .dash-modal
   override above for its dark-mode fix). What's left below is just the
   form content rendered inside AppModal's default/footer slots. */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.input-label {
  font-size: var(--font-size-sm);
  font-weight: 500;
  color: var(--text-primary);
}

.required {
  color: var(--error);
}

.input-field {
  width: 100%;
  height: 48px;
  padding: 0 16px;
  font-size: var(--font-size-base);
  color: var(--text-primary);
  background: var(--bg-input);
  border: 2px solid transparent;
  border-radius: 12px;
  outline: none;
  transition: all 150ms;
  font-family: inherit;
  box-sizing: border-box;
}

.input-field::placeholder {
  color: var(--text-muted);
}

.input-field:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-light);
}

.input-field.input-error {
  border-color: var(--error);
}

.error-message {
  font-size: var(--font-size-xs);
  color: var(--status-danger-text);
  margin: 0;
}

.submit-error {
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 10px;
  padding: var(--space-8px) var(--space-16px);
  font-size: var(--font-size-sm);
  color: var(--status-danger-text);
}

.btn-secondary {
  height: 44px;
  padding: 0 24px;
  font-size: var(--font-size-base);
  font-weight: 600;
  color: var(--text-primary);
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 12px;
  cursor: pointer;
  transition: all 150ms;
  font-family: inherit;
}

.btn-secondary:hover:not(:disabled) {
  background: var(--bg-hover);
  border-color: var(--text-muted);
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.spinner-inline {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  flex-shrink: 0;
}

@media (max-width: 900px) {
  .stats-grid {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 600px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
