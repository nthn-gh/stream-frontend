<template>
  <span :class="badgeClasses">
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant: 'success' | 'warning' | 'error' | 'info' | 'neutral'
}

const props = defineProps<Props>()

const badgeClasses = computed(() => {
  const base = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold'
  
  const variants = {
    success: 'bg-success-bg text-success-text',
    warning: 'bg-warning-bg text-warning-text',
    error: 'bg-error-bg text-error-text',
    info: 'bg-blue-100 text-blue-900',
    neutral: 'bg-slate-100 text-slate-700'
  }
  
  return `${base} ${variants[props.variant]}`
})
</script>
