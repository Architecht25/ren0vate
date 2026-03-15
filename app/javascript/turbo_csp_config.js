// Vider le cache Turbo AVANT chaque navigation pour éviter la fuite de données cross-user.
// turbo:before-visit s'exécute avant que Turbo affiche un snapshot, contrairement à
// turbo:load qui s'exécute après (trop tard, le snapshot serait déjà visible).
document.addEventListener('turbo:before-visit', function() {
  if (window.Turbo) {
    Turbo.cache.clear()
  }
})

// Vider aussi au premier chargement de page (supprime les snapshots résiduels en mémoire)
document.addEventListener('turbo:load', function() {
  if (window.Turbo) {
    Turbo.cache.clear()
  }
})

// Configurer Turbo pour respecter les nonces CSP
document.addEventListener('DOMContentLoaded', function() {
  // Patch Turbo pour utiliser les nonces CSP
  if (window.Turbo && Turbo.config) {
    // Configuration pour que Turbo respecte les nonces
    const originalExecuteScript = Turbo.StreamActions.append_script || function() {};

    // Override pour ajouter automatiquement les nonces aux scripts Turbo
    if (Turbo.StreamActions) {
      const nonce = document.querySelector('meta[name="csp-nonce"]')?.content;

      if (nonce) {
        // Intercepter les scripts créés par Turbo
        const originalCreateElement = document.createElement;
        document.createElement = function(tagName) {
          const element = originalCreateElement.call(this, tagName);
          if (tagName.toLowerCase() === 'script') {
            element.setAttribute('nonce', nonce);
          }
          return element;
        };
      }
    }
  }
});
