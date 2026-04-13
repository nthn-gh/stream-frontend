# STREAM Dashboard No-Scroll Refactor - Quick Start

## What Was Changed

This refactor makes the STREAM Therapist Dashboard fit perfectly in a 1440×900px viewport with ZERO scrolling on the main layout.

### Files Already Applied ✅

1. **src/App.vue** - Root layout with h-screen, overflow-hidden
2. **src/main.css** - Added typography CSS variables  
3. **src/components/layout/AppTopBar.vue** - Reduced to 56px height
4. **src/components/layout/AppSidebar.vue** - Fixed overflow handling

### Files Ready to Apply 📦

Four view files have .NEW versions ready:
- **DashboardView.NEW.vue** - Complete no-scroll refactor
- **AlertsView.NEW.vue** - Applied no-scroll pattern
- **ReportsView.NEW.vue** - Applied no-scroll pattern
- **SettingsView.NEW.vue** - Applied no-scroll pattern

## Apply the Changes

### Option 1: Batch File (Easiest)
```bash
apply-refactor.bat
```

### Option 2: PowerShell Script
```powershell
.\replace-views.ps1
```

### Option 3: Manual
1. Backup originals:
   ```bash
   cd src\views
   copy DashboardView.vue DashboardView.OLD.vue
   copy AlertsView.vue AlertsView.OLD.vue
   copy ReportsView.vue ReportsView.OLD.vue
   copy SettingsView.vue SettingsView.OLD.vue
   ```

2. Replace with new versions:
   ```bash
   copy DashboardView.NEW.vue DashboardView.vue /Y
   copy AlertsView.NEW.vue AlertsView.vue /Y
   copy ReportsView.NEW.vue ReportsView.vue /Y
   copy SettingsView.NEW.vue SettingsView.vue /Y
   ```

3. Clean up:
   ```bash
   del *.NEW.vue
   ```

## Test the Changes

1. Start the dev server:
   ```bash
   npm run dev
   ```

2. Open browser at http://localhost:5173

3. Set viewport to 1440×900px (Chrome DevTools or browser window)

4. Navigate to Dashboard and verify:
   - ✅ No scrollbar on body/main container
   - ✅ Patient table has scrollbar (if >8 patients)
   - ✅ Alert widget scrolls independently
   - ✅ Session widget scrolls independently
   - ✅ Sidebar collapse/expand works
   - ✅ All text sizes are smaller/tighter

5. Test other views:
   - Alerts: Content scrolls, header fixed
   - Reports: Content scrolls, header fixed
   - Settings: Content scrolls, tabs fixed

## Key Changes Summary

### Layout
- App wrapper: `h-screen overflow-hidden flex`
- Main content: `flex-1 overflow-hidden flex flex-col`
- Each view: `flex flex-col h-full overflow-hidden`

### Dashboard Specific
- Greeting: 48px height
- Stat cards: 88px height (from ~100px)
- Table: Fixed header/footer, scrollable body
- Widgets: Mix of fixed and scrollable

### Typography (All Views)
- Page titles: 20px (from 36px)
- Section titles: 14px (from 24px)
- Body text: 13px (from 16px)
- Labels: 12px (from 14px)
- Badges: 10-11px

### Spacing
- Padding: 20px (from 32px)
- Gaps: 12-16px (from 20px)
- Component heights: 30-36px (from 38-44px)

## Rollback

If you need to revert:

```bash
cd src\views
copy DashboardView.OLD.vue DashboardView.vue /Y
copy AlertsView.OLD.vue AlertsView.vue /Y
copy ReportsView.OLD.vue ReportsView.vue /Y
copy SettingsView.OLD.vue SettingsView.vue /Y
```

## Documentation

See `REFACTOR_COMPLETE.md` for full technical details and specifications.
