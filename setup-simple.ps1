# STREAM Therapist Dashboard - Simple Setup Script
# Run from: c:\Users\Ethan\stream\stream-frontend

Write-Host "========================================"
Write-Host " STREAM Therapist Dashboard Setup"
Write-Host "========================================"
Write-Host ""

# Create directory structure
Write-Host "[1/3] Creating directory structure..."

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
        Write-Host "  [OK] Created: $dir"
    } else {
        Write-Host "  [OK] Exists: $dir"
    }
}

# Create .env file
Write-Host ""
Write-Host "[2/3] Creating environment template..."

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
    Write-Host "  [OK] Created: .env"
} else {
    Write-Host "  [OK] .env already exists"
}

# Verify main.css
Write-Host ""
Write-Host "[3/3] Verifying main.css..."
if (Test-Path "src\main.css") {
    $cssContent = Get-Content "src\main.css" -Raw
    if ($cssContent -match "--color-primary") {
        Write-Host "  [OK] CSS tokens present"
    } else {
        Write-Host "  [WARN] CSS tokens missing - check main.css"
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Setup Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Update .env with your Supabase credentials"
Write-Host "  2. Let the assistant create all component files"
Write-Host "  3. Run: npm install (if needed)"
Write-Host "  4. Run: npm run dev"
Write-Host ""
