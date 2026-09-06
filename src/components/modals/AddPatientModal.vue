<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-[1000] flex items-center justify-center p-6"
        style="background: rgba(0, 0, 0, 0.4); backdrop-filter: blur(4px)"
        @click.self="handleClose"
        @keydown.escape="handleClose"
      >
        <div
          v-if="isOpen"
          class="modal-card w-full max-w-[600px] max-h-[90vh] flex flex-col"
          style="border-radius: 20px"
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-title"
        >
          <!-- Header -->
          <div class="modal-header" style="padding: 20px 24px 16px">
            <div class="flex items-center justify-between">
              <div class="flex items-center" style="gap: 10px">
                <UserPlus :size="22" style="color: var(--text-primary)" />
                <h3 id="modal-title" style="font-size: 20px; font-weight: 700; color: var(--text-primary)">
                  Add New Patient
                </h3>
              </div>
              <button
                type="button"
                @click="handleClose"
                :disabled="isSubmitting"
                class="close-btn"
                style="
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
                  transition: all 150ms;
                "
                aria-label="Close modal"
              >
                <X :size="20" />
              </button>
            </div>
          </div>

          <!-- Body -->
          <form
            v-if="!isSuccess"
            @submit.prevent="handleSubmit"
            class="overflow-y-auto flex-1"
            style="padding: 20px 24px"
          >
            <!-- Self-Registration Warning -->
            <div
              style="
                display: flex;
                align-items: flex-start;
                gap: 10px;
                background: rgba(251, 191, 36, 0.12);
                border: 1px solid rgba(251, 191, 36, 0.4);
                border-radius: 12px;
                padding: 12px 14px;
                margin-bottom: 16px;
              "
            >
              <AlertCircle :size="18" style="color: #f59e0b; flex-shrink: 0; margin-top: 1px" />
              <p style="font-size: 13px; color: var(--text-primary); line-height: 1.5">
                <strong>Important:</strong> Patients created here must self-register in the STREAM Android app using the same email address to link their account.
              </p>
            </div>

            <!-- Section 1: Patient Information -->
            <div class="mb-5">
              <h4 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-bottom: 12px">
                Patient Information
              </h4>
              <div class="grid grid-cols-2 gap-4 mb-4">
                <!-- Full Name -->
                <div>
                  <label :for="'input-fullname'" class="input-label">
                    Full Name <span style="color: #ef4444">*</span>
                  </label>
                  <input
                    :id="'input-fullname'"
                    v-model="form.fullName"
                    type="text"
                    placeholder="Enter full name"
                    :class="['input-field', { 'input-error': errors.fullName }]"
                  />
                  <p v-if="errors.fullName" class="error-message">{{ errors.fullName }}</p>
                </div>

                <!-- Email -->
                <div>
                  <label :for="'input-email'" class="input-label">
                    Email <span style="color: #ef4444">*</span>
                  </label>
                  <input
                    :id="'input-email'"
                    v-model="form.email"
                    type="email"
                    placeholder="patient@example.com"
                    :class="['input-field', { 'input-error': errors.email }]"
                  />
                  <p v-if="errors.email" class="error-message">{{ errors.email }}</p>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4 mb-4">
                <!-- Age -->
                <div>
                  <label :for="'input-age'" class="input-label">Age</label>
                  <input
                    :id="'input-age'"
                    v-model="form.age"
                    type="number"
                    min="0"
                    placeholder="Optional"
                    :class="['input-field', { 'input-error': errors.age }]"
                  />
                  <p v-if="errors.age" class="error-message">{{ errors.age }}</p>
                </div>

                <!-- Condition -->
                <div>
                  <label :for="'input-condition'" class="input-label">
                    Condition <span style="color: #ef4444">*</span>
                  </label>
                  <input
                    :id="'input-condition'"
                    v-model="form.condition"
                    type="text"
                    placeholder="e.g., Post-stroke rehabilitation"
                    :class="['input-field', { 'input-error': errors.condition }]"
                  />
                  <p v-if="errors.condition" class="error-message">{{ errors.condition }}</p>
                </div>
              </div>

              <div>
                <label :for="'input-stroke-type'" class="input-label">Stroke Type</label>
                <input
                  :id="'input-stroke-type'"
                  v-model="form.strokeType"
                  type="text"
                  placeholder="e.g., Ischemic"
                  class="input-field"
                />
              </div>
            </div>

          </form>

          <!-- Success State -->
          <div
            v-else
            class="overflow-y-auto flex-1"
            style="
              padding: 40px 24px;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              text-align: center;
              gap: 20px;
            "
          >
            <div
              style="
                width: 64px;
                height: 64px;
                border-radius: 50%;
                background: rgba(16, 185, 129, 0.12);
                display: flex;
                align-items: center;
                justify-content: center;
              "
            >
              <CheckCircle :size="30" style="color: #10b981" />
            </div>
            <div style="max-width: 420px">
              <h4
                style="
                  font-size: 18px;
                  font-weight: 700;
                  color: var(--text-primary);
                  margin-bottom: 10px;
                "
              >
                Patient Added Successfully
              </h4>
              <p style="font-size: 14px; color: var(--text-muted); margin-bottom: 16px">
                Share this email and invite code with your patient:
              </p>
              <div
                style="
                  background: var(--bg-input);
                  border-radius: 12px;
                  padding: 12px 20px;
                  font-size: 15px;
                  font-weight: 600;
                  color: var(--text-primary);
                  margin-bottom: 12px;
                  word-break: break-all;
                "
              >
                {{ successEmail }}
              </div>
              <div
                style="
                  background: var(--bg-input);
                  border-radius: 12px;
                  padding: 12px 20px;
                  font-size: 18px;
                  font-weight: 700;
                  letter-spacing: 0.15em;
                  color: var(--text-primary);
                  margin-bottom: 16px;
                "
              >
                {{ successClaimCode }}
              </div>
              <p style="font-size: 13px; color: var(--text-muted); line-height: 1.65">
                They must register in the STREAM app using this exact email and enter this invite code to link their account.
              </p>
            </div>
          </div>

          <!-- Footer -->
          <div
            class="flex justify-end modal-footer"
            style="padding: 16px 24px 20px; gap: 12px"
          >
            <template v-if="!isSuccess">
              <button
                type="button"
                @click="handleClose"
                :disabled="isSubmitting"
                class="btn-secondary"
              >
                Cancel
              </button>
              <button type="button" @click="handleSubmit" :disabled="isSubmitting" class="btn-primary">
                <span
                  v-if="isSubmitting"
                  class="spinner"
                  style="
                    width: 16px;
                    height: 16px;
                    border: 2px solid #ffffff;
                    border-top-color: transparent;
                    border-radius: 50%;
                    display: inline-block;
                    margin-right: 8px;
                  "
                ></span>
                {{ isSubmitting ? 'Creating...' : 'Add Patient' }}
              </button>
            </template>
            <button v-else type="button" @click="handleClose" class="btn-primary">
              Done
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
<script setup lang="ts">
import { supabase } from '@/services/supabase'
import { ref, reactive, watch } from 'vue'
import { UserPlus, X, CheckCircle, AlertCircle } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/authStore'

