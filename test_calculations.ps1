# ==============================================================================
# TEST CALCULATIONS & AGGREGATION ALGORITHMS
# ==============================================================================
$ErrorActionPreference = "Continue"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$dir = (Get-Location).Path
$p3 = Join-Path $dir "parts\03_core_data_state.js"
$p4 = Join-Path $dir "parts\04_calculations_services.js"

Write-Host "=== TESTING CALCULATION ENGINE & AGGREGATION IN ENGINE ===" -ForegroundColor Cyan

$testHtml = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body>
<script>
$(Get-Content $p3 -Raw)
</script>
<script>
$(Get-Content $p4 -Raw)
</script>
<script>
  window.addEventListener('DOMContentLoaded', () => {
    const results = [];
    
    // 1. Test unit normalization
    results.push(window.GroceryAggregator.normalizeUnit('Grams') === 'g');
    results.push(window.GroceryAggregator.normalizeUnit('kilogram') === 'kg');
    results.push(window.GroceryAggregator.normalizeUnit('Milliliters') === 'ml');

    // 2. Test canAggregate
    results.push(window.GroceryAggregator.canAggregate('g', 'kg') === true);
    results.push(window.GroceryAggregator.canAggregate('ml', 'l') === true);
    results.push(window.GroceryAggregator.canAggregate('cups', 'g') === false);

    // 3. Test base unit conversion
    const b1 = window.GroceryAggregator.toBaseUnit(2, 'kg');
    results.push(b1.qty === 2000 && b1.unit === 'g');

    // 4. Test format back
    const f1 = window.GroceryAggregator.formatFromBaseUnit(1500, 'g');
    results.push(f1.qty === 1.5 && f1.unit === 'kg');

    // 5. Test nutrition calculation
    const today = window.formatDateISO();
    const nutri = window.CalculationEngine.calculateDailyNutrition(today);
    results.push(nutri.totals.calories > 0);
    results.push(nutri.totals.protein > 0);

    // 6. Test pantry recipe suggestions
    const suggestions = window.SmartSuggestionsService.findPantryMatches();
    results.push(suggestions.length > 0);

    const allPassed = results.every(x => x === true);
    document.body.innerText = allPassed ? 'CALCULATIONS_ALL_PASS' : 'CALCULATIONS_FAIL';
  });
</script>
</body>
</html>
"@

$testFile = Join-Path $dir "test_math.html"
[System.IO.File]::WriteAllText($testFile, $testHtml, [System.Text.Encoding]::UTF8)

# Run via cmd to cleanly redirect stderr to nul
$output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($testFile.Replace('\', '/'))`" 2>nul"

if ($output -like "*CALCULATIONS_ALL_PASS*") {
  Write-Host "[PASS] Unit normalization, aggregation, nutrition calculation, and pantry matching verified!" -ForegroundColor Green
} else {
  Write-Host "[FAIL] Calculations test output: $output" -ForegroundColor Red
}

Remove-Item $testFile -ErrorAction SilentlyContinue
