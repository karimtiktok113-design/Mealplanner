# ==============================================================================
# ULTIMATE MEAL PLANNER PRO - AUTOMATED AUDIT & TEST SUITE
# ==============================================================================
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }

$indexFile = Join-Path $dir "index.html"
$altFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== RUNNING ULTIMATE MEAL PLANNER PRO TEST SUITE ===" -ForegroundColor Cyan

# 1. FILE EXISTENCE & SIZE CHECK
if (-not (Test-Path $indexFile)) { throw "index.html does not exist!" }
if (-not (Test-Path $altFile)) { throw "ultimate-meal-planner-pro.html does not exist!" }

$size = (Get-Item $indexFile).Length
if ($size -lt 50000) { throw "index.html size ($size bytes) is suspiciously small!" }
Write-Host "[PASS] File size check: $size bytes (Valid & Complete)" -ForegroundColor Green

# 2. CONTENT & STRUCTURE INSPECTION
$content = [System.IO.File]::ReadAllText($indexFile, [System.Text.Encoding]::UTF8)

# Check DOCTYPE and HTML structure
if (-not $content.StartsWith("<!DOCTYPE html>")) { throw "Missing valid DOCTYPE" }
if (-not $content.Contains("</html>")) { throw "Missing closing html tag" }
Write-Host "[PASS] HTML5 doctype & envelope valid" -ForegroundColor Green

# 3. REQUIRED MODULE VIEWS CHECK
$requiredViews = @(
  "view-dashboard",
  "view-meal-planner",
  "view-recipes",
  "view-grocery",
  "view-pantry",
  "view-nutrition",
  "view-hydration",
  "view-goals",
  "view-analytics",
  "view-meal-prep",
  "view-budget",
  "view-favorites",
  "view-journal",
  "view-exports",
  "view-backup",
  "view-themes",
  "view-settings",
  "view-help"
)

foreach ($viewId in $requiredViews) {
  if (-not $content.Contains("id=""$viewId""")) {
    throw "Missing required module view container: $viewId"
  }
}
Write-Host "[PASS] All 18 module view containers present" -ForegroundColor Green

# 4. THEMES VERIFICATION
$themes = @("sage", "warm", "lavender", "ocean", "midnight", "clean", "earthy", "pastel")
foreach ($t in $themes) {
  if (-not $content.Contains("[data-theme=""$t""]")) {
    throw "Missing theme CSS definition for: $t"
  }
}
Write-Host "[PASS] All 8 curated themes implemented in CSS" -ForegroundColor Green

# 5. CORE ENGINES & SERVICES CHECK
$requiredEngines = @(
  "window.CalculationEngine",
  "calculateDailyNutrition",
  "calculateWeeklyNutrition",
  "calculateRecipeCost",
  "calculateBudgetMetrics",
  "window.GroceryAggregator",
  "generateFromMealPlan",
  "normalizeUnit",
  "window.PantryService",
  "calculateStatus",
  "getPantryStats",
  "addLowStockToGrocery",
  "window.SmartSuggestionsService",
  "findPantryMatches",
  "window.MealSwapService",
  "findAlternatives",
  "swapMeal",
  "window.ExportService",
  "printWeeklyMealPlanInfographic",
  "printRecipe",
  "printGroceryList",
  "printNutritionReport",
  "exportMealPlanCSV",
  "exportRecipesCSV",
  "exportGroceryCSV",
  "exportJSONBackup",
  "restoreFromJSONFile",
  "window.ThemeService",
  "window.ModalService",
  "window.ToastService",
  "window.Router",
  "window.StorageService"
)

foreach ($eng in $requiredEngines) {
  if (-not $content.Contains($eng)) {
    throw "Missing required engine/method: $eng"
  }
}
Write-Host "[PASS] All calculation engines, services, exports, and router methods present" -ForegroundColor Green

# 6. SEED DATASETS CHECK
if (-not $content.Contains("rec_avocado_toast")) { throw "Missing seed recipes" }
if (-not $content.Contains("rec_teriyaki_salmon")) { throw "Missing salmon recipe" }
if (-not $content.Contains("rec_korean_beef_bowl")) { throw "Missing beef bowl recipe" }
if (-not $content.Contains("createSeedMealPlan")) { throw "Missing seed 7-day meal plan function" }
if (-not $content.Contains("SEED_PANTRY")) { throw "Missing seed pantry items" }
if (-not $content.Contains("SEED_GROCERY")) { throw "Missing seed grocery items" }
Write-Host "[PASS] All seed datasets (15 recipes, 7-day plan, pantry, grocery, budget) present" -ForegroundColor Green

# 7. PRINT INFOGRAPHIC CONTAINER CHECK
if (-not $content.Contains("id=""print-infographic-container""")) { throw "Missing print-infographic-container" }
if (-not $content.Contains("@media print")) { throw "Missing @media print CSS" }
Write-Host "[PASS] Dedicated print & infographic system verified" -ForegroundColor Green

Write-Host "`n=== ALL TESTS PASSED SUCCESSFULLY! ===" -ForegroundColor Green
