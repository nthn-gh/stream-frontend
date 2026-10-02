<template>
  <div class="adherence-wrap">
    <div class="adherence-track">
      <div
        class="adherence-fill"
        :style="{ width: `${value}%`, background: fillColor }"
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

// Flat status colors per the locked spec (design/stream-portal.html
// .bar-fill: solid color, not a gradient -- e.g. the Patients table's
// adherence column fills with var(--color-error)/-warning/success
// directly based on the value, never a gradient).
const fillColor = computed(() => {
  if (props.value >= 75) return 'var(--color-teal)'
  if (props.value >= 50) return 'var(--color-warning)'
  return 'var(--color-error)'
})
</script>

<style scoped>
.adherence-wrap {
  display: flex;
  align-items: center;
  gap: var(--spacing-2);
}
.adherence-track {
  flex: 1;
  height: 8px;
  background: var(--border);
  border-radius: var(--radius-full);
  overflow: hidden;
}
.adherence-fill {
  height: 100%;
  border-radius: var(--radius-full);
  transition: width 0.4s ease;
}
.adherence-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-secondary);
  white-space: nowrap;
  min-width: 36px;
  text-align: right;
}
</style>
