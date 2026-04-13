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
            @submit.prevent="handleSubmit"
            class="overflow-y-auto flex-1"
            style="padding: 20px 24px"
          >
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
                <!-- Date of Birth -->
                <div>
                  <label :for="'input-dob'" class="input-label">
                    Date of Birth <span style="color: #ef4444">*</span>
                  </label>
                  <input
                    :id="'input-dob'"
                    v-model="form.dateOfBirth"
                    type="date"
                    :class="['input-field', { 'input-error': errors.dateOfBirth }]"
                  />
                  <p v-if="errors.dateOfBirth" class="error-message">{{ errors.dateOfBirth }}</p>
                </div>

                <!-- Phone Number -->
                <div>
                  <label :for="'input-phone'" class="input-label">
                    Phone Number <span style="color: #ef4444">*</span>
                  </label>
                  <input
                    :id="'input-phone'"
                    v-model="form.phone"
                    type="tel"
                    placeholder="(555) 123-4567"
                    :class="['input-field', { 'input-error': errors.phone }]"
                  />
                  <p v-if="errors.phone" class="error-message">{{ errors.phone }}</p>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <!-- Sex -->
                <div>
                  <label :for="'input-sex'" class="input-label"> Sex </label>
                  <select :id="'input-sex'" v-model="form.sex" class="input-field">
                    <option value="">Select...</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Prefer not to say">Prefer not to say</option>
                  </select>
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
            </div>

            <!-- Section 2: Account Security -->
            <div style="margin-top: 20px">
              <h4 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-bottom: 12px">
                Account Security
              </h4>
              <div class="grid grid-cols-2 gap-4 mb-4">
                <!-- Password -->
                <div>
                  <label :for="'input-password'" class="input-label">
                    Password <span style="color: #ef4444">*</span>
                  </label>
                  <div style="position: relative">
                    <input
                      :id="'input-password'"
                      v-model="form.password"
                      :type="showPassword ? 'text' : 'password'"
                      placeholder="Enter password"
                      :class="['input-field', { 'input-error': errors.password }]"
                      style="padding-right: 40px"
                    />
                    <button
                      type="button"
                      @click="showPassword = !showPassword"
                      class="eye-toggle"
                      tabindex="-1"
                      :aria-label="showPassword ? 'Hide password' : 'Show password'"
                    >
                      <Eye v-if="!showPassword" :size="18" />
                      <EyeOff v-else :size="18" />
                    </button>
                  </div>
                  <p v-if="errors.password" class="error-message">{{ errors.password }}</p>
                </div>

                <!-- Confirm Password -->
                <div>
                  <label :for="'input-confirm-password'" class="input-label">
                    Confirm Password <span style="color: #ef4444">*</span>
                  </label>
                  <div style="position: relative">
                    <input
                      :id="'input-confirm-password'"
                      v-model="form.confirmPassword"
                      :type="showConfirmPassword ? 'text' : 'password'"
                      placeholder="Re-enter password"
                      :class="['input-field', { 'input-error': errors.confirmPassword }]"
                      style="padding-right: 40px"
                    />
                    <button
                      type="button"
                      @click="showConfirmPassword = !showConfirmPassword"
                      class="eye-toggle"
                      tabindex="-1"
                      :aria-label="showConfirmPassword ? 'Hide password' : 'Show password'"
                    >
                      <Eye v-if="!showConfirmPassword" :size="18" />
                      <EyeOff v-else :size="18" />
                    </button>
                  </div>
                  <p v-if="errors.confirmPassword" class="error-message">
                    {{ errors.confirmPassword }}
                  </p>
                </div>
              </div>

              <!-- Password Requirements -->
              <div class="password-requirements">
                <p style="font-size: 14px; font-weight: 700; color: var(--text-primary); margin-bottom: 10px">
                  Password Requirements:
                </p>
                <ul style="display: flex; flex-direction: column; gap: 8px">
                  <li style="display: flex; align-items: center; gap: 8px; font-size: 14px">
                    <span
                      :class="['requirement-dot', { 'requirement-met': passwordChecks.length }]"
                    ></span>
                    <span
                      class="requirement-text"
                      :class="{ 'requirement-text-met': passwordChecks.length }"
                    >
                      At least 8 characters
                    </span>
                  </li>
                  <li style="display: flex; align-items: center; gap: 8px; font-size: 14px">
                    <span
                      :class="['requirement-dot', { 'requirement-met': passwordChecks.uppercase }]"
                    ></span>
                    <span
                      class="requirement-text"
                      :class="{ 'requirement-text-met': passwordChecks.uppercase }"
                    >
                      One uppercase letter
                    </span>
                  </li>
                  <li style="display: flex; align-items: center; gap: 8px; font-size: 14px">
                    <span
                      :class="['requirement-dot', { 'requirement-met': passwordChecks.lowercase }]"
                    ></span>
                    <span
                      class="requirement-text"
                      :class="{ 'requirement-text-met': passwordChecks.lowercase }"
                    >
                      One lowercase letter
                    </span>
                  </li>
                  <li style="display: flex; align-items: center; gap: 8px; font-size: 14px">
                    <span
                      :class="['requirement-dot', { 'requirement-met': passwordChecks.number }]"
                    ></span>
                    <span
                      class="requirement-text"
                      :class="{ 'requirement-text-met': passwordChecks.number }"
                    >
                      One number
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          </form>

          <!-- Footer -->
          <div
            class="flex justify-end modal-footer"
            style="padding: 16px 24px 20px; gap: 12px"
          >
            <button
              type="button"
              @click="handleClose"
              :disabled="isSubmitting"
              class="btn-secondary"
            >
              Cancel
            </button>
            <button type="submit" @click="handleSubmit" :disabled="isSubmitting" class="btn-primary">
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
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue'
import { Eye, EyeOff, UserPlus, X } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/authStore'
import { supabase } from '@/services/supabase'

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
const showPassword = ref(false)
const showConfirmPassword = ref(false)

