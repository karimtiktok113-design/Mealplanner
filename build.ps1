# ==============================================================================
# ULTIMATE MEAL PLANNER PRO - COMPILER / BUILD SCRIPT
# Assembles modular components in parts/ into standalone index.html & ultimate-meal-planner-pro.html (UTF-8)
# ==============================================================================
$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }

$partsDir = Join-Path $dir "parts"
$outputFile = Join-Path $dir "index.html"
$altOutputFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "Assembling Ultimate Meal Planner Pro..." -ForegroundColor Cyan

$sb = New-Object System.Text.StringBuilder

# 1. 01_head_css.html
$head = [System.IO.File]::ReadAllText((Join-Path $partsDir "01_head_css.html"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine($head.TrimEnd())

# 2. 02_layout_shell.html
$body = [System.IO.File]::ReadAllText((Join-Path $partsDir "02_layout_shell.html"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine($body.TrimEnd())

# 3. 03_core_data_state.js
$p3 = [System.IO.File]::ReadAllText((Join-Path $partsDir "03_core_data_state.js"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine("<script>")
[void]$sb.AppendLine($p3.Trim())
[void]$sb.AppendLine("</script>")
[void]$sb.AppendLine()

# 4. 04_calculations_services.js
$p4 = [System.IO.File]::ReadAllText((Join-Path $partsDir "04_calculations_services.js"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine("<script>")
[void]$sb.AppendLine($p4.Trim())
[void]$sb.AppendLine("</script>")
[void]$sb.AppendLine()

# 5. 05_modules_ui.js
$p5 = [System.IO.File]::ReadAllText((Join-Path $partsDir "05_modules_ui.js"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine("<script>")
[void]$sb.AppendLine($p5.Trim())
[void]$sb.AppendLine("</script>")
[void]$sb.AppendLine()

# 6. 06_export_settings_init.js
$p6 = [System.IO.File]::ReadAllText((Join-Path $partsDir "06_export_settings_init.js"), [System.Text.Encoding]::UTF8)
[void]$sb.AppendLine("<script>")
[void]$sb.AppendLine($p6.Trim())
[void]$sb.AppendLine("</script>")

# Closing tags
[void]$sb.AppendLine("</body>")
[void]$sb.AppendLine("</html>")

$finalHtml = $sb.ToString()
[System.IO.File]::WriteAllText($outputFile, $finalHtml, $utf8NoBom)
[System.IO.File]::WriteAllText($altOutputFile, $finalHtml, $utf8NoBom)

$size = (Get-Item $outputFile).Length
Write-Host "Build complete! index.html & ultimate-meal-planner-pro.html ($size bytes) generated successfully." -ForegroundColor Green
