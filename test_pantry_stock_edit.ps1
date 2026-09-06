$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING PANTRY STOCK QUANTITY EDITING FEATURE ===" -ForegroundColor Cyan

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
    if (!window.PantryService) throw new Error('PantryService is missing');
    if (!window.ModulesUI) throw new Error('ModulesUI is missing');
    if (!window.ModalService) throw new Error('ModalService is missing');

    // 1. Setup controlled test pantry items
    window.appState.pantry = [
      { id: 'p_test1', item: 'Rolled Oats', quantity: 500, unit: 'g', category: 'Grains', minStock: 200, status: 'In Stock', expiryDate: '2026-12-01' },
      { id: 'p_test2', item: 'Greek Yogurt', quantity: 150, unit: 'g', category: 'Dairy', minStock: 250, status: 'Low Stock', expiryDate: '2026-12-01' },
      { id: 'p_test3', item: 'Eggs', quantity: 0, unit: 'pcs', category: 'Dairy', minStock: 6, status: 'Out of Stock', expiryDate: '2026-12-01' }
    ];

    // TEST 1: PantryService.updatePantryQuantity direct update & status recalculation
    const updated1 = window.PantryService.updatePantryQuantity('p_test1', 120);
    if (!updated1 || updated1.quantity !== 120) throw new Error('updatePantryQuantity failed to set 120. Got: ' + (updated1 && updated1.quantity));
    if (updated1.status !== 'Low Stock') throw new Error('updatePantryQuantity status should be Low Stock (120 <= 200). Got: ' + updated1.status);
    log.push('[PASS] TEST 1: updatePantryQuantity direct update & status recalculation');

    // TEST 2: Setting quantity to 0 yields 'Out of Stock'
    const updatedZero = window.PantryService.updatePantryQuantity('p_test1', 0);
    if (updatedZero.status !== 'Out of Stock') throw new Error('Quantity 0 should yield Out of Stock. Got: ' + updatedZero.status);
    log.push('[PASS] TEST 2: Quantity 0 yields Out of Stock');

    // TEST 3: Restocking to 600 yields 'In Stock'
    const updatedHigh = window.PantryService.updatePantryQuantity('p_test1', 600);
    if (updatedHigh.status !== 'In Stock') throw new Error('Quantity 600 should yield In Stock. Got: ' + updatedHigh.status);
    log.push('[PASS] TEST 3: Restocking above minStock yields In Stock');

    // TEST 4: PantryService.updatePantryItem comprehensive update
    const updatedFull = window.PantryService.updatePantryItem('p_test2', {
      item: 'Organic Greek Yogurt',
      quantity: 450,
      unit: 'g',
      category: 'Dairy',
      minStock: 100,
      cost: 4.25
    });
    if (updatedFull.item !== 'Organic Greek Yogurt' || updatedFull.quantity !== 450 || updatedFull.cost !== 4.25) {
      throw new Error('updatePantryItem failed to update all properties.');
    }
    if (updatedFull.status !== 'In Stock') throw new Error('Status should be In Stock after update');
    log.push('[PASS] TEST 4: updatePantryItem full property update');

    // TEST 5: Render pantry view and check inline stock badge & edit buttons
    window.ModulesUI.renderPantry();
    const container = document.getElementById('view-pantry');
    if (!container) throw new Error('view-pantry missing');
    const html = container.innerHTML;

    if (!html.includes('pantry-stock-badge') || !html.includes('openQuickEditPantryQty')) {
      throw new Error('Pantry card missing interactive pantry-stock-badge or openQuickEditPantryQty trigger');
    }
    if (!html.includes('openEditPantryModal')) {
      throw new Error('Pantry card missing openEditPantryModal edit button');
    }
    log.push('[PASS] TEST 5: Pantry cards render stock badge and edit triggers');

    // TEST 6: Inline quick edit open, save, and cancellation
    window.ModulesUI.openQuickEditPantryQty('p_test1');
    const inlineInput = document.getElementById('inline-qty-p_test1');
    if (!inlineInput) throw new Error('inline-qty-p_test1 input not found after openQuickEditPantryQty');
    if (parseFloat(inlineInput.value) !== 600) throw new Error('Inline input should have value 600. Got: ' + inlineInput.value);

    // Modify inline input and save
    inlineInput.value = '750';
    window.ModulesUI.saveQuickEditPantryQty('p_test1');
    const p1Item = window.appState.pantry.find(x => x.id === 'p_test1');
    if (p1Item.quantity !== 750) throw new Error('saveQuickEditPantryQty failed to update quantity to 750. Got: ' + p1Item.quantity);
    log.push('[PASS] TEST 6: Inline quick-edit successfully modified stock quantity');

    // TEST 7: openEditPantryModal elements and live preview
    window.ModalService.openEditPantryModal('p_test1');
    const modalContainer = document.getElementById('modal-container');
    if (!modalContainer) throw new Error('modal-container not found');

    const editQtyInput = document.getElementById('edit-pantry-qty');
    const editUnitInput = document.getElementById('edit-pantry-unit');
    const editPreviewBadge = document.getElementById('edit-pantry-status-preview');
    if (!editQtyInput || !editUnitInput || !editPreviewBadge) {
      throw new Error('Modal missing edit-pantry-qty, edit-pantry-unit, or edit-pantry-status-preview');
    }
    if (parseFloat(editQtyInput.value) !== 750) throw new Error('Modal input should have value 750');
    log.push('[PASS] TEST 7: openEditPantryModal rendered with stock quantity and status preview');

    // TEST 8: Quick adjustment nudges
    window.ModalService.nudgeEditPantryQty(100, 'p_test1');
    if (parseFloat(editQtyInput.value) !== 850) throw new Error('nudgeEditPantryQty +100 failed. Got: ' + editQtyInput.value);

    window.ModalService.setEditPantryQty(0, 'p_test1');
    if (parseFloat(editQtyInput.value) !== 0) throw new Error('setEditPantryQty 0 failed. Got: ' + editQtyInput.value);
    if (editPreviewBadge.textContent.trim() !== 'Out of Stock') {
      throw new Error('Preview badge should show Out of Stock for quantity 0. Got: ' + editPreviewBadge.textContent);
    }
    log.push('[PASS] TEST 8: Quick adjustment nudges (+100, zero-out) work seamlessly');

    // TEST 9: Save modal changes
    editQtyInput.value = '350';
    document.getElementById('edit-pantry-min').value = '150';
    window.ModalService.savePantryItemEdit('p_test1');
    const savedItem = window.appState.pantry.find(x => x.id === 'p_test1');
    if (savedItem.quantity !== 350 || savedItem.minStock !== 150) {
      throw new Error('savePantryItemEdit failed to persist 350 qty and 150 minStock');
    }
    log.push('[PASS] TEST 9: Edit Modal successfully modified stock quantity & thresholds');

    // TEST 10: Two-way sync with grocery list in-pantry tag
    window.appState.groceryList = [
      { id: 'g_test1', ingredient: 'Rolled Oats', quantity: 200, unit: 'g', purchased: false }
    ];
    window.ModulesUI.renderGrocery();
    const grocContainer = document.getElementById('view-grocery');
    const grocHtml = grocContainer ? grocContainer.innerHTML : '';
    if (!grocHtml.includes('In Pantry: 350 g')) {
      throw new Error('Grocery list should reflect In Pantry: 350 g. Rendered: ' + grocHtml);
    }
    log.push('[PASS] TEST 10: Grocery in-pantry tag updated seamlessly with edited stock quantity');

    const resultDiv = document.createElement('div');
    resultDiv.id = 'pantry-test-results';
    resultDiv.innerHTML = log.join('\n') + '\n=== ALL PANTRY STOCK EDIT TESTS PASSED! ===';
    document.body.appendChild(resultDiv);
    console.log('ALL_TESTS_PASSED');
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'pantry-test-error';
    errDiv.textContent = 'ERROR: ' + err.message;
    document.body.appendChild(errDiv);
    console.error(err);
  }
});
</script>
'@

