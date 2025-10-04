# Configuration Geocoder
Geocoder.configure(
  # Délai entre les requêtes API (en secondes)
  timeout: 5,

  # Service de géocodage à utiliser
  lookup: :nominatim,

  # Configuration pour Nominatim (OpenStreetMap)
  nominatim: {
    email: "admin@ren0vate.be" # Email requis pour Nominatim
  },

  # Unités de distance
  units: :km,

  # Cache des résultats
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # Gestion des erreurs
  always_raise: [
    Geocoder::OverQueryLimitError,
    Geocoder::RequestDenied,
    Geocoder::InvalidRequest,
    Geocoder::InvalidApiKey
  ]
)
