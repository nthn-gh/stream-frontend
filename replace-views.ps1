# STREAM Dashboard Refactor - File Replacement Script
# This script will replace the old view files with the new no-scroll versions

Write-Host "STREAM Dashboard Refactor - Applying Changes..." -ForegroundColor Cyan

$basePath = "c:\Users\Ethan\stream\stream-frontend\src\views"

# Function to backup and replace files
function Replace-ViewFile {
    param (
        [string]$ViewName
    )
    
    $oldFile = Join-Path $basePath "$ViewName.vue"
    $newFile = Join-Path $basePath "$ViewName.NEW.vue"
    $backupFile = Join-Path $basePath "$ViewName.OLD.vue"
    
    if (Test-Path $newFile) {
        Write-Host "Replacing $ViewName.vue..." -ForegroundColor Yellow
        
        # Backup old file if it exists
        if (Test-Path $oldFile) {
            Copy-Item $oldFile $backupFile -Force
            Write-Host "  - Backed up to $ViewName.OLD.vue" -ForegroundColor Gray
        }
        
        # Replace with new file
        Copy-Item $newFile $oldFile -Force
        Write-Host "  - Replaced with new version" -ForegroundColor Green
        
        # Remove the .NEW file
        Remove-Item $newFile -Force
        Write-Host "  - Cleaned up temporary file" -ForegroundColor Gray
    } else {
        Write-Host "Skipping $ViewName.vue (no new version found)" -ForegroundColor DarkGray
    }
}

# Replace view files
Write-Host "`nReplacing view files..." -ForegroundColor Cyan
Replace-ViewFile -ViewName "DashboardView"
Replace-ViewFile -ViewName "AlertsView"
Replace-ViewFile -ViewName "ReportsView"
Replace-ViewFile -ViewName "SettingsView"

Write-Host "`nDone! All files have been replaced." -ForegroundColor Green
Write-Host "Old versions backed up as .OLD.vue files" -ForegroundColor Gray