$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injectedContent = $content.Replace("</body>", "$testScript`n</body>")
$tempHtml = Join-Path $dir "temp_test_pantry_edit.html"
Set-Content -Path $tempHtml -Value $injectedContent -Encoding utf8

try {
  $uri = "file:///$($tempHtml.Replace('\', '/'))#pantry"
  $cmdOutput = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"$uri`" 2>nul"

  if ($cmdOutput -like "*=== ALL PANTRY STOCK EDIT TESTS PASSED! ===*") {
    Write-Host "`n=== ALL PANTRY STOCK EDIT TESTS PASSED SUCCESSFULLY! ===" -ForegroundColor Green
    $lines = $cmdOutput -split "`r?`n"
    foreach ($line in $lines) {
      $trimmed = $line.Trim()
      if ($trimmed -like "*[PASS]*") {
        Write-Host "  $trimmed" -ForegroundColor Green
      }
    }
  } else {
    Write-Host "`n=== TESTS FAILED! ===" -ForegroundColor Red
    $lines = $cmdOutput -split "`r?`n"
    foreach ($line in $lines) {
      if ($line -like "*ERROR:*" -or $line -like "*Error:*") {
        Write-Host "  $line" -ForegroundColor Red
      }
    }
    throw "Pantry Stock Edit tests failed."
  }
} finally {
  if (Test-Path $tempHtml) {
    Remove-Item $tempHtml -Force
  }
}
