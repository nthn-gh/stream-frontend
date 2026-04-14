<template>
  <div class="app-input">
    <label v-if="label" :for="inputId" class="input-label">{{ label }}</label>
    <div class="input-shell" :class="{ 'input-shell--error': Boolean(error), 'input-shell--disabled': disabled }">
      <input
        :id="inputId"
        :value="modelValue"
        :type="type"
        :placeholder="placeholder"
        :disabled="disabled"
        class="input-control"
        @input="handleInput"
        @focus="$emit('focus')"
        @blur="$emit('blur')"
      />
      <div v-if="$slots.iconRight" class="icon-right">
        <slot name="iconRight" />
      </div>
    </div>
    <p v-if="error" class="input-error">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
interface Props {
  modelValue: string
  type?: string
  label?: string
  placeholder?: string
  disabled?: boolean
  error?: string
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  disabled: false,
  id: undefined,
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  focus: []
  blur: []
}>()

const inputId = props.id ?? `input-${Math.random().toString(36).slice(2, 10)}`

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>

<style scoped>
.app-input {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.input-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.input-shell {
  position: relative;
  display: flex;
  align-items: center;
  min-height: 52px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--bg-input);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.input-shell:focus-within {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-light);
}

.input-shell--error {
  border-color: #dc2626;
}

.input-shell--error:focus-within {
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.14);
}

.input-shell--disabled {
  opacity: 0.65;
}

.input-control {
  width: 100%;
  min-height: 52px;
  border: none;
  outline: none;
  background: transparent;
  color: var(--text-primary);
  font: inherit;
  font-size: 15px;
  padding: 0 16px;
}

.input-control::placeholder {
  color: var(--text-muted);
}

.icon-right {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding-right: 12px;
}

.input-error {
  font-size: 12px;
  color: #b91c1c;
}
</style>
