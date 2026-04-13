# STREAM Therapist Dashboard - Complete File Generator
# This script creates all remaining component, layout, and view files
# Run from: c:\Users\Ethan\stream\stream-frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " STREAM - Creating All Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$filesCreated = 0
$errorCount = 0

function Write-FileContent {
    param($Path, $Content, $Description)
    try {
        $Content | Out-File -FilePath $Path -Encoding UTF8 -Force
        Write-Host "[OK] Created: $Description" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Failed: $Description - $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "[1/4] Creating Shared Components (10 files)..." -ForegroundColor Yellow
Write-Host ""

# AppInput.vue
$appInputContent = @'
<template>
  <div class="w-full">
    <label v-if="label" :for="inputId" class="block text-label text-slate-900 mb-2">
      {{ label }}
    </label>
    <div class="relative">
      <input
        :id="inputId"
        v-model="modelValue"
        :type="type"
        :placeholder="placeholder"
        :disabled="disabled"
        :class="inputClasses"
        @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
        @focus="$emit('focus')"
        @blur="$emit('blur')"
      />
      <div v-if="$slots.iconRight" class="absolute right-4 top-1/2 -translate-y-1/2">
        <slot name="iconRight" />
      </div>
    </div>
    <p v-if="error" class="mt-1 text-caption text-error-text">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue: string
  type?: string
  label?: string
  placeholder?: string
  disabled?: boolean
  error?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  disabled: false
})

defineEmits<{
  'update:modelValue': [value: string]
  focus: []
  blur: []
}>()

const inputId = computed(() => `input-${Math.random().toString(36).substr(2, 9)}`)

const inputClasses = computed(() => {
  const base = 'w-full h-13 px-5 text-body rounded-xl transition-all duration-200 focus:outline-none'
  const normal = 'bg-slate-100 border-2 border-transparent focus:border-primary focus:ring-2 focus:ring-primary/20'
  const errorState = 'border-2 border-error focus:border-error focus:ring-2 focus:ring-error/20'
  const disabledState = 'bg-slate-200 text-slate-400 cursor-not-allowed'
  
  if (props.disabled) return `${base} ${disabledState}`
  if (props.error) return `${base} ${errorState}`
  return `${base} ${normal}`
})
</script>
'@

if (Write-FileContent "src\components\shared\AppInput.vue" $appInputContent "AppInput.vue") { $filesCreated++ } else { $errorCount++ }

# AppCard.vue
$appCardContent = @'
<template>
  <div :class="cardClasses">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  padding?: 'small' | 'medium' | 'large'
  hoverable?: boolean
  clickable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  padding: 'medium',
  hoverable: false,
  clickable: false
})

const cardClasses = computed(() => {
  const base = 'bg-white border border-slate-200 rounded-2xl transition-all duration-200'
  const hover = props.hoverable ? 'hover:border-slate-300 hover:shadow-lg hover:-translate-y-0.5' : ''
  const click = props.clickable ? 'cursor-pointer' : ''
  
  const paddings = {
    small: 'p-4',
    medium: 'p-6',
    large: 'p-8'
  }
  
  return `${base} ${paddings[props.padding]} ${hover} ${click} shadow-md`
})
</script>
'@

if (Write-FileContent "src\components\shared\AppCard.vue" $appCardContent "AppCard.vue") { $filesCreated++ } else { $errorCount++ }

# AppBadge.vue
$appBadgeContent = @'
<template>
  <span :class="badgeClasses">
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant: 'success' | 'warning' | 'error' | 'info' | 'neutral'
}

const props = defineProps<Props>()

const badgeClasses = computed(() => {
  const base = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold'
  
  const variants = {
    success: 'bg-success-bg text-success-text',
    warning: 'bg-warning-bg text-warning-text',
    error: 'bg-error-bg text-error-text',
    info: 'bg-blue-100 text-blue-900',
    neutral: 'bg-slate-100 text-slate-700'
  }
  
  return `${base} ${variants[props.variant]}`
})
</script>
'@

