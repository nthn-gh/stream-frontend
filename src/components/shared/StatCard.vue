<template>
  <div class="stat-card sl-card">
    <div class="stat-head">
      <div
        class="stat-icon"
        :style="{ background: iconBg ?? 'var(--status-info-bg)', color: iconColor ?? 'var(--status-info-text)' }"
      >
        <slot name="icon" />
      </div>
      <div class="stat-label">{{ label }}</div>
    </div>
    <div class="stat-value">{{ value }}</div>
    <div v-if="trend" class="stat-trend" :class="trend.positive ? 'trend--up' : 'trend--down'">
      {{ trend.text }}
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
  // Legacy prop, kept so existing callers still compile. It is no longer rendered:
  // the icon tile is a flat tint (iconBg/iconColor, default = the info status tint),
  // per design/stream-portal.html .stat-card__icon, not a gradient.
  gradient: {
    type: String,
    default: undefined
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
/* Content-height card on the same surface tokens as the other dashboard cards
   (.dash-card), so it follows the theme instead of staying white on a dark page.
   Icon tile and label share one row; the number is the dominant element below.
   Padding is .sl-card's 24px. The status tints (--status-*) are themed in main.css,
   so a tile keeps its contrast in both light and dark. */
.stat-card {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
  min-width: 200px;
  background: var(--bg-card);
  border-color: var(--border);
  box-shadow: var(--shadow-card);
}
.stat-head {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);
  min-width: 0;
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
.stat-label {
  font-size: 14px;
  line-height: 20px;
  font-weight: 500;
  color: var(--text-secondary);
  min-width: 0;
}
.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.15;
  font-variant-numeric: tabular-nums;
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
