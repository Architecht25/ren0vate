import { Controller } from "@hotwired/stimulus"

// ROI Calculator — calculs en temps réel côté client
export default class extends Controller {
  static targets = [
    "coutTravaux", "primesObtenues", "gainMensuelEnergie",
    "valeurBien", "horizonAns", "tauxValorisation",
    "coutNet", "economiesEnergie", "valorisationBien",
    "gainTotal", "roi", "delaiRemboursement", "resultsSection"
  ]

  connect() {
    this.calculate()
  }

  calculate() {
    const cout       = parseFloat(this.coutTravauxTarget.value) || 0
    const primes     = parseFloat(this.primesObtenuesTarget.value) || 0
    const gainMois   = parseFloat(this.gainMensuelEnergieTarget.value) || 0
    const valeurBien = parseFloat(this.valeurBienTarget.value) || 0
    const horizon    = parseInt(this.horizonAnsTarget.value) || 20
    const tauxValo   = parseFloat(this.tauxValorisationTarget.value) / 100 || 0.05

    // Calculs
    const coutNet          = Math.max(cout - primes, 0)
    const economiesEnergie = gainMois * 12 * horizon
    const plusValueBien    = valeurBien * tauxValo
    const gainTotal        = primes + economiesEnergie + plusValueBien
    const roiPct           = coutNet > 0 ? ((gainTotal - coutNet) / coutNet * 100) : 0

    // Délai de remboursement (en années)
    const gainAnnuel = (gainMois * 12) + (plusValueBien / horizon)
    const delaiMois  = gainAnnuel > 0 ? Math.ceil((coutNet / gainAnnuel) * 12) : null

    // Affichage
    this.coutNetTarget.textContent         = this.format(coutNet)
    this.economiesEnergieTarget.textContent = this.format(economiesEnergie)
    this.valorisationBienTarget.textContent = this.format(plusValueBien)
    this.gainTotalTarget.textContent       = this.format(gainTotal)
    this.roiTarget.textContent             = roiPct.toFixed(0) + "%"

    if (delaiMois !== null && delaiMois <= horizon * 12) {
      const annees = Math.floor(delaiMois / 12)
      const mois   = delaiMois % 12
      this.delaiRemboursementTarget.textContent =
        annees > 0 ? `${annees} an${annees > 1 ? "s" : ""} ${mois > 0 ? mois + " mois" : ""}` : `${mois} mois`
    } else {
      this.delaiRemboursementTarget.textContent = "> horizon"
    }

    // Couleur ROI
    const roiEl = this.roiTarget
    roiEl.classList.remove("text-danger", "text-warning", "text-success")
    if (roiPct < 0)       roiEl.classList.add("text-danger")
    else if (roiPct < 50) roiEl.classList.add("text-warning")
    else                  roiEl.classList.add("text-success")

    this.resultsSectionTarget.classList.remove("d-none")
  }

  format(val) {
    return new Intl.NumberFormat("fr-BE", { style: "currency", currency: "EUR", maximumFractionDigits: 0 }).format(val)
  }
}
