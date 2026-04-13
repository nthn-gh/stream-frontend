<template>
  <div class="base-card" :class="{ 'base-card--elevated': elevated }">
    <slot />
  </div>
</template>

<script setup lang="ts">
defineProps({
  elevated: {
    type: Boolean,
    default: false
  }
})
</script>

<style scoped>
.base-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: var(--padding-card);
  box-shadow: var(--shadow-card);
  border: 1px solid rgba(226, 232, 240, 0.6);
}
.base-card--elevated {
  box-shadow: var(--shadow-elevated);
}
</style>
