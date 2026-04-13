<template>
  <div class="adherence-wrap">
    <div class="adherence-track">
      <div 
        class="adherence-fill" 
        :style="{ width: `${value}%`, background: fillGradient }" 
        role="progressbar" 
        :aria-valuenow="value" 
        aria-valuemin="0" 
        aria-valuemax="100" 
      />
    </div>
    <span class="adherence-label">{{ value }}%</span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  value: {
    type: Number,
    default: 0
  }
})

const fillGradient = computed(() => {
  if (props.value >= 75) return 'var(--gradient-success)'
  if (props.value >= 50) return 'var(--gradient-warning)'
  return 'var(--gradient-danger)'
})
</script>

<style scoped>
.adherence-wrap {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}
.adherence-track {
  flex: 1;
  height: 8px;
  background: var(--border);
  border-radius: var(--radius-pill);
  overflow: hidden;
}
.adherence-fill {
  height: 100%;
  border-radius: var(--radius-pill);
  transition: width 0.4s ease;
}
.adherence-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  white-space: nowrap;
  min-width: 36px;
  text-align: right;
}
</style>
