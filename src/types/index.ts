import type {
  Database,
  ExerciseDifficulty,
  ExercisePlanStatus,
  PatientStatus,
  SessionFormQuality,
  UserRole,
} from '@/services/database.types'

type Tables = Database['public']['Tables']
type Row<T extends keyof Tables> = Tables[T]['Row']
type Insert<T extends keyof Tables> = Tables[T]['Insert']
type Update<T extends keyof Tables> = Tables[T]['Update']

export type User = Row<'users'>
export type UserInsert = Insert<'users'>
export type UserUpdate = Update<'users'>

export type TherapistProfile = Row<'therapist_profiles'>
export type TherapistProfileInsert = Insert<'therapist_profiles'>
export type TherapistProfileUpdate = Update<'therapist_profiles'>

export type Patient = Row<'patients'>
export type PatientInsert = Insert<'patients'>
export type PatientUpdate = Update<'patients'>

export type Exercise = Row<'exercises'>
export type ExerciseInsert = Insert<'exercises'>
export type ExerciseUpdate = Update<'exercises'>

export type ExercisePlan = Row<'exercise_plans'>
export type ExercisePlanInsert = Insert<'exercise_plans'>
export type ExercisePlanUpdate = Update<'exercise_plans'>

export type PlanExercise = Row<'plan_exercises'>
export type PlanExerciseInsert = Insert<'plan_exercises'>
export type PlanExerciseUpdate = Update<'plan_exercises'>

export type Session = Row<'sessions'>
export type SessionInsert = Insert<'sessions'>
export type SessionUpdate = Update<'sessions'>

export type ProgressMetric = Row<'progress_metrics'>
export type ProgressMetricInsert = Insert<'progress_metrics'>
export type ProgressMetricUpdate = Update<'progress_metrics'>

export type Alert = Row<'alerts'>
export type AlertInsert = Insert<'alerts'>
export type AlertUpdate = Update<'alerts'>

export type SessionNote = Row<'session_notes'>
export type SessionNoteInsert = Insert<'session_notes'>
export type SessionNoteUpdate = Update<'session_notes'>

export interface AlertWithPatient extends Alert {
  patient: Pick<Patient, 'id' | 'name' | 'email' | 'avatar_url'> | null
}

export interface SessionWithExercise extends Session {
  exercise: Pick<Exercise, 'id' | 'name' | 'category' | 'difficulty'> | null
}

export interface SessionNoteWithTherapist extends SessionNote {
  therapist: Pick<TherapistProfile, 'id' | 'name'> | null
}

export interface PlanExerciseWithExercise extends PlanExercise {
  exercise: Exercise | null
}

export interface ExercisePlanWithExercises extends ExercisePlan {
  plan_exercises: PlanExerciseWithExercise[]
}

export interface ExerciseAssignmentDraft {
  client_id: string
  difficulty: ExerciseDifficulty
  duration_minutes: number
  exercise_id: string
  reps: number
  sets: number
  special_instructions: string | null
}

export interface Report {
  type: 'progress' | 'adherence' | 'performance'
  patient_id: string
  start_date: string
  end_date: string
  generated_by: string
  generated_at: string
}

export interface ReportData {
  patient: Patient
  metrics: {
    adherence: number
    avg_accuracy: number
    total_sessions: number
    rom_improvement: number
  }
  chart_data: {
    rom_progress: Array<{ date: string; value: number }>
    weekly_adherence: Array<{ week: string; value: number }>
  }
  exercise_breakdown: Array<{
    exercise_name: string
    sessions_count: number
    avg_accuracy: number
  }>
}

export interface LoginForm {
  email: string
  password: string
}

export interface ChangePasswordForm {
  current_password: string
  new_password: string
  confirm_password: string
}

export interface AssignExerciseForm {
  patient_id: string
  name: string
  start_date: string
  end_date: string
  exercises: Array<{
    exercise_id: string
    sets: number
    reps: number
    duration_minutes: number
    difficulty: ExerciseDifficulty
    special_instructions?: string | null
  }>
}

export interface BadgeVariant {
  variant: 'success' | 'warning' | 'error' | 'info' | 'neutral'
}

export interface StatCardProps {
  title: string
  value: string | number
  icon: unknown
  bgColor: string
  iconColor: string
}

export interface TableColumn {
  key: string
  label: string
  width?: string
  sortable?: boolean
  align?: 'left' | 'center' | 'right'
}

export interface TabItem {
  key: string
  label: string
  icon?: unknown
}

export interface ToastMessage {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message: string
  duration?: number
}

export type { ExerciseDifficulty, ExercisePlanStatus, PatientStatus, SessionFormQuality, UserRole }
