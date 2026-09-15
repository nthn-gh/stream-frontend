<template>
  <div>
    <div class="sl-tabs" role="tablist">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        class="sl-tab"
        role="tab"
        :aria-selected="tab.value === modelValue"
        :id="`tab-${tab.value}`"
        :aria-controls="`tabpanel-${tab.value}`"
        type="button"
        @click="$emit('update:modelValue', tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>
    <div
      v-for="tab in tabs"
      :key="tab.value"
      :id="`tabpanel-${tab.value}`"
      role="tabpanel"
      :aria-labelledby="`tab-${tab.value}`"
      :hidden="tab.value !== modelValue"
      style="margin-top: var(--spacing-6)"
    >
      <slot :name="tab.value" />
    </div>
  </div>
</template>

<script setup lang="ts">
interface Tab {
  value: string
  label: string
}

defineProps<{
  tabs: Tab[]
  modelValue: string
}>()

defineEmits<{
  'update:modelValue': [value: string]
}>()
</script>
