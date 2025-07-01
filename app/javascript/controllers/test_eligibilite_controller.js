import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "formCard"]

  connect() {
    console.log("✅ Contrôleur test-eligibilite connecté")
    if (this.hasResultTarget) {
    this.resultTarget.style.display = "none"
  }
  }

  handleAnswer(event) {
    console.log("🚀 handleAnswer déclenché", event.target.name, event.target.value)

    const form = this.formTarget

    // Récupérer la valeur userType (stockée dans localStorage)
    const userType = localStorage.getItem("userType")

    // Conditions d'inéligibilité immédiates
    if (userType === "entreprise") {
      this.showResult("❌ Les entreprises ne sont pas éligibles.", false)
      return
    }

    const annee = form.querySelector('input[name="annee"]:checked')?.value
    if (annee === "apres") {
      this.showResult("❌ Logement trop récent (après 2006).", false)
      return
    }

    const demolition = form.querySelector('input[name="demolition"]:checked')?.value
    if (demolition === "oui") {
      this.showResult("❌ Les logements reconstruits avec TVA à 6% ne sont pas éligibles.", false)
      return
    }

    const travaux = form.querySelector('input[name="travaux"]:checked')?.value
    if (travaux === "non") {
      this.showResult("❌ Travaux obligatoires non prévus.", false)
      return
    }

    // Vérifie que toutes les questions ont une réponse
    const radioGroups = Array.from(form.querySelectorAll("input[type='radio']"))
    const réponsesParQuestion = radioGroups.reduce((acc, input) => {
      if (!acc[input.name]) acc[input.name] = false
      if (input.checked) acc[input.name] = true
      return acc
    }, {})

    const toutRempli = Object.values(réponsesParQuestion).every(val => val)

    if (!toutRempli) {
      // Tu peux afficher un message ici si tu veux que l'utilisateur complète toutes les questions avant de vérifier
      console.log("⚠️ Toutes les questions ne sont pas encore répondues.")
      return
    }

    // Si tout est bon
    this.showResult("✅ Félicitations ! Vous êtes éligible aux primes.", true)
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
