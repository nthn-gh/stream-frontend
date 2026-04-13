<template>
  <span class="badge" :class="`badge--${variant}`">
    <span class="badge-dot" aria-hidden="true"></span>
    <slot />
  </span>
</template>

<script setup lang="ts">
defineProps({
  variant: {
    type: String as () => 'active' | 'warning' | 'danger' | 'info' | 'neutral',
    default: 'info'
  }
})
</script>

<style scoped>
.badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px;
  border-radius: var(--radius-pill);
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}
.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
}
.badge--active {
  background: var(--status-active-bg);
  color: var(--status-active-text);
}
.badge--warning {
  background: var(--status-warning-bg);
  color: var(--status-warning-text);
}
.badge--danger {
  background: var(--status-danger-bg);
  color: var(--status-danger-text);
}
.badge--info {
  background: var(--status-info-bg);
  color: var(--status-info-text);
}
.badge--neutral {
  background: var(--status-neutral-bg);
  color: var(--status-neutral-text);
}
</style>
