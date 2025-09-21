# Stratégie de Scalabilité Multi-Propriétés/Entreprises

## Contexte

L'architecture actuelle permet à un utilisateur de créer théoriquement :
- **50+ propriétés résidentielles** (maisons, appartements) dans les 3 régions
- **50+ entreprises différentes** (chacune avec son propre numéro BCE)

**Architecture confirmée :**
```ruby
User (1) ---> (n) Properties
              ├── type: "maison" (région: bruxelles)
              ├── type: "appartement" (région: wallonie) 
              ├── type: "entreprise" (numero_ean: 0123456789)
              ├── type: "entreprise" (numero_ean: 0987654321)
              └── ... (jusqu'à 100+ propriétés au total)
```

## Problématiques identifiées

- **Performance** : Requêtes lourdes avec beaucoup de propriétés
- **UX/UI** : Interface devient difficile à naviguer avec beaucoup d'éléments
- **Gestion** : Difficulté à organiser et retrouver ses biens/entreprises

## Solutions proposées

### 1. Interface utilisateur améliorée

#### Dashboard avec onglets et filtres
```erb
<!-- Dashboard avec onglets -->
<ul class="nav nav-tabs">
  <li><a href="#residentielles">Propriétés (#{@user.properties.residential.count})</a></li>
  <li><a href="#entreprises">Entreprises (#{@user.properties.entreprises.count})</a></li>
</ul>

<!-- Filtres par région, type, statut -->
<div class="filters">
  <%= select_tag :region, options_for_select([['Toutes', ''], ['Bruxelles', 'bruxelles']]) %>
  <%= text_field_tag :search, '', placeholder: "Rechercher..." %>
</div>
```

#### Vue en cartes compactes avec pagination
```ruby
# Controller
@properties = current_user.properties.includes(:projects, :simulations)
                                    .page(params[:page]).per(12)
```

### 2. Optimisations base de données

#### Index de performance
```ruby
# Migration à créer
class AddPerformanceIndexesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_index :properties, [:user_id, :type, :region]
    add_index :properties, [:user_id, :created_at]
    add_index :projects, [:property_id, :bce_number]
    add_index :properties, [:user_id, :type, :numero_ean] # Pour les entreprises
  end
end
```

#### Requêtes optimisées
```ruby
# Property model - ajouter ces scopes
scope :with_stats, -> { 
  includes(:projects, :simulations)
  .select('properties.*, COUNT(projects.id) as projects_count')
  .left_joins(:projects)
  .group('properties.id')
}

scope :residential, -> { where.not(type: 'entreprise') }
scope :entreprises, -> { where(type: 'entreprise') }
scope :by_region, ->(region) { where(region: region) if region.present? }
```

### 3. Gestion intelligente des entreprises

#### Modèle Company séparé (refactoring majeur)
```ruby
# Nouveau modèle pour éviter la duplication
class Company < ApplicationRecord
  belongs_to :user
  has_many :properties, foreign_key: :company_id
  has_many :projects, through: :properties
  
  validates :bce_number, uniqueness: { scope: :user_id }
  validates :name, presence: true
  
  def display_name
    "#{name} (#{bce_number})"
  end
end

# Migration
class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :bce_number, null: false
      t.string :legal_form
      t.text :address
      t.integer :employees_count
      t.date :creation_date
      t.timestamps
    end
    
    add_index :companies, [:user_id, :bce_number], unique: true
    add_column :properties, :company_id, :bigint
    add_foreign_key :properties, :companies
  end
end

# Property model - ajout
class Property < ApplicationRecord
  belongs_to :company, optional: true
  
  def company_bce_number
    company&.bce_number || numero_ean
  end
  
  def is_company_property?
    company_id.present? || type == 'entreprise'
  end
end
```

### 4. UX/UI pour la scalabilité

#### Sélecteur d'entreprise avec autocomplete
```erb
<!-- Dans les formulaires de création de projet -->
<div class="form-group">
  <%= f.label :company_id, "Entreprise associée" %>
  <%= f.select :company_id, 
      options_from_collection_for_select(current_user.companies, :id, :display_name),
      { include_blank: "Nouvelle entreprise..." },
      { class: "select2", data: { placeholder: "Rechercher une entreprise..." } } %>
</div>

<!-- JavaScript pour autocomplete -->
<script>
$('.select2').select2({
  placeholder: "Rechercher une entreprise...",
  allowClear: true,
  width: '100%'
});
</script>
```

