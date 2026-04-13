@echo off
echo ========================================
echo STREAM Dashboard Refactor - Apply Views
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Backing up original view files...
if exist "src\views\DashboardView.vue" copy /Y "src\views\DashboardView.vue" "src\views\DashboardView.OLD.vue" >nul
if exist "src\views\AlertsView.vue" copy /Y "src\views\AlertsView.vue" "src\views\AlertsView.OLD.vue" >nul
if exist "src\views\ReportsView.vue" copy /Y "src\views\ReportsView.vue" "src\views\ReportsView.OLD.vue" >nul
if exist "src\views\SettingsView.vue" copy /Y "src\views\SettingsView.vue" "src\views\SettingsView.OLD.vue" >nul
echo Backups created.

echo.
echo Step 2: Replacing with new versions...
if exist "src\views\DashboardView.NEW.vue" (
    copy /Y "src\views\DashboardView.NEW.vue" "src\views\DashboardView.vue" >nul
    del "src\views\DashboardView.NEW.vue"
    echo - DashboardView.vue replaced
)
if exist "src\views\AlertsView.NEW.vue" (
    copy /Y "src\views\AlertsView.NEW.vue" "src\views\AlertsView.vue" >nul
    del "src\views\AlertsView.NEW.vue"
    echo - AlertsView.vue replaced
)
if exist "src\views\ReportsView.NEW.vue" (
    copy /Y "src\views\ReportsView.NEW.vue" "src\views\ReportsView.vue" >nul
    del "src\views\ReportsView.NEW.vue"
    echo - ReportsView.vue replaced
)
if exist "src\views\SettingsView.NEW.vue" (
    copy /Y "src\views\SettingsView.NEW.vue" "src\views\SettingsView.vue" >nul
    del "src\views\SettingsView.NEW.vue"
    echo - SettingsView.vue replaced
)

echo.
echo ========================================
echo Refactor Complete!
echo ========================================
echo.
echo Original files backed up as .OLD.vue
echo New no-scroll versions are now active
echo.
echo Next steps:
echo 1. npm run dev
echo 2. Test at 1440x900px viewport
echo 3. Verify zero scrolling on main layout
echo.
pause
