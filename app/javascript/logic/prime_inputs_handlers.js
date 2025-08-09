// Gestionnaire universel pour les inputs de primes (Flandre et Wallonie)
// Ce fichier gère la fonctionnalité "Enter" et les événements de saisie pour tous les inputs de primes

document.addEventListener('DOMContentLoaded', function() {
  console.log('🚀 Prime inputs handlers chargé');

  // Gestionnaire universel pour tous les containers de primes
  const primeContainers = [
    document.getElementById('prime-cards-container'), // Flandre
    document.getElementById('primes-container'),      // Wallonie générique
    document.querySelector('.primes-wallonie'),      // Wallonie spécifique
    document.querySelector('[data-region="wallonie"]'), // Wallonie par attribut
    document.querySelector('[data-region="flandre"]')   // Flandre par attribut
  ].filter(container => container !== null);

  primeContainers.forEach(container => {
    setupPrimeInputHandlers(container);
  });

  // Si aucun container spécifique trouvé, appliquer à tout le document
  if (primeContainers.length === 0) {
    setupPrimeInputHandlers(document);
    console.log('📝 Gestionnaires appliqués au document entier');
  }
});

function setupPrimeInputHandlers(container) {
  console.log('🔧 Configuration des gestionnaires pour:', container);

  // Gestionnaire pour la touche Enter sur tous les inputs de primes
  container.addEventListener('keydown', function(event) {
    if (event.key === 'Enter' && event.target.classList.contains('prime-input')) {
      console.log('⌨️ Enter pressé sur:', event.target.dataset.primeSlug || event.target.name);
      event.preventDefault(); // Empêche la soumission du formulaire

      // Déclenche un événement change pour forcer la mise à jour
      const changeEvent = new Event('change', { bubbles: true });
      event.target.dispatchEvent(changeEvent);

      // Trouve le prochain input et lui donne le focus
      const inputs = Array.from(container.querySelectorAll('.prime-input'));
      const currentIndex = inputs.indexOf(event.target);

      if (currentIndex < inputs.length - 1) {
        const nextInput = inputs[currentIndex + 1];
        setTimeout(() => {
          nextInput.focus();
          // Sélectionne tout le texte si c'est un input de type number/text
          if (nextInput.type === 'number' || nextInput.type === 'text') {
            nextInput.select();
          }
        }, 100);
      } else {
        // Si c'est le dernier input, retire le focus
        event.target.blur();
        console.log('✅ Dernier input atteint, focus retiré');
      }
    }
  });

  // Gestionnaire pour améliorer l'expérience de saisie
  container.addEventListener('focus', function(event) {
    if (event.target.classList.contains('prime-input') &&
        (event.target.type === 'number' || event.target.type === 'text')) {
      // Sélectionne tout le texte lors du focus
      setTimeout(() => event.target.select(), 50);
    }
  }, true);

  // Gestionnaire pour les changements d'inputs
  container.addEventListener('change', function(event) {
    if (event.target.classList.contains('prime-input')) {
      console.log('🔄 Changement détecté sur:', event.target.dataset.primeSlug || event.target.name);

      // Ajoute une classe pour indiquer que l'input a été modifié
      event.target.classList.add('modified');

      // Retire la classe après un délai pour l'effet visuel
      setTimeout(() => {
        event.target.classList.remove('modified');
      }, 1000);
    }
  });

  console.log('✅ Gestionnaires configurés pour le container');
}

// Style CSS pour l'effet visuel lors de la modification
const style = document.createElement('style');
style.textContent = `
  .prime-input.modified {
    background-color: #e8f5e8 !important;
    border-color: #28a745 !important;
    transition: all 0.3s ease;
  }

  .prime-input:focus {
    border-color: #007bff !important;
    box-shadow: 0 0 0 0.2rem rgba(0,123,255,.25) !important;
  }
`;
document.head.appendChild(style);
