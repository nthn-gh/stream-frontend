import { supabase } from '@/services/supabase'

export async function getTherapistPatientIds(therapistId: string) {
  const { data, error } = await supabase
    .from('patients')
    .select('id')
    .eq('therapist_id', therapistId)

  if (error) {
    throw error
  }

  return (data ?? []).map((row) => row.id)
}

export async function therapistHasPatientAccess(therapistId: string, patientId: string) {
  const { data, error } = await supabase
    .from('patients')
    .select('id')
    .eq('therapist_id', therapistId)
    .eq('id', patientId)
    .limit(1)
    .maybeSingle()

  if (error) {
    throw error
  }

  return Boolean(data)
}
