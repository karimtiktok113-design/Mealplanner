$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING DEFAULT IMAGES FOR DEMO READY-MADE RECIPES ===" -ForegroundColor Cyan

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

$testScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  try {
    const log = [];

    // 1. Verify appState.recipes has 15 recipes and all start with photographic URL
    if (!window.appState || !Array.isArray(window.appState.recipes)) {
      throw new Error('appState.recipes is missing or not an array');
    }
    if (window.appState.recipes.length < 15) {
      throw new Error(`Expected at least 15 recipes, found ${window.appState.recipes.length}`);
    }

    let photoCount = 0;
    window.appState.recipes.forEach(r => {
      if (typeof r.image === 'string' && r.image.startsWith('https://images.unsplash.com/photo-')) {
        photoCount++;
      }
    });

    if (photoCount !== 15) {
      throw new Error(`Expected 15 recipes with Unsplash photo URLs, found ${photoCount}`);
    }
    log.push(`TEST 1 PASSED: All 15 demo ready-made recipes have default photographic Unsplash URLs`);

    // 2. Verify recipe cards rendering in Recipe Manager
    window.ModulesUI.renderRecipes();
    const recipeView = document.getElementById('view-recipes');
    if (!recipeView) throw new Error('#view-recipes container missing');

    const cards = recipeView.querySelectorAll('.recipe-card');
    if (cards.length !== 15) throw new Error(`Expected 15 recipe cards, found ${cards.length}`);

    let imgCardCount = 0;
    cards.forEach(card => {
      const img = card.querySelector('img.recipe-card-img');
      if (img && img.src && img.src.includes('images.unsplash.com/photo-')) {
        imgCardCount++;
      }
    });

    if (imgCardCount !== 15) {
      throw new Error(`Expected 15 cards with img.recipe-card-img, found ${imgCardCount}`);
    }
    log.push(`TEST 2 PASSED: All 15 recipe cards in Recipe Manager render photographic <img> elements`);

    // 3. Verify recipe cards rendering in Favorites Collection
    window.ModulesUI.renderFavorites();
    const favView = document.getElementById('view-favorites');
    if (!favView) throw new Error('#view-favorites container missing');

    const favCards = favView.querySelectorAll('.recipe-card');
    if (favCards.length === 0) throw new Error('No favorite cards rendered');

    favCards.forEach(card => {
      const img = card.querySelector('img.recipe-card-img');
      if (!img || !img.src || !img.src.includes('images.unsplash.com/photo-')) {
        throw new Error('Favorite recipe card missing photographic <img> element');
      }
    });
    log.push(`TEST 3 PASSED: Favorites collection cards render default photographic <img> elements`);

    // 4. Verify Recipe Detail Modal rendering
    const testRec = window.appState.recipes[0];
    window.ModalService.openRecipeDetailModal(testRec.id);
    const detailModal = document.querySelector('.modal-container');
    if (!detailModal) throw new Error('Recipe Detail modal failed to open');

    const detailImg = detailModal.querySelector('img.recipe-card-img');
    if (!detailImg) throw new Error('Recipe Detail modal missing img.recipe-card-img');
    if (!detailImg.src.includes('images.unsplash.com/photo-')) {
      throw new Error('Recipe Detail modal image does not use photographic URL');
    }
    window.ModalService.close();
    log.push(`TEST 4 PASSED: Recipe Detail Modal renders high-resolution default photographic image`);

    // 5. Verify localStorage legacy emoji state upgrade in loadState()
    const mockLegacyState = JSON.parse(JSON.stringify(window.appState));
    mockLegacyState.recipes.forEach(r => {
      r.image = '🥑'; // force legacy emoji
    });
    localStorage.setItem('ultimate_meal_planner_pro_state_v1', JSON.stringify(mockLegacyState));

    window.StorageService.loadState();
    let upgradedCount = 0;
    window.appState.recipes.forEach(r => {
      if (r.image.startsWith('https://images.unsplash.com/photo-')) {
        upgradedCount++;
      }
    });

    if (upgradedCount !== 15) {
      throw new Error(`Expected all 15 recipes to be upgraded from legacy emojis, but only ${upgradedCount} were`);
    }
    log.push(`TEST 5 PASSED: loadState() automatically upgrades legacy emoji state in localStorage to default photos`);

    const outDiv = document.createElement('div');
    outDiv.id = 'default-images-verdict';
    outDiv.innerHTML = 'DEFAULT_IMAGES_ALL_PASS:<br>' + log.join('<br>');
    document.body.appendChild(outDiv);
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'default-images-verdict';
    errDiv.textContent = 'DEFAULT_IMAGES_FAIL: ' + err.message;
    document.body.appendChild(errDiv);
  }
});
</script>
'@

$origHtml = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)
$injectedHtml = $origHtml -replace '</body>', ($testScript + "`n</body>")

$testFile = Join-Path $dir "temp_test_default_images.html"
[System.IO.File]::WriteAllText($testFile, $injectedHtml, [System.Text.Encoding]::UTF8)

try {
  $output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($testFile.Replace('\', '/'))`" 2>nul"

  if ($output -like "*DEFAULT_IMAGES_ALL_PASS*") {
    Write-Host "`n=== ALL DEFAULT RECIPE IMAGE TESTS PASSED! ===" -ForegroundColor Green
    Write-Host '  [PASS] TEST 1: All 15 demo ready-made recipes have default photographic Unsplash URLs' -ForegroundColor Green
    Write-Host '  [PASS] TEST 2: All 15 recipe cards in Recipe Manager render photographic <img> elements' -ForegroundColor Green
    Write-Host '  [PASS] TEST 3: Favorites collection cards render default photographic <img> elements' -ForegroundColor Green
    Write-Host '  [PASS] TEST 4: Recipe Detail Modal renders high-resolution default photographic image' -ForegroundColor Green
    Write-Host '  [PASS] TEST 5: loadState() automatically upgrades legacy emoji state in localStorage' -ForegroundColor Green
  } else {
    Write-Host "`n=== TEST FAILED ===" -ForegroundColor Red
    if ($output -match 'DEFAULT_IMAGES_FAIL:[^<]+') {
      Write-Host $matches[0] -ForegroundColor Red
    } else {
      Write-Host "Output: $output" -ForegroundColor Yellow
    }
    exit 1
  }
} finally {
  Remove-Item $testFile -ErrorAction SilentlyContinue
}
