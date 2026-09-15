<template>
  <div class="stat-card sl-card">
    <div class="stat-icon" :style="{ background: iconBg ?? gradient, color: iconColor }">
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
  // Legacy prop, kept for callers that haven't moved to iconBg/iconColor
  // yet -- the locked spec (design/stream-portal.html .stat-card__icon)
  // uses a flat tinted background with a colored icon, not a gradient
  // with a white icon, so prefer iconBg/iconColor on any new call site.
  gradient: {
    type: String,
    default: 'var(--gradient-primary)'
  },
  iconBg: {
    type: String,
    default: undefined
  },
  iconColor: {
    type: String,
    default: undefined
  },
  trend: {
    type: Object as () => Trend,
    default: null
  }
})
</script>

<style scoped>
/* Sized/tinted per design/stream-portal.html Section 6.4 .stat-card:
   min-width 200px, 24px padding, 40x40 icon container (12px radius),
   32px bold value, 14px slate-600 label -- was 48px/8px-radius icon and
   28px/13px value+label before this pass. */
.stat-card {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-4);
  min-width: 200px;
}
.stat-icon {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: var(--color-slate-900);
  line-height: 1.15;
  font-variant-numeric: tabular-nums;
}
.stat-label {
  font-size: 14px;
  color: var(--color-slate-600);
}
.stat-trend {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 600;
}
.trend--up {
  color: var(--color-success-text);
}
.trend--down {
  color: var(--color-error-text);
}
</style>
