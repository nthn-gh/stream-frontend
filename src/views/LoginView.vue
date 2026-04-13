<template>
  <div class="login-page">
    <!-- Left Panel - Brand -->
    <div class="brand-panel">
      <div class="brand-content">
        <div class="brand-icon">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5">
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
          </svg>
        </div>
        <h1 class="brand-title">STREAM</h1>
        <p class="brand-subtitle">Your recovery, guided by AI</p>
      </div>
    </div>
    
    <!-- Right Panel - Login Form -->
    <div class="form-panel">
      <div class="form-container">
        <div class="form-header">
          <h2 class="h1">Therapist Portal</h2>
          <p style="color: var(--text-muted); margin-top: var(--space-2);">Sign in to access your dashboard</p>
        </div>
        
        <form @submit.prevent="handleLogin" class="login-form">
          <AppInput
            v-model="form.email"
            type="email"
            label="Email"
            placeholder="therapist@example.com"
            :error="errors.email"
            :disabled="isLoading"
          />
          
          <AppInput
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            label="Password"
            placeholder="Enter your password"
            :error="errors.password"
            :disabled="isLoading"
          >
            <template #iconRight>
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="password-toggle"
              >
                <Eye v-if="!showPassword" :size="20" />
                <EyeOff v-else :size="20" />
              </button>
            </template>
          </AppInput>
          
          <div class="form-options">
            <label class="remember-me">
              <input type="checkbox" v-model="rememberMe" />
              <span class="caption">Remember me</span>
            </label>
            <a href="#" class="forgot-link caption">Forgot Password?</a>
          </div>
          
          <button
            type="submit"
            :disabled="isLoading"
            class="btn-login"
          >
            <span v-if="isLoading" class="loading-spinner"></span>
            <span v-else>Log In</span>
          </button>
          
          <p v-if="errors.general" class="error-message">
            {{ errors.general }}
          </p>

          <p class="signup-link caption">
            Don't have an account?
            <router-link to="/register" class="link">Sign up</router-link>
          </p>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Eye, EyeOff } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/authStore'
import AppInput from '@/components/shared/AppInput.vue'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive({
  email: '',
  password: ''
})

const errors = reactive({
  email: '',
  password: '',
  general: ''
})

const showPassword = ref(false)
const rememberMe = ref(false)
const isLoading = ref(false)

const validateForm = () => {
  errors.email = ''
  errors.password = ''
  errors.general = ''
  
  if (!form.email) {
    errors.email = 'Email is required'
    return false
  }
  
  if (!/\S+@\S+\.\S+/.test(form.email)) {
    errors.email = 'Please enter a valid email'
    return false
  }
  
  if (!form.password) {
    errors.password = 'Password is required'
    return false
  }
  
  if (form.password.length < 6) {
    errors.password = 'Password must be at least 6 characters'
    return false
  }
  
  return true
}

const handleLogin = async () => {
  if (!validateForm()) return
  
  isLoading.value = true
  
  try {
    const result = await authStore.login(form.email, form.password)
    
    if (result.success) {
      router.push('/dashboard')
    } else {
      errors.general = result.error || 'Login failed. Please check your credentials.'
    }
  } catch (error: any) {
    errors.general = error.message || 'An unexpected error occurred'
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
}

.brand-panel {
  display: none;
  background: var(--gradient-primary);
  width: 50%;
  align-items: center;
  justify-content: center;
  padding: var(--space-12);
}

@media (min-width: 1024px) {
  .brand-panel {
    display: flex;
  }
}

.brand-content {
  max-width: 480px;
  text-align: center;
}

.brand-icon {
  width: 128px;
  height: 128px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto var(--space-8);
}

.brand-title {
  font-size: 56px;
  font-weight: 700;
  color: white;
  margin-bottom: var(--space-4);
  letter-spacing: 0.1em;
}

.brand-subtitle {
  font-size: 24px;
  color: rgba(255, 255, 255, 0.9);
}

.form-panel {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-8);
  background: white;
}

.form-container {
  width: 100%;
  max-width: 440px;
}

.form-header {
  text-align: center;
  margin-bottom: var(--space-8);
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.form-options {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.remember-me {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
}

.remember-me input[type="checkbox"] {
  width: 16px;
  height: 16px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  cursor: pointer;
}

.remember-me span {
  color: var(--text-secondary);
}

.forgot-link {
  color: var(--text-link);
  text-decoration: none;
  font-weight: 500;
}

.forgot-link:hover {
  text-decoration: underline;
}

.btn-login {
  width: 100%;
  height: 48px;
  background: var(--gradient-primary);
  color: white;
  border: none;
  border-radius: var(--radius-sm);
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
}

.btn-login:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-login:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.loading-spinner {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  color: #DC2626;
  font-size: 13px;
  text-align: center;
  padding: var(--space-3);
  background: var(--status-danger-bg);
  border-radius: var(--radius-sm);
}

.signup-link {
  text-align: center;
  color: var(--text-secondary);
}

.link {
  color: var(--text-link);
  font-weight: 600;
  text-decoration: none;
}

.link:hover {
  text-decoration: underline;
}

.password-toggle {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-muted);
  padding: var(--space-1);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.15s;
}

.password-toggle:hover {
  color: var(--text-primary);
}
</style>