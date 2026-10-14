/**
 * Whether any patient statistic (sessions, average score, streak) is shown.
 *
 * Off. The numbers stored on `patients` (total_sessions, avg_accuracy, current_streak, adherence_rate) are
 * stale: they hold leftover test values, they are only recomputed when a session is completed, and
 * "adherence" has no defined target (plans store no frequency). Until the patient_stats view exists and
 * both apps read it (STREAM repo: docs/patient-stats-plan.md), no screen shows them. When switched on, a
 * real 0 shows "0" and anything not known shows a dash (never an invented 0).
 */
export const PATIENT_STATS_SHOWN = false

export const STAT_UNKNOWN = '—'

/** A count, or a dash when it is not known. A real 0 is "0". */
export function countText(value: number | null | undefined): string {
  return value === null || value === undefined ? STAT_UNKNOWN : String(value)
}

/** A whole percent, or a dash when it is not known. A real 0 is "0%". */
export function percentText(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return STAT_UNKNOWN
  const n = Number(value)
  return Number.isFinite(n) ? `${Math.round(n)}%` : STAT_UNKNOWN
}
