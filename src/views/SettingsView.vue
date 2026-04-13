<template>
  <div class="page">
    <!-- Success Toast -->
    <transition name="fade">
      <div v-if="successMessage" class="success-toast">
        {{ successMessage }}
      </div>
    </transition>

    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2">Settings</h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px">
          Manage your profile and preferences
        </p>
      </div>
    </div>

    <!-- Tabs -->
    <div class="settings-tabs">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        @click="activeTab = tab.key"
        class="tab-button"
        :class="{ 'tab-button--active': activeTab === tab.key }"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Content Area -->
    <div class="settings-content">
      <!-- Profile Tab -->
      <div v-if="activeTab === 'profile'">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-6)">Profile Information</h3>

          <div class="profile-layout">
            <!-- Avatar -->
            <div class="avatar-section">
              <div class="avatar-large">
                {{ initials }}
              </div>
              <button class="btn-ghost" style="margin-top: var(--space-3)" @click="changePhoto">Change Photo</button>
            </div>

            <!-- Form Fields -->
            <div class="form-fields">
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Full Name</label>
                  <input v-model="profileForm.name" type="text" class="form-input" />
                </div>
                <div class="form-group">
                  <label class="form-label">Email</label>
                  <input v-model="profileForm.email" type="email" class="form-input" />
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">License Number</label>
                  <input v-model="profileForm.license" type="text" class="form-input" />
                </div>
                <div class="form-group">
                  <label class="form-label">Specialty</label>
                  <select v-model="profileForm.specialty" class="form-input">
                    <option value="physical_therapy">Physical Therapy</option>
                    <option value="occupational_therapy">Occupational Therapy</option>
                    <option value="sports_medicine">Sports Medicine</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">Bio</label>
                <textarea
                  v-model="profileForm.bio"
                  rows="3"
                  class="form-textarea"
                  placeholder="Tell us about yourself..."
                ></textarea>
              </div>

              <div class="form-actions">
                <button class="btn-ghost" @click="resetProfileForm">Cancel</button>
                <button class="btn-primary" :disabled="isSaving" @click="saveProfile">
                  {{ isSaving ? 'Saving...' : 'Save Changes' }}
                </button>
              </div>
            </div>
          </div>
        </BaseCard>
      </div>

      <!-- Security Tab -->
      <div v-if="activeTab === 'security'" class="settings-section">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-4)">Change Password</h3>

          <div class="form-container">
            <div class="form-group">
              <label class="form-label">Current Password</label>
              <input v-model="securityForm.currentPassword" type="password" class="form-input" />
            </div>

            <div class="form-group">
              <label class="form-label">New Password</label>
              <input v-model="securityForm.newPassword" type="password" class="form-input" />
            </div>

            <div class="form-group">
              <label class="form-label">Confirm New Password</label>
              <input v-model="securityForm.confirmPassword" type="password" class="form-input" />
            </div>

            <div class="form-actions">
              <button class="btn-ghost" @click="resetSecurityForm">Cancel</button>
              <button class="btn-primary" :disabled="isSaving" @click="updatePassword">
                {{ isSaving ? 'Updating...' : 'Update Password' }}
              </button>
            </div>
          </div>
        </BaseCard>

        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-2)">Two-Factor Authentication</h3>
          <p class="caption" style="color: var(--text-muted); margin-bottom: var(--space-4)">
            Add an extra layer of security to your account
          </p>

          <button class="btn-ghost" :disabled="isSaving" @click="enable2FA">
            {{ isSaving ? 'Enabling...' : 'Enable 2FA' }}
          </button>
        </BaseCard>
      </div>

      <!-- Notifications Tab -->
      <div v-if="activeTab === 'notifications'">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-6)">Notification Preferences</h3>

          <div class="notification-list">
            <div class="notification-item">
              <div class="notification-info">
                <p class="h4">Patient Alerts</p>
                <p class="caption" style="color: var(--text-muted); margin-top: 2px">
                  Get notified when patients miss sessions or show low adherence
                </p>
              </div>
              <label class="toggle">
                <input type="checkbox" v-model="notificationForm.patientAlerts" />
                <span class="toggle-slider"></span>
              </label>
            </div>

            <div class="notification-item">
              <div class="notification-info">
                <p class="h4">Email Notifications</p>
                <p class="caption" style="color: var(--text-muted); margin-top: 2px">
                  Receive email updates about your practice
                </p>
              </div>
              <label class="toggle">
                <input type="checkbox" v-model="notificationForm.emailNotifications" />
                <span class="toggle-slider"></span>
              </label>
            </div>

            <div class="notification-item">
              <div class="notification-info">
                <p class="h4">Session Reminders</p>
                <p class="caption" style="color: var(--text-muted); margin-top: 2px">
                  Get reminders about upcoming patient sessions
                </p>
              </div>
              <label class="toggle">
                <input type="checkbox" v-model="notificationForm.sessionReminders" />
                <span class="toggle-slider"></span>
              </label>
            </div>
          </div>

          <div
            class="form-actions"
            style="
              margin-top: var(--space-6);
              border-top: 1px solid var(--border);
            "
          >
            <button class="btn-primary" :disabled="isSaving" @click="saveNotifications">
              {{ isSaving ? 'Saving...' : 'Save Preferences' }}
            </button>
          </div>
        </BaseCard>
      </div>

      <!-- Preferences Tab -->
      <div v-if="activeTab === 'preferences'">
        <BaseCard>
          <h3 class="h3" style="margin-bottom: var(--space-4)">Display Preferences</h3>

          <div class="form-container">
            <div class="form-group">
              <label class="form-label">Theme</label>
              <select v-model="preferencesForm.theme" class="form-input">
                <option value="light">Light</option>
                <option value="dark">Dark</option>
                <option value="system">System</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Date Format</label>
              <select v-model="preferencesForm.dateFormat" class="form-input">
                <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                <option value="DD/MM/YYYY">DD/MM/YYYY</option>
                <option value="YYYY-MM-DD">YYYY-MM-DD</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Time Format</label>
              <select v-model="preferencesForm.timeFormat" class="form-input">
                <option value="12h">12 Hour</option>
                <option value="24h">24 Hour</option>
              </select>
            </div>

            <div class="form-actions">
              <button class="btn-primary" :disabled="isSaving" @click="savePreferences">
                {{ isSaving ? 'Saving...' : 'Save Preferences' }}
              </button>
            </div>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/authStore'
