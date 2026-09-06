<template>
  <AppModal
    :model-value="isOpen"
    class="dash-modal"
    title="Add New Therapist"
    :closable="!isSubmitting"
    @update:model-value="handleClose"
    @keydown.escape="handleClose"
  >
    <!-- Form -->
    <form v-if="!isSuccess" id="add-therapist-form" class="modal-body" @submit.prevent="handleSubmit">
            <div class="form-grid">
              <div class="form-group">
                <label class="input-label">Full Name <span class="required">*</span></label>
                <input
                  v-model="form.fullName"
                  type="text"
                  placeholder="Dr. Jane Smith"
                  :class="['input-field', { 'input-error': errors.fullName }]"
                />
                <p v-if="errors.fullName" class="error-message">{{ errors.fullName }}</p>
              </div>
              <div class="form-group">
                <label class="input-label">Email <span class="required">*</span></label>
                <input
                  v-model="form.email"
                  type="email"
                  placeholder="therapist@clinic.com"
                  :class="['input-field', { 'input-error': errors.email }]"
                />
                <p v-if="errors.email" class="error-message">{{ errors.email }}</p>
              </div>
            </div>

            <div class="form-grid">
              <div class="form-group">
                <label class="input-label">Clinic Name</label>
                <input
                  v-model="form.clinicName"
                  type="text"
                  placeholder="City Rehabilitation Center"
                  class="input-field"
                />
              </div>
              <div class="form-group">
                <label class="input-label">License Number</label>
                <input
                  v-model="form.licenseNumber"
                  type="text"
                  placeholder="PT-12345"
                  class="input-field"
                />
              </div>
            </div>

            <div class="form-group">
              <label class="input-label">Temporary Password <span class="required">*</span></label>
              <div class="password-wrap">
                <input
                  v-model="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  placeholder="Min. 8 characters"
                  :class="['input-field', { 'input-error': errors.password }]"
                  style="padding-right: var(--space-48px)"
                />
                <button type="button" class="eye-toggle" @click="showPassword = !showPassword">
                  <EyeOff v-if="showPassword" :size="18" />
                  <Eye v-else :size="18" />
                </button>
              </div>
              <p v-if="errors.password" class="error-message">{{ errors.password }}</p>
            </div>

            <div v-if="submitError" class="submit-error">{{ submitError }}</div>
          </form>

    <!-- Success State -->
    <div v-else class="modal-body success-body">
      <div class="success-icon-wrap">
        <CheckCircle :size="32" style="color: var(--success)" />
      </div>
      <h4 class="success-title">Therapist Created Successfully</h4>
      <p class="success-subtitle">Share these credentials with the therapist:</p>
      <div class="credentials-box">
        <div class="credential-row">
          <span class="credential-label">Email</span>
          <span class="credential-value">{{ successCredentials.email }}</span>
        </div>
        <div class="credential-row">
          <span class="credential-label">Password</span>
          <span class="credential-value">{{ successCredentials.password }}</span>
        </div>
      </div>
      <p class="success-note">
        The therapist can log in to the portal and change their password in Settings.
      </p>
    </div>

    <template #footer>
      <template v-if="!isSuccess">
        <AppButton variant="secondary" :disabled="isSubmitting" @click="handleClose">
          Cancel
        </AppButton>
        <AppButton type="submit" form="add-therapist-form" variant="primary" class="btn-icon-gap" :disabled="isSubmitting" @click="handleSubmit">
          <span v-if="isSubmitting" class="spinner-inline"></span>
          {{ isSubmitting ? 'Creating...' : 'Create Therapist' }}
        </AppButton>
      </template>
      <AppButton v-else variant="primary" @click="handleClose">Done</AppButton>
    </template>
  </AppModal>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { Eye, EyeOff, CheckCircle } from 'lucide-vue-next'
import { useAdminStore } from '@/stores/adminStore'
import AppModal from '@/components/shared/AppModal.vue'
import AppButton from '@/components/shared/AppButton.vue'

interface Props {
  isOpen: boolean
}