interface Props {
  isOpen: boolean
  therapistId: string
}

interface Emits {
  (e: 'close'): void
  (e: 'patientAdded', patientId: string): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const authStore = useAuthStore()
const isSubmitting = ref(false)
const isSuccess = ref(false)
const successEmail = ref('')
const successClaimCode = ref('')

// Excludes 0/O/1/I/L to avoid transcription errors when relayed by hand.
const CLAIM_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'
const generateClaimCode = (): string => {
  return Array.from(
    { length: 6 },
    () => CLAIM_CODE_ALPHABET[Math.floor(Math.random() * CLAIM_CODE_ALPHABET.length)],
  ).join('')
}

const form = reactive({
  fullName: '',
  email: '',
  age: '',
  condition: '',
  strokeType: '',
})

const errors = reactive({
  fullName: '',
  email: '',
  age: '',
  condition: '',
})

watch(
  () => props.isOpen,
  (val) => {
    if (!val) {
      resetForm()
    }
  },
)

const validateEmail = (email: string): boolean => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

const validateForm = (): boolean => {
  let isValid = true

  // Reset errors
  Object.keys(errors).forEach((key) => {
    errors[key as keyof typeof errors] = ''
  })

  // Validate Full Name
  if (!form.fullName.trim()) {
    errors.fullName = 'Full name is required'
    isValid = false
  }

  // Validate Email
  if (!form.email.trim()) {
    errors.email = 'Email is required'
    isValid = false
  } else if (!validateEmail(form.email)) {
    errors.email = 'Please enter a valid email address'
    isValid = false
  }

  // Vue casts a type="number" input's v-model to a Number once a value is
  // typed, even without the .number modifier, so form.age may be a string or a number here.
  const ageStr = String(form.age).trim()
  if (ageStr) {
    const parsedAge = Number.parseInt(ageStr, 10)
    if (!Number.isInteger(parsedAge) || parsedAge < 0) {
      errors.age = 'Age must be a whole number'
      isValid = false
    }
  }

  // Validate Condition
  if (!form.condition.trim()) {
    errors.condition = 'Condition is required'
    isValid = false
  }

  return isValid
}

const resetForm = () => {
  form.fullName = ''
  form.email = ''
  form.age = ''
  form.condition = ''
  form.strokeType = ''

  Object.keys(errors).forEach((key) => {
    errors[key as keyof typeof errors] = ''
  })

  isSuccess.value = false
  successEmail.value = ''
  successClaimCode.value = ''
}

const handleClose = () => {
  if (!isSubmitting.value) {
    emit('close')
  }
}

const handleSubmit = async () => {
  isSubmitting.value = true

  try {
    if (!validateForm()) return

    const therapistId = props.therapistId || authStore.therapistProfile?.id
    if (!therapistId) {
      throw new Error('Therapist profile is not loaded.')
    }

    const ageStr = String(form.age).trim()
    const parsedAge = ageStr ? Number.parseInt(ageStr, 10) : null
    const claimCode = generateClaimCode()
    const { data: patientData, error: patientError } = await supabase
      .from('patients')
      .insert({
        user_id: null,
        therapist_id: therapistId,
        claim_code: claimCode,
        name: form.fullName,
        email: form.email,
        age: Number.isInteger(parsedAge) ? parsedAge : null,
        stroke_type: form.strokeType.trim() || null,
        condition: form.condition.trim(),
        status: 'active',
        enrolled_date: new Date().toISOString().split('T')[0],
        adherence_rate: 0,
        total_sessions: 0,
        avg_accuracy: 0,
        current_streak: 0,
      })
      .select()
      .single()

    if (patientError) throw new Error(patientError.message)

    successEmail.value = form.email
    successClaimCode.value = claimCode
    isSuccess.value = true
    emit('patientAdded', patientData.id)
  } catch (error: any) {
    console.error('Error creating patient:', error)
    alert(`Failed to create patient: ${error.message}`)
  } finally {
    isSubmitting.value = false
  }
}
</script>
<style scoped>
/* Modal Card */
.modal-card {
  background: var(--bg-card);
  box-shadow: var(--shadow-elevated);
}

/* Modal Header */
.modal-header {
  border-bottom: 1px solid var(--border);
}

/* Modal Footer */
.modal-footer {
  border-top: 1px solid var(--border);
}

/* Modal Transitions */
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.96);
}

