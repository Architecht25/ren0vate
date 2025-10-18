# Configuration spécifique au bot contextuel avec optimisations de performance
# Ces paramètres sont utilisés par ContextualBotService pour optimiser les performances

# Timeout pour les requêtes OpenAI (en secondes) - réduit pour performances
CONTEXTUAL_BOT_TIMEOUT = 8

# Mode de fonctionnement par défaut
CONTEXTUAL_BOT_DEFAULT_MODE = 'guide'

# Nombre maximum de suggestions par page
CONTEXTUAL_BOT_MAX_SUGGESTIONS = 4

# Configuration du cache pour performances optimales
CONTEXTUAL_BOT_CACHE_ENABLED = true
CONTEXTUAL_BOT_CACHE_DURATION = 1.hour
CONTEXTUAL_BOT_SUGGESTIONS_CACHE_DURATION = 30.minutes
CONTEXTUAL_BOT_INSTANT_RESPONSES_ENABLED = true

# Préchargement des réponses communes
CONTEXTUAL_BOT_PRELOAD_COMMON_RESPONSES = true

# Limite de taille des réponses pour éviter les timeouts
CONTEXTUAL_BOT_MAX_RESPONSE_LENGTH = 800
