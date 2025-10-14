# 📄 Export PDF des Données d'Éligibilité et Primes

## 🎯 Objectif

Cette fonctionnalité permet aux utilisateurs d'exporter leurs données de test d'éligibilité et calculs de primes stockées en localStorage vers des documents PDF formatés et professionnels.

## 🏗️ Architecture

### Backend (Rails)
- **Contrôleur**: `PdfExportsController` - Gère les 3 types d'export (éligibilité, primes, complet)
- **Gems**:
  - `wicked_pdf` - Génération de PDF depuis HTML
  - `wkhtmltopdf-binary` - Moteur de rendu PDF
- **Templates**: Layouts et vues HTML/ERB dans `app/views/pdf_exports/`
- **Routes**: 3 endpoints POST pour les différents types d'export

### Frontend (Stimulus)
- **Contrôleur**: `pdf_export_controller.js` - Récupère les données localStorage et lance l'export
- **Détection automatique**: Détecte la région (Flandre, Bruxelles, Wallonie) via URL et données
- **Collecte de données**: Agrège les données depuis localStorage et le DOM actuel

## 📋 Types d'Export Disponibles

### 1. Export Éligibilité (`/pdf_exports/eligibilite`)
- Résultats du test d'éligibilité uniquement
- Questions/réponses formatées en tableau
- Résultat d'éligibilité (accepté/refusé)

### 2. Export Primes (`/pdf_exports/primes`)
- Calculs de primes uniquement
- Travaux sélectionnés
- Primes calculées par type
- Total des primes

### 3. Export Complet (`/pdf_exports/complet`)
- Combine éligibilité + primes
- Document complet avec toutes les informations

## 🎨 Données Exportées

### Données d'Éligibilité
```javascript
// Flandre
localStorage.getItem('eligibiliteRenovate')

// Bruxelles
localStorage.getItem('eligibiliteBruxelles')
localStorage.getItem('eligibiliteBruxellesParticulier')

// Wallonie
localStorage.getItem('eligibiliteWallonieParticulier')
localStorage.getItem('eligibiliteWallonieEntreprise')
localStorage.getItem('eligibiliteWallonieSyndic')
localStorage.getItem('eligibiliteWallonieAsbl')
```

### Données de Primes
```javascript
// Communes à toutes les régions
localStorage.getItem('total_primes')
localStorage.getItem('details_primes')

// Spécifique Bruxelles
localStorage.getItem('selectedBruxellesCategory')
localStorage.getItem('bruxellesCategorieEstimee')

// Spécifique Wallonie
localStorage.getItem('selectedWallonieCategory')
localStorage.getItem('wallonie_categorie')
```

## 🔧 Utilisation

### 1. Inclusion des Boutons d'Export

```erb
<!-- Dans n'importe quelle vue -->
<%= render 'shared/pdf_export_buttons' %>
```

### 2. Contrôleur Stimulus

```html
<!-- Div avec le contrôleur Stimulus -->
<div data-controller="pdf-export">
  <!-- Boutons avec les actions correspondantes -->
  <button data-action="click->pdf-export#exportEligibilite">Export Éligibilité</button>
  <button data-action="click->pdf-export#exportPrimes">Export Primes</button>
  <button data-action="click->pdf-export#exportComplet">Export Complet</button>
</div>
```

### 3. Utilisation Manuelle (JavaScript)

```javascript
// Déclenchement programmatique
const controller = application.getControllerForElementAndIdentifier(element, 'pdf-export')
controller.exportComplet(new Event('click'))
```

## 🎨 Personalisation du Design

### CSS Personnalisé
Le partial `_pdf_export_buttons.html.erb` inclut du CSS inline pour le styling des boutons. Vous pouvez :
- Modifier les couleurs dans le CSS inline
- Déplacer les styles vers un fichier SCSS séparé
- Adapter le responsive design

### Templates PDF
Les templates sont dans `app/views/pdf_exports/` :
- `eligibilite_export.html.erb`
- `primes_export.html.erb`
- `complet_export.html.erb`
- `layouts/pdf.html.erb` (layout commun)

## 🔍 Débogage

### Vérification des Données
```javascript
// Console du navigateur
console.log('Données Flandre:', localStorage.getItem('eligibiliteRenovate'))
console.log('Données Bruxelles:', localStorage.getItem('eligibiliteBruxelles'))
console.log('Total primes:', localStorage.getItem('total_primes'))
```

### Logs Rails
```ruby
# Dans le contrôleur
Rails.logger.info "Export data: #{@export_data.inspect}"
```

### Test des Routes
```bash
# Test en curl
curl -X POST http://localhost:3000/pdf_exports/eligibilite \
  -H "Content-Type: application/json" \
  -d '{"data": "{\"test\": \"value\"}", "region": "bruxelles"}'
```

## 🚀 Améliorations Futures

### Fonctionnalités Envisageables
1. **Email automatique** : Envoi du PDF par email
2. **Sauvegarde cloud** : Upload vers Cloudinary/AWS S3
3. **Templates personnalisés** : Choix de mise en page
4. **Historique** : Sauvegarde des exports précédents
5. **Compression** : Optimisation de la taille des PDF
6. **Signature numérique** : Authentification des documents

### Optimisations Techniques
1. **Cache des templates** : Mise en cache des rendus HTML
2. **Queue jobs** : Export asynchrone pour gros volumes
3. **CDN** : Delivery optimisée des PDF
4. **Monitoring** : Métriques d'utilisation et performance

## 📱 Responsive Design

Les boutons d'export s'adaptent automatiquement :
- **Desktop** : Boutons côte à côte
- **Mobile** : Boutons empilés verticalement
- **Tablette** : Layout adaptatif

## 🔒 Sécurité

### Validation des Données
- Parsing sécurisé du JSON
- Validation des paramètres d'entrée
- Protection CSRF automatique Rails

### Limitations
- Taille maximale des données JSON
- Rate limiting recommandé
- Validation du contenu HTML

## 📊 Métriques

Pour suivre l'utilisation, vous pouvez ajouter :
```ruby
# Dans le contrôleur
Rails.logger.info "PDF Export: #{@export_type} for region #{@region}"

# Ou avec un service d'analytics
Analytics.track('pdf_export', {
  type: @export_type,
  region: @region,
  data_size: @export_data.to_s.length
})
```
