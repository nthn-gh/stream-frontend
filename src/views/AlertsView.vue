<template>
  <div class="page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2" style="display: flex; align-items: center; gap: var(--space-2);">
          Movement Alerts
          <span v-if="unreadCount > 0" class="unread-badge">
            {{ unreadCount }} Unread
          </span>
        </h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px;">Monitor patient issues and take action</p>
      </div>
      
      <div class="filter-tabs">
        <button
          v-for="filter in filters"
          :key="filter.key"
          @click="activeFilter = filter.key"
          class="filter-tab"
          :class="{ 'filter-tab--active': activeFilter === filter.key }"
        >
          {{ filter.label }}
        </button>
      </div>
    </div>
    
    <!-- Content Area -->
    <div class="alerts-content">
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
      </div>
      
      <div v-else-if="displayedAlerts.length === 0" class="empty-state">
        <div class="empty-icon">
          <CheckCircle :size="48" style="color: #10B981;" />
        </div>
        <h3 class="h3" style="margin-bottom: var(--space-1);">No alerts right now</h3>
        <p style="color: var(--text-muted);">All patients are on track. Great work!</p>
      </div>
      
      <div v-else class="alert-cards">
        <div
          v-for="alert in displayedAlerts"
          :key="alert.id"
          class="alert-card"
          :class="{ 'alert-card--resolved': alert.resolved }"
          :style="{ borderLeftColor: !alert.resolved ? getSeverityColor(alert.priority) : 'var(--border)' }"
        >
          <div class="alert-card-header">
            <div class="alert-icon" :style="{ background: getIconBackground(alert.type) }">
              <component :is="getAlertIcon(alert.type)" :size="20" style="color: white;" />
            </div>
            
            <div class="alert-card-body">
              <div class="alert-card-top">
                <div class="alert-patient">
                  <h3 class="h4">{{ alert.patient?.name || 'Unknown Patient' }}</h3>
                  <BaseBadge :variant="getPriorityVariant(alert.priority)">
                    {{ alert.priority.toUpperCase() }}
                  </BaseBadge>
                </div>
                
                <div class="alert-actions">
                  <button class="btn-ghost" @click="viewPatient(alert.patient_id)">
                    View Patient
                  </button>
                  <button
                    v-if="!alert.resolved"
                    class="btn-primary"
                    @click="handleResolve(alert.id)"
                  >
                    Mark Resolved
                  </button>
                </div>
              </div>
              
              <p class="alert-message">{{ alert.message }}</p>
              <p class="caption" style="color: var(--text-muted); margin-top: var(--space-1);">
                {{ formatTimestamp(alert.created_at) }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { AlertCircle, Activity, Clock, CheckCircle } from 'lucide-vue-next'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'
import BaseCard from '@/components/shared/BaseCard.vue'
import BaseBadge from '@/components/shared/BaseBadge.vue'

const router = useRouter()
const alertStore = useAlertStore()

const { alerts, isLoading, unreadCount } = storeToRefs(alertStore)

const activeFilter = ref('all')

const filters = [
  { key: 'all', label: 'All' },
  { key: 'unread', label: 'Unread' },
  { key: 'high', label: 'High Priority' },
  { key: 'resolved', label: 'Resolved' }
]

const displayedAlerts = computed(() => {
  let result = alerts.value

  if (activeFilter.value === 'unread') {
    result = result.filter(a => !a.resolved)
  } else if (activeFilter.value === 'high') {
    result = result.filter(a => a.priority === 'high')
  } else if (activeFilter.value === 'resolved') {
    result = result.filter(a => a.resolved)
  }

  return result
})

const getAlertIcon = (type: string) => {
  switch (type) {
    case 'missed_session':
      return Clock
    case 'low_adherence':
      return Activity
    case 'critical':
      return AlertCircle
    default:
      return AlertCircle
  }
}

const getIconBackground = (type: string) => {
  switch (type) {
    case 'missed_session':
      return 'var(--gradient-warning)'
    case 'low_adherence':
      return 'var(--gradient-danger)'
    case 'critical':
      return 'var(--gradient-danger)'
    default:
      return 'var(--gradient-info)'
  }
}

const getSeverityColor = (priority: string) => {
  if (priority === 'high') return '#EF4444'
  if (priority === 'medium') return '#F59E0B'
  return '#3B82F6'
}

const getPriorityVariant = (priority: string): 'active' | 'warning' | 'danger' | 'info' | 'neutral' => {
  if (priority === 'high') return 'danger'
  if (priority === 'medium') return 'warning'
  return 'info'
}

const formatTimestamp = (timestamp: string) => {
  const date = new Date(timestamp)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffHours < 1) return 'Just now'
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const viewPatient = (patientId: string) => {
  router.push(`/patients/${patientId}`)
}

const handleResolve = async (alertId: string) => {
  await alertStore.resolveAlert(alertId)
}

onMounted(async () => {
  await alertStore.fetchAlerts()
})
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
.unread-badge {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: var(--radius-pill);
  background: var(--status-danger-bg);
  color: var(--status-danger-text);
}
.filter-tabs {
  display: flex;
  gap: var(--space-2);
}
.filter-tab {
  height: 36px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-secondary);
  font: inherit;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}
.filter-tab:hover {
  border-color: var(--primary);
  color: var(--primary);
}
.filter-tab--active {
  background: var(--gradient-primary);
  color: white;
  border-color: transparent;
}
.alerts-content {
  flex: 1;
}
.loading-state {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
.empty-state {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-height: 400px;
  text-align: center;
  padding: var(--space-12) var(--space-4);
  background: var(--bg-card);
  border: 1px solid rgba(226, 232, 240, 0.6);
  border-radius: var(--radius-lg);
}
.empty-icon {
  width: 64px;
  height: 64px;
  border-radius: var(--radius-pill);
  background: var(--status-active-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto var(--space-4);
}
.alert-cards {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}
.alert-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: var(--space-5);
  box-shadow: var(--shadow-card);
  border: 1px solid rgba(226, 232, 240, 0.6);
  border-left: 4px solid;
  transition: all 0.15s;
}
.alert-card:hover {
  box-shadow: var(--shadow-elevated);
}
.alert-card--resolved {
  opacity: 0.7;
}
.alert-card-header {
  display: flex;
  gap: var(--space-4);
}
.alert-icon {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.alert-card-body {
  flex: 1;
  min-width: 0;
}
.alert-card-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-4);
  margin-bottom: var(--space-2);
}
.alert-patient {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1;
  min-width: 0;
}
.alert-actions {
  display: flex;
  gap: var(--space-2);
  flex-shrink: 0;
}
.alert-message {
  color: var(--text-secondary);
  margin-bottom: var(--space-1);
}
.btn-primary {
  background: var(--gradient-primary);
  color: white;
  border: none;
  cursor: pointer;
  height: 36px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  transition: opacity 0.15s;
}
.btn-primary:hover {
  opacity: 0.9;
}
.btn-ghost {
  background: none;
  border: 1px solid var(--border);
  cursor: pointer;
  height: 36px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 13px;
  color: var(--primary);
  font-weight: 600;
  transition: background 0.15s, border-color 0.15s;
}
.btn-ghost:hover {
  background: var(--primary-light);
  border-color: var(--primary);
}
</style>