interface Emits {
  (e: 'close'): void
  (e: 'created'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const adminStore = useAdminStore()

const isSubmitting = ref(false)
const isSuccess = ref(false)
const showPassword = ref(false)
const submitError = ref('')

const form = reactive({
  fullName: '',
  email: '',
  clinicName: '',
  licenseNumber: '',
  password: '',
})

const errors = reactive({
  fullName: '',
  email: '',
  password: '',
})

const successCredentials = reactive({ email: '', password: '' })

watch(
  () => props.isOpen,
  (val) => {
    if (!val) resetForm()
  },
)

function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function validateForm(): boolean {
  let valid = true
  errors.fullName = ''
  errors.email = ''
  errors.password = ''

  if (!form.fullName.trim()) {
    errors.fullName = 'Full name is required'
    valid = false
  }
  if (!form.email.trim()) {
    errors.email = 'Email is required'
    valid = false
  } else if (!validateEmail(form.email)) {
    errors.email = 'Please enter a valid email address'
    valid = false
  }
  if (!form.password.trim()) {
    errors.password = 'Password is required'
    valid = false
  } else if (form.password.length < 8) {
    errors.password = 'Password must be at least 8 characters'
    valid = false
  }

  return valid
}

function resetForm() {
  form.fullName = ''
  form.email = ''
  form.clinicName = ''
  form.licenseNumber = ''
  form.password = ''
  errors.fullName = ''
  errors.email = ''
  errors.password = ''
  submitError.value = ''
  isSuccess.value = false
  showPassword.value = false
}

function handleClose() {
  if (!isSubmitting.value) emit('close')
}

async function handleSubmit() {
  if (!validateForm()) return

  isSubmitting.value = true
  submitError.value = ''

  try {
    const result = await adminStore.createTherapist({ ...form })
    if (!result.success) {
      submitError.value = result.error ?? 'Failed to create therapist'
      return
    }
    successCredentials.email = form.email
    successCredentials.password = form.password
    isSuccess.value = true
    emit('created')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<style scoped>
/* .modal-backdrop/.modal-card/.modal-header*/.modal-title-*/.close-btn*
   removed: AppModal now owns all of that chrome. .modal-body is kept
   but trimmed down to just the flex-column layout it still needs to
   provide for its own children (form-grid/form-group/etc.) -- padding,
   overflow-y, and flex:1 are now AppModal's own body wrapper's job.
   AppCard/AppModal hardcode bg-white/border-slate-200/text-slate-900
   with no dark-mode handling (same gap fixed in DashboardView.vue's
   .dash-card and AdminView.vue's .dash-modal). */
.dash-modal :deep(.bg-white) {
  background: var(--bg-card);
}
.dash-modal :deep(.border-slate-200) {
  border-color: var(--border);
}
.dash-modal :deep(.text-slate-900) {
  color: var(--text-primary);
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: var(--space-16px);
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-16px);
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-8px);
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

.input-field.input-error:focus {
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.15);
}

.password-wrap {
  position: relative;
}

.eye-toggle {
  position: absolute;
  right: var(--space-16px);
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: var(--space-half);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 150ms;
}

.eye-toggle:hover {
  color: var(--text-primary);
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

.success-body {
  align-items: center;
  text-align: center;
  padding: var(--space-32px) var(--space-24px);
}

.success-icon-wrap {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: rgba(16, 185, 129, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.success-title {
  font-size: var(--font-size-lg);
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
}

.success-subtitle {
  font-size: var(--font-size-sm);
  color: var(--text-muted);
  margin: 0;
}

.credentials-box {
  background: var(--bg-input);
  border-radius: 12px;
  padding: var(--space-16px) var(--space-24px);
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--space-8px);
}

.credential-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-16px);
}

.credential-label {
  font-size: var(--font-size-sm);
  color: var(--text-muted);
  font-weight: 500;
  flex-shrink: 0;
}

.credential-value {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--text-primary);
  word-break: break-all;
  text-align: right;
}

.success-note {
  font-size: var(--font-size-sm);
  color: var(--text-muted);
  line-height: 1.6;
  margin: 0;
}

/* .btn-secondary/.btn-primary removed: both already matched
   AppButton's own native secondary/primary variants exactly (unlike
   other files' bespoke ghost/outline looks), so Cancel/Create
   Therapist/Done now render through AppButton's native styling
   directly, no override needed. .btn-icon-gap replaces .btn-primary's
   gap: 8px for the spinner+label layout on the submit button. */
.btn-icon-gap {
  gap: var(--space-8px);
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

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (max-width: 600px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
