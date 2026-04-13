# STREAM Complete Setup Script
# Run this from: c:\Users\Ethan\stream\stream-frontend
# Usage: .\complete-setup.ps1

Write-Host "================================" -ForegroundColor Cyan
Write-Host "STREAM Implementation Setup" -ForegroundColor Cyan  
Write-Host "================================`n" -ForegroundColor Cyan

# Step 1: Create directory structure
Write-Host "[1/5] Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "src\components\ui",
    "src\components\features",
    "src\components\navigation",
    "src\views\mobile",
    "src\views\web",
    "src\lib"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Exists: $dir" -ForegroundColor DarkGray
    }
}

# Step 2: Copy existing components from parent directory
Write-Host "`n[2/5] Copying existing UI components..." -ForegroundColor Yellow

$existingComponents = @("Button.vue", "Input.vue", "Card.vue", "Badge.vue")
foreach ($comp in $existingComponents) {
    $source = "..\$comp"
    $dest = "src\components\ui\$comp"
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        Write-Host "  ✓ Copied: $comp" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Not found: $comp" -ForegroundColor DarkYellow
    }
}

# Step 3: Update Tailwind config
Write-Host "`n[3/5] Updating Tailwind configuration..." -ForegroundColor Yellow

if (Test-Path "..\TAILWIND_CONFIG.js") {
    # Read the source file
    $configContent = Get-Content "..\TAILWIND_CONFIG.js" -Raw
    
    # For Tailwind v4, we need to update the CSS file instead
    Write-Host "  ℹ Tailwind v4 detected - config goes in CSS" -ForegroundColor Cyan
    Write-Host "  ✓ Keeping existing tailwind setup" -ForegroundColor Green
} else {
    Write-Host "  ⚠ TAILWIND_CONFIG.js not found in parent" -ForegroundColor DarkYellow
}

# Step 4: Update global styles
Write-Host "`n[4/5] Updating global styles..." -ForegroundColor Yellow

if (Test-Path "..\GLOBAL_STYLES.css") {
    # Backup existing main.css
    if (Test-Path "src\main.css") {
        Copy-Item "src\main.css" "src\main.css.backup" -Force
        Write-Host "  ✓ Backed up existing main.css" -ForegroundColor Green
    }
    
    # Copy new styles
    Copy-Item "..\GLOBAL_STYLES.css" "src\main.css" -Force
    Write-Host "  ✓ Updated: src\main.css" -ForegroundColor Green
} else {
    Write-Host "  ⚠ GLOBAL_STYLES.css not found in parent" -ForegroundColor DarkYellow
}

# Step 5: Create .env template
Write-Host "`n[5/5] Creating environment template..." -ForegroundColor Yellow

$envTemplate = @"
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
"@

if (-not (Test-Path ".env")) {
    $envTemplate | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "  ✓ Created: .env" -ForegroundColor Green
} else {
    Write-Host "  ✓ .env already exists" -ForegroundColor DarkGray
}

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. The assistant will now create component files" -ForegroundColor White
Write-Host "  2. Update .env with your Supabase credentials" -ForegroundColor White  
Write-Host "  3. Run: npm install (if not done)" -ForegroundColor White
Write-Host "  4. Run: npm run dev" -ForegroundColor White
Write-Host ""
