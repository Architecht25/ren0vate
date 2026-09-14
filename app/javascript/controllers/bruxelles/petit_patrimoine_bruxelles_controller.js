// Contrôleur pour le calcul des primes Petit Patrimoine Bruxelles
// Gère les taux (50% ou 75%), plafonds (10k ou 15k€) et majorations

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Exposer les données courantes pour la sauvegarde (cf. debounceSaveTotal
    // dans _prime_calculation_script.html.erb, même mécanisme que pour Communes).
    // Ne renvoie rien si la carte est encore vierge, pour ne pas persister un
    // objet vide à chaque autosave global déclenché par une autre carte.
    window.getBruxellesPetitPatrimoineData = () => {
      const data = this.collectData()
      const hasContent = data.element_type || data.statut_demandeur || data.montant_travaux
      return hasContent ? data : undefined
    }

    this.restoreSavedData()
  }

  // Récupère les saisies persistées (parameters['bruxelles_petit_patrimoine'], sauvegardées
  // via PATCH save_total) et repeuple les champs au chargement de la page.
  restoreSavedData() {
    const savedEl = document.getElementById("brx-saved-patrimoine")
    if (!savedEl) return

    let saved = {}
    try {
      saved = JSON.parse(savedEl.dataset.patrimoine || "{}")
    } catch (e) {
      saved = {}
    }
    if (!saved || Object.keys(saved).length === 0) return

    if (saved.element_type) {
      const select = document.getElementById("element_type_patrimoine")
      if (select) select.value = saved.element_type
    }

    if (saved.statut_demandeur) {
      const radio = document.querySelector(`input[name="statut_demandeur"][value="${saved.statut_demandeur}"]`)
      if (radio) radio.checked = true
    }

    if (saved.revenus) {
      const radio = document.querySelector(`input[name="revenus"][value="${saved.revenus}"]`)
      if (radio) radio.checked = true
    }

    if (saved.zone_revitalisation) {
      const checkbox = document.getElementById("zone_revitalisation")
      if (checkbox) checkbox.checked = true
    }

    if (saved.montant_travaux) {
      const input = document.getElementById("montant_travaux_patrimoine")
      if (input) input.value = saved.montant_travaux
    }

    // Réafficher les sections dépendantes du statut restauré
    if (saved.statut_demandeur === "prive") {
      const revenuSection = document.getElementById("revenus_section")
      const revitalisationSection = document.getElementById("revitalisation_section")
      if (revenuSection) revenuSection.style.display = "block"
      if (revitalisationSection) revitalisationSection.style.display = "block"
    }

    this.showMontantSection()
    this.calculatePrime()
  }

  // Valeurs courantes des champs de la carte, envoyées à save_total pour persistance
  collectData() {
    return {
      element_type: document.getElementById("element_type_patrimoine")?.value || "",
      statut_demandeur: document.querySelector('input[name="statut_demandeur"]:checked')?.value || "",
      revenus: document.querySelector('input[name="revenus"]:checked')?.value || "",
      zone_revitalisation: !!document.getElementById("zone_revitalisation")?.checked,
      montant_travaux: document.getElementById("montant_travaux_patrimoine")?.value || ""
    }
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
