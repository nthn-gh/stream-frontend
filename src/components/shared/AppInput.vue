<template>
  <div class="w-full">
    <label v-if="label" :for="inputId" class="block text-label text-slate-900 mb-2">
      {{ label }}
    </label>
    <div class="relative">
      <input
        :id="inputId"
        :value="modelValue"
        :type="type"
        :placeholder="placeholder"
        :disabled="disabled"
        :class="inputClasses"
        @input="handleInput"
        @focus="$emit('focus')"
        @blur="$emit('blur')"
      />
      <div v-if="$slots.iconRight" class="absolute right-4 top-1/2 -translate-y-1/2">
        <slot name="iconRight" />
      </div>
    </div>
    <p v-if="error" class="mt-1 text-caption text-error-text">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue: string
  type?: string
  label?: string
  placeholder?: string
  disabled?: boolean
  error?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  disabled: false
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  focus: []
  blur: []
}>()

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}

const inputId = computed(() => `input-${Math.random().toString(36).substr(2, 9)}`)

const inputClasses = computed(() => {
  const base = 'w-full h-13 px-5 text-body rounded-xl transition-all duration-200 focus:outline-none'
  const normal = 'bg-slate-100 border-2 border-transparent focus:border-primary focus:ring-2 focus:ring-primary/20'
  const errorState = 'border-2 border-error focus:border-error focus:ring-2 focus:ring-error/20'
  const disabledState = 'bg-slate-200 text-slate-400 cursor-not-allowed'
  
  if (props.disabled) return `${base} ${disabledState}`
  if (props.error) return `${base} ${errorState}`
  return `${base} ${normal}`
})
</script>
