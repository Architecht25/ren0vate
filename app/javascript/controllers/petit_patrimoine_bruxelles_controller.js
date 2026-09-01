// Contrôleur pour le calcul des primes Petit Patrimoine Bruxelles
// Gère les taux (50% ou 75%), plafonds (10k ou 15k€) et majorations

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  updateElement() {
    this.showMontantSection()
    this.calculatePrime()
  }

  updateStatut() {
    const statutPrive = document.getElementById("statut_prive").checked
    const revenuSection = document.getElementById("revenus_section")
    const revitalisationSection = document.getElementById("revitalisation_section")

    if (statutPrive) {
      revenuSection.style.display = "block"
      revitalisationSection.style.display = "block"
    } else {
      revenuSection.style.display = "none"
      revitalisationSection.style.display = "none"
      // Reset des valeurs
      document.querySelectorAll('input[name="revenus"]').forEach(input => input.checked = false)
      document.getElementById("zone_revitalisation").checked = false
    }

    this.showMontantSection()
    this.calculatePrime()
  }

  updateRevenus() {
    this.calculatePrime()
  }

  updateZone() {
    this.calculatePrime()
  }

  showMontantSection() {
    const elementSelectionne = document.getElementById("element_type_patrimoine").value
    const statutSelectionne = document.querySelector('input[name="statut_demandeur"]:checked')

    if (elementSelectionne && statutSelectionne) {
      document.getElementById("montant_section_patrimoine").style.display = "block"
      document.getElementById("info_calcul").style.display = "block"
    }
  }

  calculatePrime() {
    const montant = parseFloat(document.getElementById("montant_travaux_patrimoine").value) || 0
    const elementSelectionne = document.getElementById("element_type_patrimoine").value
    const statutSelectionne = document.querySelector('input[name="statut_demandeur"]:checked')?.value

    if (!montant || !elementSelectionne || !statutSelectionne) {
      this.hideResult()
      return
    }

    // Calcul du taux et plafond selon le statut
    let taux, plafond

    if (statutSelectionne === "public") {
      // Demandeurs publics : 75% plafonné à 15 000€
      taux = 0.75
      plafond = 15000
    } else {
      // Demandeurs privés : 50% plafonné à 10 000€ par défaut
      taux = 0.50
      plafond = 10000

      // Vérification des conditions de majoration
      const revenusBas = document.getElementById("revenus_bas")?.checked
      const zoneRevitalisation = document.getElementById("zone_revitalisation")?.checked

      if (revenusBas || zoneRevitalisation) {
        // Majoration de 25% : taux passe à 75%, plafond à 15 000€
        taux = 0.75
        plafond = 15000
      }
    }

    // Calcul de la prime
    const primeCalculee = montant * taux
    const primePlafonee = Math.min(primeCalculee, plafond)

    // Affichage des informations
    this.updateCalculInfo(taux, plafond)
    this.showResult(primePlafonee, montant, taux, plafond)
  }

  updateCalculInfo(taux, plafond) {
    document.getElementById("taux_affiche").textContent = `${Math.round(taux * 100)}%`
    document.getElementById("plafond_affiche").textContent = `${plafond.toLocaleString('fr-BE')}€`
  }

  showResult(prime, montant, taux, plafond) {
    const resultSection = document.getElementById("result_section_patrimoine")
    const resultElement = document.getElementById("result_patrimoine")
    const detailsElement = document.getElementById("details_patrimoine")

    resultElement.textContent = `${prime.toLocaleString('fr-BE', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })} €`

    // Détails du calcul
    let details = `${montant.toLocaleString('fr-BE')}€ × ${Math.round(taux * 100)}%`
    if (prime < montant * taux) {
      details += ` (plafonné à ${plafond.toLocaleString('fr-BE')}€)`
    }
    detailsElement.textContent = details

    resultSection.style.display = "block"
    this.notifyGlobalTotal()
  }

  hideResult() {
    document.getElementById("result_section_patrimoine").style.display = "none"
    // Remettre le montant à 0 pour que le total général (qui additionne tous les
    // spans .prime-result, y compris masqués) ne compte pas une valeur périmée.
    document.getElementById("result_patrimoine").textContent = "0.00 €"
    this.notifyGlobalTotal()
  }

  // Déclenche le recalcul + la sauvegarde du total général de la simulation Bruxelles
  notifyGlobalTotal() {
    if (typeof window.updateTotalImmediate === "function") window.updateTotalImmediate()
  }
}
