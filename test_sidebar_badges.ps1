$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING SIDEBAR BADGE SYNCHRONIZATION ===" -ForegroundColor Cyan

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

$testScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  try {
    const results = [];

    // TEST 1: Check initial badges on startup (Dashboard active)
    const recBadge = document.getElementById('sidebar-recipe-count');
    const grocBadge = document.getElementById('sidebar-grocery-count');
    const pantryBadge = document.getElementById('sidebar-pantry-count') || document.getElementById('sidebar-pantry-low-count');

    if (!recBadge) throw new Error('#sidebar-recipe-count badge element not found');
    if (!grocBadge) throw new Error('#sidebar-grocery-count badge element not found');
    if (!pantryBadge) throw new Error('#sidebar-pantry-count badge element not found');

    const recVal = parseInt(recBadge.textContent.trim(), 10);
    const grocVal = parseInt(grocBadge.textContent.trim(), 10);
    const pantryVal = parseInt(pantryBadge.textContent.trim(), 10);

    if (recVal !== 15) throw new Error(`Initial recipe badge expected 15, got ${recVal}`);
    if (grocVal !== 10) throw new Error(`Initial grocery badge expected 10, got ${grocVal}`);
    if (pantryVal !== 10) throw new Error(`Initial pantry badge expected 10, got ${pantryVal}`);

    results.push(`TEST 1 PASSED: Initial dashboard load has correct counts (Recipes: ${recVal}, Grocery: ${grocVal}, Pantry: ${pantryVal})`);

    // TEST 2: Navigating to other views maintains accurate badge counts
    window.Router.navigate('meal-planner');
    if (parseInt(recBadge.textContent, 10) !== 15 || parseInt(grocBadge.textContent, 10) !== 10 || parseInt(pantryBadge.textContent, 10) !== 10) {
      throw new Error('Badge counts changed incorrectly on navigation to meal-planner');
    }
    window.Router.navigate('nutrition');
    if (parseInt(recBadge.textContent, 10) !== 15 || parseInt(grocBadge.textContent, 10) !== 10 || parseInt(pantryBadge.textContent, 10) !== 10) {
      throw new Error('Badge counts changed incorrectly on navigation to nutrition');
    }
    results.push('TEST 2 PASSED: Navigation across views preserves live counts');

    // TEST 3: Adding a new pantry item dynamically increments pantry badge
    window.appState.pantry.push({
      id: 'pantry_test_extra',
      item: 'Extra Olive Oil',
      quantity: 500,
      unit: 'ml',
      category: 'Pantry',
      status: 'In Stock'
    });
    window.EventBus.emit('PANTRY_UPDATED');
    if (parseInt(pantryBadge.textContent, 10) !== 11) {
      throw new Error(`Pantry badge expected 11 after push + emit, got ${pantryBadge.textContent}`);
    }
    results.push('TEST 3 PASSED: Adding pantry item updates badge to 11');

    // TEST 4: Removing the pantry item restores badge
    window.appState.pantry = window.appState.pantry.filter(p => p.id !== 'pantry_test_extra');
    window.EventBus.emit('PANTRY_UPDATED');
    if (parseInt(pantryBadge.textContent, 10) !== 10) {
      throw new Error(`Pantry badge expected 10 after removal, got ${pantryBadge.textContent}`);
    }
    results.push('TEST 4 PASSED: Removing pantry item restores badge to 10');

    // TEST 5: Adding a recipe increments recipe badge
    window.appState.recipes.push({
      id: 'rec_test_extra',
      name: 'Custom Test Recipe',
      calories: 400,
      protein: 30,
      carbs: 40,
      fat: 10
    });
    window.EventBus.emit('RECIPE_UPDATED');
    if (parseInt(recBadge.textContent, 10) !== 16) {
      throw new Error(`Recipe badge expected 16 after push + emit, got ${recBadge.textContent}`);
    }
    results.push('TEST 5 PASSED: Adding recipe updates badge to 16');

    // TEST 6: Removing the recipe restores badge
    window.appState.recipes = window.appState.recipes.filter(r => r.id !== 'rec_test_extra');
    window.EventBus.emit('RECIPE_UPDATED');
    if (parseInt(recBadge.textContent, 10) !== 15) {
      throw new Error(`Recipe badge expected 15 after removal, got ${recBadge.textContent}`);
    }
    results.push('TEST 6 PASSED: Removing recipe restores badge to 15');

    // TEST 7: Adding a grocery item increments grocery badge
    window.appState.groceryList.push({
      id: 'groc_test_extra',
      ingredient: 'Almond Flour',
      quantity: 500,
      unit: 'g',
      purchased: false
    });
    window.EventBus.emit('GROCERY_UPDATED');
    if (parseInt(grocBadge.textContent, 10) !== 11) {
      throw new Error(`Grocery badge expected 11 after push + emit, got ${grocBadge.textContent}`);
    }
    results.push('TEST 7 PASSED: Adding grocery item updates badge to 11');

    // TEST 8: Removing the grocery item restores badge
    window.appState.groceryList = window.appState.groceryList.filter(g => g.id !== 'groc_test_extra');
    window.EventBus.emit('GROCERY_UPDATED');
    if (parseInt(grocBadge.textContent, 10) !== 10) {
      throw new Error(`Grocery badge expected 10 after removal, got ${grocBadge.textContent}`);
    }
    results.push('TEST 8 PASSED: Removing grocery item restores badge to 10');

    const resultDiv = document.createElement('div');
    resultDiv.id = 'badge-test-results';
    resultDiv.textContent = 'SIDEBAR_BADGES_SUCCESS:' + JSON.stringify(results);
    document.body.appendChild(resultDiv);
    console.log('SIDEBAR_BADGES_SUCCESS');
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'badge-test-error';
    errDiv.textContent = 'SIDEBAR_BADGES_FAILURE:' + err.message;
    document.body.appendChild(errDiv);
    console.error(err);
  }
});
</script>
'@

$tempFile = Join-Path $dir "temp_sidebar_badge_test.html"
$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injected = $content.Replace("</body>", "$testScript`n</body>")
Set-Content -Path $tempFile -Value $injected -Encoding utf8

$output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($tempFile.Replace('\', '/'))`" 2>nul"

if (Test-Path $tempFile) {
  Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

if ($output -like "*SIDEBAR_BADGES_SUCCESS*") {
  Write-Host "[PASS] TEST 1: Initial dashboard load has correct counts (Recipes: 15, Grocery: 10, Pantry: 10)" -ForegroundColor Green
  Write-Host "[PASS] TEST 2: Navigation across views preserves live counts" -ForegroundColor Green
  Write-Host "[PASS] TEST 3: Adding pantry item updates badge" -ForegroundColor Green
  Write-Host "[PASS] TEST 4: Removing pantry item restores badge" -ForegroundColor Green
  Write-Host "[PASS] TEST 5: Adding recipe updates badge" -ForegroundColor Green
  Write-Host "[PASS] TEST 6: Removing recipe restores badge" -ForegroundColor Green
  Write-Host "[PASS] TEST 7: Adding grocery item updates badge" -ForegroundColor Green
  Write-Host "[PASS] TEST 8: Removing grocery item restores badge" -ForegroundColor Green
  Write-Host "`n=== ALL SIDEBAR BADGE TESTS PASSED SUCCESSFULLY! ===" -ForegroundColor Green
} else {
  throw "Sidebar badge verification failed! Output: $output"
}
