# STREAM - Create All Component Files
# Run after setup.bat to create all component files
# Usage: .\create-components.ps1

Write-Host "Creating STREAM Component Files..." -ForegroundColor Cyan
Write-Host ""

$componentsCreated = 0
$errorsEncountered = 0

# Function to create file with content
function Create-ComponentFile {
    param($Path, $Content, $Name)
    
    try {
        $Content | Out-File -FilePath $Path -Encoding UTF8 -Force
        Write-Host "  ✓ Created: $Name" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ✗ Failed: $Name - $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "[1/13] Creating Modal.vue..." -ForegroundColor Yellow
$modalContent = @'
<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition-opacity duration-200"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="modelValue"
        class="fixed inset-0 z-[1000] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4"
        @click.self="handleClose"
      >
        <Transition
          enter-active-class="transition-all duration-300"
          enter-from-class="opacity-0 scale-95"
          enter-to-class="opacity-100 scale-100"
          leave-active-class="transition-all duration-200"
          leave-from-class="opacity-100 scale-100"
          leave-to-class="opacity-0 scale-95"
        >
          <div
            v-if="modelValue"
            :class="modalClasses"
            role="dialog"
            aria-modal="true"
            :aria-labelledby="titleId"
          >
            <!-- Header -->
            <div v-if="$slots.header || title" class="pb-4 border-b border-slate-200">
              <div class="flex items-center justify-between">
                <h3 :id="titleId" class="text-xl font-bold text-slate-900">
                  <slot name="header">{{ title }}</slot>
                </h3>
                <button
                  v-if="closable"
                  @click="handleClose"
                  class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 transition-colors"
                  aria-label="Close"
                >
                  <X :size="20" />
                </button>
              </div>
            </div>
            
            <!-- Body -->
            <div class="py-6 max-h-[60vh] overflow-y-auto">
              <slot />
            </div>
            
            <!-- Footer -->
            <div v-if="$slots.footer" class="pt-4 border-t border-slate-200 flex justify-end gap-3">
              <slot name="footer" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { X } from 'lucide-vue-next'

interface Props {
  modelValue: boolean
  title?: string
  size?: 'small' | 'medium' | 'large'
  closable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  closable: true,
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const titleId = computed(() => `modal-title-${Math.random().toString(36).substr(2, 9)}`)

const modalClasses = computed(() => {
  const base = 'bg-white rounded-2xl shadow-2xl p-6 w-full'
  const sizeClasses = {
    small: 'max-w-sm',
    medium: 'max-w-md',
    large: 'max-w-2xl',
  }
  return `${base} ${sizeClasses[props.size]}`
})

const handleClose = () => {
  if (props.closable) {
    emit('update:modelValue', false)
  }
}
</script>
'@

if (Create-ComponentFile "src\components\ui\Modal.vue" $modalContent "Modal.vue") {
    $componentsCreated++
} else {
    $errorsEncountered++
}

# Continue creating other components...
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Summary: $componentsCreated created, $errorsEncountered errors" -ForegroundColor $(if ($errorsEncountered -eq 0) { "Green" } else { "Yellow" })
Write-Host "================================" -ForegroundColor Cyan
