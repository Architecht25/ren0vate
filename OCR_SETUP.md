# Installation et Configuration OCR

Ce guide explique comment configurer les fonctionnalités OCR (reconnaissance optique de caractères) dans l'application Ren0vate.

## 📋 Fonctionnalités OCR

L'application propose deux modes d'OCR :

1. **Upload normal + OCR optionnel** : L'utilisateur peut choisir d'activer l'OCR lors du drag & drop
2. **Scan OCR rapide** : Modal dédiée pour un scan rapide depuis les simulations

### Intégration

- ✅ **Zone de drag & drop améliorée** avec option OCR
- ✅ **Modal de scan rapide** dans les simulations
- ✅ **Extraction automatique** du texte dans les notes du document
- ✅ **Support multi-format** : PDF, JPEG, PNG, GIF, WebP
- ✅ **Détection de langue** automatique (FR, NL, EN)
- ✅ **Calcul de confiance** basé sur la qualité du texte

## 🔧 Installation Tesseract (Recommandé)

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr tesseract-ocr-fra tesseract-ocr-nld tesseract-ocr-eng
```

### macOS
```bash
brew install tesseract tesseract-lang
```

### Test de l'installation
```bash
tesseract --version
tesseract --list-langs
```

## 🚀 Configuration Alternative : Google Vision API

Si vous préférez utiliser Google Vision API :

1. Créez un projet Google Cloud Platform
2. Activez l'API Vision
3. Créez une clé API
4. Ajoutez la gem : `gem 'google-cloud-vision'`
5. Configurez les credentials Rails

## 📁 Structure des fichiers

```
app/
├── controllers/
│   └── ocr_controller.rb          # Contrôleur API OCR
├── services/
│   └── ocr_service.rb             # Service principal OCR
└── views/
    ├── documents/
    │   └── new.html.erb           # Formulaire avec OCR
    └── simulations/
        └── show.html.erb          # Modal scan rapide
```

## 🎯 Utilisation

### 1. Upload avec OCR
- Allez sur `/documents/new`
- Sélectionnez "Scan OCR + Upload"
- Glissez votre document
- Le texte est automatiquement extrait et ajouté aux notes

### 2. Scan OCR rapide
- Depuis une simulation, cliquez "Scan OCR rapide"
- Uploadez votre document dans la modal
- Copiez le texte ou créez directement un document

### 3. API OCR
```javascript
// Endpoint : POST /ocr/scan
const formData = new FormData();
formData.append('file', file);

fetch('/ocr/scan', {
  method: 'POST',
  headers: {
    'X-CSRF-Token': token
  },
  body: formData
})
.then(response => response.json())
.then(data => {
  console.log('Texte:', data.text);
  console.log('Confiance:', data.confidence);
});
```

## 🔍 Formats supportés

| Format | Extension | OCR | Extraction directe |
|--------|-----------|-----|-------------------|
| PDF    | .pdf      | ✅   | ✅ (texte natif)  |
| JPEG   | .jpg,.jpeg| ✅   | -                 |
| PNG    | .png      | ✅   | -                 |
| GIF    | .gif      | ✅   | -                 |
| WebP   | .webp     | ✅   | -                 |

## 📊 Métriques de qualité

Le service calcule automatiquement :
- **Confiance** : Pourcentage de fiabilité du texte extrait
- **Langue détectée** : FR, NL, EN selon le contenu
- **Temps de traitement** : Performance du processus
- **Méthode utilisée** : tesseract, pdf_reader, ou fallback

## 🛠️ Personnalisation

### Modifier les langues OCR
```ruby
# Dans ocr_service.rb
def initialize(file, language: 'fra+nld+eng')
  @language = language
end
```

### Ajuster la confiance
```ruby
# Dans ocr_service.rb, méthode calculate_confidence
base_confidence = [words.length * 5, 80].min  # Augmente le plafond
```

### Ajouter d'autres formats
```ruby
# Dans ocr_service.rb
ALLOWED_CONTENT_TYPES = [
  'image/jpeg', 'image/png', 'image/tiff',  # + TIFF
  'application/pdf'
].freeze
```

## 🐛 Dépannage

### Erreur "tesseract not found"
```bash
# Vérifier l'installation
which tesseract
echo $PATH

# Réinstaller si nécessaire
sudo apt-get install --reinstall tesseract-ocr
```

### Erreur "language not found"
```bash
# Lister les langues disponibles
tesseract --list-langs

# Installer des langues supplémentaires
sudo apt-get install tesseract-ocr-all
```

### Performance lente
- Réduisez la taille des images avant upload
- Utilisez des PDF avec texte natif quand possible
- Configurez un cache Redis pour les résultats fréquents

## 📈 Améliorations futures

- [ ] **Cache intelligent** : Éviter de retraiter les mêmes documents
- [ ] **OCR en arrière-plan** : Jobs asynchrones pour gros volumes
- [ ] **IA de post-traitement** : Correction automatique des erreurs
- [ ] **Extraction structurée** : Montants, dates, numéros automatiquement
- [ ] **API Webhook** : Notifications temps réel des résultats
- [ ] **Interface admin** : Métriques et monitoring OCR

## 🔒 Sécurité

- Validation stricte des types de fichiers
- Limitation de taille (10MB par défaut)
- Nettoyage automatique des fichiers temporaires
- Logs de toutes les opérations OCR
- Aucun stockage des fichiers sur les serveurs externes

## 📞 Support

En cas de problème :
1. Vérifiez les logs Rails : `tail -f log/development.log`
2. Testez Tesseract directement : `tesseract test.jpg output.txt -l fra`
3. Consultez la documentation Tesseract : https://tesseract-ocr.github.io/
