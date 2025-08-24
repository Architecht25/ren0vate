# 📋 Système de Documents Officiels des Primes

Ce système permet de stocker et distribuer les documents officiels (attestations d'entrepreneur, formulaires, guides) associés aux primes d'énergie.

## 🎯 Fonctionnalités

- **Stockage centralisé** : 150+ documents organisés par prime
- **Téléchargement individuel** : Chaque document accessible séparément
- **Téléchargement groupé** : ZIP automatique pour plusieurs documents
- **Intégration simulation** : Documents suggérés après simulation de primes
- **Interface utilisateur** : Pages dédiées avec filtres et recherche

## 🗂️ Structure

### Modèles

- **`PrimeDocumentTemplate`** : Documents officiels liés aux primes
- **Relations** : `belongs_to :prime`, `has_one_attached :document_file`

### Types de documents supportés

- `attestation_entrepreneur` : Document obligatoire signé par l'entrepreneur
- `formulaire_demande` : Formulaire officiel de demande
- `annexe_technique` : Spécifications techniques
- `guide_remplissage` : Guide d'aide au remplissage
- `certificat_conformite` : Certificat de conformité
- `fiche_technique` : Fiche technique détaillée

## 🚀 Utilisation

### 1. Dans une simulation

```erb
<!-- Afficher les documents disponibles après simulation -->
<%= render 'prime_document_templates/simulation_documents', simulation: @simulation %>
```

### 2. Helper methods

```erb
<!-- Vérifier la disponibilité -->
<% if documents_available_for_simulation?(@simulation) %>
  <%= documents_count_for_simulation(@simulation) %> documents disponibles
<% end %>

<!-- Badge avec icône -->
<%= document_type_badge(template.type_document) %>

<!-- Lien de téléchargement groupé -->
<%= link_to "Télécharger tout", download_all_documents_url(@simulation) %>
```

### 3. Routes principales

- `/prime_document_templates` : Liste tous les documents
- `/prime_document_templates/:id` : Détail d'un document
- `/prime_document_templates/:id/download` : Téléchargement direct
- `/simulations/:id/download_documents` : ZIP des documents de simulation
- `/primes/:id/download_documents` : ZIP des documents d'une prime

## 📁 Stockage des fichiers

### Développement/Production
- **Active Storage** avec Cloudinary
- CDN mondial pour performances optimales
- Gestion automatique des transformations

### URLs alternatives
- Support des `file_url` pour fichiers externes
- Fallback automatique selon disponibilité

## 🛠️ Administration

### Ajout de nouveaux documents

```ruby
# Via seeds ou console Rails
PrimeDocumentTemplate.create!(
  prime: Prime.find_by(slug: "isolation_toiture"),
  type_document: 'attestation_entrepreneur',
  title: "Attestation entrepreneur - Isolation toiture",
  description: "Document obligatoire...",
  is_required: true,
  order_position: 1,
  file_url: "/documents/attestation_isolation.pdf"
)
```

### Seeds automatiques

```bash
# Créer documents pour toutes les primes
rails runner "load 'db/seeds/prime_documents.rb'"
```

## 🔧 Configuration

### Gemfile
```ruby
gem 'rubyzip'  # Pour les téléchargements ZIP
```

### Active Storage
```yaml
# config/storage.yml
cloudinary:
  service: Cloudinary
  folder: <%= Rails.env %>
```

## 📊 Performance

- **Index optimisés** : `prime_id`, `type_document`, `is_required`
- **Eager loading** : Inclut automatiquement les relations prime
- **Cache** : Possibilité de mise en cache des listes fréquentes
- **Pagination** : Support intégré pour grandes listes

## 🎨 Interface utilisateur

### Features UI
- Filtres par prime et type de document
- Prévisualisation des documents
- Téléchargement en un clic
- Indicateurs visuels (obligatoire/optionnel)
- Responsive design

### Navigation
- Lien dans la navbar : "Documents officiels"
- Intégration dans les simulations
- Breadcrumbs et navigation contextuelle

## 🔒 Sécurité

- Authentification requise : `authenticate_user!`
- Contrôle d'accès par utilisateur
- URLs temporaires pour fichiers Cloudinary
- Validation des types de fichiers

## 🚨 Gestion d'erreurs

- Fallback automatique si fichier indisponible
- Messages d'erreur explicites dans les ZIP
- Logs détaillés pour le debugging
- Interface gracieuse en cas de problème

## 💡 Exemples d'intégration

Voir les fichiers :
- `app/views/prime_document_templates/_simulation_documents.html.erb`
- `app/views/simulations/_example_integration.html.erb`
- `app/helpers/prime_document_templates_helper.rb`

---

✅ **Système prêt pour 150+ attestations d'entrepreneur et documents officiels !**