#### Navigation rapide avec breadcrumbs
```erb
<nav aria-label="breadcrumb">
  <ol class="breadcrumb">
    <li><%= link_to "Dashboard", dashboard_path %></li>
    <li><%= link_to "Mes biens", properties_path %></li>
    <li><%= @property.is_company_property? ? "Entreprises" : "Résidentiel" %></li>
    <li class="active"><%= @property.titre %></li>
  </ol>
</nav>
```

#### Recherche avancée
```erb
<!-- Formulaire de recherche global -->
<%= form_with url: properties_path, method: :get, local: true, class: "search-form" do |f| %>
  <div class="row">
    <div class="col-md-3">
      <%= f.text_field :search, placeholder: "Nom, adresse...", value: params[:search] %>
    </div>
    <div class="col-md-2">
      <%= f.select :type, options_for_select([['Tous', ''], ['Résidentiel', 'residential'], ['Entreprise', 'entreprise']], params[:type]) %>
    </div>
    <div class="col-md-2">
      <%= f.select :region, options_for_select([['Toutes', ''], ['Bruxelles', 'bruxelles'], ['Wallonie', 'wallonie'], ['Flandre', 'flandre']], params[:region]) %>
    </div>
    <div class="col-md-2">
      <%= f.submit "Rechercher", class: "btn btn-primary" %>
    </div>
  </div>
<% end %>
```

### 5. Limitation intelligente et quotas

#### Système de quotas progressifs
```ruby
# User model - ajouter
class User < ApplicationRecord
  enum subscription_tier: { 
    free: 0, 
    basic: 1, 
    pro: 2, 
    enterprise: 3 
  }
  
  def max_properties
    case subscription_tier
    when 'free' then 3
    when 'basic' then 10
    when 'pro' then 50  
    when 'enterprise' then 500
    else 3
    end
  end
  
  def max_companies
    case subscription_tier
    when 'free' then 1
    when 'basic' then 3
    when 'pro' then 15  
    when 'enterprise' then 100
    else 1
    end
  end
  
  def can_add_property?
    properties.count < max_properties
  end
  
  def can_add_company?
    companies.count < max_companies
  end
  
  def properties_usage_percentage
    (properties.count.to_f / max_properties * 100).round
  end
end
```

#### Validation dans les contrôleurs
```ruby
# PropertiesController
before_action :check_property_limit, only: [:new, :create]

private

def check_property_limit
  unless current_user.can_add_property?
    redirect_to properties_path, 
                alert: "Limite de #{current_user.max_properties} propriétés atteinte. Upgradez votre compte."
  end
end
```

### 6. Performance et caching

#### Cache des statistiques utilisateur
```ruby
# User model - ajouter
class User < ApplicationRecord
  def stats_cache_key
    "user_#{id}_stats_#{properties.maximum(:updated_at)&.to_i}"
  end
  
  def cached_stats
    Rails.cache.fetch(stats_cache_key, expires_in: 1.hour) do
      {
        properties_count: properties.count,
        companies_count: companies.count,
        active_projects: projects.active.count,
        total_simulations: simulations.count
      }
    end
  end
end

# Callback pour invalider le cache
class Property < ApplicationRecord
  after_save :invalidate_user_stats_cache
  after_destroy :invalidate_user_stats_cache
  
  private
  
  def invalidate_user_stats_cache
    Rails.cache.delete(user.stats_cache_key)
  end
end
```

#### Pagination avec chargement Ajax
```javascript
// app/javascript/controllers/properties_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "loadMore"]
  
  loadMore(event) {
    event.preventDefault()
    const nextPage = parseInt(this.loadMoreTarget.dataset.page) + 1
    
    fetch(`/properties?page=${nextPage}`, {
      headers: { "Accept": "application/json" }
    })
    .then(response => response.json())
    .then(data => {
      this.containerTarget.insertAdjacentHTML('beforeend', data.html)
      this.loadMoreTarget.dataset.page = nextPage
      
      if (data.has_next_page) {
        this.loadMoreTarget.style.display = 'block'
      } else {
        this.loadMoreTarget.style.display = 'none'
      }
    })
  }
}
```

### 7. Organisation par groupes/dossiers

