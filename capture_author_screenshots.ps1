$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"
$brainDir = "C:\Users\Karim Hussain Qaisar\.gemini\antigravity-ide\brain\3b8043f2-9965-45ab-8286-3eb7525a44a3"

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

Write-Host "Preparing Author view screenshot wrapper..." -ForegroundColor Cyan

$navScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => {
    if (window.Router) {
      window.Router.navigate('author');
    }
  }, 100);
});
</script>
'@

$tempFile = Join-Path $dir "temp_author_view.html"
$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injected = $content.Replace("</body>", "$navScript`n</body>")
Set-Content -Path $tempFile -Value $injected -Encoding utf8

$desktopShot = Join-Path $brainDir "author_screen_desktop.png"
$mobileShot = Join-Path $brainDir "author_screen_mobile.png"
$url = "file:///$($tempFile.Replace('\', '/'))"

Write-Host "Capturing Desktop view (1280x950)..." -ForegroundColor Cyan
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --window-size=1280,950 --screenshot=`"$desktopShot`" `"$url`""

Write-Host "Capturing Mobile view (390x844)..." -ForegroundColor Cyan
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --window-size=390,844 --screenshot=`"$mobileShot`" `"$url`""

if (Test-Path $tempFile) {
  Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Screenshots saved:" -ForegroundColor Green
Write-Host "  Desktop: $desktopShot ($(Test-Path $desktopShot))" -ForegroundColor Green
Write-Host "  Mobile:  $mobileShot ($(Test-Path $mobileShot))" -ForegroundColor Green
