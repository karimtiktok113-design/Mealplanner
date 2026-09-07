$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING RECEIPT EDIT & RESPONSIVE INTERACTIVE CHART ===" -ForegroundColor Cyan

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
    if (!window.CalculationEngine) throw new Error('CalculationEngine is missing');
    if (!window.ModulesUI) throw new Error('ModulesUI is missing');
    if (!window.ModalService) throw new Error('ModalService is missing');

    // 1. Verify escapeHtml exists and works
    if (typeof window.escapeHtml !== 'function') throw new Error('window.escapeHtml is not defined');
    const safeStr = window.escapeHtml('<script>alert("hello & bye")</script>');
    if (safeStr.includes('<script>') || !safeStr.includes('&lt;script&gt;')) {
      throw new Error('escapeHtml failed: ' + safeStr);
    }
    log.push('[PASS] 1. escapeHtml safely escapes HTML special characters');

    // 2. Setup budget test data
    window.appState.budget = {
      weeklyBudget: 250,
      monthlyBudget: 1000,
      expenses: [
        { id: 'test_exp_1', store: 'Costco Wholesale', amount: 85.50, date: '2026-09-01', category: 'Meat', notes: 'Chicken breast' },
        { id: 'test_exp_2', store: 'Trader Joe', amount: 42.00, date: '2026-09-03', category: 'Produce', notes: 'Veggies' },
        { id: 'test_exp_3', store: 'Target', amount: 35.00, date: '2026-09-09', category: 'Dairy', notes: 'Milk and yogurt' }
      ]
    };
    window.budgetSelectedWeekStart = '2026-08-31';
    window.budgetChartYear = 2026;
    window.budgetChartMonth = 9;

    // Render budget module view
    window.ModulesUI.renderBudget();

    // 3. Test openEditExpenseModal
    window.ModalService.openEditExpenseModal('test_exp_2');
    const modalBackdrop = document.getElementById('modal-backdrop');
    if (!modalBackdrop || !modalBackdrop.classList.contains('open')) {
      throw new Error('Modal did not open');
    }
    const storeInput = document.getElementById('edit-exp-store');
    const amountInput = document.getElementById('edit-exp-amount');
    const dateInput = document.getElementById('edit-exp-date');
    const catInput = document.getElementById('edit-exp-cat');
    const notesInput = document.getElementById('edit-exp-notes');

    if (!storeInput || storeInput.value !== 'Trader Joe') throw new Error('Store input value mismatch');
    if (!amountInput || Number(amountInput.value) !== 42) throw new Error('Amount input value mismatch');
    if (!dateInput || dateInput.value !== '2026-09-03') throw new Error('Date input value mismatch');
    if (!catInput || catInput.value !== 'Produce') throw new Error('Category select mismatch');
    if (!notesInput || notesInput.value !== 'Veggies') throw new Error('Notes input mismatch');
    log.push('[PASS] 2. openEditExpenseModal populated all receipt fields accurately');

    // 4. Test saveEditedExpense: change amount to 60 and move date to 2026-09-10 (Week Sep 7-13)
    storeInput.value = "Trader Joe's Superstore";
    amountInput.value = '60.00';
    dateInput.value = '2026-09-10';
    catInput.value = 'Produce';
    notesInput.value = 'Organic Vegetables';
    window.ModalService.saveEditedExpense('test_exp_2');

    const editedExp = window.appState.budget.expenses.find(e => e.id === 'test_exp_2');
    if (!editedExp || editedExp.store !== "Trader Joe's Superstore" || editedExp.amount !== 60 || editedExp.date !== '2026-09-10') {
      throw new Error('saveEditedExpense failed to update receipt fields in appState');
    }
    if (window.budgetSelectedWeekStart !== '2026-09-07') {
      throw new Error('Selected week should have synced to 2026-09-07. Got: ' + window.budgetSelectedWeekStart);
    }
    log.push('[PASS] 3. saveEditedExpense updated receipt and synced active week navigation');

    // Verify recalculations for both weeks
    const weekAug31 = window.CalculationEngine.calculateBudgetMetrics('2026-08-31');
    const weekSep7 = window.CalculationEngine.calculateBudgetMetrics('2026-09-07');
    if (weekAug31.totalExpenses !== 85.50) throw new Error('Week Aug 31 expenses should be 85.50. Got: ' + weekAug31.totalExpenses);
    if (weekSep7.totalExpenses !== 95.00) throw new Error('Week Sep 7 expenses should be 95.00 (35 + 60). Got: ' + weekSep7.totalExpenses);
    log.push('[PASS] 4. CalculationEngine recalculated both affected weeks correctly');

    // 5. Test Chart Interaction: select week via column
    window.ModulesUI.selectBudgetWeek('2026-08-31');
    if (window.budgetSelectedWeekStart !== '2026-08-31') {
      throw new Error('selectBudgetWeek failed to set active week');
    }
    log.push('[PASS] 5. selectBudgetWeek switches active week view');

    // 6. Test Chart Tooltip: trigger showBudgetChartTooltip with weekKey
    const firstCol = document.querySelector('.budget-week-column');
    if (!firstCol) throw new Error('No .budget-week-column rendered');
    const fakeEvent = { currentTarget: firstCol };
    window.ModulesUI.showBudgetChartTooltip(fakeEvent, '2026-09-07');
    const tooltip = document.getElementById('budget-chart-tooltip');
    if (!tooltip || tooltip.style.display !== 'block') {
      throw new Error('Tooltip was not displayed');
    }
    if (!tooltip.innerHTML.includes('Weekly Budget:') || !tooltip.innerHTML.includes('Weekly Expenses:') || !tooltip.innerHTML.includes('Remaining Budget:')) {
      throw new Error('Tooltip missing essential metrics');
    }
    window.ModulesUI.hideBudgetChartTooltip();
    if (tooltip.style.display !== 'none') {
      throw new Error('hideBudgetChartTooltip did not hide tooltip');
    }
    log.push('[PASS] 6. showBudgetChartTooltip and hideBudgetChartTooltip work interactively');

    // 7. Test Month Navigation
    window.ModulesUI.navigateBudgetMonth(1);
    if (window.budgetChartMonth !== 10) throw new Error('Month navigation +1 failed');
    window.ModulesUI.navigateBudgetMonth(-1);
    if (window.budgetChartMonth !== 9) throw new Error('Month navigation -1 failed');
    log.push('[PASS] 7. Month navigation navigates across months smoothly');

    // Append success banner
    const banner = document.createElement('div');
    banner.id = 'test-suite-success';
    banner.innerHTML = '=== ALL RECEIPT EDIT & RESPONSIVE CHART TESTS PASSED! ===<br>' + log.join('<br>');
    document.body.appendChild(banner);
  } catch(err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'test-suite-error';
    errDiv.textContent = 'ERROR: ' + err.message;
    document.body.appendChild(errDiv);
    console.error(err);
  }
});
</script>
'@

$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injectedContent = $content.Replace("</body>", "$testScript`n</body>")
$tempHtml = Join-Path $dir "temp_test_receipt_edit.html"
Set-Content -Path $tempHtml -Value $injectedContent -Encoding utf8

try {
  $uri = "file:///$($tempHtml.Replace('\', '/'))#budget"
  $cmdOutput = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"$uri`" 2>nul"

  if ($cmdOutput -like "*=== ALL RECEIPT EDIT & RESPONSIVE CHART TESTS PASSED! ===*") {
    Write-Host "`n=== ALL RECEIPT EDIT & RESPONSIVE CHART TESTS PASSED! ===" -ForegroundColor Green
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
    throw "Receipt Edit & Chart tests failed."
  }
} finally {
  if (Test-Path $tempHtml) {
    Remove-Item $tempHtml -Force
  }
}
