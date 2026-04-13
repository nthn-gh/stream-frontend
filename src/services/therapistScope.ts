import { supabase } from '@/services/supabase'

export async function getTherapistPatientIds(therapistId: string) {
  const { data, error } = await supabase
    .from('exercise_plans')
    .select('patient_id')
    .eq('therapist_id', therapistId)

  if (error) {
    throw error
  }

  return [...new Set((data ?? []).map((row) => row.patient_id))]
}

export async function therapistHasPatientAccess(therapistId: string, patientId: string) {
  const { data, error } = await supabase
    .from('exercise_plans')
    .select('id')
    .eq('therapist_id', therapistId)
    .eq('patient_id', patientId)
    .limit(1)
    .maybeSingle()

  if (error) {
    throw error
  }

  return Boolean(data)
}
