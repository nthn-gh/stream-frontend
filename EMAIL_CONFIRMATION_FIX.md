# 🔧 Fix: Email Rate Limit / Email Confirmation Issue

## Problem
When trying to register, you get:
- "Email rate limit exceeded"
- Supabase sends confirmation emails which are rate-limited
- You can't complete registration

---

## Solution 1: Disable Email Confirmation (EASIEST - for development)

### **Steps:**

1. Go to your **Supabase Dashboard**: https://supabase.com
2. Select your project
3. Go to **Authentication** → **Settings** (or **Auth** → **Settings**)
4. Find **Email Confirmation** section
5. **Toggle OFF** "Enable email confirmations"
6. Click **Save**

### What this does:
- ✅ Users can register without confirming email
- ✅ No confirmation emails sent
- ✅ No rate limits
- ✅ Perfect for development/testing

---

## Solution 2: Manually Create User in Supabase (QUICK)

If you can't change settings, create the user manually:

### **Steps:**

1. Go to **Supabase Dashboard**
2. Click **Authentication** → **Users**
3. Click **"Add user"** button
4. Fill in:
   - **Email:** test@example.com (any email you want)
   - **Password:** password123 (any password you want)
   - ✅ Check **"Auto Confirm User"**
5. Click **"Create user"**

Then run this SQL in **SQL Editor**:

```sql
-- Get the user ID that was just created
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 1;

-- Copy the ID from above, then run this (replace YOUR-USER-ID):
INSERT INTO public.users (id, email, role)
VALUES (
  'YOUR-USER-ID-HERE',  -- Paste the UUID from above
  (SELECT email FROM auth.users WHERE id = 'YOUR-USER-ID-HERE'),
  'therapist'
);

-- Create therapist profile
INSERT INTO public.therapist_profiles (user_id, name, clinic_name)
VALUES (
  'YOUR-USER-ID-HERE',  -- Same UUID
  'Dr. Test User',
  'Test Clinic'
);
```

---

## Solution 3: Wait and Try Again

Email rate limits usually reset after:
- **1 hour** - Most common
- **24 hours** - For stricter limits

---

## Recommended Approach

**For Development:**
1. Disable email confirmation (Solution 1)
2. Register normally through the app
3. Everything will work instantly

**For Production:**
- Keep email confirmation enabled
- Set up proper SMTP (not rate-limited)
- Configure email templates

---

## After Disabling Email Confirmation:

1. Go to http://localhost:5173/register
2. Fill out the form with ANY email (doesn't need to be real)
3. Click "Create Account"
4. Should work immediately!
5. Redirects to login
6. Log in with the credentials you just created
7. See the dashboard! 🎉

---

**Quick Fix:** Go to Supabase → Authentication → Settings → Disable "Email Confirmation" → Try registering again!
