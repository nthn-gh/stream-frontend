<template>
  <aside class="sidebar">
    <!-- Logo -->
    <div class="sidebar-logo">
      <img :src="logoMark" alt="" aria-hidden="true" class="logo-mark" />
      <span class="logo-text">STREAM</span>
    </div>

    <!-- Nav -->
    <nav class="sidebar-nav">
      <div class="nav-section-label">MAIN MENU</div>
      <router-link to="/dashboard" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="LayoutDashboard" />
        <span>Dashboard</span>
      </router-link>
      <router-link to="/patients" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="Users" />
        <span>Patients</span>
      </router-link>

      <div class="nav-section-label" style="margin-top: var(--spacing-4)">MANAGEMENT</div>
      <router-link to="/assign-exercise" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="ClipboardCheck" />
        <span>Assign Exercise</span>
      </router-link>
      <router-link to="/alerts" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="Bell" />
        <span>Alerts</span>
        <span v-if="unreadCount > 0" class="nav-badge">{{ unreadCount }}</span>
      </router-link>
      <router-link to="/messages" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="MessageSquare" />
        <span>Messages</span>
        <span v-if="unreadMessageCount > 0" class="nav-badge">{{ unreadMessageCount }}</span>
      </router-link>
      <router-link to="/reports" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="FileText" />
        <span>Reports</span>
      </router-link>

      <template v-if="user?.role === 'admin'">
        <div class="nav-section-label" style="margin-top: var(--spacing-4)">ADMINISTRATION</div>
        <router-link to="/admin" class="nav-item" active-class="nav-item--active">
          <AppIcon :icon="ShieldCheck" />
          <span>Admin Panel</span>
        </router-link>
      </template>

      <div class="nav-section-label" style="margin-top: var(--spacing-4)">SETTINGS</div>
      <router-link to="/settings" class="nav-item" active-class="nav-item--active">
        <AppIcon :icon="Settings" />
        <span>Settings</span>
      </router-link>
    </nav>

    <!-- User -->
    <div class="sidebar-user">
      <div class="user-avatar">{{ initials }}</div>
      <div class="user-info">
        <div class="user-name">{{ therapistProfile?.name || user?.full_name || 'Admin' }}</div>
        <div class="user-role">{{ user?.role === 'admin' ? 'Admin' : 'Therapist' }}</div>
      </div>
      <button class="logout-btn" title="Logout" aria-label="Logout" @click="handleLogout">
        <AppIcon :icon="LogOut" size="lg" />
      </button>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'
import { useAlertStore } from '@/stores/alertStore'
import { useMessageStore } from '@/stores/messageStore'
import { usePatientStore } from '@/stores/patientStore'
import { storeToRefs } from 'pinia'
import logoMark from '@/assets/brand/stream-mark.png'
import AppIcon from '@/components/shared/AppIcon.vue'
import { Bell, ClipboardCheck, FileText, LayoutDashboard, LogOut, MessageSquare, Settings, ShieldCheck, Users } from 'lucide-vue-next'

const router = useRouter()
const authStore = useAuthStore()
const alertStore = useAlertStore()
const messageStore = useMessageStore()
const patientStore = usePatientStore()
const { therapistProfile, user } = storeToRefs(authStore)
const { unreadCount } = storeToRefs(alertStore)
const { patients } = storeToRefs(patientStore)

// Populated once DashboardView (the post-login landing route) has
// fetched message threads -- same singleton-store pattern unreadCount
// above relies on for the Alerts badge.
const unreadMessageCount = computed(() =>
  patients.value.reduce((sum, patient) => {
    if (!patient.user_id) return sum
    return sum + messageStore.unreadCountFor(patient.user_id)
  }, 0),
)

const initials = computed(() => {
  const name = therapistProfile.value?.name || user.value?.full_name
  if (!name) return 'AD'
  const parts = name.split(' ')
  return parts
    .map((p) => p[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
})

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  top: 0;
  left: 0;
  width: var(--sidebar-width);
  height: 100vh;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  z-index: 200;
  box-shadow: var(--shadow-sidebar);
}
.sidebar-logo {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);
  padding: 0 var(--spacing-5);
  height: var(--header-height);
  border-bottom: 1px solid var(--border);
  flex-shrink: 0;
}
.logo-mark {
  width: 36px;
  height: 36px;
  object-fit: contain;
  flex-shrink: 0;
}
.logo-text {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--text-primary);
}
.sidebar-nav {
  flex: 1;
  overflow-y: auto;
  padding: var(--spacing-4) var(--spacing-3);
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.nav-section-label {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  padding: var(--spacing-3) var(--spacing-3) var(--spacing-1);
  text-transform: uppercase;
}
.nav-item {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);
  height: 44px;
  padding: 0 var(--spacing-3);
  border-radius: var(--radius-md);
  text-decoration: none;
  color: var(--text-secondary);
  font-size: 14px;
  font-weight: 500;
  transition: background 0.15s, color 0.15s;
  position: relative;
}
.nav-item:hover {
  background: var(--bg-hover);
  color: var(--primary);
}
.nav-item--active {
  background: var(--gradient-primary);
  color: white !important;
}
.nav-badge {
  margin-left: auto;
  background: #EF4444;
  color: white;
  font-size: 12px;
  font-weight: 600;
  min-width: 20px;
  height: 20px;
  border-radius: var(--radius-full);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 6px;
}
.sidebar-user {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);
  padding: var(--spacing-4) var(--spacing-4);
  border-top: 1px solid var(--border);
  flex-shrink: 0;
}
.user-avatar {
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
  flex-shrink: 0;
}
.user-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}
.user-role {
  font-size: 12px;
  color: var(--text-muted);
}
.user-info {
  flex: 1;
  min-width: 0;
}
.logout-btn {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-muted);
  padding: var(--spacing-2);
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 44px;
  height: 44px;
  transition: background 0.15s, color 0.15s;
}
.logout-btn:hover {
  background: var(--status-danger-bg);
  color: #EF4444;
}
</style>
