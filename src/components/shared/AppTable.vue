<template>
  <div class="sl-table-wrap">
    <div class="sl-table-scroll">
      <table class="sl-data-table">
        <thead>
          <tr>
            <th v-for="col in columns" :key="col.key" :style="col.width ? { width: col.width } : undefined">
              {{ col.label }}
            </th>
          </tr>
        </thead>
        <tbody>
          <slot />
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Column {
  key: string
  label: string
  width?: string
}

defineProps<{
  columns: Column[]
}>()
</script>
