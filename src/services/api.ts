// STREAM Therapist Dashboard - Axios API Client

import axios, { type AxiosError } from 'axios'
import { supabase } from './supabase'
import { useAuthStore } from '@/stores/authStore'
import router from '@/router'

// Create axios instance
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor - attach auth token
api.interceptors.request.use(
  async (config) => {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (session?.access_token) {
        config.headers.Authorization = `Bearer ${session.access_token}`
      }
    } catch (error) {
      console.error('Error attaching auth token:', error)
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => {
    return response
  },
  async (error: AxiosError) => {
    const authStore = useAuthStore()
    
    // Handle 401 Unauthorized - logout and redirect to login
    if (error.response?.status === 401) {
      console.error('Unauthorized - logging out')
      await authStore.logout()
      router.push('/login')
      return Promise.reject(new Error('Session expired. Please log in again.'))
    }
    
    // Handle 403 Forbidden
    if (error.response?.status === 403) {
      console.error('Forbidden - insufficient permissions')
      return Promise.reject(new Error('You do not have permission to perform this action.'))
    }
    
    // Handle 500 Internal Server Error
    if (error.response?.status === 500) {
      console.error('Server error:', error.response.data)
      return Promise.reject(new Error('Server error. Please try again later.'))
    }
    
    // Handle network errors
    if (!error.response) {
      console.error('Network error:', error.message)
      return Promise.reject(new Error('Network error. Please check your connection.'))
    }
    
    return Promise.reject(error)
  }
)

export default api
