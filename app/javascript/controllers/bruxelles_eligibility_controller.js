import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]

  connect() {
    console.log("🎯 Contrôleur eligibilité Bruxelles connecté");
  }

  // Méthode appelée par le bouton "Vérifier l'éligibilité Bruxelles"
  checkEligibility(event) {
    event.preventDefault();

    const button = this.buttonTarget;
    const statusDiv = this.statusTarget;

    // Récupérer l'ID de simulation depuis l'URL ou les données
    const simulationId = this.getSimulationId();

    if (!simulationId) {
      console.error("❌ ID de simulation non trouvé");
      this.showError("Erreur : ID de simulation non trouvé");
      return;
    }

    console.log("🔄 Vérification éligibilité Bruxelles pour simulation:", simulationId);

    // Désactiver le bouton pendant la requête
    button.disabled = true;
    button.innerHTML = '<i class="bi bi-hourglass-split me-2"></i>Vérification en cours...';

    // Appel AJAX vers le service Rails
    fetch(`/simulations/${simulationId}/check_eligibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      console.log("✅ Réponse éligibilité:", data);
      this.handleEligibilityResponse(data);
    })
    .catch(error => {
      console.error("❌ Erreur lors du test d'éligibilité:", error);
      this.showError("Erreur lors de la vérification d'éligibilité");
    })
    .finally(() => {
      // Réactiver le bouton
      button.disabled = false;
      button.innerHTML = '<i class="bi bi-shield-check me-2"></i>Vérifier l\'éligibilité Bruxelles';
    });
  }

  // Gestion de la réponse du service d'éligibilité
  handleEligibilityResponse(data) {
    const statusDiv = this.statusTarget;

    if (data.eligible) {
      // Éligible : afficher succès
      statusDiv.innerHTML = `
        <div class="alert alert-success d-flex align-items-center" role="alert">
          <i class="bi bi-check-circle-fill me-3 fs-4"></i>
          <div>
            <h6 class="alert-heading mb-1">✅ Votre demande est éligible !</h6>
            <p class="mb-0">Vous remplissez les conditions pour bénéficier des primes RENOLUTION de Bruxelles-Capitale.</p>
            <small class="text-muted">Détails : ${data.message}</small>
          </div>
        </div>
      `;

      // Masquer le bouton après succès
      this.buttonTarget.style.display = 'none';

      // Déclencher l'étape suivante si spécifiée
      if (data.next_step) {
        this.triggerNextStep(data.next_step);
      }

    } else {
      // Non éligible : afficher l'erreur
      statusDiv.innerHTML = `
        <div class="alert alert-danger d-flex align-items-center" role="alert">
          <i class="bi bi-x-circle-fill me-3 fs-4"></i>
          <div>
            <h6 class="alert-heading mb-1">❌ Votre demande n'est pas éligible</h6>
            <p class="mb-0">Certaines conditions ne sont pas remplies pour les primes RENOLUTION Bruxelles.</p>
            <small class="text-muted">Raison : ${data.message}</small>
          </div>
        </div>
      `;
    }
  }

  // Affichage d'erreur générique
  showError(message) {
    const statusDiv = this.statusTarget;
    statusDiv.innerHTML = `
      <div class="alert alert-warning d-flex align-items-center" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-3 fs-4"></i>
        <div>
          <h6 class="alert-heading mb-1">⚠️ Erreur technique</h6>
          <p class="mb-0">${message}</p>
          <small class="text-muted">Veuillez réessayer ou contacter le support.</small>
        </div>
      </div>
    `;
  }

  // Déclencher l'étape suivante (ex: calcul de catégorie)
  triggerNextStep(step) {
    console.log("🎯 Déclenchement étape suivante:", step);

    if (step === 'category') {
      // Déclencher le calcul de catégorie automatiquement
      const simulationId = this.getSimulationId();
      this.calculateCategory(simulationId);
    }
  }

  // Calcul automatique de la catégorie après éligibilité
  calculateCategory(simulationId) {
    console.log("🔄 Calcul de catégorie pour simulation:", simulationId);

    fetch(`/simulations/${simulationId}/calculate_category`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      console.log("✅ Catégorie calculée:", data);
      // Actualiser la page ou déclencher l'étape suivante
      if (data.success) {
        location.reload(); // Simple rechargement pour voir les résultats
      }
    })
    .catch(error => {
      console.error("❌ Erreur calcul catégorie:", error);
    });
  }

  // Récupérer l'ID de simulation depuis l'URL ou les data attributes
  getSimulationId() {
    // Méthode 1: depuis l'URL
    const pathParts = window.location.pathname.split('/');
    const simulationIndex = pathParts.indexOf('simulations');
    if (simulationIndex !== -1 && pathParts[simulationIndex + 1]) {
      return pathParts[simulationIndex + 1];
    }

    // Méthode 2: depuis un data attribute
    const dataId = this.element.dataset.simulationId;
    if (dataId) {
      return dataId;
    }

    // Méthode 3: depuis un élément de la page
    const simulationElement = document.querySelector('[data-simulation-id]');
    if (simulationElement) {
      return simulationElement.dataset.simulationId;
    }

    return null;
  }

  // Récupérer le token CSRF
  getCSRFToken() {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.getAttribute('content') : null;
  }
}