const form = reactive({
  fullName: '',
  email: '',
  dateOfBirth: '',
  phone: '',
  sex: '',
  condition: '',
  password: '',
  confirmPassword: '',
})

const errors = reactive({
  fullName: '',
  email: '',
  dateOfBirth: '',
  phone: '',
  condition: '',
  password: '',
  confirmPassword: '',
})

// Password validation checks
const passwordChecks = computed(() => ({
  length: form.password.length >= 8,
  uppercase: /[A-Z]/.test(form.password),
  lowercase: /[a-z]/.test(form.password),
  number: /[0-9]/.test(form.password),
}))

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

const validatePassword = (password: string): string | null => {
  if (password.length < 8) return 'Password must be at least 8 characters'
  if (!/[A-Z]/.test(password)) return 'Password must contain at least one uppercase letter'
  if (!/[a-z]/.test(password)) return 'Password must contain at least one lowercase letter'
  if (!/[0-9]/.test(password)) return 'Password must contain at least one number'
  return null
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

  // Validate Date of Birth
  if (!form.dateOfBirth) {
    errors.dateOfBirth = 'Date of birth is required'
    isValid = false
  }

  // Validate Phone Number
  if (!form.phone.trim()) {
    errors.phone = 'Phone number is required'
    isValid = false
  }

  // Validate Condition
  if (!form.condition.trim()) {
    errors.condition = 'Condition is required'
    isValid = false
  }

  // Validate Password
  if (!form.password) {
    errors.password = 'Password is required'
    isValid = false
  } else {
    const passwordError = validatePassword(form.password)
    if (passwordError) {
      errors.password = passwordError
      isValid = false
    }
  }

  // Validate Confirm Password
  if (!form.confirmPassword) {
    errors.confirmPassword = 'Please confirm password'
    isValid = false
  } else if (form.password !== form.confirmPassword) {
    errors.confirmPassword = 'Passwords do not match'
    isValid = false
  }

  return isValid
}

const resetForm = () => {
  form.fullName = ''
  form.email = ''
  form.dateOfBirth = ''
  form.phone = ''
  form.sex = ''
  form.condition = ''
  form.password = ''
  form.confirmPassword = ''

  Object.keys(errors).forEach((key) => {
    errors[key as keyof typeof errors] = ''
  })
}

const handleClose = () => {
  if (!isSubmitting.value) {
    emit('close')
  }
}

const handleSubmit = async () => {
  if (!validateForm()) return

  isSubmitting.value = true

  try {
    // 1. Create Supabase auth user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: form.email,
      password: form.password,
      options: {
        emailRedirectTo: undefined,
        data: {
          role: 'patient',
          name: form.fullName,
        },
      },
    })

    if (authError) throw new Error(authError.message)
    if (!authData.user) throw new Error('Failed to create user account')

    // 2. Insert into patients table
    const nameParts = form.fullName.trim().split(' ')
    const firstName = nameParts[0]
    const lastName = nameParts.slice(1).join(' ') || ''

    const { data: patientData, error: patientError } = await supabase
      .from('patients')
      .insert({
        user_id: authData.user.id,
        name: form.fullName,
        email: form.email,
        phone_number: form.phone,
        date_of_birth: form.dateOfBirth,
        sex: form.sex || null,
        condition: form.condition,
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

    emit('patientAdded', patientData.id)
    emit('close')
    alert(`Patient "${form.fullName}" has been added successfully!`)
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
