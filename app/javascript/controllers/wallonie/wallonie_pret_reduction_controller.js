import { Controller } from "@hotwired/stimulus"

// Nouveau régime wallon (dès le 01/10/2026) — un seul champ (montant global du projet),
// pas de saisie poste par poste. Voir Regions::Wallonie::PretReduction côté backend.
export default class extends Controller {
  static targets = ["montantProjet", "reductionSolde", "montantRetenu", "tauxReduction", "ecomateriaux", "tauxInteret"]
  static values = { simulationId: Number }

  montantChanged() {
    clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => this.save(), 600)
  }

  save() {
    const montantProjet = this.montantProjetTarget.value || 0
    const ecomateriaux = this.hasEcomateriauxTarget ? this.ecomateriauxTarget.checked : false

    fetch(`/fr/simulations/${this.simulationIdValue}/update_prime_inputs`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ montant_projet: montantProjet, ecomateriaux: ecomateriaux })
    })
      .then(response => response.json())
      .then(data => {
        if (!data.success) return

        this.reductionSoldeTarget.textContent = this.formatCurrency(data.total_amount)
        this.montantRetenuTarget.textContent = this.formatCurrency(data.montant_projet_retenu)
        this.tauxReductionTarget.textContent = `${Math.round((data.taux_reduction || 0) * 100)}%`
        if (this.hasTauxInteretTarget && data.taux_interet_label) {
          this.tauxInteretTarget.textContent = data.taux_interet_label
        }
      })
      .catch(error => {
        console.error("Erreur mise à jour réduction prêt wallon:", error)
      })
  }

  formatCurrency(value) {
    const amount = parseFloat(value || 0)
    return `${amount.toLocaleString("fr-BE", { maximumFractionDigits: 0 })} €`
  }
}
