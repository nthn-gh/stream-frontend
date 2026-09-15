<template>
  <div ref="rootEl" class="sl-dropdown">
    <span @click="toggle">
      <slot name="trigger" :open="isOpen" />
    </span>
    <div
      v-if="isOpen"
      class="sl-dropdown__panel"
      role="menu"
      :style="align === 'right' ? { right: 0 } : { left: 0 }"
    >
      <button
        v-for="item in items"
        :key="item.value"
        type="button"
        class="sl-dropdown__item"
        role="menuitemradio"
        :aria-selected="item.value === modelValue"
        @click="select(item.value)"
      >
        {{ item.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'

interface Item {
  value: string
  label: string
}

defineProps<{
  items: Item[]
  modelValue?: string
  align?: 'left' | 'right'
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  select: [value: string]
}>()

const isOpen = ref(false)
const rootEl = ref<HTMLElement | null>(null)

function toggle() {
  isOpen.value = !isOpen.value
}

function select(value: string) {
  emit('update:modelValue', value)
  emit('select', value)
  isOpen.value = false
}

function handleClickOutside(event: MouseEvent) {
  if (rootEl.value && !rootEl.value.contains(event.target as Node)) {
    isOpen.value = false
  }
}

function handleEscape(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  document.addEventListener('keydown', handleEscape)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
  document.removeEventListener('keydown', handleEscape)
})
</script>
