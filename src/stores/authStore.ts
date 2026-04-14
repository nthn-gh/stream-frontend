import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '@/services/supabase'
import type { Database } from '@/services/database.types'
import type { TherapistProfile, TherapistProfileUpdate, User } from '@/types'

type AllowedProfileUpdates = Pick<
  TherapistProfileUpdate,
  'avatar_url' | 'clinic_name' | 'email_alerts' | 'in_app_alerts' | 'license_number' | 'name' | 'weekly_summary'
>

function createIsolatedSupabaseClient() {
  return createClient<Database>(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  })
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const therapistProfile = ref<TherapistProfile | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => Boolean(user.value))
  const isTherapist = computed(() => user.value?.role === 'therapist')

  function clearState() {
    user.value = null
    therapistProfile.value = null
  }

  async function loadTherapistUser(userId: string) {
    const { data, error: userError } = await supabase.from('users').select('*').eq('id', userId).maybeSingle()

    if (userError) {
      throw userError
    }

    if (!data) {
      throw new Error('No matching record was found in public.users for this account.')
    }

    if (data.role !== 'therapist') {
      throw new Error('Access denied. Therapist account required.')
    }

    return data as User
  }

  async function loadTherapistProfile(userId: string) {
    const { data, error: profileError } = await supabase
      .from('therapist_profiles')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle()

    if (profileError) {
      throw profileError
    }

    if (!data) {
      throw new Error('Therapist profile not found in public.therapist_profiles.')
    }

    return data as TherapistProfile
  }

  async function hydrateTherapistSession(userId: string) {
    const [userData, profileData] = await Promise.all([loadTherapistUser(userId), loadTherapistProfile(userId)])

    user.value = userData
    therapistProfile.value = profileData

    return { user: userData, profile: profileData }
  }

  async function login(email: string, password: string) {
    isLoading.value = true
    error.value = null

    try {
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (authError) {
        throw authError
      }

      if (!authData.user) {
        throw new Error('Login failed. No auth user was returned.')
      }

      await hydrateTherapistSession(authData.user.id)

      return { success: true as const }
    } catch (err: any) {
      clearState()
      error.value = err.message || 'Login failed'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function logout() {
    isLoading.value = true

    try {
      await supabase.auth.signOut()
    } finally {
      clearState()
      isLoading.value = false
    }
  }

  async function fetchProfile() {
    if (!user.value) {
      return null
    }

    isLoading.value = true

    try {
      therapistProfile.value = await loadTherapistProfile(user.value.id)
      return therapistProfile.value
    } catch (err: any) {
      error.value = err.message || 'Unable to load therapist profile'
      return null
    } finally {
      isLoading.value = false
    }
  }

  async function updateProfile(updates: AllowedProfileUpdates) {
    if (!therapistProfile.value || !user.value) {
      return { success: false as const, error: 'Therapist profile is not loaded.' }
    }

    isLoading.value = true
    error.value = null

    try {
      const payload: AllowedProfileUpdates & { updated_at: string } = {
        ...updates,
        updated_at: new Date().toISOString(),
      }

      const { error: userUpdateError } = await supabase
        .from('users')
        .update({
          full_name: updates.name ?? therapistProfile.value.name,
        })
        .eq('id', user.value.id)

      if (userUpdateError) {
        throw userUpdateError
      }

      const { data, error: updateError } = await supabase
        .from('therapist_profiles')
        .update(payload)
        .eq('id', therapistProfile.value.id)
        .select('*')
        .single()

      if (updateError) {
        throw updateError
      }

      therapistProfile.value = data as TherapistProfile
      user.value = {
        ...user.value,
        full_name: therapistProfile.value.name,
      }
      return { success: true as const, data: therapistProfile.value }
    } catch (err: any) {
      error.value = err.message || 'Unable to update therapist profile'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function changePassword(_currentPassword: string, newPassword: string) {
    isLoading.value = true
    error.value = null

    try {
      const { error: passwordError } = await supabase.auth.updateUser({
        password: newPassword,
      })

      if (passwordError) {
        throw passwordError
      }

      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Unable to update password'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  async function checkAuth() {
    isLoading.value = true
    error.value = null

    try {
      const {
        data: { session },
      } = await supabase.auth.getSession()

      if (!session?.user?.id) {
        clearState()
        return false
      }

      await hydrateTherapistSession(session.user.id)
      return true
    } catch (err: any) {
      clearState()
      error.value = err.message || 'Unable to validate session'
      return false
    } finally {
      isLoading.value = false
    }
  }

  async function register(
    email: string,
    password: string,
    name: string,
    clinicName: string,
    licenseNumber?: string,
  ) {
    isLoading.value = true
    error.value = null

    try {
      const isolatedClient = createIsolatedSupabaseClient()
      const { data: authData, error: authError } = await isolatedClient.auth.signUp({
        email,
        password,
        options: {
          data: {
            role: 'therapist',
            name,
          },
        },
      })

      if (authError) {
        throw authError
      }

      if (!authData.user) {
        throw new Error('Registration failed. No auth user was created.')
      }

      const therapistEmail = authData.user.email ?? email
      const authenticatedClient = authData.session ? isolatedClient : supabase

      const { error: userError } = await authenticatedClient.from('users').upsert(
        {
          id: authData.user.id,
          email: therapistEmail,
          full_name: name,
          role: 'therapist',
        },
        { onConflict: 'id' },
      )

      if (userError) {
        throw userError
      }

      const { error: profileError } = await authenticatedClient.from('therapist_profiles').upsert(
        {
          user_id: authData.user.id,
          name,
          clinic_name: clinicName || null,
          license_number: licenseNumber || null,
        },
        { onConflict: 'user_id' },
      )

      if (profileError) {
        throw profileError
      }

      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Registration failed'
      return { success: false as const, error: error.value }
    } finally {
      isLoading.value = false
    }
  }

  return {
    user,
    therapistProfile,
    isLoading,
    error,
    isAuthenticated,
    isTherapist,
    login,
    logout,
    fetchProfile,
    updateProfile,
    changePassword,
    checkAuth,
    register,
  }
})