if (Write-FileContent "src\components\shared\AppBadge.vue" $appBadgeContent "AppBadge.vue") { $filesCreated++ } else { $errorCount++ }

Write-Host ""
Write-Host "Shared components created. Continuing with more files..."
Write-Host "This may take a minute..."
Write-Host ""

# AppModal.vue
$appModalContent = @'
<template>
  <Teleport to="body">
    <Transition name="modal-overlay">
      <div
        v-if="modelValue"
        class="fixed inset-0 z-[1000] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4"
        @click.self="handleClose"
      >
        <Transition name="modal-content">
          <div
            v-if="modelValue"
            class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col"
            role="dialog"
            aria-modal="true"
          >
            <div v-if="title" class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <h3 class="text-xl font-bold text-slate-900">{{ title }}</h3>
              <button
                v-if="closable"
                @click="handleClose"
                class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 transition-colors"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            
            <div class="px-6 py-6 overflow-y-auto flex-1">
              <slot />
            </div>
            
            <div v-if="$slots.footer" class="px-6 py-4 border-t border-slate-200 flex justify-end gap-3">
              <slot name="footer" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
interface Props {
  modelValue: boolean
  title?: string
  closable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  closable: true
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const handleClose = () => {
  if (props.closable) {
    emit('update:modelValue', false)
  }
}
</script>

<style scoped>
.modal-overlay-enter-active,
.modal-overlay-leave-active {
  transition: opacity 0.2s ease;
}

.modal-overlay-enter-from,
.modal-overlay-leave-to {
  opacity: 0;
}

.modal-content-enter-active {
  transition: all 0.3s ease-out;
}

.modal-content-leave-active {
  transition: all 0.2s ease-in;
}

.modal-content-enter-from,
.modal-content-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
'@

if (Write-FileContent "src\components\shared\AppModal.vue" $appModalContent "AppModal.vue") { $filesCreated++ } else { $errorCount++ }

Write-Host ""
Write-Host "[2/4] Creating Layout Components (2 files)..." -ForegroundColor Yellow
Write-Host ""

# AppSidebar.vue  
$appSidebarContent = @'
<template>
  <aside :class="sidebarClasses">
    <div class="h-18 px-5 border-b border-slate-200 flex items-center justify-between">
      <div v-if="!collapsed" class="flex items-center gap-3">
        <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
          <Activity :size="24" class="text-white" />
        </div>
        <span class="text-xl font-bold text-navy">STREAM</span>
      </div>
      <button
        @click="toggleSidebar"
        class="w-10 h-10 flex items-center justify-center rounded-lg hover:bg-slate-200 transition-colors"
      >
        <ChevronLeft v-if="!collapsed" :size="20" />
        <ChevronRight v-else :size="20" />
      </button>
    </div>
    
    <nav class="flex-1 px-3 py-4 space-y-1">
      <router-link
        v-for="item in navItems"
        :key="item.path"
        :to="item.path"
        v-slot="{ isActive }"
        custom
      >
        <button
          :class="getNavItemClass(isActive)"
          @click="$router.push(item.path)"
        >
          <component :is="item.icon" :size="20" />
          <span v-if="!collapsed" class="text-base">{{ item.label }}</span>
        </button>
      </router-link>
    </nav>
  </aside>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Activity, LayoutDashboard, Users, Dumbbell, BellDot, FileText, Settings, ChevronLeft, ChevronRight } from 'lucide-vue-next'

const collapsed = ref(false)

