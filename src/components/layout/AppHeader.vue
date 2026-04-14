<template>
  <header class="app-header">
    <div class="header-left">
      <h1 class="page-title">{{ pageTitle }}</h1>
    </div>
    <div class="header-center">
      <div class="search-bar">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <circle cx="11" cy="11" r="8"/>
          <path d="m21 21-4.35-4.35"/>
        </svg>
        <input 
          v-model="searchQuery" 
          type="search" 
          placeholder="Search patients..." 
          aria-label="Search patients"
          @keyup.enter="handleSearch" 
        />
      </div>
    </div>
    <div class="header-right">
      <div class="header-clock">
        <div class="header-date">{{ today }}</div>
        <div class="header-time">{{ currentTime }}</div>
      </div>
      <button class="icon-btn" aria-label="Notifications" @click="$router.push('/alerts')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="20" height="20">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <span v-if="unreadCount > 0" class="notification-dot"></span>
      </button>
      <div class="header-avatar">{{ initials }}</div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed, onBeforeUnmount, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const alertStore = useAlertStore()
const { therapistProfile, user } = storeToRefs(authStore)
const { unreadCount } = storeToRefs(alertStore)

const searchQuery = ref('')
const now = ref(new Date())
let clockTimer: number | null = null

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/patients': 'Patients',
  '/assign-exercise': 'Assign Exercise',
  '/alerts': 'Alerts',
  '/reports': 'Reports',
  '/settings': 'Settings',
}

const pageTitle = computed(() => {
  const path = route.path
  if (path.startsWith('/patients/') && path !== '/patients') {
    return 'Patient Profile'
  }
  return pageTitles[path] || 'STREAM'
})

const today = computed(() =>
  now.value.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }),
)

const currentTime = computed(() =>
  now.value.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  }),
)

const initials = computed(() => {
  const displayName = therapistProfile.value?.name || user.value?.full_name || 'Therapist'
  const parts = displayName.split(' ')
  return parts
    .map((p) => p[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
})

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    router.push({ path: '/patients', query: { search: searchQuery.value } })
  }
}

onMounted(() => {
  clockTimer = window.setInterval(() => {
    now.value = new Date()
  }, 1000)
})

onBeforeUnmount(() => {
  if (clockTimer !== null) {
    window.clearInterval(clockTimer)
  }
})
</script>

<style scoped>
.app-header {
  position: fixed;
  top: 0;
  left: var(--sidebar-width);
  right: 0;
  height: var(--header-height);
  background: var(--bg-header);
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: var(--space-6);
  padding: 0 var(--padding-page);
  z-index: 100;
  backdrop-filter: blur(8px);
}
.header-left {
  flex-shrink: 0;
}
.page-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
}
.header-center {
  flex: 1;
  max-width: 360px;
  margin: 0 auto;
}
.search-bar {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  background: var(--primary-light);
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  height: 38px;
  padding: 0 var(--space-4);
}
.search-bar input {
  flex: 1;
  border: none;
  background: transparent;
  font: inherit;
  font-size: 14px;
  color: var(--text-primary);
  outline: none;
}
.search-bar input::placeholder {
  color: var(--text-muted);
}
.search-icon {
  color: var(--text-muted);
  flex-shrink: 0;
}
.header-right {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-left: auto;
}
.header-clock {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  white-space: nowrap;
}

.header-date {
  font-size: 13px;
  color: var(--text-muted);
}

.header-time {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-primary);
}
.icon-btn {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-secondary);
  width: 40px;
  height: 40px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s;
  position: relative;
}
.icon-btn:hover {
  background: var(--bg-hover);
  color: var(--primary);
}
.notification-dot {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 8px;
  height: 8px;
  background: #EF4444;
  border-radius: 50%;
  border: 2px solid var(--bg-header);
}
.header-avatar {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-pill);
  background: var(--gradient-primary);
  color: white;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
</style>
