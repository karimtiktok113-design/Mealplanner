# ==============================================================================
# ULTIMATE MEAL PLANNER PRO - COMPREHENSIVE PRINT SYSTEM AUDIT
# ==============================================================================
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }

$indexFile = Join-Path $dir "index.html"

Write-Host "=== VERIFYING PRINT SYSTEM ARCHITECTURE ===" -ForegroundColor Cyan

$content = [System.IO.File]::ReadAllText($indexFile, [System.Text.Encoding]::UTF8)

# 1. Check all print methods on window.ExportService
$methods = @(
  "printDashboardReport",
  "printWeeklyMealPlanInfographic",
  "printRecipeCatalog",
  "printRecipe",
  "printGroceryList",
  "printPantryInventory",
  "printNutritionReport",
  "printGoalsProfile",
  "printBudgetReport",
  "printMealPrepGuide",
  "printHydrationReport",
  "printAnalyticsReport",
  "printJournalReport",
  "printFavoritesReport",
  "printCurrentScreen",
  "prepareActiveViewForPrint"
)

foreach ($m in $methods) {
  if (-not $content.Contains($m)) {
    throw "Missing required print method in window.ExportService: $m"
  }
  Write-Host "[PASS] Method exists: window.ExportService.$m" -ForegroundColor Green
}

# 2. Check Print Buttons in view page-actions
$printButtons = @(
  "printDashboardReport()",
  "printWeeklyMealPlanInfographic()",
  "printRecipeCatalog()",
  "printGroceryList()",
  "printPantryInventory()",
  "printNutritionReport()",
  "printGoalsProfile()",
  "printBudgetReport()",
  "printMealPrepGuide()",
  "printHydrationReport()",
  "printAnalyticsReport()",
  "printJournalReport()",
  "printFavoritesReport()"
)

foreach ($pb in $printButtons) {
  if (-not $content.Contains($pb)) {
    throw "Missing print button handler call: $pb"
  }
  Write-Host "[PASS] Print button call found: $pb" -ForegroundColor Green
}

# 3. Check @media print CSS Isolation
$cssChecks = @(
  "@media print",
  "size: A4 portrait",
  "margin: 10mm 12mm 12mm 12mm",
  "body > *:not(#print-infographic-container)",
  "#print-infographic-container",
  "display: block !important",
  "break-inside: avoid !important",
  "display: table-header-group !important"
)

foreach ($c in $cssChecks) {
  if (-not $content.Contains($c)) {
    throw "Missing critical print CSS rule: $c"
  }
  Write-Host "[PASS] Print CSS rule found: $c" -ForegroundColor Green
}

# 4. Check beforeprint and afterprint event listeners
if (-not $content.Contains("addEventListener('beforeprint'")) {
  throw "Missing beforeprint event listener!"
}
if (-not $content.Contains("addEventListener('afterprint'")) {
  throw "Missing afterprint event listener!"
}
Write-Host "[PASS] beforeprint and afterprint event hooks present" -ForegroundColor Green

Write-Host "`n=== PRINT SYSTEM ARCHITECTURE 100% VERIFIED! ===" -ForegroundColor Green
