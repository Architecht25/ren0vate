# Migration Bruxelles & Wallonie vers Architecture Flandre

## 📋 Contexte de la Correction Flandre

### Problème résolu
- **Issue initiale** : Spans affichant "0 €" au lieu des montants calculés (ex: "1600 €" pour isolation_toiture)
- **Cause racine** : Calculs JavaScript locaux dans les cartes au lieu d'utiliser le service Ruby centralisé
- **Solution** : Architecture centralisée avec distribution des résultats du service Ruby vers les spans individuels

### Architecture Flandre corrigée
```
Input HTML → Card JS → Parent Controller → Service Ruby → JSON Response → Distribution aux spans
```

## 🔍 État Actuel : Bruxelles & Wallonie

### Structure Existante
- **Bruxelles** : `bruxelles_simulation_controller.js` + `bruxelles_simulation_card_controller.js`
- **Wallonie** : `wallonie_simulation_controller.js` + `wallonie_simulation_card_controller.js`
- **Services** : `BruxellesPostLoginCalculatorService` + `WalloniePostLoginCalculatorService`
- **API** : `SimulationPrimesUpdater` centralisé

### Problèmes identifiés
1. ❌ **Calculs locaux dans les cartes** : Logique de calcul dupliquée en JavaScript
2. ❌ **Pas de distribution centralisée** : Résultats du service Ruby non redistribués aux spans
3. ❌ **onInputChange() local** : Cards calculent localement au lieu de déléguer au parent
4. ❌ **Structure de réponse différente** : Services renvoient des formats incompatibles avec distribution

## 🎯 Plan de Migration

### Phase 1 : Architecture des Contrôleurs

#### 1.1 Parent Controllers (simulation_controller.js)
**À modifier dans** :
- `app/javascript/controllers/bruxelles_simulation_controller.js`
- `app/javascript/controllers/wallonie_simulation_controller.js`

**Ajouts nécessaires** :
```javascript
// Méthode de distribution (inspirée de Flandre)
updateCardsWithCalculatedAmounts(updatedCards) {
  if (!updatedCards) return

  Object.keys(updatedCards).forEach(categoryKey => {
    const categoryData = updatedCards[categoryKey]
    if (!categoryData.primes) return

    categoryData.primes.forEach(prime => {
      const slug = prime.slug
      const calculatedAmount = prime.calculated_amount || 0

      // Trouver la carte correspondante pour Bruxelles
      const cardElement = document.querySelector(`[data-bruxelles-simulation-card-slug-value="${slug}"]`)
      // OU pour Wallonie
      const cardElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)

      if (cardElement) {
        const resultSpan = cardElement.querySelector('[data-bruxelles-simulation-card-target="total"]')
        // OU pour Wallonie
        const resultSpan = cardElement.querySelector('[data-wallonie-simulation-card-target="total"]')

        if (resultSpan) {
          const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
          resultSpan.textContent = `${formattedAmount} €`
        }
      }
    })
  })
}

// Méthode de sauvegarde centralisée (inspirée de Flandre)
saveUserInput() {
  // Collecter toutes les saisies utilisateur
  const userInputs = this.collectAllUserInputs()

  // Appeler le service via API
  this.callUpdateService(userInputs)
}

callUpdateService(userInputs) {
  fetch(`/simulations/${this.simulationIdValue}/update_prime_inputs`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({ user_inputs: userInputs })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success && data.updated_cards) {
      this.updateCardsWithCalculatedAmounts(data.updated_cards)
      // Mettre à jour le total général
      this.updateTotalGlobal()
    }
  })
}
```

#### 1.2 Card Controllers (simulation_card_controller.js)
**À modifier dans** :
- `app/javascript/controllers/bruxelles_simulation_card_controller.js`
- `app/javascript/controllers/wallonie_simulation_card_controller.js`

**Modifications nécessaires** :
```javascript
// Remplacer la méthode onInputChange() actuelle
onInputChange() {
  // Au lieu de this.calculate(), déléguer au parent
  const parentController = this.getParentController()
  if (parentController && parentController.saveUserInput) {
    parentController.saveUserInput()
  }
}

// Améliorer getParentController() pour plus de robustesse
getParentController() {
  // Version améliorée avec traversée DOM robuste
  let currentElement = this.element
  while (currentElement) {
    const parentElement = currentElement.closest('[data-controller*="bruxelles-simulation"], [data-controller*="wallonie-simulation"]')
    if (parentElement) {
      const controllerName = parentElement.getAttribute('data-controller').includes('bruxelles')
        ? 'bruxelles-simulation'
        : 'wallonie-simulation'
      return this.application.getControllerForElementAndIdentifier(parentElement, controllerName)
    }
    currentElement = currentElement.parentElement
  }
  return null
}
```

### Phase 2 : Services Backend

#### 2.1 Structure de Réponse Unifiée
**Services concernés** :
- `app/services/regions/bruxelles/bruxelles_post_login_calculator_service.rb`
- `app/services/regions/wallonie/wallonie_post_login_calculator_service.rb`

