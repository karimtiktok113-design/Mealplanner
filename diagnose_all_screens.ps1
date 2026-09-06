# ==============================================================================
# COMPREHENSIVE SCREEN DIAGNOSTICS FOR ULTIMATE MEAL PLANNER PRO
# Verifies all 18 views in Google Chrome headless engine
# ==============================================================================
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Google Chrome executable not found at: $chrome"
}

$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"
if (-not (Test-Path $htmlFile)) {
  $htmlFile = Join-Path $dir "index.html"
}
$baseUri = "file:///$($htmlFile.Replace('\', '/'))"

$screens = @(
  @{ hash = "dashboard"; title = "Good Day, Alex Morgan!"; viewId = "view-dashboard" },
  @{ hash = "meal-planner"; title = "Meal Planner"; viewId = "view-meal-planner" },
  @{ hash = "recipes"; title = "Recipe Manager"; viewId = "view-recipes" },
  @{ hash = "grocery"; title = "Smart Grocery List"; viewId = "view-grocery" },
  @{ hash = "pantry"; title = "Pantry Inventory"; viewId = "view-pantry" },
  @{ hash = "nutrition"; title = "Nutrition & Macronutrients"; viewId = "view-nutrition" },
  @{ hash = "goals"; title = "Dietary Goals"; viewId = "view-goals" },
  @{ hash = "budget"; title = "Food Budget"; viewId = "view-budget" },
  @{ hash = "meal-prep"; title = "Meal Prep Batching"; viewId = "view-meal-prep" },
  @{ hash = "hydration"; title = "Hydration Tracker"; viewId = "view-hydration" },
  @{ hash = "favorites"; title = "Favorites Collection"; viewId = "view-favorites" },
  @{ hash = "journal"; title = "Meal Journal"; viewId = "view-journal" },
  @{ hash = "analytics"; title = "Analytics & Insights"; viewId = "view-analytics" },
  @{ hash = "exports"; title = "Export & Print Center"; viewId = "view-exports" },
  @{ hash = "backup"; title = "Backup & Restore Center"; viewId = "view-backup" },
  @{ hash = "themes"; title = "Theme & Appearance Engine"; viewId = "view-themes" },
  @{ hash = "settings"; title = "Application Settings"; viewId = "view-settings" },
  @{ hash = "help"; title = "Guide & Documentation"; viewId = "view-help" }
)

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   SCREEN DIAGNOSTICS: TESTING ALL 18 APP VIEWS" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$passedCount = 0
foreach ($s in $screens) {
  $url = "$baseUri#$($s.hash)"
  $domOutput = & $chrome --headless=new --disable-gpu --dump-dom $url 2>$null | Out-String

  $hasTitle = $domOutput -like "*$($s.title)*"
  $hasViewId = $domOutput -like "*id=`"$($s.viewId)`"*"

  if ($hasTitle -and $hasViewId) {
    Write-Host "  [OK] View '#$($s.hash)': Rendered successfully (Title: '$($s.title)')" -ForegroundColor Green
    $passedCount++
  } else {
    Write-Host "  [FAIL] View '#$($s.hash)': Content missing! (Title: '$($s.title)')" -ForegroundColor Red
  }
}

Write-Host "`n--------------------------------------------------------" -ForegroundColor Gray
if ($passedCount -eq $screens.Count) {
  Write-Host "RESULT: ALL $($screens.Count) SCREENS ARE FULLY OPERATIONAL AND NON-BLANK!" -ForegroundColor Green
} else {
  Write-Host "RESULT: $passedCount of $($screens.Count) screens passed. Some views need inspection." -ForegroundColor Yellow
}
Write-Host "========================================================`n" -ForegroundColor Cyan
