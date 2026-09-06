$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"
$url = "file:///$($htmlFile.Replace('\', '/'))"

$dashPng = Join-Path $dir "mobile_dashboard.png"
$planPng = Join-Path $dir "mobile_planner.png"
$recPng  = Join-Path $dir "mobile_recipes.png"
$anPng   = Join-Path $dir "mobile_analytics.png"

cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --screenshot=`"$dashPng`" --window-size=375,812 `"$url#dashboard`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --screenshot=`"$planPng`" --window-size=375,812 `"$url#meal-planner`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --screenshot=`"$recPng`" --window-size=375,812 `"$url#recipes`" 2>nul"
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --screenshot=`"$anPng`" --window-size=375,812 `"$url#analytics`" 2>nul"

Write-Host "Captured 4 mobile screenshots at 375x812."
