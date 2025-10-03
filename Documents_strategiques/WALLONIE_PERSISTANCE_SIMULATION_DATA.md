# Persistance des données de simulation Wallonie

## État actuel ✅

Le simulateur Wallonie fonctionne parfaitement avec :
- ✅ Backend `WalloniePostLoginCalculatorService` opérationnel
- ✅ Frontend avec tous les mappings et méthodes calculate
- ✅ Communication backend-frontend via events `wallonie:prime-updated`
- ✅ Affichage des spans individuels pour toutes les cartes
- ✅ Calculs corrects pour toutes les primes

## Objectif 🎯

Implémenter la persistance des données de simulation sous forme de hash pour permettre :
- Sauvegarde automatique des inputs utilisateur
- Rechargement des données lors du retour sur la simulation
- Mise à jour sans perte de données
- Historique des modifications

## 1. Structure de données proposée

### Base de données
```ruby
# Migration à créer
add_column :simulations, :wallonie_data, :json, default: {}
```

### Structure JSON
```json
{
  "user_inputs": {
    "wallonie_toiture_remplacement_couverture": 200,
    "wallonie_toiture_appropriation_charpente": "1",
    "wallonie_vmc_simple": "1",
    "wallonie_vmc_double": "1",
    "wallonie_chauffage_isol_conduites": "1",
    "wallonie_menuiseries_vitrages": 25,
    "wallonie_installation_electrique": "1"
  },
  "calculated_primes": {
    "wallonie_toiture_remplacement_couverture": 1600.0,
    "wallonie_toiture_appropriation_charpente": 200,
    "wallonie_vmc_simple": 560,
    "wallonie_vmc_double": 1360,
    "wallonie_chauffage_isol_conduites": 68,
    "wallonie_menuiseries_vitrages": 1300.0,
    "wallonie_installation_electrique": 640
  },
  "totals": {
    "global": 5728,
    "audit": 0,
    "isolation": 0,
    "chauffage": 68,
    "autres": 5660
  },
  "metadata": {
    "last_updated": "2025-10-03T22:20:00Z",
    "calculation_version": "v1.0",
    "user_category": "standard"
  }
}
```

## 2. Modifications Backend

### 2.1 Service WalloniePostLoginCalculatorService

```ruby
# Dans app/services/regions/wallonie/wallonie_post_login_calculator_service.rb

class Regions::Wallonie::WalloniePostLoginCalculatorService
  # ... code existant ...

  def calculate_all_primes_with_persistence(user_inputs, simulation = nil)
    prime_results = calculate_all_primes(user_inputs)

    if simulation
      save_calculation_data(simulation, user_inputs, prime_results)
    end

    prime_results
  end

  private

  def save_calculation_data(simulation, user_inputs, prime_results)
    # Calculer les totaux par catégorie
    totals = calculate_category_totals(prime_results)

    wallonie_data = {
      user_inputs: user_inputs,
      calculated_primes: prime_results.transform_values { |v| v[:amount] },
      totals: totals,
      metadata: {
        last_updated: Time.current.iso8601,
        calculation_version: "v1.0",
        user_category: determine_user_category(simulation)
      }
    }

    simulation.update!(wallonie_data: wallonie_data)

    Rails.logger.info "💾 Données Wallonie sauvegardées pour simulation #{simulation.id}"
  end

  def calculate_category_totals(prime_results)
    total_global = prime_results.values.sum { |v| v[:amount] }

    # Logique de catégorisation selon le système existant
    audit_total = prime_results.select { |k, v| k.include?('audit') }.values.sum { |v| v[:amount] }
    isolation_total = prime_results.select { |k, v| k.include?('isolation') || k.include?('sols') }.values.sum { |v| v[:amount] }
    chauffage_total = prime_results.select { |k, v| k.include?('chauffage') || k.include?('pac') || k.include?('chaudiere') }.values.sum { |v| v[:amount] }
    autres_total = total_global - audit_total - isolation_total - chauffage_total

    {
      global: total_global,
      audit: audit_total,
      isolation: isolation_total,
      chauffage: chauffage_total,
      autres: autres_total
    }
  end

  def determine_user_category(simulation)
    # Logique pour déterminer la catégorie utilisateur
    # basée sur les données de la simulation
    "standard" # Pour l'instant
  end
end
```

### 2.2 Contrôleur SimulationsController

```ruby
# Dans app/controllers/simulations_controller.rb

def update_prime_inputs
  # ... code existant jusqu'à la ligne calculate_all_primes ...

  # Utiliser la nouvelle méthode avec persistance
  if @simulation.region == 'wallonie'
    service = Regions::Wallonie::WalloniePostLoginCalculatorService.new(@simulation.property)
    prime_results = service.calculate_all_primes_with_persistence(user_inputs, @simulation)
    # ... reste du code existant ...
  end

  # ... reste du code ...
end

def show
  # ... code existant ...

  # Charger les données persistantes pour pré-remplir le formulaire
  if @simulation.region == 'wallonie' && @simulation.wallonie_data.present?
    @wallonie_persisted_data = @simulation.wallonie_data
  end

  # ... reste du code ...
end
```

## 3. Modifications Frontend

### 3.1 Template ERB pour passer les données

```erb
<!-- Dans app/views/simulations/show.html.erb -->
<div id="wallonie-simulation-container"
     data-controller="wallonie-simulation"
     data-wallonie-simulation-slug-value="<%= @simulation.region %>"
     <% if @wallonie_persisted_data.present? %>
     data-wallonie-simulation-persisted-data-value="<%= @wallonie_persisted_data.to_json %>"
     <% end %>>
  <!-- ... contenu existant ... -->
</div>
```

