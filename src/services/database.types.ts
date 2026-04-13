export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type AlertType = 'missed_session' | 'low_performance' | 'technical_issue'
export type AlertPriority = 'high' | 'moderate' | 'low'
export type ExercisePlanStatus = 'active' | 'completed' | 'draft'
export type ExerciseCategory = 'upper_body' | 'lower_body' | 'balance' | 'flexibility'
export type ExerciseDifficulty = 'easy' | 'medium' | 'hard'
export type NotificationType =
  | 'session_reminder'
  | 'therapist_message'
  | 'plan_updated'
  | 'achievement'
export type PatientStatus = 'active' | 'needs_attention' | 'inactive'
export type SessionFormQuality = 'excellent' | 'good' | 'needs_work'
export type UserRole = 'therapist' | 'patient' | 'admin'

export type Database = {
  public: {
    Tables: {
      alerts: {
        Row: {
          created_at: string | null
          id: string
          message: string
          patient_id: string
          priority: AlertPriority
          resolved: boolean | null
          resolved_at: string | null
          type: AlertType
        }
        Insert: {
          created_at?: string | null
          id?: string
          message: string
          patient_id: string
          priority: AlertPriority
          resolved?: boolean | null
          resolved_at?: string | null
          type: AlertType
        }
        Update: {
          created_at?: string | null
          id?: string
          message?: string
          patient_id?: string
          priority?: AlertPriority
          resolved?: boolean | null
          resolved_at?: string | null
          type?: AlertType
        }
        Relationships: [
          {
            foreignKeyName: 'alerts_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
        ]
      }
      exercise_plans: {
        Row: {
          created_at: string | null
          end_date: string
          id: string
          name: string
          patient_id: string
          start_date: string
          status: ExercisePlanStatus | null
          therapist_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          end_date: string
          id?: string
          name: string
          patient_id: string
          start_date: string
          status?: ExercisePlanStatus | null
          therapist_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          end_date?: string
          id?: string
          name?: string
          patient_id?: string
          start_date?: string
          status?: ExercisePlanStatus | null
          therapist_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'exercise_plans_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'exercise_plans_therapist_id_fkey'
            columns: ['therapist_id']
            isOneToOne: false
            referencedRelation: 'therapist_profiles'
            referencedColumns: ['id']
          },
        ]
      }
      exercise_sessions: {
        Row: {
          completion_percent: number
          created_at: string | null
          duration_seconds: number
          exercise_name: string
          id: string
          patient_id: string | null
          reps_completed: number
          score: string
          target_reps: number
          user_id: string
        }
        Insert: {
          completion_percent: number
          created_at?: string | null
          duration_seconds: number
          exercise_name: string
          id?: string
          patient_id?: string | null
          reps_completed: number
          score: string
          target_reps?: number
          user_id: string
        }
        Update: {
          completion_percent?: number
          created_at?: string | null
          duration_seconds?: number
          exercise_name?: string
          id?: string
          patient_id?: string | null
          reps_completed?: number
          score?: string
          target_reps?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'exercise_sessions_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
        ]
      }
      exercises: {
        Row: {
          category: ExerciseCategory
          created_at: string | null
          description: string | null
          difficulty: ExerciseDifficulty
          duration_minutes: number | null
          id: string
          instructions: string | null
          name: string
          thumbnail_url: string | null
        }
        Insert: {
          category: ExerciseCategory
          created_at?: string | null
          description?: string | null
          difficulty: ExerciseDifficulty
          duration_minutes?: number | null
          id?: string
          instructions?: string | null
          name: string
          thumbnail_url?: string | null
        }
        Update: {
          category?: ExerciseCategory
          created_at?: string | null
          description?: string | null
          difficulty?: ExerciseDifficulty
          duration_minutes?: number | null
          id?: string
          instructions?: string | null
          name?: string
          thumbnail_url?: string | null
        }
        Relationships: []
      }
      messages: {
        Row: {
          content: string
          created_at: string | null
          id: string
          read_at: string | null
          receiver_id: string
          sender_id: string
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          receiver_id: string
          sender_id: string
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          receiver_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'messages_receiver_id_fkey'
            columns: ['receiver_id']
            isOneToOne: false
            referencedRelation: 'users'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'messages_sender_id_fkey'
            columns: ['sender_id']
            isOneToOne: false
            referencedRelation: 'users'
            referencedColumns: ['id']
          },
        ]
      }
      notifications: {
        Row: {
          body: string
          created_at: string | null
          id: string
          read: boolean | null
          title: string
          type: NotificationType
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string | null
          id?: string
          read?: boolean | null
          title: string
          type: NotificationType
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string | null
          id?: string
          read?: boolean | null
          title?: string
          type?: NotificationType
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'notifications_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'users'
            referencedColumns: ['id']
          },
        ]
      }
      patients: {
        Row: {
          adherence_rate: number | null
          age: number | null
          avatar_url: string | null
          avg_accuracy: number | null
          condition: string
          created_at: string | null
          current_streak: number | null
          email: string
          enrolled_date: string | null
          id: string
          last_session: string | null
          name: string
          status: PatientStatus | null
          stroke_type: string | null
          total_sessions: number | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          adherence_rate?: number | null
          age?: number | null
          avatar_url?: string | null
          avg_accuracy?: number | null
          condition: string
          created_at?: string | null
          current_streak?: number | null
          email: string
          enrolled_date?: string | null
          id?: string
          last_session?: string | null
          name: string
          status?: PatientStatus | null
          stroke_type?: string | null
          total_sessions?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          adherence_rate?: number | null
          age?: number | null
          avatar_url?: string | null
          avg_accuracy?: number | null
          condition?: string
          created_at?: string | null
          current_streak?: number | null
          email?: string
          enrolled_date?: string | null
          id?: string
          last_session?: string | null
          name?: string
          status?: PatientStatus | null
          stroke_type?: string | null
          total_sessions?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'patients_user_id_fkey'
            columns: ['user_id']
            isOneToOne: true
            referencedRelation: 'users'
            referencedColumns: ['id']
          },
        ]
      }
      plan_exercises: {
        Row: {
          difficulty: ExerciseDifficulty | null
          duration_minutes: number | null
          exercise_id: string
          id: string
          order: number | null
          plan_id: string
          reps: number | null
          sets: number | null
          special_instructions: string | null
        }
        Insert: {
          difficulty?: ExerciseDifficulty | null
          duration_minutes?: number | null
          exercise_id: string
          id?: string
          order?: number | null
          plan_id: string
          reps?: number | null
          sets?: number | null
          special_instructions?: string | null
        }
        Update: {
          difficulty?: ExerciseDifficulty | null
          duration_minutes?: number | null
          exercise_id?: string
          id?: string
          order?: number | null
          plan_id?: string
          reps?: number | null
          sets?: number | null
          special_instructions?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'plan_exercises_exercise_id_fkey'
            columns: ['exercise_id']
            isOneToOne: false
            referencedRelation: 'exercises'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'plan_exercises_plan_id_fkey'
            columns: ['plan_id']
            isOneToOne: false
            referencedRelation: 'exercise_plans'
            referencedColumns: ['id']
          },
        ]
      }
      progress_metrics: {
        Row: {
          adherence_percent: number | null
          balance_score: number | null
          created_at: string | null
          date: string
          id: string
          patient_id: string
          rom_degrees: number | null
          strength_score: number | null
        }
        Insert: {
          adherence_percent?: number | null
          balance_score?: number | null
          created_at?: string | null
          date?: string
          id?: string
          patient_id: string
          rom_degrees?: number | null
          strength_score?: number | null
        }
        Update: {
          adherence_percent?: number | null
          balance_score?: number | null
          created_at?: string | null
          date?: string
          id?: string
          patient_id?: string
          rom_degrees?: number | null
          strength_score?: number | null
        }
        Relationships: [
          {
            foreignKeyName: 'progress_metrics_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
        ]
      }
      session_notes: {
        Row: {
          created_at: string | null
          id: string
          note: string
          patient_id: string
          session_id: string | null
          therapist_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          note: string
          patient_id: string
          session_id?: string | null
          therapist_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          note?: string
          patient_id?: string
          session_id?: string | null
          therapist_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'session_notes_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'session_notes_session_id_fkey'
            columns: ['session_id']
            isOneToOne: false
            referencedRelation: 'sessions'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'session_notes_therapist_id_fkey'
            columns: ['therapist_id']
            isOneToOne: false
            referencedRelation: 'therapist_profiles'
            referencedColumns: ['id']
          },
        ]
      }
      sessions: {
        Row: {
          accuracy_percent: number | null
          created_at: string | null
          date: string
          duration_minutes: number | null
          exercise_id: string
          form_quality: SessionFormQuality | null
          id: string
          notes: string | null
          patient_id: string
          reps_completed: number | null
          sets_completed: number | null
        }
        Insert: {
          accuracy_percent?: number | null
          created_at?: string | null
          date?: string
          duration_minutes?: number | null
          exercise_id: string
          form_quality?: SessionFormQuality | null
          id?: string
          notes?: string | null
          patient_id: string
          reps_completed?: number | null
          sets_completed?: number | null
        }
        Update: {
          accuracy_percent?: number | null
          created_at?: string | null
          date?: string
          duration_minutes?: number | null
          exercise_id?: string
          form_quality?: SessionFormQuality | null
          id?: string
          notes?: string | null
          patient_id?: string
          reps_completed?: number | null
          sets_completed?: number | null
        }
        Relationships: [
          {
            foreignKeyName: 'sessions_exercise_id_fkey'
            columns: ['exercise_id']
            isOneToOne: false
            referencedRelation: 'exercises'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'sessions_patient_id_fkey'
            columns: ['patient_id']
            isOneToOne: false
            referencedRelation: 'patients'
            referencedColumns: ['id']
          },
        ]
      }
      therapist_profiles: {
        Row: {
          avatar_url: string | null
          clinic_name: string | null
          created_at: string | null
          email_alerts: boolean | null
          id: string
          in_app_alerts: boolean | null
          license_number: string | null
          name: string
          updated_at: string | null
          user_id: string
          weekly_summary: boolean | null
        }
        Insert: {
          avatar_url?: string | null
          clinic_name?: string | null
          created_at?: string | null
          email_alerts?: boolean | null
          id?: string
          in_app_alerts?: boolean | null
          license_number?: string | null
          name: string
          updated_at?: string | null
          user_id: string
          weekly_summary?: boolean | null
        }
        Update: {
          avatar_url?: string | null
          clinic_name?: string | null
          created_at?: string | null
          email_alerts?: boolean | null
          id?: string
          in_app_alerts?: boolean | null
          license_number?: string | null
          name?: string
          updated_at?: string | null
          user_id?: string
          weekly_summary?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: 'therapist_profiles_user_id_fkey'
            columns: ['user_id']
            isOneToOne: true
            referencedRelation: 'users'
            referencedColumns: ['id']
          },
        ]
      }
      users: {
        Row: {
          created_at: string | null
          email: string
          id: string
          role: UserRole
        }
        Insert: {
          created_at?: string | null
          email: string
          id: string
          role: UserRole
        }
        Update: {
          created_at?: string | null
          email?: string
          id?: string
          role?: UserRole
        }
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
