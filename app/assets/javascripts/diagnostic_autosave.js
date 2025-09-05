// Script de diagnostic pour l'auto-save
console.log("🔍 DIAGNOSTIC AUTO-SAVE");
console.log("=".repeat(50));

// 1. Vérifier la variable isRestoringValues
console.log("1️⃣ Variable isRestoringValues:", window.isRestoringValues);

// 2. Vérifier les éléments DOM
const simulationId = document.querySelector('[data-simulation-id]')?.dataset.simulationId ||
                    window.location.pathname.match(/simulations\/(\d+)/)?.[1];
console.log("2️⃣ Simulation ID détecté:", simulationId);

// 3. Vérifier le token CSRF
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content ||
                  document.querySelector('[name="csrf-token"]')?.content;
console.log("3️⃣ CSRF Token:", csrfToken ? "✅ Présent" : "❌ Manquant");

// 4. Vérifier les inputs avec data-slug
const inputsWithSlug = document.querySelectorAll('input[data-slug], select[data-slug]');
console.log("4️⃣ Inputs avec data-slug:", inputsWithSlug.length);

// 5. Vérifier les cartes Wallonie
const wallonnieCards = document.querySelectorAll('[data-controller="wallonie-prime-card"]');
console.log("5️⃣ Cartes Wallonie:", wallonnieCards.length);

// 6. Tester une sauvegarde simulée
function testAutoSave() {
  console.log("\n🧪 TEST AUTO-SAVE SIMULÉ");

  if (window.isRestoringValues) {
    console.log("❌ Bloqué par isRestoringValues =", window.isRestoringValues);
    return;
  }

  if (!simulationId) {
    console.log("❌ Pas de simulation ID");
    return;
  }

  if (!csrfToken) {
    console.log("❌ Pas de CSRF token");
    return;
  }

  const userInputs = { 'test_key': 'test_value' };

  console.log("📤 Envoi requête test...");

  fetch(`/simulations/${simulationId}/update_prime_inputs`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
      'Accept': 'application/json'
    },
    body: JSON.stringify({ user_inputs: userInputs })
  })
  .then(response => {
    console.log("📨 Réponse reçue:", response.status);
    return response.json();
  })
  .then(data => {
    console.log("✅ Données reçues:", data);
  })
  .catch(error => {
    console.error("❌ Erreur:", error);
  });
}

// 7. Analyser les événements d'input
let inputEventCount = 0;
document.addEventListener('input', function(e) {
  inputEventCount++;
  if (inputEventCount <= 5) { // Limiter les logs
    console.log(`📝 Event input #${inputEventCount}:`, e.target.tagName, e.target.type, e.target.value);
  }
});

// 8. Vérifier les fonctions debounced
const debouncedFunctions = [];
window.originalSetTimeout = window.setTimeout;
window.setTimeout = function(func, delay) {
  if (delay === 1000) { // Délai typique des debounced saves
    debouncedFunctions.push({ func: func.toString().substring(0, 100), delay });
  }
  return window.originalSetTimeout(func, delay);
};

console.log("\n💡 Pour tester: testAutoSave()");
console.log("💡 Surveillez les logs ci-dessus lors de vos modifications");

// Exposer la fonction de test
window.testAutoSave = testAutoSave;
