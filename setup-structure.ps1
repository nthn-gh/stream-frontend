# STREAM Implementation Setup Script
# Run this script from: c:\Users\Ethan\stream\stream-frontend

Write-Host "Creating directory structure..." -ForegroundColor Green

# Create directories
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
        Write-Host "Created: $dir" -ForegroundColor Cyan
    } else {
        Write-Host "Exists: $dir" -ForegroundColor Yellow
    }
}

Write-Host "`nCopying existing components from parent directory..." -ForegroundColor Green

# Copy existing components from parent directory
$componentsToopy = @("Button.vue", "Input.vue", "Card.vue", "Badge.vue")
foreach ($comp in $componentsToopy) {
    $source = "..\$comp"
    $dest = "src\components\ui\$comp"
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        Write-Host "Copied: $comp" -ForegroundColor Cyan
    }
}

# Update Tailwind config
Write-Host "`nUpdating Tailwind configuration..." -ForegroundColor Green
Copy-Item "..\TAILWIND_CONFIG.js" "tailwind.config.js" -Force
Write-Host "Updated: tailwind.config.js" -ForegroundColor Cyan

# Update global styles  
Write-Host "`nUpdating global styles..." -ForegroundColor Green
Copy-Item "..\GLOBAL_STYLES.css" "src\main.css" -Force
Write-Host "Updated: src\main.css" -ForegroundColor Cyan

Write-Host "`n✅ Directory structure and configuration complete!" -ForegroundColor Green
Write-Host "Next: Component files will be created by the assistant." -ForegroundColor Yellow