#### Système de groupes de propriétés
```ruby
# Nouveau modèle
class PropertyGroup < ApplicationRecord
  belongs_to :user
  has_many :property_group_memberships, dependent: :destroy
  has_many :properties, through: :property_group_memberships
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
  
  scope :ordered, -> { order(:name) }
end

class PropertyGroupMembership < ApplicationRecord
  belongs_to :property
  belongs_to :property_group
  
  validates :property_id, uniqueness: { scope: :property_group_id }
end

# Migration
class CreatePropertyGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :property_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, default: '#007bff'
      t.text :description
      t.timestamps
    end
    
    create_table :property_group_memberships do |t|
      t.references :property, null: false, foreign_key: true
      t.references :property_group, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :property_groups, [:user_id, :name], unique: true
    add_index :property_group_memberships, [:property_id, :property_group_id], 
              unique: true, name: 'index_property_group_memberships_unique'
  end
end
```

#### Interface de gestion des groupes
```erb
<!-- Vue pour gérer les groupes -->
<div class="property-groups">
  <h3>Mes dossiers</h3>
  
  <% current_user.property_groups.ordered.each do |group| %>
    <div class="group-card" style="border-left: 4px solid <%= group.color %>">
      <h5><%= group.name %> (<%= group.properties.count %>)</h5>
      <p class="text-muted"><%= group.description %></p>
      
      <div class="group-actions">
        <%= link_to "Voir", properties_path(group_id: group.id), class: "btn btn-sm btn-outline-primary" %>
        <%= link_to "Modifier", edit_property_group_path(group), class: "btn btn-sm btn-outline-secondary" %>
      </div>
    </div>
  <% end %>
  
  <%= link_to "Nouveau dossier", new_property_group_path, class: "btn btn-primary" %>
</div>
```

## Plan d'implémentation par priorité

### Phase 1 (Immédiat) - Performance de base
1. ✅ Ajouter les index de performance
2. ✅ Implémenter la pagination sur `/properties`
3. ✅ Ajouter les filtres par type et région

### Phase 2 (Court terme) - UX améliorée
1. ✅ Dashboard avec onglets Résidentiel/Entreprise
2. ✅ Recherche avec autocomplete
3. ✅ Breadcrumbs de navigation

### Phase 3 (Moyen terme) - Quotas et limitations
1. ✅ Système de quotas par abonnement
2. ✅ Interface d'upgrade de compte
3. ✅ Alertes de limite atteinte

### Phase 4 (Long terme) - Refactoring avancé
1. ⏳ Modèle Company séparé (breaking change)
2. ⏳ Système de groupes/dossiers
3. ⏳ Cache avancé et optimisations

## Analyse Plans SaaS Existants

### Plans B2C (Particuliers)

| Plan | Prix | Limite Propriétés | Limite Entreprises | Statut Multi-Biens |
|------|------|-------------------|-------------------|---------------------|
| **Découverte** | 0€/mois | 1 propriété | 0 | ❌ Inadapté |
| **Propriétaire** | 39€/mois | 3 propriétés | 0 | ⚠️ Insuffisant pour 50+ |
| **Investisseur** | 89€/mois | 10 propriétés | 0 | ⚠️ Limite trop basse |

### Plans B2B (Professionnels)

| Plan | Prix | Limite Propriétés | Fonctionnalités Multi-Entreprises | Statut |
|------|------|-------------------|-----------------------------------|---------|
| **Expert** | 149€/mois | ♾️ Clients illimités | ✅ Multi-utilisateurs + API | ⭐⭐ Adapté mais B2B |
| **Platform** | 299€/mois | ♾️ Illimité | ✅ IA dédiée + Custom | ⭐⭐⭐ Parfait mais cher |

### Gap Identifié : Investisseurs Multi-Propriétés

**Problème** : Aucun plan B2C entre 89€ (10 propriétés) et 299€ (illimité)

**Segment non couvert** : Investisseurs avec 10-50 propriétés + entreprises multiples

## Recommandations Pricing

