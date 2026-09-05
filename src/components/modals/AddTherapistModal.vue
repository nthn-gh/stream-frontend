<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="isOpen"
        class="modal-backdrop"
        @click.self="handleClose"
        @keydown.escape="handleClose"
      >
        <div
          class="modal-card"
          role="dialog"
          aria-modal="true"
          aria-labelledby="add-therapist-title"
        >
          <!-- Header -->
          <div class="modal-header">
            <div class="modal-header-inner">
              <div class="modal-title-group">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--text-primary); flex-shrink: 0">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                  <polyline points="9 12 11 14 15 10"/>
                </svg>
                <h3 id="add-therapist-title" class="modal-title-text">Add New Therapist</h3>
              </div>
              <button
                type="button"
                class="close-btn"
                :disabled="isSubmitting"
                aria-label="Close modal"
                @click="handleClose"
              >
                <X :size="20" />
              </button>
            </div>
          </div>

          <!-- Form -->
          <form v-if="!isSuccess" class="modal-body" @submit.prevent="handleSubmit">
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
                  style="padding-right: 44px"
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
              <CheckCircle :size="32" style="color: #10b981" />
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

          <!-- Footer -->
          <div class="modal-footer">
            <template v-if="!isSuccess">
              <button type="button" class="btn-secondary" :disabled="isSubmitting" @click="handleClose">
                Cancel
              </button>
              <button type="submit" class="btn-primary" :disabled="isSubmitting" @click="handleSubmit">
                <span v-if="isSubmitting" class="spinner-inline"></span>
                {{ isSubmitting ? 'Creating...' : 'Create Therapist' }}
              </button>
            </template>
            <button v-else type="button" class="btn-primary" @click="handleClose">Done</button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { X, Eye, EyeOff, CheckCircle } from 'lucide-vue-next'
import { useAdminStore } from '@/stores/adminStore'

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
.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(4px);
}

.modal-card {
  background: var(--bg-card);
  box-shadow: var(--shadow-elevated);
  border-radius: 20px;
  width: 100%;
  max-width: 580px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 20px 24px 16px;
  border-bottom: 1px solid var(--border);
  flex-shrink: 0;
}

.modal-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.modal-title-text {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
}

.close-btn {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 150ms, color 150ms;
}

.close-btn:hover:not(:disabled) {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.close-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-footer {
  padding: 16px 24px 20px;
  border-top: 1px solid var(--border);
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  flex-shrink: 0;
}

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
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.required {
  color: #ef4444;
}

.input-field {
  width: 100%;
  height: 48px;
  padding: 0 16px;
  font-size: 15px;
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
  border-color: #ef4444;
}

.input-field.input-error:focus {
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.15);
}

.password-wrap {
  position: relative;
}

.eye-toggle {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 150ms;
}

.eye-toggle:hover {
  color: var(--text-primary);
}

.error-message {
  font-size: 12px;
  color: #991b1b;
  margin: 0;
}

.submit-error {
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  color: #dc2626;
}

.success-body {
  align-items: center;
  text-align: center;
  padding: 32px 24px;
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
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
}

.success-subtitle {
  font-size: 14px;
  color: var(--text-muted);
  margin: 0;
}

.credentials-box {
  background: var(--bg-input);
  border-radius: 12px;
  padding: 16px 20px;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.credential-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.credential-label {
  font-size: 13px;
  color: var(--text-muted);
  font-weight: 500;
  flex-shrink: 0;
}

.credential-value {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  word-break: break-all;
  text-align: right;
}

.success-note {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.6;
  margin: 0;
}

.btn-secondary {
  height: 44px;
  padding: 0 24px;
  font-size: 15px;
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

.btn-primary {
  height: 44px;
  padding: 0 24px;
  font-size: 15px;
  font-weight: 600;
  color: #ffffff;
  background: var(--primary);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 150ms;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-family: inherit;
}

.btn-primary:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-primary:disabled {
  background: var(--text-muted);
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

@keyframes spin {
  to { transform: rotate(360deg); }
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.96);
}

.modal-enter-active {
  transition: opacity 200ms ease, transform 300ms ease;
}

.modal-leave-active {
  transition: opacity 150ms ease, transform 200ms ease;
}

@media (max-width: 600px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
