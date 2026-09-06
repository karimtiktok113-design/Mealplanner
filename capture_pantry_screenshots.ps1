$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"
$uri = "file:///$($htmlFile.Replace('\', '/'))#pantry"

$outPantry = Join-Path $dir "pantry_stock_overview.png"
if (Test-Path $outPantry) { Remove-Item $outPantry -Force }

# 1. Capture Pantry Screen Overview
Write-Host "Capturing Pantry Screen Overview..."
cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --run-all-compositor-stages-before-draw --virtual-time-budget=2000 --screenshot=`"$outPantry`" --window-size=1280,850 `"$uri`" 2>nul"

# 2. Capture Edit Pantry Modal
Write-Host "Capturing Edit Pantry Modal..."
$modalScript = @'
<style>
.modal-backdrop { transition: none !important; opacity: 1 !important; display: flex !important; }
.modal-container { transition: none !important; transform: none !important; }
</style>
<script>
window.addEventListener('load', () => {
  setTimeout(() => {
    if (window.ModalService && window.appState && window.appState.pantry && window.appState.pantry[0]) {
      window.ModalService.openEditPantryModal(window.appState.pantry[0].id);
    }
  }, 100);
});
</script>
'@

$content = Get-Content -Raw -Encoding utf8 $htmlFile
$injected = $content.Replace("</body>", "$modalScript`n</body>")
$tempModalHtml = Join-Path $dir "temp_modal_snap.html"
Set-Content -Path $tempModalHtml -Value $injected -Encoding utf8

$modalUri = "file:///$($tempModalHtml.Replace('\', '/'))#pantry"
$outModal = Join-Path $dir "pantry_stock_modal.png"
if (Test-Path $outModal) { Remove-Item $outModal -Force }

cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --run-all-compositor-stages-before-draw --virtual-time-budget=2000 --screenshot=`"$outModal`" --window-size=1280,850 `"$modalUri`" 2>nul"

Start-Sleep -Milliseconds 500

if (Test-Path $tempModalHtml) {
  Remove-Item $tempModalHtml -Force
}

Get-Item $outPantry, $outModal -ErrorAction SilentlyContinue | Select-Object Name, Length
Write-Host "Pantry screenshots process finished."
