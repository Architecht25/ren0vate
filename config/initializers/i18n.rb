# Configuration I18n pour la Belgique
# Support du français, néerlandais (flamand) et anglais

# Langues disponibles
I18n.available_locales = [:fr, :nl, :en]

# Langue par défaut (français)
I18n.default_locale = :fr

# Configuration des fallbacks
I18n.fallbacks = {
  fr: [:fr, :en],          # Français -> Anglais si pas de traduction
  nl: [:nl, :fr, :en],     # Néerlandais -> Français -> Anglais
  en: [:en, :fr]           # Anglais -> Français
}

# Configuration pour la détection automatique de la langue
Rails.application.configure do
  # Permettre la détection automatique via l'URL ou les préférences
  config.i18n.fallbacks = I18n.fallbacks

  # Lever une exception en développement si une traduction manque
  config.i18n.raise_on_missing_translations = true if Rails.env.development?
end
