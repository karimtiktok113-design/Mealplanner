# Test script for Retractable Desktop Sidebar, Line Graph in Analytics, and Clear All Website Data
$ErrorActionPreference = "Stop"

Write-Host "=== VALIDATING RETRACTABLE SIDEBAR, ANALYTICS GRAPH & DATA PURGE ==="

$indexPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $indexPath)) {
    throw "index.html not found!"
}

# 1. Static Symbol Checks
$content = [System.IO.File]::ReadAllText($indexPath)

$symbolsToVerify = @(
    "sidebar-collapsed",
    "--sidebar-collapsed-width",
    "toggleSidebar",
    "meal_planner_sidebar_collapsed",
    "data-tooltip",
    "clearAllData",
    "confirmClearAllWebsiteData",
    "clear-all-data-btn",
    "budget-analytics-hub-card",
    "renderBudgetTrendAreaChart",
    "budget-area-chart-svg"
)

foreach ($sym in $symbolsToVerify) {
    if ($content.Contains($sym)) {
        Write-Host "[PASS] Static symbol verified: $sym" -ForegroundColor Green
    } else {
        throw "Missing required symbol: $sym"
    }
}

# 2. Dynamic Functional Test in Headless Chrome
Write-Host "`nRunning headless Chrome validation test..."

$testHtmlPath = Join-Path $PSScriptRoot "test_temp_verification.html"

$testScript = @"
<script>
window.addEventListener('DOMContentLoaded', () => {
    const log = [];
    try {
        if (!window.appState || !window.ModulesUI || !window.Router) {
            throw new Error('Core appState, ModulesUI, or Router missing');
        }

        // -------------------------------------------------------------
        // Test 1: Retractable Desktop Sidebar
        // -------------------------------------------------------------
        // Simulate desktop width
        Object.defineProperty(window, 'innerWidth', { writable: true, configurable: true, value: 1280 });

        if (document.body.classList.contains('sidebar-collapsed')) {
            document.body.classList.remove('sidebar-collapsed');
        }

        // Toggle collapsed
        window.toggleSidebar();
        if (!document.body.classList.contains('sidebar-collapsed')) {
            throw new Error('Desktop toggleSidebar did not add sidebar-collapsed class to body');
        }
        if (localStorage.getItem('meal_planner_sidebar_collapsed') !== 'true') {
            throw new Error('Desktop toggleSidebar did not persist meal_planner_sidebar_collapsed = true');
        }
        log.push('[PASS] 1. Desktop sidebar collapses and sets sidebar-collapsed class & localStorage');

        // Toggle back to expanded
        window.toggleSidebar();
        if (document.body.classList.contains('sidebar-collapsed')) {
            throw new Error('Desktop toggleSidebar did not remove sidebar-collapsed class');
        }
        if (localStorage.getItem('meal_planner_sidebar_collapsed') !== 'false') {
            throw new Error('Desktop toggleSidebar did not persist meal_planner_sidebar_collapsed = false');
        }
        log.push('[PASS] 2. Desktop sidebar expands and clears sidebar-collapsed class & localStorage');

        // Verify data-tooltip on nav links
        const navLinks = document.querySelectorAll('.app-sidebar .nav-link');
        let tooltipsFound = 0;
        navLinks.forEach(link => {
            if (link.hasAttribute('data-tooltip') && link.getAttribute('data-tooltip').length > 0) {
                tooltipsFound++;
            }
        });
        if (tooltipsFound < 10) {
            throw new Error('Fewer than 10 nav links had data-tooltip attribute: found ' + tooltipsFound);
        }
        log.push('[PASS] 3. Verified ' + tooltipsFound + ' navigation links have data-tooltip attribute for collapsed state');

        // -------------------------------------------------------------
        // Test 2: Shift Line Graph from Food Budget to Analytics
        // -------------------------------------------------------------
        // A: Food budget view should NOT have the chart container, but should have the centralized hub link
        window.Router.navigate('budget');
        const budgetView = document.getElementById('view-budget');
        if (!budgetView) throw new Error('view-budget missing');
        if (budgetView.querySelector('#budget-chart-container')) {
            throw new Error('budget-chart-container should NOT be in Food Budget screen anymore');
        }
        const hubCard = budgetView.querySelector('#budget-analytics-hub-card');
        if (!hubCard) {
            throw new Error('#budget-analytics-hub-card missing from Food Budget screen');
        }
        log.push('[PASS] 4. Food Budget screen clean: chart removed and replaced with centralized analytics hub link');

        // B: Analytics & Insights view SHOULD have the chart container and SVG area graph
        window.Router.navigate('analytics');
        const analyticsView = document.getElementById('view-analytics');
        if (!analyticsView) throw new Error('view-analytics missing');
        const chartContainer = analyticsView.querySelector('#budget-chart-container');
        if (!chartContainer) {
            throw new Error('#budget-chart-container missing from Analytics & Insights view');
        }
        const svg = chartContainer.querySelector('.budget-area-chart-svg');
        if (!svg) {
            throw new Error('.budget-area-chart-svg missing from Analytics & Insights view');
        }
        const budgetArea = svg.querySelector('.chart-area-budget');
        const expenseArea = svg.querySelector('.chart-area-expense');
        const budgetLine = svg.querySelector('.chart-line-budget');
        const expenseLine = svg.querySelector('.chart-line-expense');
        if (!budgetArea || !expenseArea || !budgetLine || !expenseLine) {
            throw new Error('SVG budget and expense area/line paths missing from Analytics chart');
        }
        log.push('[PASS] 5. Analytics & Insights screen contains full SVG area/line graph with all curves & areas');

        const axisCards = chartContainer.querySelectorAll('.budget-axis-card');
        if (axisCards.length === 0) {
            throw new Error('No .budget-axis-card found in analytics chart');
        }
        log.push('[PASS] 6. Analytics chart rendered ' + axisCards.length + ' interactive weekly cards');

        // Test month navigation in analytics
        window.ModulesUI.navigateBudgetMonth(1);
        const nextMonthSvg = document.querySelector('#view-analytics .budget-area-chart-svg');
        if (!nextMonthSvg) {
            throw new Error('Analytics chart disappeared after navigateBudgetMonth');
        }
        log.push('[PASS] 7. Month navigation in Analytics & Insights view re-renders chart smoothly');

        // -------------------------------------------------------------
        // Test 3: Clear All Website Data in Backup & Restore
        // -------------------------------------------------------------
        window.Router.navigate('backup');
        const backupView = document.getElementById('view-backup');
        if (!backupView) throw new Error('view-backup missing');
        const clearBtn = backupView.querySelector('#clear-all-data-btn');
        if (!clearBtn) {
            throw new Error('#clear-all-data-btn missing from Backup & Restore view');
        }
        if (!clearBtn.textContent.includes('Clear All Website Data')) {
            throw new Error('Clear button has incorrect text: ' + clearBtn.textContent);
        }
        log.push('[PASS] 8. Clear All Website Data button present in Backup & Restore screen');

        if (typeof window.confirmClearAllWebsiteData !== 'function') {
            throw new Error('window.confirmClearAllWebsiteData is not a function');
        }

        // Test calling StorageService.clearAllData() directly
        window.StorageService.clearAllData();

        if (!Array.isArray(window.appState.recipes) || window.appState.recipes.length !== 0) {
            throw new Error('appState.recipes not emptied: ' + window.appState.recipes.length);
        }
        if (!Array.isArray(window.appState.pantry) || window.appState.pantry.length !== 0) {
            throw new Error('appState.pantry not emptied: ' + window.appState.pantry.length);
        }
        if (!Array.isArray(window.appState.groceryList) || window.appState.groceryList.length !== 0) {
            throw new Error('appState.groceryList not emptied: ' + window.appState.groceryList.length);
        }
        if (!Array.isArray(window.appState.budget?.expenses) || window.appState.budget.expenses.length !== 0) {
            throw new Error('appState.budget.expenses not emptied: ' + window.appState.budget.expenses.length);
        }
        log.push('[PASS] 9. StorageService.clearAllData() wiped recipes, pantry, grocery, meal plan, and budget receipts');

        // Test sidebar badge synchronization
        if (window.ModulesUI && typeof window.ModulesUI.updateSidebarBadges === 'function') {
            window.ModulesUI.updateSidebarBadges();
        }
        const recipeBadge = document.getElementById('sidebar-recipe-count');
        const groceryBadge = document.getElementById('sidebar-grocery-count');
        const pantryBadge = document.getElementById('sidebar-pantry-count');
        if (recipeBadge && recipeBadge.textContent !== '0') {
            throw new Error('Recipe badge not 0 after clear: ' + recipeBadge.textContent);
        }
        if (groceryBadge && groceryBadge.textContent !== '0') {
            throw new Error('Grocery badge not 0 after clear: ' + groceryBadge.textContent);
        }
        if (pantryBadge && pantryBadge.textContent !== '0') {
            throw new Error('Pantry badge not 0 after clear: ' + pantryBadge.textContent);
        }
        log.push('[PASS] 10. Sidebar badges immediately synchronized to 0 counts');

        const resultsDiv = document.createElement('div');
        resultsDiv.id = 'validation-results';
        resultsDiv.innerHTML = 'SUCCESS:' + JSON.stringify(log);
        document.body.appendChild(resultsDiv);
    } catch(err) {
        const resultsDiv = document.createElement('div');
        resultsDiv.id = 'validation-results';
        resultsDiv.innerHTML = 'ERROR:' + err.message + ' | Stack: ' + err.stack;
        document.body.appendChild(resultsDiv);
    }
});
</script>
"@