const navItems = [
  { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/patients', label: 'Patients', icon: Users },
  { path: '/assign-exercise', label: 'Assign Exercise', icon: Dumbbell },
  { path: '/alerts', label: 'Alerts', icon: BellDot },
  { path: '/reports', label: 'Reports', icon: FileText },
  { path: '/settings', label: 'Settings', icon: Settings }
]

const sidebarClasses = computed(() => {
  const base = 'fixed left-0 top-0 h-screen bg-slate-50 border-r border-slate-200 flex flex-col transition-all duration-300 z-[100]'
  const width = collapsed.value ? 'w-16' : 'w-70'
  return `${base} ${width}`
})

const getNavItemClass = (isActive: boolean) => {
  const base = 'w-full h-11 px-4 flex items-center gap-3 rounded-xl transition-all duration-150'
  if (isActive) {
    return `${base} bg-primary text-white font-semibold`
  }
  return `${base} text-slate-700 hover:bg-slate-200`
}

const toggleSidebar = () => {
  collapsed.value = !collapsed.value
}
</script>
'@

if (Write-FileContent "src\components\layout\AppSidebar.vue" $appSidebarContent "AppSidebar.vue") { $filesCreated++ } else { $errorCount++ }

# AppTopBar.vue
$appTopBarContent = @'
<template>
  <header class="fixed top-0 right-0 left-70 h-18 bg-white border-b border-slate-200 px-8 flex items-center justify-between z-[90]">
    <div class="flex items-center gap-4 flex-1">
      <div class="relative w-96">
        <Search :size="20" class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search patients..."
          class="w-full h-10 pl-11 pr-4 bg-slate-100 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary/50"
          @keyup.enter="handleSearch"
        />
      </div>
    </div>
    
    <div class="flex items-center gap-4">
      <button class="relative w-10 h-10 flex items-center justify-center rounded-xl hover:bg-slate-100 transition-colors">
        <BellDot v-if="unreadAlerts > 0" :size="24" class="text-slate-900" />
        <Bell v-else :size="24" class="text-slate-900" />
        <span v-if="unreadAlerts > 0" class="absolute -top-1 -right-1 w-5 h-5 bg-error rounded-full flex items-center justify-center text-xs text-white font-bold">
          {{ unreadAlerts }}
        </span>
      </button>
      
      <div class="flex items-center gap-3 pl-4 border-l border-slate-200">
        <img v-if="therapistProfile?.avatar_url" :src="therapistProfile.avatar_url" class="w-10 h-10 rounded-full object-cover" />
        <div v-else class="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-semibold">
          {{ initials }}
        </div>
        <div class="hidden md:block">
          <p class="text-sm font-semibold text-slate-900">{{ therapistProfile?.name }}</p>
          <p class="text-xs text-slate-600">Therapist</p>
        </div>
        <button @click="showUserMenu = !showUserMenu" class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100">
          <ChevronDown :size="16" />
        </button>
      </div>
    </div>
    
    <div v-if="showUserMenu" class="absolute top-16 right-8 w-48 bg-white rounded-xl shadow-xl border border-slate-200 py-2">
      <router-link to="/settings" class="block px-4 py-2 text-sm text-slate-700 hover:bg-slate-50">Settings</router-link>
      <button @click="handleLogout" class="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50">Logout</button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Bell, BellDot, ChevronDown } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/authStore'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'

const router = useRouter()
const authStore = useAuthStore()
const alertStore = useAlertStore()

const { therapistProfile } = storeToRefs(authStore)
const { unreadCount: unreadAlerts } = storeToRefs(alertStore)

const searchQuery = ref('')
const showUserMenu = ref(false)

const initials = computed(() => {
  if (!therapistProfile.value?.name) return 'T'
  const parts = therapistProfile.value.name.split(' ')
  return parts.map(p => p[0]).join('').toUpperCase().slice(0, 2)
})

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    router.push({ path: '/patients', query: { search: searchQuery.value } })
  }
}

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>
'@

if (Write-FileContent "src\components\layout\AppTopBar.vue" $appTopBarContent "AppTopBar.vue") { $filesCreated++ } else { $errorCount++ }

Write-Host ""
Write-Host "Creating remaining shared components..."
Write-Host ""