.modal-enter-active {
  transition:
    opacity 200ms ease,
    transform 300ms ease;
}

.modal-leave-active {
  transition:
    opacity 150ms ease,
    transform 200ms ease;
}

/* Close Button Hover */
.close-btn:hover:not(:disabled) {
  background: var(--bg-hover) !important;
  color: var(--text-primary) !important;
}

.close-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Input Label */
.input-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  margin-bottom: 6px;
}

/* Input Field */
.input-field {
  width: 100%;
  height: 48px;
  padding: 0 16px;
  font-size: 15px;
  color: var(--text-primary);
  background: var(--bg-input);
  border: 2px solid transparent;
  border-radius: 12px;
  transition: all 150ms;
  outline: none;
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

/* Select Dropdown */
select.input-field {
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 16 16'%3E%3Cpath fill='%2394A3B8' d='M4.427 6.427l3.396 3.396a.25.25 0 00.354 0l3.396-3.396A.25.25 0 0011.396 6H4.604a.25.25 0 00-.177.427z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  padding-right: 40px;
}

/* Error Message */
.error-message {
  font-size: 12px;
  color: #991b1b;
  margin-top: 4px;
}

/* Eye Toggle Button */
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

/* Password Requirements */
.password-requirements {
  background: var(--primary-light);
  border-radius: 12px;
  padding: 14px 16px;
  margin-top: 16px;
}

.requirement-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 1.5px solid var(--text-muted);
  background: transparent;
  flex-shrink: 0;
  transition: all 200ms;
}

.requirement-dot.requirement-met {
  background: #10b981;
  border-color: #10b981;
}

.requirement-text {
  color: var(--text-muted);
  font-weight: 400;
}

.requirement-text-met {
  color: #10b981;
  font-weight: 500;
}

/* Buttons */
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
}

.btn-primary:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-primary:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-primary:disabled {
  background: var(--text-muted);
  color: #94a3b8;
  cursor: not-allowed;
}

/* Spinner Animation */
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.spinner {
  animation: spin 0.6s linear infinite;
}

/* Responsive */
@media (max-width: 640px) {
  .grid-cols-2 {
    grid-template-columns: 1fr !important;
  }

  .modal-card {
    border-radius: 16px !important;
  }
}

/* Grid Utilities */
.grid {
  display: grid;
}

.grid-cols-2 {
  grid-template-columns: 1fr 1fr;
}

.gap-4 {
  gap: 16px;
}

.mb-4 {
  margin-bottom: 16px;
}

.mb-5 {
  margin-bottom: 20px;
}
</style>
