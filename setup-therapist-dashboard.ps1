# STREAM Therapist Dashboard - Complete Setup Script
# Run from: c:\Users\Ethan\stream\stream-frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " STREAM Therapist Dashboard Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Create directory structure
Write-Host "[1/3] Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "src\components\shared",
    "src\components\layout",
    "src\views",
    "src\stores",
    "src\services",
    "src\types"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Exists: $dir" -ForegroundColor DarkGray
    }
}

# Create .env file
Write-Host "`n[2/3] Creating environment template..." -ForegroundColor Yellow

$envContent = @"
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_project_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here

# App Configuration
VITE_APP_NAME=STREAM Therapist Dashboard
VITE_APP_VERSION=1.0.0
"@

if (-not (Test-Path ".env")) {
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "  ✓ Created: .env" -ForegroundColor Green
} else {
    Write-Host "  ✓ .env already exists" -ForegroundColor DarkGray
}

# Verify main.css updated
Write-Host "`n[3/3] Verifying main.css..." -ForegroundColor Yellow
if (Test-Path "src\main.css") {
    $cssContent = Get-Content "src\main.css" -Raw
    if ($cssContent -match "--color-primary") {
        Write-Host "  ✓ CSS tokens present" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ CSS tokens missing - check main.css" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Update .env with your Supabase credentials" -ForegroundColor White
Write-Host "  2. Let the assistant create all component files" -ForegroundColor White
Write-Host "  3. Run: npm install (if needed)" -ForegroundColor White
Write-Host "  4. Run: npm run dev" -ForegroundColor White
Write-Host ""
