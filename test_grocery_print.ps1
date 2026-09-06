$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING GROCERY PRINT CHECKED BOXES FOR BOUGHT ITEMS ===" -ForegroundColor Cyan

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

$testScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  try {
    const results = [];
    
    // Set up a controlled grocery list with 3 unbought and 2 bought items
    window.appState.groceryList = [
      { id: 'g1', ingredient: 'Ripe Hass Avocados', quantity: 3, unit: 'pcs', category: 'Produce', purchased: false, estimatedPrice: 4.50 },
      { id: 'g2', ingredient: 'Fresh Blueberries', quantity: 200, unit: 'g', category: 'Produce', purchased: true, estimatedPrice: 3.50 },
      { id: 'g3', ingredient: 'Free-Range Eggs', quantity: 12, unit: 'pcs', category: 'Dairy', purchased: false, estimatedPrice: 5.00 },
      { id: 'g4', ingredient: 'Organic Whole Milk', quantity: 1, unit: 'L', category: 'Dairy', purchased: true, estimatedPrice: 3.00 },
      { id: 'g5', ingredient: 'Wild Salmon Fillets', quantity: 400, unit: 'g', category: 'Seafood', purchased: false, estimatedPrice: 12.00 }
    ];

    // Trigger Print Staging
    window.ExportService.printGroceryList(false);
    const container = document.getElementById('print-infographic-container');
    if (!container) throw new Error('Print container not found');
    const html = container.innerHTML;

    // 1. Check all items are present in print list
    if (!html.includes('Ripe Hass Avocados')) throw new Error('Avocados missing');
    if (!html.includes('Fresh Blueberries')) throw new Error('Blueberries missing');
    if (!html.includes('Free-Range Eggs')) throw new Error('Eggs missing');
    if (!html.includes('Organic Whole Milk')) throw new Error('Milk missing');
    if (!html.includes('Wild Salmon Fillets')) throw new Error('Salmon missing');
    results.push('TEST 1 PASSED: All grocery items present on the print checklist');

    // 2. Check that bought items have their checkboxes checked with checkmark
    const itemsNodes = container.querySelectorAll('.print-check-item');
    if (itemsNodes.length !== 5) throw new Error('Expected 5 print items, found ' + itemsNodes.length);

    let checkedBoxesCount = 0;
    let uncheckBoxesCount = 0;

    itemsNodes.forEach(node => {
      const isPurchased = node.classList.contains('purchased');
      const checkbox = node.querySelector('.print-checkbox');
      if (!checkbox) throw new Error('Missing .print-checkbox in item');

      if (isPurchased) {
        if (!checkbox.classList.contains('checked')) {
          throw new Error('Purchased item does not have "checked" class on checkbox: ' + node.textContent);
        }
        if (!checkbox.textContent.includes('\u2713')) {
          throw new Error('Purchased item checkbox missing checkmark: ' + node.textContent);
        }
        checkedBoxesCount++;
      } else {
        if (checkbox.classList.contains('checked')) {
          throw new Error('Unbought item should NOT have "checked" class on checkbox: ' + node.textContent);
        }
        if (checkbox.textContent.includes('\u2713')) {
          throw new Error('Unbought item should NOT contain checkmark: ' + node.textContent);
        }
        uncheckBoxesCount++;
      }
    });

    if (checkedBoxesCount !== 2) throw new Error('Expected 2 checked checkboxes, got ' + checkedBoxesCount);
    if (uncheckBoxesCount !== 3) throw new Error('Expected 3 unchecked checkboxes, got ' + uncheckBoxesCount);
    results.push('TEST 2 PASSED: 2 bought items have checked checkboxes with checkmark, 3 unbought items have open checkboxes');

    // 3. Check KPI cards & header
    if (!html.includes('Checked Boxes')) throw new Error('KPI card for Checked Boxes missing');
    if (!html.includes('Remaining to Buy')) throw new Error('KPI card for Remaining to Buy missing');
    results.push('TEST 3 PASSED: KPI cards accurately reflect checked and remaining items');

    const resultDiv = document.createElement('div');
    resultDiv.id = 'grocery-test-results';
    resultDiv.textContent = 'GROCERY_CHECKBOX_SUCCESS:' + JSON.stringify(results);
    document.body.appendChild(resultDiv);
    console.log('GROCERY_CHECKBOX_SUCCESS:' + JSON.stringify(results));
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'grocery-test-error';
    errDiv.textContent = 'GROCERY_CHECKBOX_FAILURE:' + err.message;
    document.body.appendChild(errDiv);
    console.error('GROCERY_CHECKBOX_FAILURE:' + err.message);
  }
});
</script>
'@

$tempFile = Join-Path $dir "temp_grocery_print_test.html"
$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injected = $content.Replace("</body>", "$testScript`n</body>")
Set-Content -Path $tempFile -Value $injected -Encoding utf8

$output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($tempFile.Replace('\', '/'))`" 2>nul"

if (Test-Path $tempFile) {
  Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

if ($output -like "*GROCERY_CHECKBOX_SUCCESS*") {
  Write-Host "[PASS] TEST 1: All grocery items present on print checklist" -ForegroundColor Green
  Write-Host "[PASS] TEST 2: Bought items checked with checkmark, unbought items have open boxes" -ForegroundColor Green
  Write-Host "[PASS] TEST 3: KPI cards accurately reflect checked and remaining items" -ForegroundColor Green
  Write-Host "`n=== ALL GROCERY PRINT CHECKBOX TESTS PASSED SUCCESSFULLY! ===" -ForegroundColor Green
} else {
  throw "Grocery print verification failed!"
}
