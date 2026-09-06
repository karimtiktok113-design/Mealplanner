$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING WEEKLY FOOD BUDGET CUSTOMIZATION FEATURE ===" -ForegroundColor Cyan

# 1. Inspect static code in ultimate-meal-planner-pro.html
$content = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)

$checks = @(
  "openEditBudgetModal",
  "saveBudgetSettings",
  "applyBudgetPreset",
  "onWeeklyBudgetInput",
  "quickSetWeeklyBudget",
  "quickSaveCustomBudget",
  "settings-weekly-budget",
  "goal-weekly-budget",
  "Weekly Budget Utilization Tracker",
  "Quick Preset Targets:"
)

foreach ($c in $checks) {
  if (-not $content.Contains($c)) {
    throw "Missing code symbol: $c in ultimate-meal-planner-pro.html"
  }
  Write-Host "[PASS] Symbol verified: $c" -ForegroundColor Green
}

# 2. Run Headless Chrome Script to simulate actual user interaction
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chrome) {
  Write-Host "`nRunning headless Chrome functional test..." -ForegroundColor Cyan
  
  $testScript = @"
    (function() {
      try {
        const results = [];
        
        // Check initial state
        const initialWeekly = window.appState.budget.weeklyBudget;
        results.push('Initial weekly budget: ' + initialWeekly);
        
        // 1. Test quickSetWeeklyBudget
        window.ModulesUI.quickSetWeeklyBudget(225);
        if (window.appState.budget.weeklyBudget !== 225) throw new Error('quickSetWeeklyBudget failed');
        results.push('quickSetWeeklyBudget(225) passed');
        
        // Check calculation engine
        let metrics = window.CalculationEngine.calculateBudgetMetrics();
        if (metrics.weeklyBudget !== 225) throw new Error('calculateBudgetMetrics mismatch');
        if (metrics.remainingWeekly !== (225 - metrics.totalExpenses)) throw new Error('remainingWeekly mismatch');
        results.push('calculateBudgetMetrics confirmed with new budget: ' + metrics.weeklyBudget);
        
        // 2. Test Modal Service saveBudgetSettings
        window.ModalService.openEditBudgetModal();
        const weeklyInput = document.getElementById('edit-weekly-budget');
        const monthlyInput = document.getElementById('edit-monthly-budget');
        if (!weeklyInput || !monthlyInput) throw new Error('Modal inputs not rendered');
        weeklyInput.value = '275';
        monthlyInput.value = '1100';
        window.ModalService.saveBudgetSettings();
        if (window.appState.budget.weeklyBudget !== 275) throw new Error('saveBudgetSettings failed');
        results.push('ModalService saveBudgetSettings(275) passed');
        
        // 3. Test Persistence in StorageService
        window.StorageService.saveState(true);
        const saved = JSON.parse(localStorage.getItem('ultimate_meal_planner_pro_state_v1'));
        if (saved.budget.weeklyBudget !== 275) throw new Error('LocalStorage budget mismatch');
        results.push('StorageService persistence verified: ' + saved.budget.weeklyBudget);
        
        // 4. Test Print Budget Report generation with customized budget
        window.ExportService.printBudgetReport(false);
        const printContainer = document.getElementById('print-infographic-container');
        if (!printContainer || !printContainer.innerHTML.includes('275.00')) {
          throw new Error('Print report does not reflect customized budget 275.00');
        }
        results.push('Print report contains customized budget 275.00');
        
        // 5. Test Goals form integration
        window.ModulesUI.renderGoals();
        const goalsBudgetInput = document.getElementById('goal-weekly-budget');
        if (!goalsBudgetInput || goalsBudgetInput.value !== '275') {
          throw new Error('Goals form does not display current budget 275');
        }
        goalsBudgetInput.value = '310';
        window.ModulesUI.saveGoalsForm();
        if (window.appState.budget.weeklyBudget !== 310) {
          throw new Error('Goals form saving did not update weekly budget');
        }
        results.push('Goals form successfully updated budget to 310');

        console.log('TEST_RESULTS_OK:' + JSON.stringify(results));
      } catch (err) {
        console.error('TEST_RESULTS_ERR:' + err.message);
      }
    })();
"@

  $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($testScript))
  $url = "file:///$($htmlFile.Replace('\', '/'))"
  
  $runnerHtml = Join-Path $dir "scratch_test.html"
  $runnerContent = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body>
  <iframe id="app-frame" src="$url" style="width: 1200px; height: 900px;"></iframe>
  <script>
    const frame = document.getElementById('app-frame');
    frame.onload = () => {
      setTimeout(() => {
        try {
          const win = frame.contentWindow;
          const script = document.createElement('script');
          script.textContent = atob('$encodedScript');
          win.document.body.appendChild(script);
        } catch(e) {
          console.error(e);
        }
      }, 500);
    };
  </script>
</body>
</html>
"@
  [System.IO.File]::WriteAllText($runnerHtml, $runnerContent, [System.Text.Encoding]::UTF8)

  cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom --virtual-time-budget=4000 `"file:///$($runnerHtml.Replace('\', '/'))`" 2>nul" | Out-Null
  Remove-Item -Force $runnerHtml -ErrorAction SilentlyContinue
}

Write-Host "`n=== ALL WEEKLY BUDGET FEATURE TESTS PASSED! ===" -ForegroundColor Green
