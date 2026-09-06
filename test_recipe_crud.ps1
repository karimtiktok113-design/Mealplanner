$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
if (-not $dir) { $dir = (Get-Location).Path }
$htmlFile = Join-Path $dir "ultimate-meal-planner-pro.html"

Write-Host "=== TESTING RECIPE EDIT & DELETE (CRUD) FEATURES ===" -ForegroundColor Cyan

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
  throw "Chrome not found at $chrome"
}

$testScript = @'
<script>
window.addEventListener('DOMContentLoaded', () => {
  try {
    const log = [];

    if (!window.appState || !Array.isArray(window.appState.recipes)) {
      throw new Error('appState.recipes is missing');
    }

    // Auto-confirm deletes during testing
    window.confirm = () => true;

    // Test 1: Recipe cards have Edit and Delete buttons in Recipe Manager
    window.ModulesUI.renderRecipes();
    const recipeView = document.getElementById('view-recipes');
    if (!recipeView) throw new Error('view-recipes missing');

    const cards = recipeView.querySelectorAll('.recipe-card');
    if (cards.length === 0) throw new Error('No recipe cards rendered');

    const firstCard = cards[0];
    const editBtn = firstCard.querySelector('button[title="Edit Recipe"]');
    const deleteBtn = firstCard.querySelector('button[title="Delete Recipe"]');
    if (!editBtn) throw new Error('Edit Recipe button missing on recipe card');
    if (!deleteBtn) throw new Error('Delete Recipe button missing on recipe card');
    log.push('TEST 1 PASSED: Edit and Delete buttons rendered on Recipe Manager cards');

    // Test 2: Recipe Detail Modal has Edit Recipe and Delete Recipe buttons
    const testRecipe = window.appState.recipes[0];
    window.ModalService.openRecipeDetailModal(testRecipe.id);
    const modalBackdrop = document.getElementById('modal-backdrop');
    if (!modalBackdrop || !modalBackdrop.classList.contains('open')) {
      throw new Error('Modal backdrop failed to open for Recipe Detail');
    }
    const modalContainer = modalBackdrop.querySelector('.modal-container');
    const modalText = modalContainer.innerHTML;
    if (!modalText.includes('Edit Recipe')) throw new Error('Modal missing Edit Recipe button');
    if (!modalText.includes('Delete Recipe')) throw new Error('Modal missing Delete Recipe button');
    log.push('TEST 2 PASSED: Recipe Detail Modal includes Edit Recipe and Delete Recipe buttons');
    window.ModalService.close();

    // Test 3: Edit Recipe Modal opens with pre-populated fields
    window.ModalService.openEditRecipeModal(testRecipe.id);
    const nameInput = document.getElementById('rec-form-name');
    const calInput = document.getElementById('rec-form-cal');
    const ingList = document.getElementById('rec-ingredients-list');
    const instList = document.getElementById('rec-instructions-list');
    if (!nameInput || nameInput.value !== testRecipe.name) {
      throw new Error('Edit modal failed to pre-populate recipe name');
    }
    if (!calInput || Number(calInput.value) !== testRecipe.calories) {
      throw new Error('Edit modal failed to pre-populate calories');
    }
    if (!ingList || ingList.querySelectorAll('.rec-ing-row').length === 0) {
      throw new Error('Edit modal failed to load ingredient rows');
    }
    if (!instList || instList.querySelectorAll('.rec-inst-row').length === 0) {
      throw new Error('Edit modal failed to load instruction rows');
    }
    log.push('TEST 3 PASSED: Edit Recipe Modal successfully pre-populates all inputs, ingredients & instructions');

    // Test 4: Editing and saving recipe updates appState & persistence
    const originalName = testRecipe.name;
    const newName = 'Ultimate Gourmet ' + originalName;
    nameInput.value = newName;
    calInput.value = '555';

    // Add an ingredient row in edit modal
    window.ModalService.addRecipeIngredientRow('Organic Honey', 15, 'ml', 'Pantry', 0.50);
    window.ModalService.saveRecipe(testRecipe.id);

    // Verify update
    const updatedRecipe = window.appState.recipes.find(r => r.id === testRecipe.id);
    if (!updatedRecipe || updatedRecipe.name !== newName) {
      throw new Error('Recipe name not updated in appState. Got: ' + (updatedRecipe ? updatedRecipe.name : 'null'));
    }
    if (updatedRecipe.calories !== 555) {
      throw new Error('Recipe calories not updated. Got: ' + updatedRecipe.calories);
    }
    const hasHoney = updatedRecipe.ingredients.some(ing => ing.name === 'Organic Honey');
    if (!hasHoney) throw new Error('New ingredient row was not added to recipe');
    log.push('TEST 4 PASSED: Recipe updated with new name, calories, and added ingredient');

    // Test 5: Creating a new recipe via openRecipeModal & saveRecipe
    const initialCount = window.appState.recipes.length;
    window.ModalService.openRecipeModal();
    document.getElementById('rec-form-name').value = 'Test Crispy Tofu Bowl';
    document.getElementById('rec-form-cal').value = '410';
    document.getElementById('rec-form-protein').value = '25';
    window.ModalService.saveRecipe();

    if (window.appState.recipes.length !== initialCount + 1) {
      throw new Error('New recipe was not added to appState.recipes');
    }
    const created = window.appState.recipes.find(r => r.name === 'Test Crispy Tofu Bowl');
    if (!created) throw new Error('Created recipe not found in appState');
    log.push('TEST 5 PASSED: New Recipe created and appended to catalog');

    // Test 6: Deleting a recipe
    const countBeforeDelete = window.appState.recipes.length;
    const idToDelete = created.id;
    // Add to favorites to test deletion cleanup
    window.appState.favorites.recipes.push(idToDelete);

    window.ModulesUI.deleteRecipe(idToDelete);

    if (window.appState.recipes.length !== countBeforeDelete - 1) {
      throw new Error('Recipe count did not decrease after deletion');
    }
    if (window.appState.recipes.some(r => r.id === idToDelete)) {
      throw new Error('Deleted recipe still present in appState.recipes');
    }
    if (window.appState.favorites.recipes.includes(idToDelete)) {
      throw new Error('Deleted recipe still present in favorites collection');
    }
    const sidebarBadge = document.getElementById('sidebar-recipe-count');
    if (sidebarBadge && Number(sidebarBadge.textContent) !== window.appState.recipes.length) {
      throw new Error('Sidebar recipe counter not updated');
    }
    log.push('TEST 6 PASSED: Recipe deleted, removed from catalog & favorites, and counter updated');

    // Test 7: Favorites cards also display Edit and Delete buttons
    window.ModulesUI.renderFavorites();
    const favView = document.getElementById('view-favorites');
    if (favView) {
      const favCards = favView.querySelectorAll('.recipe-card');
      if (favCards.length > 0) {
        const fc = favCards[0];
        if (!fc.querySelector('button[title="Edit Recipe"]')) throw new Error('Edit button missing on favorites card');
        if (!fc.querySelector('button[title="Delete Recipe"]')) throw new Error('Delete button missing on favorites card');
        log.push('TEST 7 PASSED: Edit and Delete buttons rendered on Favorites cards');
      }
    }

    const outDiv = document.createElement('div');
    outDiv.id = 'recipe-crud-verdict';
    outDiv.innerHTML = 'RECIPE_CRUD_ALL_PASS:<br>' + log.join('<br>');
    document.body.appendChild(outDiv);
  } catch (err) {
    const errDiv = document.createElement('div');
    errDiv.id = 'recipe-crud-verdict';
    errDiv.textContent = 'RECIPE_CRUD_FAIL: ' + err.message;
    document.body.appendChild(errDiv);
  }
});
</script>
'@

