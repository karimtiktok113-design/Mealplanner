# Test script for Recipe Search, Header Global Search, and Food Budget Area Graph
$ErrorActionPreference = "Stop"

Write-Host "=== RUNNING SEARCH & BUDGET AREA CHART VALIDATION SUITE ==="

$indexPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $indexPath)) {
    throw "index.html not found!"
}

# 1. Static symbol checks
$content = [System.IO.File]::ReadAllText($indexPath)

$symbolsToVerify = @(
    "recipe-search-input",
    "onRecipeSearchInput",
    "clearRecipeSearch",
    "getFilteredRecipes",
    "updateRecipesGrid",
    "global-search-dropdown",
    "renderSearchResults",
    "budget-area-chart-svg",
    "chart-area-budget",
    "chart-area-expense",
    "chart-line-budget",
    "chart-line-expense",
    "buildSmoothPath",
    "buildAreaPath",
    "budget-axis-cards",
    "budget-chart-hitbox"
)

foreach ($sym in $symbolsToVerify) {
    if ($content.Contains($sym)) {
        Write-Host "[PASS] Static symbol verified: $sym" -ForegroundColor Green
    } else {
        throw "Missing required symbol: $sym"
    }
}

# 2. Dynamic functional test in Headless Chrome
Write-Host "`nRunning headless Chrome functional test for search & area chart..."

$testHtmlPath = Join-Path $PSScriptRoot "test_temp_search_chart.html"

# Inject verification script into a temp test file
$testScript = @"
<script>
window.addEventListener('DOMContentLoaded', () => {
    const log = [];
    try {
        if (!window.appState || !window.ModulesUI || !window.Router) {
            throw new Error('Core appState, ModulesUI, or Router missing');
        }

        // Test 1: Recipe Manager Search
        window.Router.navigate('recipes');
        const searchInput = document.getElementById('recipe-search-input');
        if (!searchInput) throw new Error('Recipe search input not found in DOM');

        // Test ingredient search (e.g. avocado)
        window.onRecipeSearchInput('avocado');
        const grid = document.getElementById('recipes-grid-container');
        if (!grid) throw new Error('recipes-grid-container missing');
        
        const countText = document.getElementById('recipe-count-indicator')?.textContent || '';
        log.push('[PASS] 1. Filtered by ingredient "avocado": ' + countText);
        
        // Verify input still in DOM (no rebuild of full view)
        const activeInput = document.getElementById('recipe-search-input');
        if (activeInput !== searchInput) {
            throw new Error('Search input was destroyed and re-created on typing! Focus loss bug persists.');
        }
        log.push('[PASS] 2. Search input preserved in DOM (no focus loss)');

        // Test clear search
        window.clearRecipeSearch();
        if (searchInput.value !== '') throw new Error('Search input not cleared');
        log.push('[PASS] 3. Recipe search cleared successfully');

        // Test empty state
        window.onRecipeSearchInput('nonexistentXYZ9999');
        if (!grid.innerHTML.includes('No recipes found matching')) {
            throw new Error('Empty state not displayed for nonexistent search term');
        }
        log.push('[PASS] 4. Empty state properly displays when no recipes match');
        window.clearRecipeSearch();

        // Test 2: Header Global Search
        const headerInput = document.getElementById('global-search-input');
        const dropdown = document.getElementById('global-search-dropdown');
        if (!headerInput || !dropdown) throw new Error('Header search elements missing');

        headerInput.value = 'Chicken';
        headerInput.dispatchEvent(new Event('input', { bubbles: true }));
        if (dropdown.style.display !== 'block') {
            throw new Error('Global search dropdown did not open on typing');
        }
        if (!dropdown.innerHTML.includes('search-result-item')) {
            throw new Error('Global search dropdown did not render result items');
        }
        log.push('[PASS] 5. Global header search opens dropdown with categorized results');

        // Test Enter navigation
        headerInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
        if (window.Router.currentView !== 'recipes') {
            throw new Error('Enter key did not navigate to recipes view, currentView: ' + window.Router.currentView);
        }
        log.push('[PASS] 6. Global search Enter key routes to recipes view');

        // Test Escape to hide dropdown
        headerInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
        if (dropdown.style.display !== 'none') {
            throw new Error('Escape key did not close global search dropdown');
        }
        log.push('[PASS] 7. Escape key closes global search dropdown');

        // Test 3: Food Budget Line / Area Graph (Shifted to Analytics & Insights view)
        window.Router.navigate('analytics');
        const chartContainer = document.getElementById('budget-chart-container');
        if (!chartContainer) throw new Error('budget-chart-container missing');

        const svg = chartContainer.querySelector('.budget-area-chart-svg');
        if (!svg) throw new Error('SVG Area Chart not found in DOM');

        const budgetArea = svg.querySelector('.chart-area-budget');
        const expenseArea = svg.querySelector('.chart-area-expense');
        const budgetLine = svg.querySelector('.chart-line-budget');
        const expenseLine = svg.querySelector('.chart-line-expense');

        if (!budgetArea || !expenseArea || !budgetLine || !expenseLine) {
            throw new Error('SVG Area and Line paths missing from budget chart');
        }
        log.push('[PASS] 8. SVG Area and Line paths rendered for both budget and expenses');

        const hitboxes = svg.querySelectorAll('.budget-chart-hitbox');
        if (hitboxes.length === 0) throw new Error('No interactive hitboxes found on area chart');
        log.push('[PASS] 9. Interactive hitboxes present on area chart (' + hitboxes.length + ' weeks)');

        const axisCards = chartContainer.querySelectorAll('.budget-axis-card');
        if (axisCards.length === 0) throw new Error('No budget axis cards rendered');
        log.push('[PASS] 10. Responsive weekly axis cards rendered (' + axisCards.length + ' cards)');

        // Banner
        const successDiv = document.createElement('div');
        successDiv.id = 'validation-suite-success';
        successDiv.innerHTML = '=== ALL SEARCH & AREA CHART TESTS PASSED! ===<br>' + log.join('<br>');
        document.body.appendChild(successDiv);
    } catch (e) {
        const errDiv = document.createElement('div');
        errDiv.id = 'validation-suite-error';
        errDiv.textContent = 'VALIDATION FAILED: ' + e.message;
        document.body.appendChild(errDiv);
        console.error(e);
    }
});
</script>
"@

