<template>
  <div class="stat-card">
    <div class="stat-icon" :style="{ background: gradient }">
      <slot name="icon" />
    </div>
    <div class="stat-body">
      <div class="stat-value">{{ value }}</div>
      <div class="stat-label">{{ label }}</div>
      <div v-if="trend" class="stat-trend" :class="trend.positive ? 'trend--up' : 'trend--down'">
        {{ trend.text }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Trend {
  text: string
  positive: boolean
}

defineProps({
  value: {
    type: String,
    required: true
  },
  label: {
    type: String,
    required: true
  },
  gradient: {
    type: String,
    default: 'var(--gradient-primary)'
  },
  trend: {
    type: Object as () => Trend,
    default: null
  }
})
</script>

<style scoped>
.stat-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: var(--padding-card);
  box-shadow: var(--shadow-card);
  border: 1px solid rgba(226, 232, 240, 0.6);
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
}
.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: white;
}
.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.1;
}
.stat-label {
  font-size: 13px;
  color: var(--text-muted);
  margin-top: 2px;
}
.stat-trend {
  font-size: 12px;
  font-weight: 600;
  margin-top: 4px;
}
.trend--up {
  color: #059669;
}
.trend--down {
  color: #DC2626;
}
</style>