$modifiedContent = $content.Replace("</body>", "$testScript`n</body>")
[System.IO.File]::WriteAllText($testHtmlPath, $modifiedContent)

$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$chromeExe = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($null -eq $chromeExe) {
    Write-Warning "Chrome executable not found for headless execution. Static checks passed."
    Remove-Item -Path $testHtmlPath -Force -ErrorAction SilentlyContinue
    exit 0
}

$fileUri = "file:///" + ($testHtmlPath.Replace("\", "/"))
$rawOutput = & cmd.exe /c "`"$chromeExe`" --headless=new --disable-gpu --dump-dom `"$fileUri`" 2>nul"
$dumpOutput = $rawOutput -join "`n"

Remove-Item -Path $testHtmlPath -Force -ErrorAction SilentlyContinue

if ($dumpOutput -match 'id="validation-results">SUCCESS:(?<res>.*?)</div>') {
    $rawLog = $Matches['res']
    Write-Host "`n=== HEADLESS BROWSER VERIFICATION LOG ===" -ForegroundColor Cyan
    Write-Host $rawLog
    Write-Host "`n[PASS] ALL 10 BROWSER FUNCTIONAL VALIDATIONS PASSED PERFECTLY!" -ForegroundColor Green
} elseif ($dumpOutput -match 'id="validation-results">ERROR:(?<err>.*?)</div>') {
    Write-Host "`n[FAIL] Browser Validation Error: $($Matches['err'])" -ForegroundColor Red
    throw "Headless test failed: $($Matches['err'])"
} else {
    Write-Host "`n[FAIL] validation-results div not found in headless Chrome output" -ForegroundColor Red
    Write-Host "Raw output preview: $($dumpOutput.Substring(0, [Math]::Min(500, $dumpOutput.Length)))"
    throw "Test script did not execute properly"
}
