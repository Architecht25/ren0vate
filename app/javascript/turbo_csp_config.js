// Vider le cache Turbo AVANT chaque navigation pour éviter la fuite de données cross-user.
// turbo:before-visit s'exécute avant que Turbo affiche un snapshot.
function clearTurboCache() {
  try {
    if (typeof Turbo !== 'undefined') {
      if (Turbo.cache && typeof Turbo.cache.clear === 'function') {
        Turbo.cache.clear()
      } else if (typeof Turbo.clearCache === 'function') {
        Turbo.clearCache()
      }
    }
  } catch(e) {
    // Silently ignore if Turbo cache API unavailable
  }
}

document.addEventListener('turbo:before-visit', clearTurboCache)
document.addEventListener('turbo:load', clearTurboCache)

// Configurer Turbo pour respecter les nonces CSP
// Turbo lit automatiquement le nonce depuis <meta name="csp-nonce"> — aucun patch nécessaire.
document.addEventListener('DOMContentLoaded', function() {
  // Configuration minimale : s'assurer que Turbo est disponible
  if (window.Turbo && Turbo.config) {
    // Turbo 2.x lit le nonce CSP automatiquement via la meta tag
  }
});
