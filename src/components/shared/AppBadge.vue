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
    success: 'app-badge--success',
    warning: 'app-badge--warning',
    error: 'app-badge--error',
    info: 'app-badge--info',
    neutral: 'app-badge--neutral'
  }

  return `${base} ${variants[props.variant]}`
})
</script>

<style scoped>
/* All five variants go through the canonical CSS-var status tokens
   instead of Tailwind utility classes. success/warning/error previously
   referenced bg-success-bg/text-success-text/etc., which don't exist
   anywhere in tailwind.config.ts -- those three variants rendered with
   no background/text color at all. info/neutral weren't broken, but
   were hardcoded to raw Tailwind grays/blues rather than the token
   system; fixed here too for consistency. Mapping mirrors BaseBadge.vue
   exactly (success~active, error~danger). */
.app-badge--success {
  background: var(--status-active-bg);
  color: var(--status-active-text);
}
.app-badge--warning {
  background: var(--status-warning-bg);
  color: var(--status-warning-text);
}
.app-badge--error {
  background: var(--status-danger-bg);
  color: var(--status-danger-text);
}
.app-badge--info {
  background: var(--status-info-bg);
  color: var(--status-info-text);
}
.app-badge--neutral {
  background: var(--status-neutral-bg);
  color: var(--status-neutral-text);
}
</style>
