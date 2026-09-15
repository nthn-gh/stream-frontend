<template>
  <span
    class="sl-avatar"
    :class="sizeClass"
    :style="src ? undefined : { background: color }"
    role="img"
    :aria-label="name"
  >
    <img v-if="src" :src="src" :alt="name" />
    <template v-else>{{ initials }}</template>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  name: string
  src?: string | null
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  color?: string
}

const props = withDefaults(defineProps<Props>(), {
  src: null,
  size: 'md',
  color: 'var(--color-primary)',
})

const sizeClass = computed(() => `sl-avatar-${props.size}`)

const initials = computed(() =>
  props.name
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2),
)
</script>
