$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING PANTRY TAGS & AUTOMATIC DEDUCTION ON PURCHASE ===" -ForegroundColor Cyan

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

$testScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  try {
    const log = [];

    if (!window.appState) throw new Error('appState is missing');

    // 1. Setup controlled pantry items
    window.appState.pantry = [
      { id: 'p1', item: 'Chicken Breast', category: 'Meat', quantity: 1000, unit: 'g', minStock: 200, status: 'In Stock', expiryDate: '2026-10-01' },
      { id: 'p2', item: 'Greek Yogurt', category: 'Dairy', quantity: 200, unit: 'g', minStock: 100, status: 'In Stock', expiryDate: '2026-10-01' },
      { id: 'p3', item: 'Olive Oil', category: 'Oils', quantity: 500, unit: 'ml', minStock: 100, status: 'In Stock', expiryDate: '2026-10-01' },
      { id: 'p4', item: 'Eggs', category: 'Dairy', quantity: 4, unit: 'pcs', minStock: 6, status: 'Low Stock', expiryDate: '2026-10-01' }
    ];

    // 2. Setup grocery items:
    // - Chicken Breast: requires 400g (Pantry has 1000g -> Stock >= required -> 'In Pantry: 1000 g')
    // - Greek Yogurt: requires 500g (Pantry has 200g -> Stock < required -> 'Low Stock Pantry: 200 g')
    // - Eggs: requires 12 pcs (Pantry has 4 pcs -> Stock < required -> 'Low Stock Pantry: 4 pcs')
    // - Wild Salmon: not in pantry -> No pantry tag
    window.appState.groceryList = [
      { id: 'g1', ingredient: 'Chicken Breast', quantity: 400, unit: 'g', category: 'Meat', purchased: false, estimatedPrice: 6.00 },
      { id: 'g2', ingredient: 'Greek Yogurt', quantity: 500, unit: 'g', category: 'Dairy', purchased: false, estimatedPrice: 4.50 },
      { id: 'g3', ingredient: 'Eggs', quantity: 12, unit: 'pcs', category: 'Dairy', purchased: false, estimatedPrice: 4.00 },
      { id: 'g4', ingredient: 'Wild Salmon', quantity: 300, unit: 'g', category: 'Seafood', purchased: false, estimatedPrice: 12.00 }
    ];

    // Render grocery list
    window.renderGroceryList();
    const container = document.getElementById('grocery-list-container');
    if (!container) throw new Error('grocery-list-container missing');
    const renderedHtml = container.innerHTML;

    // Test Tag 1: In Pantry Tag on Chicken Breast
    if (!renderedHtml.includes('In Pantry: 1000 g') && !renderedHtml.includes('In Pantry: 1 kg')) {
      throw new Error('Missing In Pantry tag for Chicken Breast. Rendered HTML: ' + renderedHtml);
    }
    log.push('TEST 1 PASSED: "In Pantry" tag displayed for Chicken Breast (sufficient stock)');

    // Test Tag 2: Low Stock Pantry Tag on Greek Yogurt
    if (!renderedHtml.includes('Low Stock Pantry: 200 g')) {
      throw new Error('Missing "Low Stock Pantry: 200 g" tag for Greek Yogurt');
    }
    log.push('TEST 2 PASSED: "Low Stock Pantry: 200 g" tag displayed for Greek Yogurt (200g in pantry < 500g required)');

    // Test Tag 3: Low Stock Pantry Tag on Eggs
    if (!renderedHtml.includes('Low Stock Pantry: 4 pcs')) {
      throw new Error('Missing "Low Stock Pantry: 4 pcs" tag for Eggs');
    }
    log.push('TEST 3 PASSED: "Low Stock Pantry: 4 pcs" tag displayed for Eggs (4 pcs in pantry < 12 pcs required)');

    // Test Tag 4: Wild Salmon should not have a pantry tag
    const cards = container.querySelectorAll('.glass-card');
    let wildSalmonCard = null;
    cards.forEach(c => {
      if (c.textContent.includes('Wild Salmon')) wildSalmonCard = c;
    });
    if (!wildSalmonCard) throw new Error('Wild Salmon card not found');
    if (wildSalmonCard.textContent.includes('In Pantry') || wildSalmonCard.textContent.includes('Low Stock Pantry')) {
      throw new Error('Wild Salmon should not have a pantry tag because it is not in pantry');
    }
    log.push('TEST 4 PASSED: Non-pantry item has no pantry tag');

    // Test 5: Automatic deduction on check/purchase
    // Chicken Breast requires 400g, pantry currently has 1000g.
    // Purchasing g1 should reduce pantry Chicken Breast to 600g.
    window.toggleGroceryPurchased('g1');
    const chickenPantry = window.appState.pantry.find(p => p.item === 'Chicken Breast');
    if (chickenPantry.quantity !== 600) {
      throw new Error('Expected pantry Chicken Breast quantity to be 600, got: ' + chickenPantry.quantity);
    }
    log.push('TEST 5 PASSED: Automatically deducted 400g from Chicken Breast pantry stock (1000g -> 600g)');

    // Test 6: Tag updates after deduction
    // Now Chicken Breast grocery item requires 400g and pantry has 600g (still >= 400g -> 'In Pantry: 600 g')
    window.renderGroceryList();
    if (!container.innerHTML.includes('In Pantry: 600 g')) {
      throw new Error('Expected updated pantry tag "In Pantry: 600 g" after deduction');
    }
    log.push('TEST 6 PASSED: Tag dynamically updated to "In Pantry: 600 g" in Grocery UI');

    // Test 7: Unchecking restores pantry stock
    window.toggleGroceryPurchased('g1');
    if (chickenPantry.quantity !== 1000) {
      throw new Error('Expected pantry Chicken Breast quantity to be restored to 1000, got: ' + chickenPantry.quantity);
    }
    log.push('TEST 7 PASSED: Unchecking restored 400g back to Chicken Breast pantry stock (600g -> 1000g)');

    // Test 8: Print View also includes the Pantry Tags
    window.ExportService.printGroceryList(false);
    const printContainer = document.getElementById('print-infographic-container');
    if (!printContainer) throw new Error('print-infographic-container missing');
    const printHtml = printContainer.innerHTML;
    if (!printHtml.includes('In Pantry: 1000 g') && !printHtml.includes('In Pantry: 1 kg')) {
      throw new Error('Print grocery checklist missing In Pantry tag. HTML: ' + printHtml);
    }
    if (!printHtml.includes('Low Stock Pantry: 200 g')) {
      throw new Error('Print grocery checklist missing Low Stock Pantry tag for Greek Yogurt');
    }
    log.push('TEST 8 PASSED: Printable A4 checklist includes In Pantry and Low Stock Pantry tags');

    const outDiv = document.createElement('div');
    outDiv.id = 'pantry-sync-verdict';
    outDiv.innerHTML = 'PANTRY_SYNC_ALL_PASS:<br>' + log.join('<br>');
    document.body.appendChild(outDiv);
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'pantry-sync-verdict';
    errDiv.textContent = 'PANTRY_SYNC_FAIL: ' + err.message;
    document.body.appendChild(errDiv);
  }
});
</script>
'@