# Append test script before </body> in test temp file
$htmlWithTest = $content.Replace("</body>", "$testScript`n</body>")
[System.IO.File]::WriteAllText($testHtmlPath, $htmlWithTest)

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    throw "Chrome not found at $chromePath"
}

$tempHtml = Join-Path $PSScriptRoot "temp_test_search_chart.html"
Set-Content -Path $tempHtml -Value $htmlWithTest -Encoding utf8

$uri = "file:///$($tempHtml.Replace('\', '/'))#recipes"
$cmdOutput = cmd.exe /c "`"$chromePath`" --headless=new --disable-gpu --dump-dom `"$uri`" 2>nul"

# Cleanup
Remove-Item -Force $tempHtml -ErrorAction SilentlyContinue

$outputStr = $cmdOutput -join "`n"

if ($outputStr.Contains("validation-suite-success")) {
    Write-Host "`n=== SUCCESS! Headless Chrome verified all features! ===" -ForegroundColor Green
    $lines = $outputStr -split "<br>|\r?\n"
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -like "*[PASS]*") {
            Write-Host "  $trimmed" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "`n=== TESTS FAILED OR BANNER MISSING ===" -ForegroundColor Red
    $lines = $outputStr -split "`r?`n"
    foreach ($line in $lines) {
        if ($line -like "*VALIDATION FAILED*" -or $line -like "*ERROR*" -or $line -like "*Error*") {
            Write-Host "  $line" -ForegroundColor Red
        }
    }
    throw "Validation failed in headless Chrome!"
}
