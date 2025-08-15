# Guide d'utilisation I18n - Ren0vate

## 🎯 Système de traduction pour la Belgique

Cette application supporte **3 langues** adaptées au contexte belge :
- 🇫🇷 **Français** (`fr`) - Langue par défaut
- 🇧🇪 **Néerlandais/Flamand** (`nl`) - Pour la Flandre
- 🇬🇧 **Anglais** (`en`) - Langue internationale

## 🚀 Comment utiliser les traductions

### Dans les vues (.erb)
```erb
<%= t('navigation.home') %>
<%= t('notices.property_created') %>
<%= t('errors.property_update_failed', errors: @errors) %>
```

### Dans les controllers
```ruby
redirect_to @property, notice: t('notices.property_updated')
flash.now[:alert] = t('common.please_correct_errors')
```

### Dans les modèles
```ruby
validates :name, presence: { message: I18n.t('errors.name_required') }
```

## 🔧 URLs multilingues

Le système génère automatiquement des URLs avec la locale :
- `/fr/properties` - Version française
- `/nl/properties` - Version néerlandaise
- `/en/properties` - Version anglaise

## 🌍 Détection automatique de langue

Le système détecte automatiquement la langue selon :

1. **Paramètre URL** : `?locale=nl`
2. **Session utilisateur** : Choix précédent sauvegardé
3. **Préférence utilisateur** : Si connecté et préférence définie
4. **Région des propriétés** : Flandre → `nl`, Wallonie → `fr`
5. **Navigateur** : En-têtes HTTP Accept-Language
6. **Défaut** : Français (`fr`)

## 📝 Ajouter de nouvelles traductions

### 1. Modifier les fichiers de locale
```yaml
# config/locales/fr.yml
fr:
  ma_nouvelle_section:
    titre: "Mon titre"
    description: "Ma description"

# config/locales/nl.yml
nl:
  ma_nouvelle_section:
    titre: "Mijn titel"
    description: "Mijn beschrijving"
```

### 2. Utiliser dans les vues
```erb
<h1><%= t('ma_nouvelle_section.titre') %></h1>
<p><%= t('ma_nouvelle_section.description') %></p>
```

## 🎨 Composants disponibles

### Sélecteur de langue
```erb
<%= render 'shared/language_selector' %>
```

### Helpers utiles
```erb
<%= current_locale_name %> <!-- "Français" -->
<%= current_locale_flag %> <!-- "🇫🇷" -->
<%= format_currency(1500) %> <!-- "1 500 €" -->
<%= localize_date(Date.current) %> <!-- "15/08/2025" -->
```

## 🧪 Test de l'installation

Visitez `/fr/i18n-test` pour tester toutes les fonctionnalités.

## 🔄 Rechargement des traductions

En développement, les traductions se rechargent automatiquement.
En production, redémarrer le serveur après modification des fichiers `.yml`.

## 📱 JavaScript et Stimulus

Le controller `language` gère :
- Détection automatique de la langue du navigateur
- Suggestions de changement de langue
- Sauvegarde des préférences utilisateur

## 🗂️ Structure des fichiers

```
config/locales/
├── fr.yml          # Traductions françaises
├── nl.yml          # Traductions néerlandaises
├── en.yml          # Traductions anglaises
├── devise.en.yml   # Devise en anglais
└── simple_form.en.yml # SimpleForm en anglais
```

## 🎯 Adaptation régionale intelligente

Le système s'adapte automatiquement selon la région :
- **Propriété en Flandre** → Interface en néerlandais
- **Propriété en Wallonie** → Interface en français
- **Bruxelles** → Choix utilisateur ou français par défaut

## 🛠️ Administration

### Ajouter une langue
1. Ajouter la locale dans `config/initializers/i18n.rb`
2. Créer le fichier de traduction correspondant
3. Mettre à jour les helpers et le sélecteur de langue

### Debug
En développement, activez les logs I18n dans `application.rb` :
```ruby
config.i18n.raise_on_missing_translations = true
```

## 📊 Performance

- ✅ Traductions mises en cache automatiquement
- ✅ Détection de langue optimisée
- ✅ Fallbacks configurés pour éviter les erreurs
- ✅ Assets précompilés pour la production