### 3.2 Contrôleur JavaScript wallonie_simulation_controller.js

```javascript
// Dans app/javascript/controllers/wallonie_simulation_controller.js

export default class extends Controller {
  static values = {
    slug: String,
    persistedData: Object  // Nouveau value pour les données persistantes
  }

  connect() {
    console.log(`🎯 Contrôleur Wallonie Simulation connecté pour: ${this.slugValue}`)

    // Charger les données persistantes si disponibles
    if (this.hasPersistedDataValue) {
      this.loadPersistedData()
    }

    // ... reste du code existant ...
  }

  loadPersistedData() {
    console.log('💾 Chargement des données persistantes:', this.persistedDataValue)

    const data = this.persistedDataValue

    if (data.user_inputs) {
      this.restoreUserInputs(data.user_inputs)
    }

    if (data.calculated_primes) {
      this.restoreCalculatedPrimes(data.calculated_primes)
    }

    if (data.totals) {
      this.restoreTotals(data.totals)
    }
  }

  restoreUserInputs(inputs) {
    console.log('🔄 Restauration des inputs utilisateur')

    Object.entries(inputs).forEach(([slug, value]) => {
      const input = this.element.querySelector(`[data-slug="${slug}"]`)
      if (input) {
        if (input.type === 'checkbox') {
          input.checked = value === "1" || value === 1
        } else {
          input.value = value
        }
        console.log(`✅ Input ${slug} restauré: ${value}`)
      }
    })
  }

  restoreCalculatedPrimes(primes) {
    console.log('💰 Restauration des primes calculées')

    // Émettre l'événement avec les primes calculées
    this.emitPrimeUpdateEvent(primes)
  }

  restoreTotals(totals) {
    console.log('📊 Restauration des totaux')

    if (this.hasTotalGlobalTarget && totals.global) {
      this.updateTotalGlobal(totals.global)
    }
  }

  // ... reste du code existant ...
}
```

## 4. Migration de base de données

```ruby
# db/migrate/xxx_add_wallonie_data_to_simulations.rb

class AddWallonieDataToSimulations < ActiveRecord::Migration[7.0]
  def change
    add_column :simulations, :wallonie_data, :json, default: {}

    add_index :simulations, :wallonie_data, using: :gin
  end
end
```

## 5. Modèle Simulation

```ruby
# Dans app/models/simulation.rb

class Simulation < ApplicationRecord
  # ... code existant ...

  # Validations pour wallonie_data
  validate :validate_wallonie_data_structure, if: :wallonie_data_changed?

  # Scopes
  scope :with_wallonie_data, -> { where.not(wallonie_data: {}) }
  scope :wallonie_simulations, -> { where(region: 'wallonie') }

  # Méthodes d'accès aux données Wallonie
  def wallonie_user_inputs
    wallonie_data.dig('user_inputs') || {}
  end

  def wallonie_calculated_primes
    wallonie_data.dig('calculated_primes') || {}
  end

  def wallonie_totals
    wallonie_data.dig('totals') || {}
  end

  def wallonie_last_updated
    Time.parse(wallonie_data.dig('metadata', 'last_updated')) if wallonie_data.dig('metadata', 'last_updated')
  end

  private

  def validate_wallonie_data_structure
    return unless wallonie_data.present?

    required_keys = %w[user_inputs calculated_primes totals metadata]
    missing_keys = required_keys - wallonie_data.keys

    if missing_keys.any?
      errors.add(:wallonie_data, "manque les clés: #{missing_keys.join(', ')}")
    end
  end
end
```

## 6. Tests recommandés

### 6.1 Tests du service

```ruby
# spec/services/regions/wallonie/wallonie_post_login_calculator_service_spec.rb

RSpec.describe Regions::Wallonie::WalloniePostLoginCalculatorService do
  describe '#calculate_all_primes_with_persistence' do
    let(:simulation) { create(:simulation, region: 'wallonie') }
    let(:user_inputs) { { 'wallonie_vmc_simple' => '1' } }

    it 'calcule et sauvegarde les données' do
      service = described_class.new(simulation.property)

      expect {
        service.calculate_all_primes_with_persistence(user_inputs, simulation)
      }.to change { simulation.reload.wallonie_data }

      expect(simulation.wallonie_data['user_inputs']).to eq(user_inputs)
      expect(simulation.wallonie_data['calculated_primes']).to include('wallonie_vmc_simple')
    end
  end
end
```

## 7. Déploiement

### Étapes de mise en production :

1. **Migration base de données**
   ```bash
   rails db:migrate
   ```

2. **Tests**
   ```bash
   rspec spec/services/regions/wallonie/
   rspec spec/controllers/simulations_controller_spec.rb
   ```

3. **Compilation assets**
   ```bash
   rails assets:precompile
   ```

4. **Redémarrage serveur**

## 8. Bénéfices attendus

- ✅ **Persistance complète** : Aucune perte de données utilisateur
- ✅ **Performance** : Rechargement instantané sans recalcul
- ✅ **UX améliorée** : Continuité dans l'expérience utilisateur
- ✅ **Traçabilité** : Historique des modifications
- ✅ **Robustesse** : Données sauvegardées en base
- ✅ **Extensibilité** : Structure prête pour nouvelles fonctionnalités

## 9. Points d'attention

- **Migrations données** : Prévoir la migration des simulations existantes
- **Compatibilité** : Assurer la rétrocompatibilité
- **Performance** : Optimiser les requêtes JSON
- **Validation** : Valider la structure des données JSON
- **Monitoring** : Logger les sauvegardes et erreurs

---

**Status** : Prêt pour implémentation
**Priorité** : Haute
**Estimation** : 1-2 jours de développement
