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
  const base = 'app-button inline-flex items-center justify-center font-semibold transition-all duration-150 disabled:cursor-not-allowed disabled:opacity-60'

  const variants = {
    primary: 'app-button--primary text-white active:scale-[0.98] shadow-sm',
    secondary: 'app-button--secondary border',
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

<style scoped>
/* Primary variant and its focus ring go through the canonical CSS var
   token (--primary), not a Tailwind utility, so they track main.css's
   corrected value automatically. Ring-offset uses --bg-card instead of
   Tailwind's hardcoded white so it still shows correctly in dark mode. */
.app-button--primary {
  background: var(--primary);
}
.app-button--primary:hover:not(:disabled) {
  opacity: 0.9;
}
/* Secondary variant: same reasoning as primary above -- was
   bg-white/border-slate-200/text-slate-900 (no dark-mode handling at
   all), now driven by the canonical CSS vars so it tracks theme
   correctly. Fixed here centrally rather than per-consumer since this
   look (bordered, card-colored, primary text) recurs almost everywhere
   as the standard non-primary action button. */
.app-button--secondary {
  background: var(--bg-card);
  border-color: var(--border);
  color: var(--text-primary);
}
.app-button--secondary:hover:not(:disabled) {
  background: var(--bg-hover);
  border-color: var(--text-muted);
}
.app-button:focus {
  outline: none;
  box-shadow: 0 0 0 2px var(--bg-card), 0 0 0 4px var(--primary);
}
</style>
