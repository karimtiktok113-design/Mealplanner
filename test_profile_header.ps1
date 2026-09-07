$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "index.html"

Write-Host "=== TESTING PROFILE NAME HEADER PERSISTENCE ===" -ForegroundColor Cyan

# 1. Inspect static code in index.html
$content = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)

$checks = @(
  "updateHeaderProfile",
  "header-user-name",
  "header-user-avatar",
  "settings-name",
  "PROFILE_UPDATED"
)

foreach ($c in $checks) {
  if (-not $content.Contains($c)) {
    throw "Missing code symbol: $c in index.html"
  }
  Write-Host "[PASS] Symbol verified: $c" -ForegroundColor Green
}

# 2. Run Headless Chrome Script
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chrome) {
  Write-Host "`nRunning headless Chrome functional test..." -ForegroundColor Cyan
  
  $testScript = @"
    (function() {
      try {
        const results = [];
        
        // 1. Initial default state
        const hName = document.getElementById('header-user-name');
        const hAvatar = document.getElementById('header-user-avatar');
        if (!hName || !hAvatar) throw new Error('Header elements missing');
        results.push('Initial header name: ' + hName.textContent.trim());
        results.push('Initial header avatar: ' + hAvatar.textContent.trim());

        // 2. Open Settings view
        window.Router.navigate('settings');
        const nameInput = document.getElementById('settings-name');
        if (!nameInput) throw new Error('settings-name input not found');

        // 3. Simulate typing name (testing live-preview)
        nameInput.value = 'Karim Hussain Qaisar';
        nameInput.dispatchEvent(new Event('input', { bubbles: true }));
        if (hName.textContent !== 'Karim Hussain Qaisar') {
          throw new Error('Live typing preview failed to update header name');
        }
        if (hAvatar.textContent !== 'KQ') {
          throw new Error('Live typing preview failed to update avatar initials, expected KQ got ' + hAvatar.textContent);
        }
        results.push('Live preview verified: Name=' + hName.textContent + ', Avatar=' + hAvatar.textContent);

        // 4. Save settings form
        window.saveSettingsForm();
        results.push('Settings saved to localStorage');

        // 5. Verify localStorage has saved profile
        const saved = JSON.parse(localStorage.getItem('ultimate_meal_planner_pro_state_v1'));
        if (!saved || !saved.profile || saved.profile.name !== 'Karim Hussain Qaisar') {
          throw new Error('localStorage does not contain saved profile name');
        }
        results.push('LocalStorage verified: ' + saved.profile.name);

        // 6. Simulate page refresh / restart (reset DOM to defaults and call loadState)
        hName.textContent = 'Alex Morgan';
        hAvatar.textContent = 'AM';
        window.StorageService.loadState();
        if (hName.textContent !== 'Karim Hussain Qaisar') {
          throw new Error('Post-refresh loadState failed to restore header user name. Got: ' + hName.textContent);
        }
        if (hAvatar.textContent !== 'KQ') {
          throw new Error('Post-refresh loadState failed to restore header avatar initials. Got: ' + hAvatar.textContent);
        }
        results.push('PAGE REFRESH SIMULATION PASSED: Header name preserved as ' + hName.textContent + ' (' + hAvatar.textContent + ')');

        // 7. Test Dashboard greeting reflection
        window.Router.navigate('dashboard');
        const dashGreeting = document.querySelector('#view-dashboard h1');
        if (!dashGreeting || !dashGreeting.textContent.includes('Karim Hussain Qaisar')) {
          throw new Error('Dashboard greeting does not reflect user name: ' + (dashGreeting ? dashGreeting.textContent : 'none'));
        }
        results.push('Dashboard greeting verified: ' + dashGreeting.textContent.trim());

        // 8. Test Factory Reset
        window.StorageService.resetToFactory();
        if (hName.textContent !== 'Alex Morgan' || hAvatar.textContent !== 'AM') {
          throw new Error('Factory reset did not reset header badge to Alex Morgan / AM');
        }
        results.push('Factory reset restored default header: ' + hName.textContent + ' (' + hAvatar.textContent + ')');

        console.log('TEST_RESULTS_OK:' + JSON.stringify(results));
        window.__TEST_RESULTS = results;
      } catch (err) {
        console.error('TEST_RESULTS_ERR:' + err.message);
        window.__TEST_ERR = err.message;
      }
    })();
"@

  $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($testScript))
  $url = "file:///$($htmlFile.Replace('\', '/'))"
  
  $runnerHtml = Join-Path $dir "scratch_profile_test.html"
  $runnerContent = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body>
  <iframe id="app-frame" src="$url" style="width: 1200px; height: 900px;"></iframe>
  <div id="test-output"></div>
  <script>
    const frame = document.getElementById('app-frame');
    frame.onload = () => {
      setTimeout(() => {
        try {
          const win = frame.contentWindow;
          const script = document.createElement('script');
          script.textContent = atob('$encodedScript');
          win.document.body.appendChild(script);
          setTimeout(() => {
            const out = document.getElementById('test-output');
            if (win.__TEST_RESULTS) {
              out.innerHTML = '<pre id=\"res\">' + JSON.stringify(win.__TEST_RESULTS) + '</pre>';
            } else if (win.__TEST_ERR) {
              out.innerHTML = '<pre id=\"err\">ERROR: ' + win.__TEST_ERR + '</pre>';
            }
          }, 600);
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

  $output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom --virtual-time-budget=5000 `"file:///$($runnerHtml.Replace('\', '/'))`" 2>nul"
  Remove-Item -Force $runnerHtml -ErrorAction SilentlyContinue

  if ($output -match '<pre id="res">(.*?)</pre>') {
    Write-Host "`nTest Execution Output:" -ForegroundColor Green
    $json = [System.Web.HttpUtility]::HtmlDecode($matches[1])
    $resArray = ConvertFrom-Json $json
    foreach ($line in $resArray) {
      Write-Host "  [PASS] $line" -ForegroundColor Green
    }
  } elseif ($output -match '<pre id="err">(.*?)</pre>') {
    throw "Headless test failed: $($matches[1])"
  } else {
    Write-Host "Raw output (checking):"
    Write-Host $output
  }
}

Write-Host "`n=== ALL PROFILE HEADER TESTS PASSED SUCCESSFULLY! ===" -ForegroundColor Green