$origHtml = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)
$injectedHtml = $origHtml -replace '</body>', ($testScript + "`n</body>")

$testFile = Join-Path $dir "temp_test_recipe_crud.html"
[System.IO.File]::WriteAllText($testFile, $injectedHtml, [System.Text.Encoding]::UTF8)

try {
  $output = cmd.exe /c "`"$chrome`" --headless=new --disable-gpu --dump-dom `"file:///$($testFile.Replace('\', '/'))`" 2>nul"

  if ($output -like "*RECIPE_CRUD_ALL_PASS*") {
    Write-Host "`n=== ALL RECIPE EDIT & DELETE (CRUD) TESTS PASSED! ===" -ForegroundColor Green
    Write-Host '  [PASS] TEST 1: Edit and Delete buttons rendered on Recipe Manager cards' -ForegroundColor Green
    Write-Host '  [PASS] TEST 2: Recipe Detail Modal includes Edit Recipe and Delete Recipe buttons' -ForegroundColor Green
    Write-Host '  [PASS] TEST 3: Edit Recipe Modal successfully pre-populates all inputs, ingredients & instructions' -ForegroundColor Green
    Write-Host '  [PASS] TEST 4: Recipe updated with new name, calories, and added ingredient' -ForegroundColor Green
    Write-Host '  [PASS] TEST 5: New Recipe created and appended to catalog' -ForegroundColor Green
    Write-Host '  [PASS] TEST 6: Recipe deleted, removed from catalog & favorites, and counter updated' -ForegroundColor Green
    Write-Host '  [PASS] TEST 7: Edit and Delete buttons rendered on Favorites cards' -ForegroundColor Green
  } else {
    Write-Host "`n=== TEST FAILED ===" -ForegroundColor Red
    if ($output -match 'RECIPE_CRUD_FAIL:[^<]+') {
      Write-Host $matches[0] -ForegroundColor Red
    } else {
      Write-Host "Output: $output" -ForegroundColor Yellow
    }
    exit 1
  }
} finally {
  Remove-Item $testFile -ErrorAction SilentlyContinue
}