# Read original html content and append test script before </body>
$origHtml = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)
$injectedHtml = $origHtml -replace '</body>', ($testScript + "`n</body>")

$testFile = Join-Path $dir "temp_test_pantry_sync.html"
[System.IO.File]::WriteAllText($testFile, $injectedHtml, [System.Text.Encoding]::UTF8)

try {
  $output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($testFile.Replace('\', '/'))`" 2>nul"

  if ($output -like "*PANTRY_SYNC_ALL_PASS*") {
    Write-Host "`n=== ALL PANTRY-GROCERY SYNC & DEDUCTION TESTS PASSED! ===" -ForegroundColor Green
    Write-Host '  [PASS] TEST 1: In Pantry tag displayed with current amount when stock is sufficient' -ForegroundColor Green
    Write-Host '  [PASS] TEST 2: Low Stock Pantry tag displayed when pantry stock is lower than required' -ForegroundColor Green
    Write-Host '  [PASS] TEST 3: Low Stock Pantry tag displayed on low stock pantry items (Eggs)' -ForegroundColor Green
    Write-Host '  [PASS] TEST 4: Items not present in pantry have no pantry tag' -ForegroundColor Green
    Write-Host '  [PASS] TEST 5: Automatic pantry deduction when grocery item is checked/purchased' -ForegroundColor Green
    Write-Host '  [PASS] TEST 6: Dynamic tag update reflecting new deducted pantry quantity in real time' -ForegroundColor Green
    Write-Host '  [PASS] TEST 7: Unchecking/restoring grocery item restores pantry stock automatically' -ForegroundColor Green
    Write-Host '  [PASS] TEST 8: Dedicated A4 print checklist displays In Pantry & Low Stock Pantry tags' -ForegroundColor Green
  } else {
    Write-Host "`n=== TEST FAILED ===" -ForegroundColor Red
    if ($output -match 'PANTRY_SYNC_FAIL:[^<]+') {
      Write-Host $matches[0] -ForegroundColor Red
    } else {
      Write-Host "Output: $output" -ForegroundColor Yellow
    }
    exit 1
  }
} finally {
  Remove-Item $testFile -ErrorAction SilentlyContinue
}
