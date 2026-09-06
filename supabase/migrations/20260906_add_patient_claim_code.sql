-- ============================================================
-- Add patient self-link "claim code" mechanism
--
-- Context: AddPatientModal.vue creates `patients` rows with
-- user_id: null, intended to be claimed when the patient
-- self-registers in Android using the same email. No RLS policy
-- currently permits the SELECT/UPDATE that linking needs (confirmed
-- live via pg_policies earlier this session), so linking silently
-- fails today and a disconnected duplicate patients row gets
-- created instead.
--
-- A naive fix (a policy matching only on auth.jwt()->>'email') was
-- considered and rejected: this project has email confirmation OFF
-- (STREAM_Project_Handoff_Summary.md, EMAIL_CONFIRMATION_FIX.md), so
-- auth.jwt()->>'email' is an unverified, self-reported string, not
-- proof of ownership. Patient emails are shared with patients by
-- therapists (not secret), so an email-only policy would let anyone
-- who learns a patient's email claim that patient's real clinical
-- record.
--
-- This migration adds a `claim_code` column and a SECURITY DEFINER
-- RPC function as the ONLY door for linking. No table-level
-- SELECT/UPDATE policy is added for this purpose -- a raw RLS
-- policy checking claim_code would provide no real protection here,
-- since RLS can only see the row's own data and session-level auth
-- facts (auth.uid(), auth.jwt()), not "did the client's own query
-- filter happen to include the correct code" -- a client could
-- simply omit that filter and rely on a weaker clause instead.
-- Routing the comparison through a function that takes the code as
-- a required parameter and performs the match + update atomically
-- server-side closes that gap: a wrong or missing code returns
-- NULL, full stop -- there is no path that lets a caller see or
-- affect a row without supplying the real code.
--
-- KNOWN LIMITATION, OUT OF SCOPE FOR THIS MIGRATION: rows created
-- before this migration have claim_code = NULL and can never be
-- claimed via this mechanism (NULL never equals any supplied code,
-- and no code was ever shown to a therapist to relay for them).
-- Backfilling codes for those existing orphaned rows -- and getting
-- the code to the affected patient through some out-of-band channel
-- -- is a separate, manual follow-up; this migration does not
-- attempt it.
--
-- PRE-FLIGHT -- run before executing, to confirm claim_code still
-- doesn't exist (already confirmed once this session, re-checking
-- in case anything changed since):
--
--   SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'patients' AND column_name = 'claim_code';
--   -- expect zero rows
-- ============================================================

BEGIN;

ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS claim_code text UNIQUE;

-- ------------------------------------------------------------
-- SECURITY DEFINER so it can update a row the calling patient
-- doesn't yet own (user_id IS NULL) without needing a broad
-- table-level policy that would otherwise have to grant that same
-- visibility to every authenticated caller. SET search_path = public
-- for the same hardening reason as is_admin()/role_unclaimed() in
-- earlier migrations -- pins schema resolution so a caller can't
-- redirect it via a session-level search_path change.
--
-- The email check (p_email IS DISTINCT FROM auth.jwt()->>'email')
-- is defense in depth, not the primary control -- with email
-- confirmation off it doesn't prove ownership, but it does prevent
-- a signed-in user from claiming a record under an email string that
-- doesn't even match what they themselves registered with.
-- claim_code is the actual gate: only someone who was actually given
-- the code by the therapist can succeed.
--
-- Returns the claimed patients.id, or NULL if nothing matched (wrong
-- code, wrong email, already-claimed row, or no such row at all --
-- deliberately not distinguished, so this can't be used to probe for
-- which of those was the reason).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_patient_record(p_email text, p_code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id uuid;
BEGIN
  IF p_email IS DISTINCT FROM (auth.jwt() ->> 'email') THEN
    RETURN NULL;
  END IF;

  IF p_code IS NULL OR btrim(p_code) = '' THEN
    RETURN NULL;
  END IF;

  UPDATE public.patients
  SET user_id = auth.uid()
  WHERE email = p_email
    AND claim_code = p_code
    AND user_id IS NULL
  RETURNING id INTO v_patient_id;

  RETURN v_patient_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_patient_record(text, text) TO authenticated;

COMMIT;

-- ============================================================
-- POST-FLIGHT -- run after applying:
--
--   SELECT column_name, data_type, is_nullable FROM information_schema.columns
--   WHERE table_name = 'patients' AND column_name = 'claim_code';
--   -- expect one row: text, nullable, no default
--
--   SELECT proname, prosecdef FROM pg_proc WHERE proname = 'claim_patient_record';
--   -- expect one row, prosecdef = true
--
-- Manual functional test once the app-side changes are also live:
--   1. Create a patient via AddPatientModal.vue -- note the email
--      and claim code shown in the success screen.
--   2. Register in Android as that patient, same email, entering the
--      code in the new "Invite Code" field.
--   3. Confirm exactly one patients row exists for that email
--      afterward (not two), with user_id now set and therapist_id
--      unchanged from what the therapist originally set.
--   4. Negative test: register with the same email but a wrong code
--      -- confirm a NEW, separate patients row is created instead
--      (the existing fallback behavior), not an error and not a
--      silent no-op.
-- ============================================================

-- ============================================================
-- ROLLBACK (manual -- not part of this migration):
--
--   DROP FUNCTION IF EXISTS public.claim_patient_record(text, text);
--   ALTER TABLE public.patients DROP COLUMN IF EXISTS claim_code;
-- ============================================================
