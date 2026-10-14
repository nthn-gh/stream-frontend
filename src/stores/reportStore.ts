// STREAM Therapist Dashboard - Report Store

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase'
import type { Report, ReportData, Patient } from '@/types'
import jsPDF from 'jspdf'
import html2canvas from 'html2canvas'

export const useReportStore = defineStore('report', () => {
  // State
  const config = ref<Partial<Report>>({
    type: 'progress',
    patient_id: '',
    start_date: '',
    end_date: ''
  })
  const data = ref<ReportData | null>(null)
  const isGenerating = ref(false)
  const error = ref<string | null>(null)

  // Actions
  async function generateReport() {
    if (!config.value.patient_id || !config.value.start_date || !config.value.end_date) {
      error.value = 'Missing required configuration'
      return { success: false, error: error.value }
    }

    isGenerating.value = true
    error.value = null

    try {
      // Fetch patient data
      const { data: patient, error: patientError } = await supabase
        .from('patients')
        .select('*')
        .eq('id', config.value.patient_id)
        .single()

      if (patientError) throw patientError

      // Fetch progress metrics
      const { data: progressData, error: progressError } = await supabase
        .from('progress_metrics')
        .select('*')
        .eq('patient_id', config.value.patient_id)
        .gte('date', config.value.start_date)
        .lte('date', config.value.end_date)
        .order('date', { ascending: true })

      if (progressError) throw progressError

      // Fetch sessions for adherence and accuracy
      const { data: sessions, error: sessionsError } = await supabase
        .from('sessions')
        .select(`
          *,
          exercise:exercises(name, category),
          session_logs(accuracy_score, range_of_motion)
        `)
        .eq('patient_id', config.value.patient_id)
        .gte('started_at', config.value.start_date)
        .lte('started_at', config.value.end_date)

      if (sessionsError) throw sessionsError

      // Only completed sessions count: an in_progress or paused row is an attempt that was left (the app
      // writes nothing when the patient leaves), and the database marks a finished one with completed_at.
      const completedSessions = (sessions ?? []).filter((s) => s.status === 'completed' && s.completed_at)

      // Calculate metrics
      const totalSessions = completedSessions.length
      // accuracy now comes from session_logs.accuracy_score, not the legacy
      // sessions.accuracy_percent column (never written by the current app —
      // see reportStore accuracy investigation). Sessions with no logged
      // accuracy are excluded from the average rather than counted as 0.
      const loggedAccuracyScores = completedSessions.flatMap((s) => scoredLogs(s.session_logs))
      // null (a dash on screen), not 0, when nothing has been scored yet
      const avgAccuracy = loggedAccuracyScores.length
        ? loggedAccuracyScores.reduce((sum, score) => sum + score, 0) / loggedAccuracyScores.length
        : null

      // No adherence figure: assigned plans store no frequency, so there is nothing to measure it against.

      // Calculate ROM improvement
      const romImprovement = progressData && progressData.length > 1
        ? (progressData[progressData.length - 1]?.rom_degrees ?? 0) - (progressData[0]?.rom_degrees ?? 0)
        : 0

      // Prepare chart data
      const romProgress = progressData?.map(p => ({
        date: p.date,
        value: p.rom_degrees ?? 0
      })) || []

      // Completed sessions per week
      const weeklySessions = groupSessionsByWeek(completedSessions)

      // Exercise breakdown
      const exerciseBreakdown = calculateExerciseBreakdown(completedSessions)

      // Assemble report data
      data.value = {
        patient,
        metrics: {
          avg_accuracy: avgAccuracy,
          total_sessions: totalSessions,
          rom_improvement: romImprovement
        },
        chart_data: {
          rom_progress: romProgress,
          weekly_sessions: weeklySessions
        },
        exercise_breakdown: exerciseBreakdown
      }

      return { success: true, data: data.value }
    } catch (err: any) {
      error.value = err.message
      console.error('Error generating report:', err)
      return { success: false, error: error.value }
    } finally {
      isGenerating.value = false
    }
  }

  async function exportPDF(elementId: string) {
    if (!data.value) {
      error.value = 'No report data to export'
      return { success: false, error: error.value }
    }

    isGenerating.value = true

    try {
      const element = document.getElementById(elementId)
      if (!element) throw new Error('Report element not found')

      // Capture the element as canvas
      const canvas = await html2canvas(element, {
        scale: 2,
        logging: false,
        useCORS: true
      })

      // Convert to PDF
      const imgData = canvas.toDataURL('image/png')
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      const imgWidth = 210 // A4 width in mm
      const imgHeight = (canvas.height * imgWidth) / canvas.width

      pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, imgHeight)

      // Generate filename
      const [today = 'report'] = new Date().toISOString().split('T')
      const filename = `STREAM_Report_${data.value.patient.name.replace(/\s+/g, '_')}_${today}.pdf`

      // Download
      pdf.save(filename)

      return { success: true }
    } catch (err: any) {
      error.value = err.message
      console.error('Error exporting PDF:', err)
      return { success: false, error: error.value }
    } finally {
      isGenerating.value = false
    }
  }

  function updateConfig(updates: Partial<Report>) {
    config.value = { ...config.value, ...updates }
  }

  function clearReport() {
    data.value = null
    config.value = {
      type: 'progress',
      patient_id: '',
      start_date: '',
      end_date: ''
    }
  }

  // Helper functions

  /**
   * The scores of the logs that are a real measurement. An exercise that is not counted automatically is
   * stored with score 0 and no range of motion; averaging those 0s in would drag the average down for doing
   * exercises the app cannot score, so a score of 0 with no range of motion (and a null score) is left out.
   */
  function scoredLogs(
    logs: Array<{ accuracy_score: number | null; range_of_motion: number | null }> | null | undefined,
  ): number[] {
    return (logs ?? [])
      .filter((log) => log.accuracy_score !== null && !(log.accuracy_score === 0 && log.range_of_motion === null))
      .map((log) => log.accuracy_score as number)
  }
  function groupSessionsByWeek(sessions: any[]) {
    const weekMap = new Map<string, number>()

    sessions.forEach(session => {
      const date = new Date(
          session.started_at ?? session.completed_at ?? session.date
        )
      const weekStart = new Date(date.setDate(date.getDate() - date.getDay()))
      const [weekKey = weekStart.toISOString()] = weekStart.toISOString().split('T')

      weekMap.set(weekKey, (weekMap.get(weekKey) || 0) + 1)
    })

    return Array.from(weekMap.entries()).map(([week, count]) => ({
      week,
      value: count
    }))
  }

  function calculateExerciseBreakdown(sessions: any[]) {
    const exerciseMap = new Map<string, { count: number; totalAccuracy: number; accuracyCount: number }>()

    sessions.forEach(session => {
      const exerciseName = session.exercise?.name || 'Unknown'
      const current = exerciseMap.get(exerciseName) || { count: 0, totalAccuracy: 0, accuracyCount: 0 }

      // accuracy comes from session_logs.accuracy_score, not the legacy
      // sessions.accuracy_percent column — see generateReport's avgAccuracy
      // for the same fix. Sessions/logs with no accuracy score don't
      // contribute to totalAccuracy or accuracyCount, so they're excluded
      // from the average rather than counted as 0.
      const accuracyScores = scoredLogs(session.session_logs)

      exerciseMap.set(exerciseName, {
        count: current.count + 1,
        totalAccuracy: current.totalAccuracy + accuracyScores.reduce((sum: number, score: number) => sum + score, 0),
        accuracyCount: current.accuracyCount + accuracyScores.length
      })
    })

    return Array.from(exerciseMap.entries()).map(([name, stats]) => ({
      exercise_name: name,
      sessions_count: stats.count,
      avg_accuracy: stats.accuracyCount ? stats.totalAccuracy / stats.accuracyCount : null
    }))
  }

  return {
    // State
    config,
    data,
    isGenerating,
    error,
    // Actions
    generateReport,
    exportPDF,
    updateConfig,
    clearReport
  }
})
