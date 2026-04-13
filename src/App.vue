<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed, onMounted } from 'vue'
import AppSidebar from './components/layout/AppSidebar.vue'
import AppHeader from './components/layout/AppHeader.vue'
import { useTheme } from './composables/useTheme'

const route = useRoute()
const { initTheme } = useTheme()

const showLayout = computed(() => {
  return route.path !== '/login' && route.path !== '/signup' && route.path !== '/confirm-email'
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
  padding: var(--padding-page);
  margin-top: var(--header-height);
  min-height: calc(100vh - var(--header-height));
}
</style>