import { storeToRefs } from 'pinia'
import BaseCard from '@/components/shared/BaseCard.vue'
import { useTheme, type Theme } from '@/composables/useTheme'

const authStore = useAuthStore()
const { therapistProfile } = storeToRefs(authStore)
const { theme, setTheme } = useTheme()

const activeTab = ref('profile')
const isSaving = ref(false)
const successMessage = ref('')

const tabs = [
  { key: 'profile', label: 'Profile' },
  { key: 'security', label: 'Security' },
  { key: 'notifications', label: 'Notifications' },
  { key: 'preferences', label: 'Preferences' },
]

const profileForm = ref({
  name: therapistProfile.value?.name || '',
  email: therapistProfile.value?.email || '',
  license: 'PT-12345',
  specialty: 'physical_therapy',
  bio: '',
})

const securityForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
})

const notificationForm = ref({
  patientAlerts: true,
  emailNotifications: true,
  sessionReminders: true,
})

const preferencesForm = ref({
  theme: theme.value,
  dateFormat: 'MM/DD/YYYY',
  timeFormat: '12h',
})

// Watch for theme changes and apply immediately
watch(() => preferencesForm.value.theme, (newTheme) => {
  setTheme(newTheme as Theme)
})

const initials = computed(() => {
  if (!therapistProfile.value?.name) return 'T'
  const parts = therapistProfile.value.name.split(' ')
  return parts
    .map((p) => p[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
})

const showSuccess = (message: string) => {
  successMessage.value = message
  setTimeout(() => {
    successMessage.value = ''
  }, 3000)
}

const saveProfile = async () => {
  isSaving.value = true

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800))

    // In a real app, this would call:
    // await authStore.updateProfile(profileForm.value)

    console.log('Profile updated:', profileForm.value)
    showSuccess('Profile updated successfully!')
  } catch (error) {
    console.error('Error updating profile:', error)
    alert('Failed to update profile. Please try again.')
  } finally {
    isSaving.value = false
  }
}

const updatePassword = async () => {
  // Validate passwords
  if (!securityForm.value.currentPassword || !securityForm.value.newPassword) {
    alert('Please fill in all password fields')
    return
  }

  if (securityForm.value.newPassword !== securityForm.value.confirmPassword) {
    alert('New passwords do not match')
    return
  }

  if (securityForm.value.newPassword.length < 8) {
    alert('Password must be at least 8 characters long')
    return
  }

  isSaving.value = true

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800))

    // In a real app, this would call:
    // await authStore.updatePassword(securityForm.value)

    console.log('Password updated')

    // Clear form
    securityForm.value = {
      currentPassword: '',
      newPassword: '',
      confirmPassword: '',
    }

    showSuccess('Password updated successfully!')
  } catch (error) {
    console.error('Error updating password:', error)
    alert('Failed to update password. Please check your current password and try again.')
  } finally {
    isSaving.value = false
  }
}

