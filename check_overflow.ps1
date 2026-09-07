$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$htmlFile = Join-Path (Get-Location).Path "index.html"
$tmp = Join-Path (Get-Location).Path "diag_budget.html"

$script = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => {
    window.Router.navigate('budget');
    setTimeout(() => {
      const all = Array.from(document.querySelectorAll('#view-budget *'));
      const winW = window.innerWidth;
      const over = all.filter(el => el.getBoundingClientRect().right > winW + 1);
      const res = over.map(el => ({
        tag: el.tagName,
        id: el.id,
        cls: (el.className && typeof el.className === 'string') ? el.className.substring(0, 40) : '',
        right: Math.round(el.getBoundingClientRect().right),
        width: Math.round(el.getBoundingClientRect().width)
      }));
      document.title = "OVERFLOW_COUNT:" + over.length + " DETAILS:" + JSON.stringify(res.slice(0, 15));
    }, 500);
  }, 200);
});
</script>
'@

$content = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)
$injected = $content.Replace("</body>", "$script`n</body>")
[System.IO.File]::WriteAllText($tmp, $injected, [System.Text.Encoding]::UTF8)

$out = & $chrome --headless=new --disable-gpu --virtual-time-budget=2000 --window-size=390,844 --dump-dom "file:///$($tmp.Replace('\', '/'))"

Remove-Item -Force $tmp -ErrorAction SilentlyContinue

if ($out -match '<title>(OVERFLOW_COUNT:[^<]+)</title>') {
  Write-Output $matches[1]
} else {
  Write-Output "Title not matched"
}
