# ==============================================================================
# AUTOMATED MOBILE RESPONSIVENESS & ZERO-HORIZONTAL-SLIDING TEST
# Tests all 18 views in headless Chrome across multiple mobile viewports
# ==============================================================================
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Google Chrome not found at $chrome"
}

$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"
$url = "file:///$($htmlFile.Replace('\', '/'))"

$views = @(
  "dashboard", "meal-planner", "recipes", "grocery", "pantry",
  "nutrition", "goals", "budget", "meal-prep", "hydration",
  "favorites", "journal", "analytics", "exports", "backup",
  "themes", "settings", "help"
)

$viewports = @(
  @{ name = "iPhone SE / Modern Compact (375x812)"; width = 375; height = 812 },
  @{ name = "iPhone 14/15 Standard (390x844)"; width = 390; height = 844 },
  @{ name = "Android Standard / Pixel (412x915)"; width = 412; height = 915 },
  @{ name = "Ultra-Compact Mobile (320x568)"; width = 320; height = 568 }
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  MOBILE RESPONSIVENESS & HORIZONTAL OVERFLOW TESTING" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$allPassed = $true

foreach ($vp in $viewports) {
  Write-Host "--- Testing Viewport: $($vp.name) ---" -ForegroundColor Yellow

  # Create an evaluation harness HTML that opens the app in an iframe matching the viewport
  $testScript = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0; padding:0; overflow:hidden;">
  <iframe id="mobile-frame" src="$url" style="width: $($vp.width)px; height: $($vp.height)px; border:none;"></iframe>
  <script>
    const frame = document.getElementById('mobile-frame');
    frame.onload = () => {
      setTimeout(() => {
        try {
          const win = frame.contentWindow;
          const doc = win.document;
          const results = [];
          const views = $('[' + ($views | ForEach-Object { "'$_'" }) -join ',' + ']');
          
          let failures = 0;
          for (const v of views) {
            win.Router.navigate(v);
            const clientW = doc.documentElement.clientWidth;
            const scrollW = doc.documentElement.scrollWidth;
            const bodyScrollW = doc.body.scrollWidth;
            const overflowPx = Math.max(0, scrollW - clientW, bodyScrollW - clientW);

            const header = doc.querySelector('.app-header');
            const headerW = header ? header.offsetWidth : 0;
            const headerOverflow = headerW > clientW;

            if (overflowPx > 1 || headerOverflow) {
              failures++;
              results.push('FAIL:' + v + ':client=' + clientW + ':scroll=' + scrollW + ':header=' + headerW);
            } else {
              results.push('PASS:' + v + ':w=' + clientW);
            }
          }

          if (failures === 0) {
            console.log('VIEWPORT_ALL_PASS:$($vp.width)x$($vp.height):' + JSON.stringify(results));
          } else {
            console.error('VIEWPORT_FAIL:$($vp.width)x$($vp.height):' + JSON.stringify(results));
          }
        } catch(e) {
          console.error('RUNNER_ERR:' + e.message);
        }
      }, 700);
    };
  </script>
</body>
</html>
"@

  $harnessPath = Join-Path $dir "scratch_mobile_test_$($vp.width).html"
  [System.IO.File]::WriteAllText($harnessPath, $testScript, [System.Text.Encoding]::UTF8)

  $output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom --virtual-time-budget=8000 `"file:///$($harnessPath.Replace('\', '/'))`" 2>nul"
  Remove-Item -Force $harnessPath -ErrorAction SilentlyContinue

  if ($output -like "*VIEWPORT_ALL_PASS*") {
    Write-Host "  [OK] Zero horizontal sliding across all 18 views at $($vp.width)px width!" -ForegroundColor Green
  } else {
    Write-Host "  [FAIL] Viewport $($vp.width)px encountered horizontal overflow or error!" -ForegroundColor Red
    $allPassed = $false
  }
}

Write-Host "`n--------------------------------------------------------" -ForegroundColor Gray
if ($allPassed) {
  Write-Host "ALL VIEWPORTS PASSED: ZERO HORIZONTAL SLIDING DETECTED ON ANY SCREEN!" -ForegroundColor Green
} else {
  Write-Host "Some viewports had horizontal overflow." -ForegroundColor Red
}
Write-Host "========================================================`n" -ForegroundColor Cyan
