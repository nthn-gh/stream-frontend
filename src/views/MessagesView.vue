<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="t-h1">Messages</h1>
        <p class="text-secondary t-body" style="margin-top: 6px">Secure messaging with patients and caregivers.</p>
      </div>
    </div>

    <p v-if="error" class="t-body-sm" style="color: var(--color-error-text); margin-bottom: var(--spacing-4)">{{ error }}</p>

    <div class="sl-card messages-shell">
      <div class="messages-list">
        <div style="padding: var(--spacing-4)">
          <div class="input-icon-wrap">
            <Search :size="16" style="color: var(--color-slate-400)" />
            <input v-model="search" class="sl-input" style="height: 40px" placeholder="Search patients" aria-label="Search patients" />
          </div>
        </div>
        <div v-if="isLoading" style="padding: 0 var(--spacing-4); display: flex; flex-direction: column; gap: 12px">
          <AppSkeleton variant="text" height="48px" />
          <AppSkeleton variant="text" height="48px" />
          <AppSkeleton variant="text" height="48px" />
        </div>
        <div v-else style="overflow-y: auto; flex: 1">
          <button
            v-for="conversation in filteredConversations"
            :key="conversation.patientId"
            type="button"
            class="conversation-row"
            :class="{ 'is-active': conversation.patientUserId === activePatientUserId }"
            @click="selectConversation(conversation)"
          >
            <AppAvatar :name="conversation.patientName" :src="conversation.avatarUrl" size="sm" />
            <div style="flex: 1; min-width: 0; text-align: left">
              <div style="display: flex; justify-content: space-between; gap: 8px">
                <strong class="t-body-sm">{{ conversation.patientName }}</strong>
                <span class="t-caption" style="flex-shrink: 0">{{ formatTime(conversation.lastMessage?.created_at) }}</span>
              </div>
              <div class="t-caption conversation-preview">{{ conversation.lastMessage?.content || 'No messages yet' }}</div>
            </div>
            <span v-if="conversation.unreadCount" class="sl-badge sl-badge-info" style="flex-shrink: 0">{{ conversation.unreadCount }}</span>
          </button>
          <p v-if="!filteredConversations.length" class="t-body-sm text-secondary" style="padding: var(--spacing-4)">
            No patients to message yet.
          </p>
        </div>
      </div>

      <div class="messages-thread">
        <template v-if="activeConversation">
          <div class="thread-header">
            <AppAvatar :name="activeConversation.patientName" :src="activeConversation.avatarUrl" size="sm" />
            <strong class="t-body-md">{{ activeConversation.patientName }}</strong>
          </div>
          <div ref="threadScroll" class="thread-body">
            <div
              v-for="message in activeThread"
              :key="message.id"
              class="thread-bubble"
              :class="message.sender_id === myUserId ? 'from-me' : 'from-them'"
            >
              <p class="t-body-sm">{{ message.content }}</p>
            </div>
            <p v-if="!activeThread.length" class="t-body-sm text-secondary" style="text-align: center; padding: var(--spacing-6)">
              No messages yet. Say hello.
            </p>
          </div>
          <form class="thread-composer" @submit.prevent="handleSend">
            <input v-model="draft" class="sl-input" placeholder="Type a message…" aria-label="Message" />
            <button type="submit" class="sl-btn-icon" style="background: var(--color-primary); color: #fff; border: none" aria-label="Send message" :disabled="isSending || !draft.trim()">
              <Send :size="18" />
            </button>
          </form>
        </template>
        <div v-else class="sl-empty-state" style="margin: auto">
          <MessageSquare :size="40" style="margin-bottom: var(--spacing-4)" />
          <p class="t-body-md">Select a patient to start messaging.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'
import { Search, Send, MessageSquare } from 'lucide-vue-next'
import { storeToRefs } from 'pinia'
import { usePatientStore } from '@/stores/patientStore'
import { useMessageStore, type ConversationSummary } from '@/stores/messageStore'
import { useAuthStore } from '@/stores/authStore'
import AppAvatar from '@/components/shared/AppAvatar.vue'
import AppSkeleton from '@/components/shared/AppSkeleton.vue'

const patientStore = usePatientStore()
const messageStore = useMessageStore()
const authStore = useAuthStore()

