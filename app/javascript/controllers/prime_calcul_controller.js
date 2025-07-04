// === 2. app/javascript/controllers/prime_simulation_controller.js ===
import { Controller } from "@hotwired/stimulus"
import { getCategorieId } from "logic/categorie_utilitaire_logic"
import { calculerTotalToutesCartes } from "logic/prime_total_logic"

export default class extends Controller {
  static targets = ["result"]

  async calculer(event) {
    const input = event.target
    const slug = input.dataset.primeSimulationSlug
    const valeur = parseFloat(input.value) || 0
    const categorie = getCategorieId()

    try {
      const response = await fetch(`/api/primes/${slug}`)
      if (!response.ok) throw new Error("Erreur lors du chargement de la prime")
      const prime = await response.json()

      const montant = this.calculerMontant(prime, valeur, categorie)
      input.closest(".input-group").querySelector(".prime-result").textContent = `${montant.toLocaleString()} €`

      // 🔁 Met à jour le total global après chaque changement
      calculerTotalToutesCartes()
    } catch (error) {
      console.error(error)
      input.closest(".input-group").querySelector(".prime-result").textContent = `0 €`
      calculerTotalToutesCartes()
    }
  }

  calculerMontant(prime, valeur, categorie) {
    if (!prime || !prime.valeursParCategorie || !prime.valeursParCategorie[categorie]) return 0

    const config = prime.valeursParCategorie[categorie]
    if (config.type === "fixe") return config.montant
    if (config.type === "metre_carre") return Math.round(config.montant * valeur)
    if (config.type === "pourcentage_et_plafond") {
      const montant = (config.pourcentage / 100) * prime.coutIndicatif * valeur
      return Math.min(montant, config.plafond)
    }
    return 0
  }
}