const enable2FA = async () => {
  isSaving.value = true

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800))

    // In a real app, this would call:
    // await authStore.enable2FA()

    console.log('2FA enabled')
    showSuccess('Two-factor authentication has been enabled!')
  } catch (error) {
    console.error('Error enabling 2FA:', error)
    alert('Failed to enable 2FA. Please try again.')
  } finally {
    isSaving.value = false
  }
}

const saveNotifications = async () => {
  isSaving.value = true

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800))

    // In a real app, this would call:
    // await authStore.updateNotificationPreferences(notificationForm.value)

    console.log('Notification preferences updated:', notificationForm.value)
    showSuccess('Notification preferences saved!')
  } catch (error) {
    console.error('Error updating notifications:', error)
    alert('Failed to update notification preferences. Please try again.')
  } finally {
    isSaving.value = false
  }
}

const savePreferences = async () => {
  isSaving.value = true

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800))

    // Theme is already applied via the watch, so we just need to save other preferences
    // In a real app, this would call:
    // await authStore.updatePreferences(preferencesForm.value)

    console.log('Preferences updated:', preferencesForm.value)
    showSuccess('Display preferences saved!')
  } catch (error) {
    console.error('Error updating preferences:', error)
    alert('Failed to update preferences. Please try again.')
  } finally {
    isSaving.value = false
  }
}

const changePhoto = () => {
  // In a real app, this would open a file picker and handle upload
  alert('Photo upload functionality would be implemented here')
}

const resetProfileForm = () => {
  profileForm.value = {
    name: therapistProfile.value?.name || '',
    email: therapistProfile.value?.email || '',
    license: 'PT-12345',
    specialty: 'physical_therapy',
    bio: '',
  }
}

const resetSecurityForm = () => {
  securityForm.value = {
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  }
}
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

.settings-tabs {
  display: flex;
  gap: var(--space-2);
  border-bottom: 2px solid var(--border);
  margin-bottom: var(--space-4);
}

.tab-button {
  padding: var(--space-3) var(--space-4);
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  color: var(--text-secondary);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.tab-button:hover {
  color: var(--primary);
}

.tab-button--active {
  color: var(--primary);
  border-bottom-color: var(--primary);
}

.settings-content {
  flex: 1;
}

.settings-section {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

/* Profile Layout */
.profile-layout {
  display: flex;
  gap: var(--space-8);
}

.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
}

.avatar-large {
  width: 96px;
  height: 96px;
  border-radius: var(--radius-md);
  background: var(--primary-light);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
  color: var(--primary);
}

.form-fields {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.form-container {
  max-width: 480px;
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
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

.form-input,
.form-textarea {
  height: 40px;
  padding: 0 var(--space-3);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s;
}

.form-input:focus,
.form-textarea:focus {
  border-color: var(--border-focus);
}

.form-textarea {
  height: auto;
  padding: var(--space-3);
  resize: vertical;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-2);
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
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  color: var(--text-secondary);
  font-weight: 600;
  transition:
    background 0.15s,
    border-color 0.15s;
}

.btn-ghost:hover {
  background: var(--bg-hover);
  border-color: var(--primary);
  color: var(--primary);
}

.btn-ghost:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Notifications */
.notification-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.notification-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4) 0;
}

.notification-info {
  flex: 1;
}

/* Toggle Switch */
.toggle {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  flex-shrink: 0;
}

.toggle input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #e2e8f0;
  border-radius: var(--radius-pill);
  transition: 0.3s;
}

.toggle-slider:before {
  position: absolute;
  content: '';
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  border-radius: 50%;
  transition: 0.3s;
}

.toggle input:checked + .toggle-slider {
  background: var(--gradient-primary);
}

.toggle input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

.toggle input:focus + .toggle-slider {
  box-shadow: 0 0 0 2px var(--primary-light);
}

/* Success Toast */
.success-toast {
  position: fixed;
  top: 24px;
  right: 24px;
  background: var(--gradient-success);
  color: white;
  padding: var(--space-3) var(--space-5);
  border-radius: var(--radius-sm);
  font-size: 14px;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    transform: translateX(400px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
