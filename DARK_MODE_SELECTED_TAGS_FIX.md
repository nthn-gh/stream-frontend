# Dark Mode: Selected Exercise Tags Fix

## Issue
In dark mode, when selecting exercises in the "Assign Exercise" view (Step 2), the selected exercise tags at the bottom had white text on a white background, making them completely unreadable.

## Screenshot Evidence
User reported seeing white tags with invisible text in the "Selected: 1 exercise(s)" section.

## Root Cause
**Hardcoded color value**: The `.selected-tag` CSS class had `background: white;` which doesn't adapt to dark mode.

```css
/* BEFORE (broken in dark mode) */
.selected-tag {
  background: white;  /* ❌ Always white, even in dark mode */
  color: var(--text-primary);  /* This becomes white in dark mode */
}
```

This created a **white-on-white** contrast issue in dark mode:
- Light mode: ✅ Dark text on white background (readable)
- Dark mode: ❌ White text on white background (unreadable)

## Fix Applied

### File: `src/views/AssignExerciseView.vue`

**Changed line ~625:**
```css
/* BEFORE */
.selected-tag {
  background: white;
}

/* AFTER */
.selected-tag {
  background: var(--bg-input);
}
```

**Also fixed undefined CSS variable:**
```css
/* BEFORE */
.tag-remove:hover {
  color: var(--danger);  /* ❌ Undefined variable */
}

/* AFTER */
.tag-remove:hover {
  color: #EF4444;  /* ✅ Uses red from design system */
}
```

## How It Works Now

### Light Mode
- Background: `var(--bg-input)` → `#F8FAFC` (light gray)
- Text: `var(--text-primary)` → `#0F172A` (dark)
- **Result**: Dark text on light background ✅

### Dark Mode
- Background: `var(--bg-input)` → `#334155` (dark gray)
- Text: `var(--text-primary)` → `#F1F5F9` (light)
- **Result**: Light text on dark background ✅

## Testing Steps

1. **Navigate to Assign Exercise**:
   - Login as therapist
   - Click "Assign Exercise" in sidebar

2. **Select a patient** (Step 1)

3. **Select exercises** (Step 2):
   - Click checkboxes to select exercises
   - Look at "Selected: X exercise(s)" section at bottom

4. **Verify in both themes**:
   - Settings → Preferences → Theme: "Light"
     - Tags should have light gray background with dark text
   - Settings → Preferences → Theme: "Dark"
     - Tags should have dark gray background with light text
     - **Text should be clearly readable** ✅

5. **Test remove button**:
   - Hover over X button in selected tag
   - Should turn red (#EF4444)

## Visual Comparison

### Before (Broken in Dark Mode):
```
┌─────────────────────────────────┐
│ Selected: 1 exercise(s)         │
│ ┌───────────────────┐           │
│ │                   │ ← White text on white bg
│ │  Shoulder Flexion │ ← UNREADABLE
│ │                   │           │
│ └───────────────────┘           │
└─────────────────────────────────┘
```

### After (Fixed):
```
┌─────────────────────────────────┐
│ Selected: 1 exercise(s)         │
│ ┌───────────────────┐           │
│ │ Shoulder Flexion  │ ← Light text on dark gray bg
│ │                   │ ← READABLE ✅
│ └───────────────────┘           │
└─────────────────────────────────┘
```

## Related CSS Variables Used

From `src/main.css`:

```css
/* Light Mode */
:root {
  --bg-input: #F8FAFC;
  --text-primary: #0F172A;
  --border: #E2E8F0;
}

/* Dark Mode */
.dark {
  --bg-input: #334155;
  --text-primary: #F1F5F9;
  --border: #334155;
}
```

## Files Modified
- `src/views/AssignExerciseView.vue` - Fixed `.selected-tag` background and `.tag-remove:hover` color

## Additional Dark Mode Checks Performed

✅ All other styling in AssignExerciseView uses CSS variables
✅ No other hardcoded white/black colors found
✅ Exercise cards properly themed
✅ Selected summary section uses `var(--bg-hover)`
✅ Remove button uses `var(--text-muted)` with red hover

## Status
✅ **FIXED** - Selected exercise tags now properly visible in both light and dark modes

## Prevention
To avoid similar issues in the future:
1. **Never use hardcoded colors** like `white`, `black`, `#fff`, `#000`
2. **Always use CSS variables** from the design system
3. **Test both themes** when styling components
4. **Use consistent naming**: `--bg-*`, `--text-*`, `--border-*`
