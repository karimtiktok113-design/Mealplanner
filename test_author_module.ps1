# ==============================================================================
# TEST SUITE: ABOUT AUTHOR & MORE TOOLS REUSABLE MODULE
# Tests sidebar placement, view rendering, Etsy CTAs, products.json loading,
# category filtering, search, and strict absence of pricing info.
# ==============================================================================
$ErrorActionPreference = "Stop"

$htmlPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $htmlPath)) {
    Write-Error "index.html not found at $htmlPath"
}
$html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)

$passed = 0
$failed = 0

function Assert-Test([string]$desc, [bool]$condition) {
    if ($condition) {
        Write-Host " [PASS] $desc" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host " [FAIL] $desc" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n=== 1. SIDEBAR NAVIGATION & HTML STRUCTURE ===" -ForegroundColor Cyan

# Test 1: #author nav-link exists in sidebar
$hasAuthorLink = $html -match '<a href="#author" class="nav-link" data-view="author" id="sidebar-author-link">'
Assert-Test "Sidebar contains #author nav-link with data-view='author'" $hasAuthorLink

# Test 2: Sidebar item label is "About Author"
$hasAuthorLabel = $html -match '<span>About Author</span>'
Assert-Test "Sidebar link label is 'About Author'" $hasAuthorLabel

# Test 3: It is placed as the LAST item in the sidebar nav list
$lastNavMatch = [regex]::Matches($html, '(?s)<ul class="nav-items">.*?</ul>')
$lastNavGroup = $lastNavMatch[$lastNavMatch.Count - 1].Value
$isLastItem = $lastNavGroup -match '(?s)data-view="help".*?data-view="author".*?</ul>'
Assert-Test "'About Author' is positioned as the final item in the sidebar" $isLastItem

# Test 4: View container exists in main body
$hasViewAuthor = $html -match '<div id="view-author" class="page-content module-view" style="display:none;"></div>'
Assert-Test "View container #view-author exists in main body" $hasViewAuthor

Write-Host "`n=== 2. ROUTER & MODULE INTEGRATION ===" -ForegroundColor Cyan

# Test 5: Router has case 'author' and calls WebcraftAuthorModule.render
$hasRouterCase = $html -match "case 'author':\s*case 'about-author':\s*case 'more-tools':\s*if \(window\.WebcraftAuthorModule\)"
Assert-Test "Router has case 'author' mapped to WebcraftAuthorModule.render" $hasRouterCase

# Test 6: WebcraftAuthorConfig is defined with Karim and WebCraft Goods
$hasConfig = $html -match 'authorName:\s*"Karim"' -and $html -match 'brandName:\s*"WebCraft Goods"'
Assert-Test "WebcraftAuthorConfig has Karim and WebCraft Goods" $hasConfig

# Test 7: Etsy store URL is configured
$hasEtsyUrl = $html -match 'https://www.etsy.com/shop/WebCraftGoods'
Assert-Test "Etsy store URL is properly configured" $hasEtsyUrl

Write-Host "`n=== 3. SUPPORT EMAIL (karimfiverr20@gmail.com) VERIFICATION ===" -ForegroundColor Cyan

# Test 8: Support email is karimfiverr20@gmail.com
$hasSupportEmailConfig = $html -match 'supportEmail:\s*"karimfiverr20@gmail\.com"'
Assert-Test "WebcraftAuthorConfig.supportEmail is set to 'karimfiverr20@gmail.com'" $hasSupportEmailConfig

# Test 9: Customer support button links to karimfiverr20@gmail.com
$hasSupportMailto = $html -match 'href="mailto:\$\{cfg\.supportEmail\}\?subject=WebCraft%20Goods%20Customer%20Support"' -or $html -match 'mailto:karimfiverr20@gmail\.com'
Assert-Test "Customer Support button links to 'karimfiverr20@gmail.com'" $hasSupportMailto

# Test 10: Social strip support email links to karimfiverr20@gmail.com
$hasSocialMailto = $html -match 'mailto:karimfiverr20@gmail\.com'
Assert-Test "Social strip support email links to 'karimfiverr20@gmail.com'" $hasSocialMailto

Write-Host "`n=== 4. REMOVAL OF MORE TOOLS SECTION ===" -ForegroundColor Cyan

# Test 11: Section 2 (more tools from webcraft goods) is removed from WebcraftAuthorModule render
$moduleCode = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "parts\05_modules_ui.js"), [System.Text.Encoding]::UTF8)
$hasMoreToolsSectionInModule = $moduleCode -match 'tools-showcase-section' -or $moduleCode -match 'author-products-grid'
Assert-Test "More Tools section is removed from WebcraftAuthorModule in 05_modules_ui.js" (-not $hasMoreToolsSectionInModule)

# Test 12: More Tools section is removed from compiled index.html render
$hasMoreToolsInHtmlRender = $html -match '<section class="tools-showcase-section"'
Assert-Test "Compiled HTML contains no tools-showcase-section in author view" (-not $hasMoreToolsInHtmlRender)

Write-Host "`n=== 5. STANDALONE MODULE REUSABILITY ===" -ForegroundColor Cyan

$standalonePath = Join-Path $PSScriptRoot "webcraft-author-module.js"
$hasStandalone = Test-Path $standalonePath
Assert-Test "webcraft-author-module.js standalone file exists for portable reuse" $hasStandalone

if ($hasStandalone) {
    $standaloneContent = [System.IO.File]::ReadAllText($standalonePath, [System.Text.Encoding]::UTF8)
    $hasEmailInStandalone = $standaloneContent -match 'karimfiverr20@gmail\.com'
    Assert-Test "webcraft-author-module.js has supportEmail 'karimfiverr20@gmail.com'" $hasEmailInStandalone
    $hasMoreToolsInStandalone = $standaloneContent -match 'tools-showcase-section'
    Assert-Test "webcraft-author-module.js has More Tools section removed" (-not $hasMoreToolsInStandalone)
}

Write-Host "`n==================================================" -ForegroundColor Yellow
Write-Host "Total Passed: $passed | Total Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "==================================================" -ForegroundColor Yellow

if ($failed -gt 0) {
    exit 1
}
exit 0
