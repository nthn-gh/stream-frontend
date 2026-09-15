<template>
  <div
    class="sl-skeleton"
    :class="variantClass"
    :style="style"
    role="status"
    aria-label="Loading"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'text' | 'avatar' | 'card'
  width?: string
  height?: string
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'text',
  width: undefined,
  height: undefined,
})

const variantClass = computed(() => `sl-skeleton-${props.variant}`)

const style = computed(() => ({
  width: props.width,
  height: props.height,
}))
</script>
