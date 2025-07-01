import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result"]

  connect() {
    this.resultTarget.style.display = "none"
  }

  handleAnswer() {
    const form = this.formTarget

    // Conditions d'inéligibilité immédiates
    const userType = localStorage.getItem("userType")
    if (userType === "entreprise") {
      this.showResult("❌ Les entreprises ne sont pas éligibles.", false)
      return
    }

    const annee = form.annee?.value
    if (annee === "apres") {
      this.showResult("❌ Logement trop récent (après 2006).", false)
      return
    }

    const demolition = form.demolition?.value
    if (demolition === "oui") {
      this.showResult("❌ Les logements reconstruits avec TVA à 6% ne sont pas éligibles.", false)
      return
    }

    const travaux = form.travaux?.value
    if (travaux === "non") {
      this.showResult("❌ Travaux obligatoires non prévus.", false)
      return
    }

    // Vérifie si toutes les questions ont une réponse
    const radioGroups = Array.from(form.querySelectorAll("input[type='radio']"))
    const réponsesParQuestion = radioGroups.reduce((acc, input) => {
      if (!acc[input.name]) acc[input.name] = false
      if (input.checked) acc[input.name] = true
      return acc
    }, {})

    const toutRempli = Object.values(réponsesParQuestion).every(val => val)

    if (toutRempli) {
      this.showResult("✅ Félicitations ! Vous êtes éligible aux primes.")
    }
  }

  showResult(message, isEligible = true) {
    this.formTarget.style.display = "none"
    this.resultTarget.innerHTML = `
      <p>${message}</p>
      <div class="btn-group mt-3">
        <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        ${isEligible ? `<a href="/simulation" class="btn btn-primary">🎯 Accéder au simulateur</a>` : ""}
      </div>
    `
    this.resultTarget.style.display = "block"
  }
}