**Modification nécessaire** : S'assurer que les services renvoient une structure compatible avec `SimulationPrimesUpdater` :

```ruby
# Format attendu pour updated_cards
{
  "bruxelles_cat2" => {  # ou "wallonie_cat2"
    "total" => 2500,
    "primes" => [
      {
        "slug" => "isolation_toiture",
        "calculated_amount" => 1600,
        "titre" => "Isolation toiture"
      },
      {
        "slug" => "isolation_murs",
        "calculated_amount" => 900,
        "titre" => "Isolation murs"
      }
    ]
  }
}
```

#### 2.2 SimulationPrimesUpdater
**Fichier** : `app/services/simulation_primes_updater.rb`

**Vérification** : S'assurer que la méthode `build_cards_response()` fonctionne pour Bruxelles et Wallonie :
```ruby
def build_cards_response(prime_cards)
  response = {}

  prime_cards.each do |category_key, category_data|
    next unless category_data["primes"]

    primes_data = category_data["primes"].map do |prime|
      {
        slug: prime["slug"],
        titre: prime["titre"],
        calculated_amount: prime["calculated_amount"],
        user_input_value: prime["user_input_value"]
      }
    end

    response[category_key] = {
      total: category_data["total"],
      primes: primes_data
    }
  end

  response
end
```

### Phase 3 : Templates HTML

#### 3.1 Vérification des Data Attributes
**Fichiers concernés** :
- `app/views/simulations/partials_bruxelles/_cartes_*.html.erb`
- `app/views/simulations/partials_wallonie/_cartes_*.html.erb`

**Vérifications nécessaires** :
```erb
<!-- Chaque carte doit avoir -->
<div data-controller="bruxelles-simulation-card"
     data-bruxelles-simulation-card-slug-value="<%= prime.slug %>">

  <!-- Input avec action -->
  <input data-action="input->bruxelles-simulation-card#onInputChange">

  <!-- Span pour le résultat -->
  <span data-bruxelles-simulation-card-target="total">0 €</span>
</div>
```

### Phase 4 : Tests & Validation

#### 4.1 Checklist de Vérification
- [ ] **Parent Controller** : Méthode `updateCardsWithCalculatedAmounts()` implémentée
- [ ] **Parent Controller** : Méthode `saveUserInput()` implémentée
- [ ] **Card Controllers** : `onInputChange()` délègue au parent
- [ ] **Card Controllers** : `getParentController()` robuste
- [ ] **Services** : Réponse au format `updated_cards` correct
- [ ] **Templates** : Data attributes corrects
- [ ] **API** : Endpoint `/simulations/:id/update_prime_inputs` fonctionnel

#### 4.2 Tests Fonctionnels
```javascript
// Test 1 : Saisie dans un input déclenche saveUserInput()
// Test 2 : Service renvoie updated_cards
// Test 3 : updateCardsWithCalculatedAmounts() met à jour les spans
// Test 4 : Spans affichent "1600 €" au lieu de "0 €"
```

## 🔧 Ordre d'Exécution

### Étape 1 : Bruxelles
1. Modifier `bruxelles_simulation_controller.js` (parent)
2. Modifier `bruxelles_simulation_card_controller.js` (cards)
3. Vérifier `BruxellesPostLoginCalculatorService`
4. Tester avec isolation_toiture Bruxelles
5. Compiler assets : `bin/rails assets:precompile`

### Étape 2 : Wallonie
1. Modifier `wallonie_simulation_controller.js` (parent)
2. Modifier `wallonie_simulation_card_controller.js` (cards)
3. Vérifier `WalloniePostLoginCalculatorService`
4. Tester avec isolation_toiture Wallonie
5. Compiler assets : `bin/rails assets:precompile`

### Étape 3 : Déploiement
1. Git commit avec message descriptif
2. Push origin master
3. Push heroku master
4. Tests production

## 🎯 Résultat Attendu

Après migration, l'architecture sera unifiée :
```
✅ Flandre : Input → Card → Parent → Service → Distribution → Spans (1600€)
✅ Bruxelles : Input → Card → Parent → Service → Distribution → Spans (1600€)
✅ Wallonie : Input → Card → Parent → Service → Distribution → Spans (1600€)
```

## ⚠️ Points d'Attention

1. **Data Attributes** : Vérifier les noms des targets (`total` vs `result`)
2. **Sélecteurs CSS** : Adapter les sélecteurs aux data attributes régionaux
3. **Services** : S'assurer que les services Ruby renvoient le bon format
4. **Compilation Assets** : Toujours recompiler après modifications JS
5. **Tests** : Vérifier que les spans affichent les montants calculés et non "0 €"

---

*Cette architecture centralisée garantit la cohérence entre les trois régions et élimine les calculs JavaScript dupliqués en faveur du service Ruby centralisé.*
