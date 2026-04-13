import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '@/services/supabase'
import { getTherapistPatientIds } from '@/services/therapistScope'
import { useAuthStore } from '@/stores/authStore'
import type { AlertWithPatient } from '@/types'

export const useAlertStore = defineStore('alert', () => {
  const alerts = ref<AlertWithPatient[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  let realtimeChannel: RealtimeChannel | null = null

  const unreadCount = computed(() => alerts.value.filter((alert) => !alert.resolved).length)

  const filteredAlerts = computed(() => {
    return (type?: string) => {
      if (!type || type === 'all') {
        return alerts.value
      }

      return alerts.value.filter((alert) => alert.type === type)
    }
  })

  function getTherapistId() {
    const authStore = useAuthStore()
    return authStore.therapistProfile?.id ?? null
  }

  async function fetchAlerts(filters?: { resolved?: boolean; type?: AlertWithPatient['type'] | 'all' }) {
    isLoading.value = true
    error.value = null

    try {
      const therapistId = getTherapistId()

      if (!therapistId) {
        alerts.value = []
        return []
      }

      const patientIds = await getTherapistPatientIds(therapistId)

      if (patientIds.length === 0) {
        alerts.value = []
        return []
      }

      let query = supabase
        .from('alerts')
        .select(
          `
            id,
            patient_id,
            type,
            priority,
            message,
            resolved,
            created_at,
            resolved_at,
            patient:patients(id, name, email, avatar_url)
          `,
        )
        .in('patient_id', patientIds)
        .order('created_at', { ascending: false })

      if (filters?.type && filters.type !== 'all') {
        query = query.eq('type', filters.type)
      }

      if (filters?.resolved !== undefined) {
        query = query.eq('resolved', filters.resolved)
      }

      const { data, error: fetchError } = await query

      if (fetchError) {
        throw fetchError
      }

      alerts.value = (data ?? []) as unknown as AlertWithPatient[]
      return alerts.value
    } catch (err: any) {
      alerts.value = []
      error.value = err.message || 'Unable to load alerts'
      return []
    } finally {
      isLoading.value = false
    }
  }

  async function resolveAlert(alertId: string) {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: updateError } = await supabase
        .from('alerts')
        .update({
          resolved: true,
          resolved_at: new Date().toISOString(),
        })
        .eq('id', alertId)
        .select('id, patient_id, type, priority, message, resolved, created_at, resolved_at')
        .single()

      if (updateError) {
        throw updateError
      }

      alerts.value = alerts.value.map((alert) =>
        alert.id === alertId ? { ...alert, ...data } : alert,
      )

      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Unable to resolve alert'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  function subscribeRealtime() {
    if (realtimeChannel) {
      realtimeChannel.unsubscribe()
    }

    realtimeChannel = supabase
      .channel('alerts-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'alerts',
        },
        () => {
          void fetchAlerts()
        },
      )
      .subscribe()
  }

  function unsubscribeRealtime() {
    if (realtimeChannel) {
      realtimeChannel.unsubscribe()
      realtimeChannel = null
    }
  }

  return {
    alerts,
    isLoading,
    error,
    unreadCount,
    filteredAlerts,
    fetchAlerts,
    resolveAlert,
    subscribeRealtime,
    unsubscribeRealtime,
  }
})
