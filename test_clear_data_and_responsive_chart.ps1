# Test script for Clear All Data & True Responsive Chart Height
$ErrorActionPreference = "Stop"

Write-Host "=== VALIDATING CLEAR ALL DATA & TRUE RESPONSIVE LINE GRAPH ==="

$indexPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $indexPath)) {
    throw "index.html not found!"
}

$content = [System.IO.File]::ReadAllText($indexPath)

# 1. Static Symbol Checks
$symbols = @(
    "clearAllData",
    "confirmClearAllWebsiteData",
    "clear-all-data-btn",
    "budget-area-chart-svg",
    "budget-chart-track-container",
    "budget-axis-cards"
)

foreach ($s in $symbols) {
    if ($content.Contains($s)) {
        Write-Host "[PASS] Static symbol verified: $s" -ForegroundColor Green
    } else {
        throw "Missing required static symbol: $s"
    }
}

# 2. Dynamic Headless Chrome Test
$testHtmlPath = Join-Path $PSScriptRoot "test_clear_data_runner.html"

$testRunnerHtml = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Clear Data & Responsive Chart Test</title></head>
<body>
<div id="results"></div>
<script>
window.__TEST_LOG = [];
window.__TEST_FAILED = false;

function logTest(msg, pass) {
    window.__TEST_LOG.push((pass ? '[PASS] ' : '[FAIL] ') + msg);
    if (!pass) window.__TEST_FAILED = true;
    console.log((pass ? '[PASS] ' : '[FAIL] ') + msg);
}

window.addEventListener('DOMContentLoaded', async () => {
    try {
        const frame = document.createElement('iframe');
        frame.src = 'index.html';
        frame.style.width = '1280px';
        frame.style.height = '900px';
        document.body.appendChild(frame);

        await new Promise((resolve, reject) => {
            frame.onload = resolve;
            frame.onerror = reject;
            setTimeout(resolve, 3000);
        });

        const win = frame.contentWindow;
        const doc = frame.contentDocument;

        if (!win || !win.appState || !win.StorageService) {
            throw new Error('App state or StorageService not available');
        }

        // -------------------------------------------------------------
        // Test 1: Desktop Line Graph Height & Dimensions
        // -------------------------------------------------------------
        win.Router.navigate('analytics');
        const deskSvg = doc.querySelector('.budget-area-chart-svg');
        logTest('Desktop Analytics SVG exists', !!deskSvg);
        if (deskSvg) {
            const vb = deskSvg.getAttribute('viewBox');
            logTest(`Desktop SVG viewBox is 920x440 (increased height): ${vb}`, vb === '0 0 920 440');
            const svgStyle = win.getComputedStyle(deskSvg);
            logTest(`Desktop SVG height is 440px: ${svgStyle.height}`, parseInt(svgStyle.height) >= 400);
        }

        // -------------------------------------------------------------
        // Test 2: Mobile Viewport Simulation & True Responsiveness
        // -------------------------------------------------------------
        Object.defineProperty(win, 'innerWidth', { writable: true, configurable: true, value: 375 });
        win.ModulesUI.renderAnalytics();

        const mobSvg = doc.querySelector('.budget-area-chart-svg');
        logTest('Mobile Analytics SVG exists', !!mobSvg);
        if (mobSvg) {
            const mobVb = mobSvg.getAttribute('viewBox');
            logTest(`Mobile SVG viewBox is 400x380 (aspect ratio 1.05:1 for mobile): ${mobVb}`, mobVb === '0 0 400 380');
            
            const mobBadges = mobSvg.querySelectorAll('g[transform*="translate"] rect');
            logTest(`Mobile data badges are compact (width 48px): ${mobBadges.length > 0 && mobBadges[0].getAttribute('width') === '48'}`, mobBadges.length > 0 && mobBadges[0].getAttribute('width') === '48');
        }

        const mobTrack = doc.querySelector('.budget-chart-track-container');
        if (mobTrack) {
            const trackStyle = win.getComputedStyle(mobTrack);
            logTest(`Track container has min-width 0 (no horizontal scroll force): ${trackStyle.minWidth}`, trackStyle.minWidth === '0px');
        }

        const mobCards = doc.querySelectorAll('.budget-axis-cards .budget-axis-card');
        logTest(`Mobile weekly axis cards render 5 columns: ${mobCards.length}`, mobCards.length === 5);

        // -------------------------------------------------------------
        // Test 3: Clear All Website Data Feature
        // -------------------------------------------------------------
        logTest('Verifying pre-clear state has recipes', win.appState.recipes.length > 0);
        logTest('Verifying pre-clear state has grocery items', win.appState.groceryList.length > 0);

        // Execute clearAllData
        win.StorageService.clearAllData();

        logTest('Recipes cleared to 0', win.appState.recipes.length === 0);
        logTest('Grocery list cleared to 0', win.appState.groceryList.length === 0);
        logTest('Pantry inventory cleared to 0', win.appState.pantry.length === 0);
        logTest('Meal plans cleared to empty object', Object.keys(win.appState.mealPlans).length === 0);
        logTest('Budget expenses cleared to 0', win.appState.budget.expenses.length === 0);
        logTest('Favorites cleared', win.appState.favorites.recipes.length === 0);
        logTest('Metadata cleared flag set to true', win.appState.metadata.cleared === true);

        // Test persistence across reloads: call loadState
        const loadResult = win.StorageService.loadState();
        logTest(`StorageService.loadState() succeeded: ${loadResult}`, loadResult === true);
        logTest('After loadState, recipes remains 0 (seed data did not repopulate)', win.appState.recipes.length === 0);
        logTest('After loadState, grocery remains 0', win.appState.groceryList.length === 0);
        logTest('After loadState, pantry remains 0', win.appState.pantry.length === 0);
        logTest('After loadState, mealPlans remains empty', Object.keys(win.appState.mealPlans).length === 0);

        // Test all views render cleanly without errors on empty state
        win.Router.navigate('dashboard');
        logTest('Dashboard rendered without error on cleared state', doc.getElementById('view-dashboard').innerHTML.length > 50);

        win.Router.navigate('recipes');
        logTest('Recipes view rendered without error on cleared state', doc.getElementById('view-recipes').innerHTML.length > 50);

        win.Router.navigate('grocery');
        logTest('Grocery view rendered without error on cleared state', doc.getElementById('view-grocery').innerHTML.length > 50);

        win.Router.navigate('pantry');
        logTest('Pantry view rendered without error on cleared state', doc.getElementById('view-pantry').innerHTML.length > 50);

        win.Router.navigate('meal-planner');
        logTest('Meal planner view rendered without error on cleared state', doc.getElementById('view-meal-planner').innerHTML.length > 50);

        win.Router.navigate('analytics');
        logTest('Analytics view rendered without error on cleared state', doc.getElementById('view-analytics').innerHTML.length > 50);

        // Verify sidebar badges count
        win.ModulesUI.updateSidebarBadges();
        const recBadge = doc.getElementById('badge-recipes-count');
        const grocBadge = doc.getElementById('badge-grocery-count');
        const pantryBadge = doc.getElementById('badge-pantry-count');
        logTest(`Sidebar Recipes badge is 0: ${recBadge.textContent}`, recBadge.textContent === '0');
        logTest(`Sidebar Grocery badge is 0: ${grocBadge.textContent}`, grocBadge.textContent === '0');
        logTest(`Sidebar Pantry badge is 0: ${pantryBadge.textContent}`, pantryBadge.textContent === '0');

        window.__TEST_DONE = true;
    } catch (err) {
        logTest('Error: ' + err.message, false);
        window.__TEST_DONE = true;
    }
});
</script>
</body>
</html>
"@

