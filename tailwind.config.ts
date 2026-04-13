import type { Config } from 'tailwindcss'

export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        'stream-blue': '#1a9cd8',
        primary: '#0EA5E9',
        'primary-hover': 'rgba(14, 165, 233, 0.9)',
        teal: '#14B8A6',
        navy: '#030213',
        slate: {
          50: '#F8FAFC',
          100: '#F1F5F9',
          200: '#E2E8F0',
          300: '#CBD5E1',
          400: '#94A3B8',
          600: '#475569',
          700: '#334155',
          900: '#0F172A',
        },
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        destructive: '#D4183D',
      },
      boxShadow: {
        sm: '0 1px 2px 0 rgba(0,0,0,0.05)',
        md: '0 1px 3px 0 rgba(0,0,0,0.1), 0 1px 2px -1px rgba(0,0,0,0.1)',
        lg: '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1)',
        xl: '0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1)',
        '2xl': '0 25px 50px -12px rgba(0,0,0,0.25)',
      },
      borderRadius: {
        sm: '6px',
        md: '8px',
        lg: '12px',
        xl: '16px',
        '2xl': '20px',
        full: '9999px',
      },
      zIndex: {
        dropdown: '100',
        sticky: '200',
        fixed: '300',
        'modal-overlay': '1000',
        modal: '1001',
        toast: '9999',
      },
      spacing: {
        '13': '3.25rem',
        '15': '3.75rem',
        '18': '4.5rem',
        '65': '16.25rem',
        '70': '17.5rem',
      },
      width: {
        '70': '17.5rem',
      },
      height: {
        '13': '3.25rem',
        '15': '3.75rem',
        '70': '17.5rem',
      },
    },
  },
  plugins: [],
} satisfies Config