const { patients } = storeToRefs(patientStore)
const { activePatientUserId, activeThread, isLoading, isSending, error } = storeToRefs(messageStore)

const search = ref('')
const draft = ref('')
const threadScroll = ref<HTMLElement | null>(null)
const myUserId = computed(() => authStore.user?.id ?? null)

const conversations = computed<ConversationSummary[]>(() =>
  patients.value
    .filter((patient) => patient.user_id)
    .map((patient) => {
      const patientUserId = patient.user_id as string
      const thread = messageStore.messagesByUser[patientUserId] ?? []
      return {
        patientId: patient.id,
        patientName: patient.name,
        patientUserId,
        avatarUrl: patient.avatar_url,
        lastMessage: thread.length ? thread[thread.length - 1]! : null,
        unreadCount: messageStore.unreadCountFor(patientUserId),
      }
    })
    .sort((a, b) => {
      const aTime = a.lastMessage?.created_at ? new Date(a.lastMessage.created_at).getTime() : 0
      const bTime = b.lastMessage?.created_at ? new Date(b.lastMessage.created_at).getTime() : 0
      return bTime - aTime
    }),
)

const filteredConversations = computed(() => {
  if (!search.value.trim()) return conversations.value
  const q = search.value.trim().toLowerCase()
  return conversations.value.filter((c) => c.patientName.toLowerCase().includes(q))
})

const activeConversation = computed(() => conversations.value.find((c) => c.patientUserId === activePatientUserId.value) ?? null)

async function selectConversation(conversation: ConversationSummary) {
  await messageStore.openThread(conversation.patientUserId)
}

async function handleSend() {
  if (!activePatientUserId.value || !draft.value.trim()) return
  const content = draft.value
  draft.value = ''
  await messageStore.sendMessage(activePatientUserId.value, content)
}

function formatTime(timestamp?: string | null) {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  const now = new Date()
  if (date.toDateString() === now.toDateString()) {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
  }
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

watch(activeThread, () => {
  nextTick(() => {
    if (threadScroll.value) threadScroll.value.scrollTop = threadScroll.value.scrollHeight
  })
})

onMounted(async () => {
  await patientStore.fetchPatients()
  await messageStore.fetchAllThreads()
  messageStore.subscribeRealtime()
})

onBeforeUnmount(() => {
  messageStore.unsubscribeRealtime()
})
</script>

<style scoped>
.page-header {
  margin-bottom: var(--spacing-8);
}
.input-icon-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.input-icon-wrap svg {
  position: absolute;
  left: 14px;
}
.input-icon-wrap .sl-input {
  padding-left: 40px;
}
.messages-shell {
  padding: 0;
  display: grid;
  grid-template-columns: 320px 1fr;
  overflow: hidden;
  min-height: 520px;
}
.messages-list {
  border-right: 1px solid var(--color-slate-200);
  display: flex;
  flex-direction: column;
}
.conversation-row {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: var(--spacing-3) var(--spacing-4);
  border: none;
  border-bottom: 1px solid var(--color-slate-100);
  background: transparent;
  font-family: inherit;
  cursor: pointer;
  text-align: left;
}
.conversation-row:hover {
  background: var(--color-slate-50);
}
.conversation-row.is-active {
  background: var(--accent-blue-soft);
}
.conversation-preview {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-top: 2px;
}
.messages-thread {
  display: flex;
  flex-direction: column;
}
.thread-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: var(--spacing-4) var(--spacing-5);
  border-bottom: 1px solid var(--color-slate-200);
}
.thread-body {
  flex: 1;
  padding: var(--spacing-5);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-4);
}
.thread-bubble {
  max-width: 70%;
  padding: 12px 16px;
  border-radius: var(--radius-lg);
}
.thread-bubble.from-them {
  background: var(--color-slate-100);
  border-radius: var(--radius-lg) var(--radius-lg) var(--radius-lg) 4px;
  align-self: flex-start;
}
.thread-bubble.from-me {
  background: var(--color-primary);
  color: #fff;
  border-radius: var(--radius-lg) var(--radius-lg) 4px var(--radius-lg);
  align-self: flex-end;
}
.thread-composer {
  display: flex;
  gap: 12px;
  padding: var(--spacing-4) var(--spacing-5);
  border-top: 1px solid var(--color-slate-200);
}
</style>
