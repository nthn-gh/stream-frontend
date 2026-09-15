<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="t-h1">Alerts</h1>
        <p class="text-secondary t-body" style="margin-top: 6px">
          {{ unresolvedCount }} unresolved {{ unresolvedCount === 1 ? 'alert' : 'alerts' }} across your caseload.
        </p>
      </div>
    </div>

    <div class="row" style="display: flex; align-items: center; gap: 12px; margin-bottom: var(--spacing-5); flex-wrap: wrap">
      <button
        type="button"
        class="sl-btn sl-btn-sm severity-chip"
        style="background: var(--color-error-bg); border-color: transparent; color: var(--color-error-text)"
        :class="{ 'is-active': activeFilter === 'high' }"
        @click="toggleFilter('high')"
      >
        High &middot; {{ counts.high }}
      </button>
      <button
        type="button"
        class="sl-btn sl-btn-sm severity-chip"
        style="background: var(--color-warning-bg); border-color: transparent; color: var(--color-warning-text)"
        :class="{ 'is-active': activeFilter === 'moderate' }"
        @click="toggleFilter('moderate')"
      >
        Moderate &middot; {{ counts.moderate }}
      </button>
      <button
        type="button"
        class="sl-btn sl-btn-sm severity-chip"
        style="background: var(--accent-blue-soft); border-color: transparent; color: var(--color-primary)"
        :class="{ 'is-active': activeFilter === 'low' }"
        @click="toggleFilter('low')"
      >
        Low &middot; {{ counts.low }}
      </button>
      <div style="flex: 1"></div>
      <label class="sl-checkbox-row">
        <input v-model="showResolved" type="checkbox" />
        Show resolved
      </label>
    </div>

    <div v-if="error" class="sl-badge sl-badge-error" style="margin-bottom: var(--spacing-4); display: flex">
      {{ error }}
    </div>

    <div v-if="isLoading" class="stack" style="display: flex; flex-direction: column; gap: 16px">
      <AppSkeleton variant="card" height="100px" />
      <AppSkeleton variant="card" height="100px" />
      <AppSkeleton variant="card" height="100px" />
    </div>

    <div v-else-if="displayedAlerts.length === 0" class="sl-card sl-empty-state">
      <CheckCircle :size="40" style="color: var(--color-success); margin-bottom: var(--spacing-4)" />
      <p class="t-body-md">No alerts to show.</p>
      <p class="t-body-sm text-secondary" style="margin-top: 4px">All patients are on track, or try a different filter.</p>
    </div>

    <div v-else style="display: flex; flex-direction: column; gap: var(--spacing-4)">
      <div
        v-for="alert in displayedAlerts"
        :key="alert.id"
        class="sl-alert-item"
        :class="[`sev-${alert.priority}`, { 'is-resolved': alert.resolved }]"
      >
        <div class="sl-alert-item__icon" :style="{ background: iconBg(alert.type) }">
          <component :is="alertIcon(alert.type)" :size="20" :style="{ color: iconColor(alert.type) }" />
        </div>
        <div style="flex: 1; display: flex; flex-direction: column; gap: 8px">
          <div style="display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap">
            <strong class="t-body-md">{{ alert.patient?.name || 'Unknown patient' }}</strong>
            <span class="t-caption">{{ formatTimestamp(alert.created_at) }}</span>
          </div>
          <p class="t-body-sm text-secondary">{{ alert.message }}</p>
          <div v-if="alert.resolved" class="row" style="margin-top: 4px">
            <span class="sl-badge sl-badge-neutral">Resolved</span>
          </div>
          <div v-else class="row" style="display: flex; gap: 8px; margin-top: 4px">
            <AppButton size="small" @click="viewPatient(alert.patient_id)">View patient</AppButton>
            <AppButton variant="secondary" size="small" :loading="resolvingId === alert.id" @click="handleResolve(alert.id)">
              Mark resolved
            </AppButton>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { AlertCircle, AlertTriangle, Info, CheckCircle } from 'lucide-vue-next'
import { useAlertStore } from '@/stores/alertStore'
import { storeToRefs } from 'pinia'
import AppButton from '@/components/shared/AppButton.vue'
import AppSkeleton from '@/components/shared/AppSkeleton.vue'
import type { AlertWithPatient } from '@/types'

const router = useRouter()
const alertStore = useAlertStore()

const { alerts, isLoading, error } = storeToRefs(alertStore)

// DB CHECK constraint for alerts.priority is (high, moderate, low) --
// the previous version of this view filtered on 'medium', which never
// matches a real row, silently dropping every moderate-priority alert
// from its severity coloring/filter.
const activeFilter = ref<'high' | 'moderate' | 'low' | null>(null)
const showResolved = ref(false)
const resolvingId = ref<string | null>(null)

const unresolvedCount = computed(() => alerts.value.filter((a) => !a.resolved).length)

const counts = computed(() => ({
  high: alerts.value.filter((a) => !a.resolved && a.priority === 'high').length,
  moderate: alerts.value.filter((a) => !a.resolved && a.priority === 'moderate').length,
  low: alerts.value.filter((a) => !a.resolved && a.priority === 'low').length,
}))

const displayedAlerts = computed(() => {
  return alerts.value.filter((alert: AlertWithPatient) => {
    if (!showResolved.value && alert.resolved) return false
    if (activeFilter.value && alert.priority !== activeFilter.value) return false
    return true
  })
})

function toggleFilter(priority: 'high' | 'moderate' | 'low') {
  activeFilter.value = activeFilter.value === priority ? null : priority
}

// alerts.type CHECK constraint is (missed_session, low_performance,
// technical_issue) -- the previous version matched 'low_adherence' and
// 'critical', neither of which is a real value, so those two branches
// never fired and every alert fell through to the generic/info icon.
function alertIcon(type: string) {
  if (type === 'missed_session') return AlertCircle
  if (type === 'low_performance') return AlertTriangle
  if (type === 'technical_issue') return Info
  return Info
}

function iconBg(type: string) {
  if (type === 'missed_session') return 'var(--color-error-bg)'
  if (type === 'low_performance') return 'var(--color-warning-bg)'
  return 'var(--accent-blue-soft)'
}

function iconColor(type: string) {
  if (type === 'missed_session') return 'var(--color-error)'
  if (type === 'low_performance') return 'var(--color-warning)'
  return 'var(--color-primary)'
}

function formatTimestamp(timestamp: string | null) {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  const diffMs = Date.now() - date.getTime()
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffHours < 1) return 'Just now'
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

function viewPatient(patientId: string) {
  router.push(`/patients/${patientId}`)
}

async function handleResolve(alertId: string) {
  resolvingId.value = alertId
  try {
    await alertStore.resolveAlert(alertId)
  } finally {
    resolvingId.value = null
  }
}

onMounted(async () => {
  await alertStore.fetchAlerts()
  alertStore.subscribeRealtime()
})

onBeforeUnmount(() => {
  alertStore.unsubscribeRealtime()
})
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--spacing-4);
  margin-bottom: var(--spacing-8);
}
.severity-chip {
  cursor: pointer;
  opacity: 0.55;
  transition: opacity 0.15s ease;
}
.severity-chip:hover,
.severity-chip.is-active {
  opacity: 1;
}
.sl-alert-item.is-resolved {
  opacity: 0.7;
}
</style>
