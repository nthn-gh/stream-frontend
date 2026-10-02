<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed, onMounted } from 'vue'
import AppSidebar from './components/layout/AppSidebar.vue'
import AppHeader from './components/layout/AppHeader.vue'
import { useTheme } from './composables/useTheme'

const route = useRoute()
const { initTheme } = useTheme()

const showLayout = computed(() => {
  return (
    route.path !== '/login' &&
    route.path !== '/register' &&
    route.path !== '/signup' &&
    route.path !== '/confirm-email'
  )
})

// Initialize theme on app mount
onMounted(() => {
  initTheme()
})
</script>

<template>
  <div v-if="showLayout" class="app-shell">
    <AppSidebar />
    <div class="app-main">
      <AppHeader />
      <main class="app-content">
        <RouterView />
      </main>
    </div>
  </div>
  <RouterView v-else />
</template>

<style scoped>
.app-shell {
  display: flex;
  min-height: 100vh;
  background: var(--bg-app);
}
.app-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  margin-left: var(--sidebar-width);
}
.app-content {
  flex: 1;
  /* Spec content column (design/stream-portal.html .page): max-width 1160px
     INCLUDING the 32px page padding (= 1096px inner), centered. border-box comes
     from Tailwind preflight. Every authenticated route renders through here. */
  width: 100%;
  max-width: 1160px;
  padding: var(--padding-page);
  margin: var(--header-height) auto 0;
  min-height: calc(100vh - var(--header-height));
}
</style>
