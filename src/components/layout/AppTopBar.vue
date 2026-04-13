<template>
  <header
    class="flex-shrink-0 px-6 flex items-center z-[90]"
    style="height: 60px; background: var(--bg-header); backdrop-filter: blur(8px); border-bottom: 1px solid var(--border);"
  >
    <!-- Search (centered) -->
    <div class="flex-1 flex justify-center">
      <div class="relative" style="width: 360px;">
        <Search :size="16" class="absolute left-3 top-1/2 -translate-y-1/2" style="color: var(--text-muted);" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search patients..."
          class="w-full pl-10 pr-4 text-sm focus:outline-none"
          style="height: 38px; background: var(--primary-light); border: 1px solid var(--border); border-radius: var(--radius-pill); color: var(--text-primary);"
          @keyup.enter="handleSearch"
        />
      </div>
    </div>

    <!-- Right Section -->
    <div class="flex items-center gap-4">
      <button class="relative" style="min-width: 44px; min-height: 44px; display: flex; align-items: center; justify-content: center;">
        <Bell :size="20" style="color: var(--text-secondary);" />
        <span
          v-if="unreadAlerts > 0"
          class="w-2 h-2 rounded-full absolute top-2 right-2"
          style="background: #EF4444;"
        ></span>
      </button>

      <div class="w-px h-6" style="background: var(--border);"></div>

      <div class="flex items-center gap-2">
        <div
          class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold gradient-primary"
          style="color: var(--text-on-primary);"
        >
          {{ initials }}
        </div>
        <div>
          <p class="text-sm font-semibold" style="color: var(--text-primary);">
            {{ therapistProfile?.name || 'Therapist' }}
          </p>
          <p class="text-xs" style="color: var(--text-muted);">Therapist</p>
        </div>
        <button @click="showUserMenu = !showUserMenu" style="min-width: 44px; min-height: 44px; display: flex; align-items: center; justify-content: center;">
          <ChevronDown :size="16" style="color: var(--text-muted);" />
        </button>
      </div>
    </div>

    <!-- User Menu Dropdown -->
    <div
      v-if="showUserMenu"
      class="absolute right-6 py-2 z-[100]"
      style="top: 60px; width: 176px; background: var(--bg-card); border-radius: var(--radius-lg); box-shadow: var(--shadow-elevated); border: 1px solid var(--border);"
    >
      <router-link to="/settings" class="block px-4 py-2 text-sm" style="color: var(--text-secondary);" @mouseover="(e) => e.currentTarget.style.background = 'var(--bg-hover)'" @mouseleave="(e) => e.currentTarget.style.background = 'transparent'"
        >Settings</router-link
      >
      <button
        @click="handleLogout"
        class="w-full text-left px-4 py-2 text-sm"
        style="color: var(--text-secondary);"
        @mouseover="(e) => e.currentTarget.style.background = 'var(--bg-hover)'"
        @mouseleave="(e) => e.currentTarget.style.background = 'transparent'"
      >
        Logout
      </button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Bell, ChevronDown } from 'lucide-vue-next'
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

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>
