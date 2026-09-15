// STREAM Therapist Dashboard - Message Store
//
// Backed by the real `messages` table (sender_id/receiver_id -> users.id,
// content, created_at, read_at). There is no separate "conversations"
// table, so a conversation is derived here as: every patient on the
// therapist's caseload whose patient.user_id has exchanged messages (or
// could exchange messages) with the signed-in therapist.

import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { supabase } from '@/services/supabase'
import { useAuthStore } from '@/stores/authStore'
import type { Message } from '@/types'

export interface ConversationSummary {
  patientId: string
  patientName: string
  patientUserId: string
  avatarUrl: string | null
  lastMessage: Message | null
  unreadCount: number
}

export const useMessageStore = defineStore('message', () => {
  const messagesByUser = ref<Record<string, Message[]>>({})
  const activePatientUserId = ref<string | null>(null)
  const isLoading = ref(false)
  const isSending = ref(false)
  const error = ref<string | null>(null)
  let realtimeChannel: RealtimeChannel | null = null

  function getMyUserId() {
    const authStore = useAuthStore()
    return authStore.user?.id ?? null
  }

  const activeThread = computed(() => {
    if (!activePatientUserId.value) return []
    return messagesByUser.value[activePatientUserId.value] ?? []
  })

  function unreadCountFor(patientUserId: string) {
    const myId = getMyUserId()
    const thread = messagesByUser.value[patientUserId] ?? []
    return thread.filter((m) => m.receiver_id === myId && !m.read_at).length
  }

  // Fetches every message the signed-in therapist has sent or received,
  // grouped by the other party's user id. Called once on entering the
  // Messages screen; realtime keeps it current after that.
  async function fetchAllThreads() {
    const myId = getMyUserId()
    if (!myId) return

    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('messages')
        .select('*')
        .or(`sender_id.eq.${myId},receiver_id.eq.${myId}`)
        .order('created_at', { ascending: true })

      if (fetchError) throw fetchError

      const grouped: Record<string, Message[]> = {}
      for (const message of (data ?? []) as Message[]) {
        const otherId = message.sender_id === myId ? message.receiver_id : message.sender_id
        grouped[otherId] ??= []
        grouped[otherId].push(message)
      }
      messagesByUser.value = grouped
    } catch (err: any) {
      error.value = err.message || 'Unable to load messages'
    } finally {
      isLoading.value = false
    }
  }

  async function openThread(patientUserId: string) {
    activePatientUserId.value = patientUserId
    await markThreadRead(patientUserId)
  }

  async function markThreadRead(patientUserId: string) {
    const myId = getMyUserId()
    if (!myId) return

    const unreadIds = (messagesByUser.value[patientUserId] ?? [])
      .filter((m) => m.receiver_id === myId && !m.read_at)
      .map((m) => m.id)

    if (!unreadIds.length) return

    const { error: updateError } = await supabase
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .in('id', unreadIds)

    if (updateError) {
      error.value = updateError.message
      return
    }

    const nowIso = new Date().toISOString()
    messagesByUser.value[patientUserId] = (messagesByUser.value[patientUserId] ?? []).map((m) =>
      unreadIds.includes(m.id) ? { ...m, read_at: nowIso } : m,
    )
  }

  async function sendMessage(patientUserId: string, content: string) {
    const myId = getMyUserId()
    if (!myId || !content.trim()) return { success: false as const, error: 'Nothing to send' }

    isSending.value = true
    try {
      const { data, error: insertError } = await supabase
        .from('messages')
        .insert({ sender_id: myId, receiver_id: patientUserId, content: content.trim() })
        .select()
        .single()

      if (insertError) throw insertError

      messagesByUser.value[patientUserId] = [...(messagesByUser.value[patientUserId] ?? []), data as Message]
      return { success: true as const }
    } catch (err: any) {
      error.value = err.message || 'Unable to send message'
      return { success: false as const, error: error.value }
    } finally {
      isSending.value = false
    }
  }

  function subscribeRealtime() {
    const myId = getMyUserId()
    if (!myId || realtimeChannel) return

    realtimeChannel = supabase
      .channel('messages-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'messages' },
        (payload) => {
          const row = (payload.new ?? payload.old) as Message | undefined
          if (!row) return
          if (row.sender_id !== myId && row.receiver_id !== myId) return
          void fetchAllThreads()
        },
      )
      .subscribe()
  }

  function unsubscribeRealtime() {
    if (realtimeChannel) {
      realtimeChannel.unsubscribe()
      realtimeChannel = null
    }
  }

  return {
    messagesByUser,
    activePatientUserId,
    activeThread,
    isLoading,
    isSending,
    error,
    unreadCountFor,
    fetchAllThreads,
    openThread,
    sendMessage,
    subscribeRealtime,
    unsubscribeRealtime,
  }
})
