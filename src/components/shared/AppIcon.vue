<template>
  <component
    :is="icon"
    class="app-icon"
    :size="px"
    :stroke-width="2"
    :aria-hidden="label ? undefined : 'true'"
    :role="label ? 'img' : undefined"
    :aria-label="label"
    focusable="false"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { LucideIcon } from 'lucide-vue-next'

/*
 * The one place icons are sized and labelled (rules in docs/icon-set.md):
 *   sm 16px  table cells, inline with small text
 *   md 20px  navigation and buttons that also have a text label
 *   lg 24px  icon-only controls
 * Stroke is always 2px and the colour is inherited (currentColor), so tint an icon
 * by setting `color` on it or a parent. Decorative by default (aria-hidden); pass
 * `label` only when the icon is the sole content of its control or carries meaning
 * on its own. Pass the Lucide component itself (a named import) so unused icons are
 * tree-shaken.
 */
interface Props {
  icon: LucideIcon
  size?: 'sm' | 'md' | 'lg'
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  label: undefined,
})

const SIZES = { sm: 16, md: 20, lg: 24 } as const
const px = computed(() => SIZES[props.size])
</script>

<style scoped>
.app-icon {
  flex-shrink: 0;
}
</style>
