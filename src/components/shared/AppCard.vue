<template>
  <div :class="cardClasses">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  padding?: 'small' | 'medium' | 'large'
  hoverable?: boolean
  clickable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  padding: 'medium',
  hoverable: false,
  clickable: false
})

const cardClasses = computed(() => {
  const base = 'bg-white border border-slate-200 rounded-2xl transition-all duration-200'
  const hover = props.hoverable ? 'hover:border-slate-300 hover:shadow-lg hover:-translate-y-0.5' : ''
  const click = props.clickable ? 'cursor-pointer' : ''
  
  const paddings = {
    small: 'p-4',
    medium: 'p-6',
    large: 'p-8'
  }
  
  return `${base} ${paddings[props.padding]} ${hover} ${click} shadow-md`
})
</script>
