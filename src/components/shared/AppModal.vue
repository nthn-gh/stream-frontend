<template>
  <Teleport to="body">
    <Transition name="modal-overlay">
      <div
        v-if="modelValue"
        class="fixed inset-0 z-[1000] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4"
        @click.self="handleClose"
      >
        <Transition name="modal-content">
          <div
            v-if="modelValue"
            class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col"
            role="dialog"
            aria-modal="true"
            :aria-labelledby="title ? titleId : undefined"
          >
            <div v-if="title" class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <h3 :id="titleId" class="text-xl font-bold text-slate-900">{{ title }}</h3>
              <button
                v-if="closable"
                @click="handleClose"
                aria-label="Close"
                class="w-11 h-11 -my-2 -mr-2 flex items-center justify-center rounded-lg hover:bg-slate-100 transition-colors"
              >
                <AppIcon :icon="X" size="lg" />
              </button>
            </div>
            
            <div class="px-6 py-6 overflow-y-auto flex-1">
              <slot />
            </div>
            
            <div v-if="$slots.footer" class="px-6 py-4 border-t border-slate-200 flex justify-end gap-3">
              <slot name="footer" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { useId } from 'vue'
import { X } from 'lucide-vue-next'
import AppIcon from '@/components/shared/AppIcon.vue'

interface Props {
  modelValue: boolean
  title?: string
  closable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  closable: true
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

// Unique per component instance (Vue 3.5+), so multiple AppModal
// instances mounted at once never collide on this id.
const titleId = useId()

const handleClose = () => {
  if (props.closable) {
    emit('update:modelValue', false)
  }
}
</script>

<style scoped>
.modal-overlay-enter-active,
.modal-overlay-leave-active {
  transition: opacity 0.2s ease;
}

.modal-overlay-enter-from,
.modal-overlay-leave-to {
  opacity: 0;
}

.modal-content-enter-active {
  transition: all 0.3s ease-out;
}

.modal-content-leave-active {
  transition: all 0.2s ease-in;
}

.modal-content-enter-from,
.modal-content-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