# Create remaining stub components
$stubComponents = @(
    @{Name="AppToast.vue"; Content="<template><div class='toast'><slot /></div></template><script setup lang='ts'></script>"},
    @{Name="AppTabs.vue"; Content="<template><div class='tabs'><slot /></div></template><script setup lang='ts'></script>"},
    @{Name="AppTable.vue"; Content="<template><div class='table-container'><slot /></div></template><script setup lang='ts'></script>"},
    @{Name="AppAvatar.vue"; Content="<template><div class='avatar'><slot /></div></template><script setup lang='ts'></script>"},
    @{Name="AppSkeleton.vue"; Content="<template><div class='skeleton animate-pulse bg-slate-200 rounded'></div></template><script setup lang='ts'></script>"},
    @{Name="AppDropdown.vue"; Content="<template><div class='dropdown'><slot /></div></template><script setup lang='ts'></script>"}
)

foreach ($component in $stubComponents) {
    if (Write-FileContent "src\components\shared\$($component.Name)" $component.Content $component.Name) { 
        $filesCreated++ 
    } else { 
        $errorCount++ 
    }
}

Write-Host ""
Write-Host "[3/4] Creating Router Configuration..." -ForegroundColor Yellow
Write-Host ""

# Router index.ts
$routerContent = @'
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/dashboard'
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('@/views/DashboardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/patients',
      name: 'patients',
      component: () => import('@/views/PatientsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/patients/:id',
      name: 'patient-profile',
      component: () => import('@/views/PatientProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/assign-exercise',
      name: 'assign-exercise',
      component: () => import('@/views/AssignExerciseView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/alerts',
      name: 'alerts',
      component: () => import('@/views/AlertsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports',
      name: 'reports',
      component: () => import('@/views/ReportsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('@/views/SettingsView.vue'),
      meta: { requiresAuth: true }
    }
  ]
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  const requiresAuth = to.meta.requiresAuth !== false
  
  if (requiresAuth) {
    const isAuth = await authStore.checkAuth()
    
    if (!isAuth) {
      next('/login')
      return
    }
    
    if (!authStore.isTherapist) {
      console.error('Access denied - not a therapist')
      await authStore.logout()
      next('/login')
      return
    }
  }
  
  if (to.path === '/login' && authStore.isAuthenticated) {
    next('/dashboard')
    return
  }
  
  next()
})

export default router
'@

if (Write-FileContent "src\router\index.ts" $routerContent "Router Configuration") { $filesCreated++ } else { $errorCount++ }

Write-Host ""
Write-Host "[4/4] Creating View Stub Files..." -ForegroundColor Yellow
Write-Host "(Full view implementations to be created next)"
Write-Host ""

# Create view stubs
$views = @("LoginView", "DashboardView", "PatientsView", "PatientProfileView", "AssignExerciseView", "AlertsView", "ReportsView", "SettingsView")

foreach ($view in $views) {
    $viewContent = @"
<template>
  <div class='min-h-screen bg-gradient-light'>
    <h1 class='text-4xl font-bold text-center pt-20'>$view</h1>
    <p class='text-center text-slate-600 mt-4'>View implementation in progress...</p>
  </div>
</template>

<script setup lang='ts'>
// $view implementation
</script>
"@
    if (Write-FileContent "src\views\$view.vue" $viewContent "$view.vue") { $filesCreated++ } else { $errorCount++ }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "File Generation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files Created: $filesCreated" -ForegroundColor Green
Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated files" -ForegroundColor White
Write-Host "  2. Let assistant create full view implementations" -ForegroundColor White
Write-Host "  3. Install missing deps: npm install axios jspdf html2canvas" -ForegroundColor White
Write-Host "  4. Update .env with Supabase credentials" -ForegroundColor White
Write-Host "  5. Run: npm run dev" -ForegroundColor White
Write-Host ""
