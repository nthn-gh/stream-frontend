<template>
  <header class="app-header">
    <div class="header-center">
      <div class="search-bar">
        <AppIcon :icon="Search" size="sm" class="search-icon" />
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
        <AppIcon :icon="Bell" size="lg" />
        <span v-if="unreadCount > 0" class="notification-dot"></span>
      </button>
      <div class="header-avatar">{{ initials }}</div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed, onBeforeUnmount, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'
import { Bell, Search } from 'lucide-vue-next'
import AppIcon from '@/components/shared/AppIcon.vue'

const router = useRouter()
const authStore = useAuthStore()
const alertStore = useAlertStore()
const { therapistProfile, user } = storeToRefs(authStore)
const { unreadCount } = storeToRefs(alertStore)

const searchQuery = ref('')
const now = ref(new Date())
let clockTimer: number | null = null

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
  gap: var(--spacing-6);
  padding: 0 var(--padding-page);
  z-index: 100;
  backdrop-filter: blur(8px);
}
.header-center {
  flex: 1;
  max-width: 360px;
  /* The page title moved out of the app header (PageHeader owns it), so the search
     bar now sits at the start of the bar, like the spec's .topbar. */
  margin: 0;
}
.search-bar {
  display: flex;
  align-items: center;
  gap: var(--spacing-2);
  background: var(--primary-light);
  border: 1px solid var(--border);
  border-radius: var(--radius-full);
  height: 38px;
  padding: 0 var(--spacing-4);
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
  gap: var(--spacing-3);
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
  font-size: 14px;
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
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
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
  top: 10px;
  right: 10px;
  width: 8px;
  height: 8px;
  background: #EF4444;
  border-radius: 50%;
  border: 2px solid var(--bg-header);
}
.header-avatar {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-full);
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
