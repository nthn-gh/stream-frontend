import { ref, watch, onMounted } from 'vue'

export type Theme = 'light' | 'dark' | 'system'

const THEME_STORAGE_KEY = 'stream-theme'

// Shared state across all components
const theme = ref<Theme>('light')
const effectiveTheme = ref<'light' | 'dark'>('light')

export function useTheme() {
  const setTheme = (newTheme: Theme) => {
    theme.value = newTheme
    localStorage.setItem(THEME_STORAGE_KEY, newTheme)
    applyTheme(newTheme)
  }

  const applyTheme = (selectedTheme: Theme) => {
    let appliedTheme: 'light' | 'dark' = 'light'

    if (selectedTheme === 'system') {
      appliedTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    } else {
      appliedTheme = selectedTheme
    }

    effectiveTheme.value = appliedTheme

    // Apply or remove dark class on document element
    if (appliedTheme === 'dark') {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

  const initTheme = () => {
    // Load saved theme from localStorage
    const savedTheme = localStorage.getItem(THEME_STORAGE_KEY) as Theme | null
    
    if (savedTheme && ['light', 'dark', 'system'].includes(savedTheme)) {
      theme.value = savedTheme
    } else {
      // Default to system preference
      theme.value = 'system'
    }

    applyTheme(theme.value)

    // Listen for system theme changes when in system mode
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = () => {
      if (theme.value === 'system') {
        applyTheme('system')
      }
    }
    mediaQuery.addEventListener('change', handleChange)

    // Cleanup
    return () => {
      mediaQuery.removeEventListener('change', handleChange)
    }
  }

  return {
    theme,
    effectiveTheme,
    setTheme,
    initTheme,
  }
}
