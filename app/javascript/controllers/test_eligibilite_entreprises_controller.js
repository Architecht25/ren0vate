import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "validateButton"]

  connect() {
    console.log("🏢 Contrôleur Test Eligibilité Entreprises Bruxelles connecté")
    this.responses = {}
  }

  handleAnswer(event) {
    console.log("🎯 Réponse entreprise:", event.target.name, "=", event.target.value)

    this.responses[event.target.name] = event.target.value
    console.log("📊 État actuel des réponses:", this.responses)

    // Vérifications d'inéligibilité immédiate
    this.checkImmediateDisqualification(event.target.name, event.target.value)

    // Vérifier si toutes les questions obligatoires sont répondues
    this.checkIfAllRequiredAnswered()
  }

  checkImmediateDisqualification(questionName, value) {
    let message = null
    let recommendations = []

    switch(questionName) {
      case "localisation":
        if (value === "non") {
          message = "❌ Le siège d'exploitation doit être situé en Région de Bruxelles-Capitale"
          recommendations = [
            "Seules les entreprises avec au moins un siège d'exploitation en RBC sont éligibles",
            "Consultez les conditions pour les entreprises multi-sites"
          ]
        }
        break

      case "taille_entreprise":
        if (value === "grande") {
          message = "❌ Seules les PME (moins de 250 employés) sont éligibles aux aides"
          recommendations = [
            "Les grandes entreprises ne sont pas éligibles aux aides PME",
            "Consultez les dispositifs spécifiques aux grandes entreprises"
          ]
        }
        break

      case "secteur_eligible":
        if (value === "non") {
          message = "❌ Votre secteur d'activité n'est pas éligible aux aides"
          recommendations = [
            "Vérifiez la liste des secteurs soutenus sur economie-emploi.brussels",
            "Consultez les codes NACE éligibles"
          ]
        }
        break

      case "finalite_economique":
        if (value === "non") {
          message = "❌ L'entreprise doit avoir une finalité économique et ne pas être publique"
          recommendations = [
            "Les entreprises publiques ne sont pas éligibles",
            "L'activité doit être à finalité commerciale/économique"
          ]
        }
        break

      case "de_minimis":
        if (value === "oui") {
          message = "❌ Vous avez dépassé le plafond d'aides de minimis de 300.000€ sur 3 ans"
          recommendations = [
            "Le règlement de minimis limite les aides à 300.000€ sur 3 ans",
            "Attendez que la période de 3 ans soit révolue",
            "Consultez d'autres dispositifs non soumis aux règles de minimis"
          ]
        }
        break

      case "numero_bce":
        if (value === "non") {
          message = "❌ Un numéro d'entreprise BCE valide est obligatoire"
          recommendations = [
            "Inscrivez votre entreprise à la Banque Carrefour des Entreprises",
            "Consultez guichet-entreprises.be pour les démarches"
          ]
        }
        break
    }

    if (message) {
      this.showResult(message, false, recommendations)
      this.hideValidateButton()
    } else {
      // Si pas d'inéligibilité immédiate, cacher le résultat précédent
      this.clearResult()
    }
  }

  checkIfAllRequiredAnswered() {
    const requiredQuestions = [
      "localisation",
      "taille_entreprise",
      "secteur_eligible",
      "finalite_economique",
      "de_minimis",
      "numero_bce"
    ]

    const allRequiredAnswered = requiredQuestions.every(question =>
      this.responses[question] !== undefined
    )

    // Vérifier qu'aucune réponse n'a causé une inéligibilité
    const hasDisqualifyingAnswer = (
      this.responses["localisation"] === "non" ||
      this.responses["taille_entreprise"] === "grande" ||
      this.responses["secteur_eligible"] === "non" ||
      this.responses["finalite_economique"] === "non" ||
      this.responses["de_minimis"] === "oui" ||
      this.responses["numero_bce"] === "non"
    )

    if (allRequiredAnswered && !hasDisqualifyingAnswer) {
      this.showValidateButton()
    } else {
      this.hideValidateButton()
    }
  }

  showValidateButton() {
    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block"
      this.validateButtonTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }

  hideValidateButton() {
    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }
  }

  showResult(message, isEligible, recommendations = []) {
    if (!this.hasResultTarget) return

    const alertClass = isEligible ? "alert-success" : "alert-danger"
    const icon = isEligible ? "fas fa-check-circle" : "fas fa-times-circle"

    let html = `
      <div class="alert ${alertClass} border-0 shadow-sm">
        <div class="row align-items-center">
          <div class="col-1 text-center">
            <i class="${icon} fa-2x"></i>
          </div>
          <div class="col-11">
            <div class="alert-content">
              ${message}
              ${recommendations.length > 0 ? `
                <div class="mt-3">
                  <strong>Recommandations :</strong>
                  <ul class="mb-0 mt-2">
                    ${recommendations.map(rec => `<li>${rec}</li>`).join('')}
                  </ul>
                </div>
              ` : ''}
            </div>
          </div>
        </div>
      </div>
    `

    this.resultTarget.innerHTML = html
    this.resultTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }

  clearResult() {
    if (this.hasResultTarget) {
      this.resultTarget.innerHTML = ""
    }
  }
}
