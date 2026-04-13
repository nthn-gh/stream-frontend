<template>
  <button
    :class="buttonClasses"
    :disabled="disabled || loading"
    :type="type"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="inline-block mr-2 animate-spin">
      <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    </span>
    <slot />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary' | 'destructive' | 'icon'
  size?: 'small' | 'medium' | 'large'
  disabled?: boolean
  loading?: boolean
  type?: 'button' | 'submit' | 'reset'
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'medium',
  disabled: false,
  loading: false,
  type: 'button'
})

defineEmits<{
  click: [event: MouseEvent]
}>()

const buttonClasses = computed(() => {
  const base = 'inline-flex items-center justify-center font-semibold transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-60'
  
  const variants = {
    primary: 'bg-primary text-white hover:bg-primary-hover active:scale-[0.98] shadow-sm',
    secondary: 'bg-white border border-slate-200 text-slate-900 hover:bg-slate-50 hover:border-slate-300',
    destructive: 'bg-error text-white hover:bg-red-600 shadow-sm',
    icon: 'bg-transparent hover:bg-slate-100 text-slate-700'
  }
  
  const sizes = {
    small: props.variant === 'icon' ? 'w-9 h-9 rounded-lg' : 'h-9 px-4 text-sm rounded-lg',
    medium: props.variant === 'icon' ? 'w-10 h-10 rounded-xl' : 'h-11 px-6 text-base rounded-xl',
    large: props.variant === 'icon' ? 'w-12 h-12 rounded-xl' : 'h-13 px-8 text-lg rounded-xl'
  }
  
  return `${base} ${variants[props.variant]} ${sizes[props.size]}`
})
</script>
