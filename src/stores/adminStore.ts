/*
 * ============================================================
 * SUPABASE SQL — Run ALL of the following in the Supabase SQL
 * Editor before using this admin panel:
 *
 * -- 1. Add is_active column to therapist_profiles
 * ALTER TABLE therapist_profiles
 *   ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
 *
 * -- 2. Admin RLS policy: SELECT on therapist_profiles
 * CREATE POLICY "Admins can select therapist_profiles"
 *   ON therapist_profiles FOR SELECT
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 3. Admin RLS policy: INSERT on therapist_profiles
 * CREATE POLICY "Admins can insert therapist_profiles"
 *   ON therapist_profiles FOR INSERT
 *   WITH CHECK (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 4. Admin RLS policy: UPDATE on therapist_profiles
 * CREATE POLICY "Admins can update therapist_profiles"
 *   ON therapist_profiles FOR UPDATE
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 5. Admin RLS policy: DELETE on therapist_profiles
 * CREATE POLICY "Admins can delete therapist_profiles"
 *   ON therapist_profiles FOR DELETE
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 6. Admin RLS policy: SELECT on users
 * CREATE POLICY "Admins can select users"
 *   ON users FOR SELECT
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 7. Admin RLS policy: INSERT on users
 * CREATE POLICY "Admins can insert users"
 *   ON users FOR INSERT
 *   WITH CHECK (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 8. Admin RLS policy: UPDATE on users
 * CREATE POLICY "Admins can update users"
 *   ON users FOR UPDATE
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 *
 * -- 9. Admin RLS policy: DELETE on users
 * CREATE POLICY "Admins can delete users"
 *   ON users FOR DELETE
 *   USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
 * ============================================================
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '@/services/supabase'
import type { Database } from '@/services/database.types'

export interface TherapistWithUser {
  id: string
  user_id: string
  name: string
  clinic_name: string | null
  license_number: string | null
  is_active: boolean
  created_at: string
  avatar_url: string | null
  email: string
}

export interface CreateTherapistForm {
  fullName: string
  email: string
  clinicName: string
  licenseNumber: string
  password: string
}

export interface UpdateTherapistForm {
  name: string
  clinicName: string
  licenseNumber: string
  email: string
}

export interface AdminStats {
  totalTherapists: number
  totalPatients: number
  totalActiveSessions: number
}

function createIsolatedSupabaseClient() {
  return createClient<Database>(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  })
}

export const useAdminStore = defineStore('admin', () => {
  const therapists = ref<TherapistWithUser[]>([])
  const stats = ref<AdminStats>({ totalTherapists: 0, totalPatients: 0, totalActiveSessions: 0 })
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function fetchTherapists() {
    isLoading.value = true
    error.value = null
    try {
      const { data, error: fetchError } = await supabase
        .from('therapist_profiles')
        .select('*, users!user_id(id, email, full_name, role)')
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError

      therapists.value = (data ?? []).map((row: any) => ({
        id: row.id,
        user_id: row.user_id,
        name: row.name,
        clinic_name: row.clinic_name,
        license_number: row.license_number,
        is_active: row.is_active !== false,
        created_at: row.created_at,
        avatar_url: row.avatar_url ?? null,
        email: row.users?.email ?? '',
      }))
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch therapists'
    } finally {
      isLoading.value = false
    }
  }

  async function fetchStats() {
    try {
      const [therapistRes, patientRes, sessionRes] = await Promise.all([
        supabase.from('therapist_profiles').select('id', { count: 'exact', head: true }),
        supabase.from('patients').select('id', { count: 'exact', head: true }),
        supabase.from('sessions').select('id', { count: 'exact', head: true }).eq('status', 'in_progress'),
      ])

      stats.value = {
        totalTherapists: therapistRes.count ?? 0,
        totalPatients: patientRes.count ?? 0,
        totalActiveSessions: sessionRes.count ?? 0,
      }
    } catch (err: any) {
      console.error('Failed to fetch admin stats:', err)
    }
  }

  async function createTherapist(form: CreateTherapistForm) {
    isLoading.value = true
    error.value = null
    try {
      const isolatedClient = createIsolatedSupabaseClient()
      const { data: authData, error: authError } = await isolatedClient.auth.signUp({
        email: form.email,
        password: form.password,
        options: {
          data: { role: 'therapist', name: form.fullName },
        },
      })

      if (authError) throw authError
      if (!authData.user) throw new Error('Failed to create auth user.')

      const { error: userError } = await supabase.from('users').upsert(
        {
          id: authData.user.id,
          email: form.email,
          full_name: form.fullName,
          role: 'therapist',
        },
        { onConflict: 'id' },
      )
      if (userError) throw userError

      const { error: profileError } = await supabase.from('therapist_profiles').insert({
        user_id: authData.user.id,
        name: form.fullName,
        clinic_name: form.clinicName || null,
        license_number: form.licenseNumber || null,
      } as any)
      if (profileError) throw profileError

      await fetchTherapists()
      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Failed to create therapist'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function updateTherapist(id: string, data: UpdateTherapistForm) {
    isLoading.value = true
    error.value = null
    try {
      const therapist = therapists.value.find((t) => t.id === id)
      if (!therapist) throw new Error('Therapist not found.')

      const { error: profileError } = await supabase
        .from('therapist_profiles')
        .update({
          name: data.name,
          clinic_name: data.clinicName || null,
          license_number: data.licenseNumber || null,
          updated_at: new Date().toISOString(),
        } as any)
        .eq('id', id)

      if (profileError) throw profileError

      const userUpdatePayload: Record<string, string> = { full_name: data.name }
      if (data.email !== therapist.email) {
        userUpdatePayload.email = data.email
      }

      const { error: userError } = await supabase
        .from('users')
        .update(userUpdatePayload)
        .eq('id', therapist.user_id)
      if (userError) throw userError

      await fetchTherapists()
      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Failed to update therapist'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function deactivateTherapist(id: string) {
    isLoading.value = true
    error.value = null
    try {
      const { error: updateError } = await supabase
        .from('therapist_profiles')
        .update({ is_active: false })
        .eq('id', id)

      if (updateError) throw updateError

      const therapist = therapists.value.find((t) => t.id === id)
      if (therapist) therapist.is_active = false

      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Failed to deactivate therapist'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function reactivateTherapist(id: string) {
    isLoading.value = true
    error.value = null
    try {
      const { error: updateError } = await supabase
        .from('therapist_profiles')
        .update({ is_active: true })
        .eq('id', id)

      if (updateError) throw updateError

      const therapist = therapists.value.find((t) => t.id === id)
      if (therapist) therapist.is_active = true

      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Failed to reactivate therapist'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  return {
    therapists,
    stats,
    isLoading,
    error,
    fetchTherapists,
    fetchStats,
    createTherapist,
    updateTherapist,
    deactivateTherapist,
    reactivateTherapist,
  }
})
