$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$htmlFile = Join-Path $dir "index.html"
$url = "file:///$($htmlFile.Replace('\', '/'))"

$artDir = "C:\Users\Karim Hussain Qaisar\.gemini\antigravity-ide\brain\252f84e5-0f80-4d64-8cbd-4ab79f2e66d3"

$deskChart = Join-Path $artDir "desktop_chart_height_fixed.png"
$mobChart  = Join-Path $artDir "mobile_chart_responsive_fixed.png"
$deskGroc  = Join-Path $artDir "desktop_grocery_price_edit.png"
$mobGroc   = Join-Path $artDir "mobile_grocery_price_edit.png"

# Wait for chart / views to render
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --virtual-time-budget=3000 --screenshot=`"$deskChart`" --window-size=1280,950 `"$url#analytics`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --virtual-time-budget=3000 --screenshot=`"$mobChart`" --window-size=375,812 `"$url#analytics`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --virtual-time-budget=3000 --screenshot=`"$deskGroc`" --window-size=1280,950 `"$url#grocery`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --virtual-time-budget=3000 --screenshot=`"$mobGroc`" --window-size=375,812 `"$url#grocery`" 2>nul"

Write-Host "Captured 4 verification screenshots to artifact directory."
