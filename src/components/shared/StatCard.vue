<template>
  <component
    :is="to ? RouterLink : 'div'"
    v-bind="to ? { to, 'aria-label': ariaLabel } : {}"
    class="stat-card"
    :class="{ 'stat-card--link': to }"
  >
    <div
      class="stat-icon"
      aria-hidden="true"
      :style="{ background: iconBg ?? 'var(--status-info-bg)', color: iconColor ?? 'var(--stat-accent)' }"
    >
      <slot name="icon" />
    </div>
    <div class="stat-body">
      <div class="stat-label">{{ label }}</div>
      <span v-if="to" class="stat-link">{{ linkText }}</span>
      <div v-if="trend" class="stat-trend" :class="trend.positive ? 'trend--up' : 'trend--down'">
        {{ trend.text }}
      </div>
    </div>
    <div class="stat-value">{{ value }}</div>
  </component>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import type { RouteLocationRaw } from 'vue-router'

interface Trend {
  text: string
  positive: boolean
}

const props = defineProps({
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
  },
  // When set, the whole card becomes one router-link and shows linkText under the
  // label. Without it the card is a plain, non-interactive div.
  to: {
    type: [String, Object] as unknown as () => RouteLocationRaw,
    default: undefined
  },
  linkText: {
    type: String,
    default: 'View details'
  }
})

// aria-label replaces the link's content for assistive tech, so the label, value
// and link text are announced once, e.g. "Total Patients: 5, View patient list".
const ariaLabel = computed(() => `${props.label}: ${props.value}, ${props.linkText}`)
</script>

<style scoped>
/* One row: icon tile, label (+ link text) stack, value. The card height comes from the
   48px tile / 48px value line: 24 + 48 + 24 + 2 border = 98px.

   Surface, border, text and shadow use the themed tokens (--bg-card, --border,
   --text-primary, --text-secondary, --shadow-card) so the card follows light and dark.
   --stat-accent is a local alias, not a new design token: --color-primary-solid
   (#0A79AD) is 4.83:1 on the light card but only about 3.0:1 on the dark card
   (#1E293B), too low for 14px link text, so dark mode uses --text-link (#38BDF8, about
   6.8:1). The status tints on the icon tile are themed in main.css.

   The card is an inline-size container so the decorative icon tile can step aside when
   the card is narrow. Container queries measure the content box, so the 300px card
   threshold is 300 - 48 padding - 2 border = 250px here. 300 is the narrowest card where
   icon tile + "View patient list" + a 3-digit value fit on one line each (measured:
   48 + 16 + 109 + 16 + 61 + 50 = 300). */
.stat-card {
  --stat-accent: var(--color-primary-solid);
  container: stat-card / inline-size;
  display: flex;
  align-items: center;
  gap: var(--spacing-4);
  min-width: 200px;
  padding: var(--spacing-6);
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  color: inherit;
  text-decoration: none;
}
.dark .stat-card {
  --stat-accent: var(--text-link);
}
.stat-card--link {
  cursor: pointer;
}
.stat-card--link:focus-visible {
  outline: 3px solid var(--stat-accent);
  outline-offset: 2px;
}
.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.stat-icon :deep(svg) {
  width: 24px;
  height: 24px;
}
.stat-body {
  display: flex;
  flex-direction: column;
  flex: 1 1 0;
  min-width: 0;
}
.stat-label {
  font-size: 14px;
  line-height: 20px;
  font-weight: var(--weight-semibold);
  color: var(--text-secondary);
}
.stat-link {
  font-size: 14px;
  line-height: 20px;
  font-weight: var(--weight-semibold);
  color: var(--stat-accent);
}
.stat-card--link:hover .stat-link {
  text-decoration: underline;
}
.stat-value {
  flex-shrink: 0;
  font-size: 40px;
  line-height: 48px;
  font-weight: var(--weight-bold);
  letter-spacing: -0.01em;
  font-variant-numeric: tabular-nums;
  color: var(--text-primary);
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
@container stat-card (width < 250px) {
  .stat-icon {
    display: none;
  }
}
</style>
