// Vider le cache Turbo à chaque chargement de page pour éviter la fuite de données cross-user.
// Sans cela, Turbo peut servir le snapshot d'un autre utilisateur connecté précédemment.
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
