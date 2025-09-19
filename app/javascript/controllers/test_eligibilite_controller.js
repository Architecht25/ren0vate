import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "formCard", "validateButton"]

  connect() {
    console.log("🎯 Contrôleur test-eligibilite (routeur principal) connecté");
    if (this.hasResultTarget) {
      this.resultTarget.style.display = "none"
    }
    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }
  }

  // ========== ROUTEUR VERS LES CONTRÔLEURS RÉGIONAUX ==========
  //
  // Ce contrôleur sert maintenant de routeur principal.
  // La logique spécifique à chaque région a été extraite dans :
  //
  // 🟠 test_eligibilite_flandre_controller.js (méthodes Flandre)
  // 🟡 test_eligibilite_wallonie_controller.js (méthodes Wallonie - 5 profils)
  // 🟢 test_eligibilite_bruxelles_controller.js (méthodes Bruxelles - tous profils)
  //
  // Les templates utilisent maintenant directement les contrôleurs régionaux
  // via leurs data-controller spécifiques.

  // Méthode de routage générale pour usage futur si nécessaire
  routeToRegionalController(region, method, ...args) {
    console.log(`🎯 Routage vers ${region} pour la méthode ${method}`);
    // Cette méthode peut être étendue pour un routage dynamique si nécessaire
    // Pour l'instant, les contrôleurs régionaux sont utilisés directement
  }

  // Méthodes de compatibilité pour les templates existants
  // Peuvent être supprimées une fois la migration complètement terminée
  showResult(message, isEligible = true) {
    console.warn("⚠️ showResult appelée sur le routeur principal");
    console.warn("💡 Utilisez plutôt un contrôleur régional spécifique :");
    console.warn("   - test-eligibilite-flandre");
    console.warn("   - test-eligibilite-wallonie");
    console.warn("   - test-eligibilite-bruxelles");
  }

  // Méthode utilitaire pour débug
  logAvailableControllers() {
    console.log("📋 Contrôleurs d'éligibilité disponibles :");
    console.log("🟠 Flandre: test-eligibilite-flandre");
    console.log("🟡 Wallonie: test-eligibilite-wallonie");
    console.log("🟢 Bruxelles: test-eligibilite-bruxelles");
  }
}
