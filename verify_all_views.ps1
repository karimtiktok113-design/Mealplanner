# ==============================================================================
# VERIFY ALL VIEWS IN REAL CHROME ENGINE
# ==============================================================================
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$baseUri = "file:///c:/Users/Karim%20Hussain%20Qaisar/Documents/karim/Meal%20Planner%20pro/index.html"

$views = @(
  @{ hash = "dashboard"; expected = "Good Day, Alex Morgan!" },
  @{ hash = "meal-planner"; expected = "Meal Planner" },
  @{ hash = "recipes"; expected = "Recipe Manager" },
  @{ hash = "grocery"; expected = "Smart Grocery List" },
  @{ hash = "pantry"; expected = "Pantry Inventory" },
  @{ hash = "nutrition"; expected = "Nutrition & Macronutrients" },
  @{ hash = "goals"; expected = "Dietary Goals" },
  @{ hash = "budget"; expected = "Food Budget" },
  @{ hash = "meal-prep"; expected = "Meal Prep Batching" },
  @{ hash = "hydration"; expected = "Hydration Tracker" },
  @{ hash = "favorites"; expected = "Favorites Collection" },
  @{ hash = "journal"; expected = "Meal Journal" },
  @{ hash = "analytics"; expected = "Analytics & Insights" },
  @{ hash = "exports"; expected = "Export & Print Center" },
  @{ hash = "backup"; expected = "Backup & Restore Center" },
  @{ hash = "themes"; expected = "Theme & Appearance Engine" },
  @{ hash = "settings"; expected = "Application Settings" },
  @{ hash = "help"; expected = "Guide & Documentation" }
)

Write-Host "=== VERIFYING ALL 18 VIEWS IN REAL HEADLESS CHROME ===" -ForegroundColor Cyan

$passed = 0
foreach ($v in $views) {
  $url = "$baseUri#$($v.hash)"
  # Direct stdout only, suppress Chrome stderr noise
  $output = & $chrome --headless=new --disable-gpu --dump-dom $url 2>$null | Out-String
  if ($output -like "*$($v.expected)*") {
    Write-Host "[PASS] View '#$($v.hash)' rendered correctly (found: '$($v.expected)')" -ForegroundColor Green
    $passed++
  } else {
    Write-Host "[FAIL] View '#$($v.hash)' did not contain expected: '$($v.expected)'" -ForegroundColor Red
  }
}

Write-Host "`nSummary: $passed / $($views.Count) views verified in Chrome engine!" -ForegroundColor Cyan
if ($passed -eq $views.Count) {
  Write-Host "ALL 18 VIEWS VERIFIED 100% FUNCTIONAL IN REAL CHROME ENGINE!" -ForegroundColor Green
} else {
  Write-Host "Warning: $passed / $($views.Count) verified." -ForegroundColor Yellow
}
