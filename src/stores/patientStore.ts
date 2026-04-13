// STREAM Therapist Dashboard - Patient Store

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase'
import type { Patient, Session, ProgressMetric, SessionNote } from '@/types'

export const usePatientStore = defineStore('patient', () => {
  // State
  const patients = ref<Patient[]>([])
  const selectedPatient = ref<Patient | null>(null)
  const patientSessions = ref<Session[]>([])
  const patientProgress = ref<ProgressMetric[]>([])
  const patientNotes = ref<SessionNote[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Actions
  async function fetchPatients(filters?: { status?: string; search?: string }) {
    isLoading.value = true
    error.value = null

    try {
      let query = supabase.from('patients').select('*').order('name', { ascending: true })

      // Apply filters
      if (filters?.status && filters.status !== 'all') {
        query = query.eq('status', filters.status)
      }

      if (filters?.search) {
        query = query.ilike('name', `%${filters.search}%`)
      }

      const { data, error: fetchError } = await query

      if (fetchError) throw fetchError

      patients.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching patients:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchPatientById(id: string) {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('patients')
        .select('*')
        .eq('id', id)
        .single()

      if (fetchError) throw fetchError

      selectedPatient.value = data
      return data
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching patient:', err)
      return null
    } finally {
      isLoading.value = false
    }
  }

  async function fetchPatientSessions(patientId: string) {
    isLoading.value = true

    try {
      const { data, error: fetchError } = await supabase
        .from('sessions')
        .select(
          `
          *,
          exercise:exercises(name, category)
        `,
        )
        .eq('patient_id', patientId)
        .order('date', { ascending: false })

      if (fetchError) throw fetchError

      patientSessions.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching sessions:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchPatientProgress(patientId: string, startDate?: string, endDate?: string) {
    isLoading.value = true

    try {
      let query = supabase
        .from('progress_metrics')
        .select('*')
        .eq('patient_id', patientId)
        .order('date', { ascending: true })

      if (startDate) {
        query = query.gte('date', startDate)
      }

      if (endDate) {
        query = query.lte('date', endDate)
      }

      const { data, error: fetchError } = await query

      if (fetchError) throw fetchError

      patientProgress.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching progress:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchPatientNotes(patientId: string) {
    isLoading.value = true

    try {
      const { data, error: fetchError } = await supabase
        .from('session_notes')
        .select(
          `
          *,
          therapist:therapist_profiles(name)
        `,
        )
        .eq('patient_id', patientId)
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError

      patientNotes.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching notes:', err)
    } finally {
      isLoading.value = false
    }
  }

  async function addNote(patientId: string, therapistId: string, note: string) {
    isLoading.value = true

    try {
      const { data, error: insertError } = await supabase
        .from('session_notes')
        .insert({
          patient_id: patientId,
          therapist_id: therapistId,
          note,
        })
        .select()
        .single()

      if (insertError) throw insertError

      // Refresh notes
      await fetchPatientNotes(patientId)

      return { success: true, data }
    } catch (err: any) {
      error.value = err.message
      return { success: false, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function updatePatientStatus(patientId: string, status: Patient['status']) {
    isLoading.value = true

    try {
      const { data, error: updateError } = await supabase
        .from('patients')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', patientId)
        .select()
        .single()

      if (updateError) throw updateError

      // Update in local state
      const index = patients.value.findIndex((p) => p.id === patientId)
      if (index !== -1) {
        patients.value[index] = data
      }

      if (selectedPatient.value?.id === patientId) {
        selectedPatient.value = data
      }

      return { success: true }
    } catch (err: any) {
      error.value = err.message
      return { success: false, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function createPatient(
    patientData: {
      name: string
      email: string
      condition: string
      age?: number
      stroke_type?: string
    },
    userId: string,
  ) {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: insertError } = await supabase
        .from('patients')
        .insert({
          user_id: userId,
          name: patientData.name,
          email: patientData.email,
          condition: patientData.condition,
          age: patientData.age,
          stroke_type: patientData.stroke_type || 'Unknown',
          enrolled_date: new Date().toISOString().split('T')[0],
          status: 'active',
          adherence_rate: 0,
          total_sessions: 0,
          avg_accuracy: 0,
          current_streak: 0,
        })
        .select()
        .single()

      if (insertError) throw insertError

      // Add to local state
      patients.value.push(data)

      return { success: true, data }
    } catch (err: any) {
      error.value = err.message
      return { success: false, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  return {
    // State
    patients,
    selectedPatient,
    patientSessions,
    patientProgress,
    patientNotes,
    isLoading,
    error,
    // Actions
    fetchPatients,
    fetchPatientById,
    fetchPatientSessions,
    fetchPatientProgress,
    fetchPatientNotes,
    addNote,
    updatePatientStatus,
    createPatient,
  }
})