### Solution Immédiate : Modifier "Investisseur"
```ruby
# Dans pricing_controller.rb - modifier portfolio tier
portfolio: {
  name: "Investisseur",
  price: 89,
  period: "mois",
  description: "Multi-propriétaires 4-25 biens + entreprises",
  features: [
    "Jusqu'à 25 propriétés résidentielles",    # ⬆️ Up from 10
    "Jusqu'à 10 entreprises BCE",              # ✨ NEW
    "Gestion multi-sociétés",                  # ✨ NEW
    "Ren0Chat : 150 questions/mois",
    "Decision Hub : Portfolio optimization",
    "Business Intelligence dashboard",
    "Optimiseur fiscal multi-entités",         # ✨ NEW
    # ... autres features existantes
  ],
  roi: "ROI minimum : 187% • ROI réaliste : 849%",
  target: "B2C Multi-investisseurs + Entrepreneurs"
}
```

### Solution Long-terme : Nouveau Plan "Investisseur Pro"
```ruby
# Ajouter dans pricing_tiers_data
investisseur_pro: {
  name: "Investisseur Pro",
  price: 169,
  period: "mois", 
  description: "Gros portefeuilles 25-100 propriétés",
  features: [
    "Jusqu'à 100 propriétés",
    "Jusqu'à 30 entreprises BCE",
    "Ren0Chat : 300 questions/mois",
    "IA Portfolio Advisor dédiée",
    "Multi-companies advanced management",
    "Advanced BI + Predictive Analytics",
    "Tax optimization multi-entities",
    "Legal compliance monitoring",
    "API access pour comptables/notaires",
    "Support prioritaire (4h)",
    "Account manager mensuel",
    "Webinaires formation VIP"
  ],
  roi: "ROI minimum : 387% • ROI réaliste : 1500%+",
  cta: "Choisir Investisseur Pro",
  target: "B2C Gros patrimoines"
}
```

### Segmentation Optimale Proposée
```
🆓 Découverte (0€)      → 1 propriété, 0 entreprise
🏠 Propriétaire (39€)   → 1-3 propriétés, 0 entreprise  
🏢 Investisseur (89€)   → 4-25 propriétés, 5-10 entreprises
💼 Investisseur Pro (169€) → 25-100 propriétés, 10-30 entreprises
🏛️ Enterprise (299€)   → Illimité + développements custom
```

### Logique de Recommandation Automatique
```ruby
# Dans recommend_tier_for_user method
def recommend_tier_for_user
  properties_count = current_user.properties.count
  companies_count = current_user.properties.entreprises.count
  
  case
  when properties_count <= 1 && companies_count == 0
    :individual
  when properties_count <= 3 && companies_count <= 1
    :individual
  when properties_count <= 25 && companies_count <= 10
    :portfolio  # "Investisseur"
  when properties_count <= 100 && companies_count <= 30
    :investisseur_pro  # NEW
  else
    :enterprise
  end
end
```

## Implémentation Pricing Optimisé

### Phase 1 : Modification Immédiate (1-2 jours)
1. ✅ Augmenter limite "Investisseur" : 10 → 25 propriétés
2. ✅ Ajouter support entreprises dans quotas existants
3. ✅ Mettre à jour la logique de recommandation

### Phase 2 : Nouveau Plan (1-2 semaines)
1. ✅ Créer plan "Investisseur Pro"
2. ✅ Adapter l'UI B2C pour ce segment
3. ✅ Marketing ciblé gros patrimoine

### Phase 3 : Analytics & Optimisation (ongoing)
1. ✅ Tracker conversion par segment
2. ✅ A/B test sur les prix
3. ✅ Feedback utilisateurs multi-propriétés

## Métriques à surveiller

- **Performance** : Temps de chargement page `/properties`
- **Usage** : Distribution du nombre de propriétés par utilisateur
- **Conversion** : Taux d'upgrade vers plans payants
- **UX** : Temps passé sur la recherche/navigation
- **Pricing** : Conversion "Investisseur" vs "Investisseur Pro"
- **Retention** : Churn rate par segment de patrimoine

## Notes techniques

- **Breaking changes** : Le refactoring Company nécessite une migration de données
- **Cache** : Attention aux invalidations en cascade
- **Mobile** : Adapter l'UI pour les écrans mobiles avec beaucoup de données
- **API** : Prévoir les endpoints pour futures apps mobiles
- **Pricing** : Tests A/B sur les nouvelles limites avant déploiement final

---

**Date de création** : 21 septembre 2025  
**Status** : En attente d'implémentation  
**Priorité** : Haute (gap pricing identifié)  
**ROI estimé** : +40% revenus segment premium