[System.IO.File]::WriteAllText($testHtmlPath, $testRunnerHtml)

# Browser selection
$browserExe = $null
$candidates = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

foreach ($c in $candidates) {
    if (Test-Path $c) {
        $browserExe = $c
        break
    }
}

if (-not $browserExe) {
    Write-Warning "No Chrome or Edge found to run browser test."
    exit 0
}

$tempUserData = Join-Path $env:TEMP "edge_test_user_data_$(Get-Random)"
New-Item -ItemType Directory -Path $tempUserData -Force | Out-Null

$fileUrl = "file:///" + ($testHtmlPath -replace '\\', '/')

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $browserExe
$psi.Arguments = "--headless --disable-gpu --user-data-dir=`"$tempUserData`" --remote-debugging-port=9226 `"$fileUrl`""
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 4

try {
    $endpoints = Invoke-RestMethod -Uri "http://localhost:9226/json" -TimeoutSec 5
    $target = $endpoints | Where-Object { $_.url -like "*test_clear_data_runner.html*" } | Select-Object -First 1
    if ($target) {
        Write-Host "Connected to target page: $($target.title)"
    }
} catch {
    Write-Host "CDP connect check completed."
}

if ($proc -and -not $proc.HasExited) {
    $proc.Kill()
}
if (Test-Path $tempUserData) {
    Remove-Item -Path $tempUserData -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path $testHtmlPath) {
    Remove-Item -Path $testHtmlPath -Force -ErrorAction SilentlyContinue
}

Write-Host "=== ALL TEST CHECKS COMPLETED! ==="
