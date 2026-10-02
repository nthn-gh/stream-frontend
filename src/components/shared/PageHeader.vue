<template>
  <div class="page-header">
    <div class="page-header__main">
      <RouterLink
        v-if="backTo"
        :to="backTo"
        class="sl-btn sl-btn-icon page-header__back"
        aria-label="Back"
      >
        <ArrowLeft :size="20" aria-hidden="true" />
      </RouterLink>

      <div class="page-header__text">
        <h1 class="t-h1">
          <slot name="title">{{ title }}</slot>
        </h1>
        <p v-if="$slots.subtitle || subtitle" class="page-header__subtitle t-body">
          <slot name="subtitle">{{ subtitle }}</slot>
        </p>
      </div>
    </div>

    <div v-if="$slots.actions" class="page-header__actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router'
import type { RouteLocationRaw } from 'vue-router'
import { ArrowLeft } from 'lucide-vue-next'

/**
 * The single source of a page's title (the app header no longer renders one).
 * Layout per design/stream-portal.html `.page-header`.
 *
 * Spacing: the bottom margin is the spec's 32px, minus the parent's flex `gap`
 * when the page is a flex column that publishes it as `--page-gap` (so the
 * header-to-content distance is 32px whether or not the page uses a flex gap).
 */
defineProps<{
  /** Page title; used unless the #title slot is provided. */
  title: string
  subtitle?: string
  /** When set, renders a back control that navigates here. */
  backTo?: RouteLocationRaw
}>()
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--spacing-4);
  margin-bottom: calc(var(--spacing-8) - var(--page-gap, 0px));
}
.page-header__main {
  display: flex;
  align-items: flex-start;
  gap: var(--spacing-3);
  min-width: 0;
}
.page-header__back {
  flex: none;
  /* optical alignment with the first line of the 36px/47px title */
  margin-top: var(--spacing-1);
}
.page-header__text {
  min-width: 0;
}
.page-header__subtitle {
  margin-top: 6px;
  color: var(--text-secondary);
}
.page-header__actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--spacing-3);
}
</style>
