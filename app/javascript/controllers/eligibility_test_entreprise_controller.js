import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "questions", "result", "actions"]
  static values = {
    answers: { type: Object, default: {} },
    isEligible: { type: Boolean, default: false }
  }

  connect() {
    console.log("Eligibility test entreprise controller connected")
    this.initializeForm()
  }

  initializeForm() {
    console.log("Initializing eligibility form")
    // Réinitialiser les réponses
    this.answersValue = {}
    this.isEligibleValue = false
    this.hideResult()
    this.hideActions()

    // Vérifier que tous les targets sont présents
    console.log("Result target found:", this.hasResultTarget)
    console.log("Actions target found:", this.hasActionsTarget)
  }

  updateEligibility(event) {
    const questionName = event.target.name
    const questionValue = event.target.value === 'true'

    console.log(`Question ${questionName}: ${questionValue}`)

    // Mettre à jour les réponses
    this.answersValue = {
      ...this.answersValue,
      [questionName]: questionValue
    }

    // Si une réponse est "non", afficher immédiatement l'inéligibilité
    if (questionValue === false) {
      this.isEligibleValue = false
      this.showResult()
      this.showActions()
      return
    }

    // Vérifier si toutes les questions obligatoires sont répondues
    const requiredQuestions = [
      'location_bruxelles',
      'is_pme',
      'eligible_sector',
      'economic_purpose',
      'regulatory_compliance'
    ]

    const allQuestionsAnswered = requiredQuestions.every(q =>
      this.answersValue.hasOwnProperty(q)
    )

    if (allQuestionsAnswered) {
      // Vérifier l'éligibilité (toutes les réponses doivent être "oui")
      this.isEligibleValue = requiredQuestions.every(q =>
        this.answersValue[q] === true
      )

      this.showResult()
      this.showActions()

      console.log(`Eligibility result: ${this.isEligibleValue}`)
      console.log("All answers:", this.answersValue)
    } else {
      // Ne masquer le résultat que si aucune réponse n'est "non"
      const hasNegativeAnswer = Object.values(this.answersValue).includes(false)
      if (!hasNegativeAnswer) {
        this.hideResult()
        this.hideActions()
      }
    }
  }

  showResult() {
    console.log("Showing result, eligible:", this.isEligibleValue)

    if (!this.hasResultTarget) {
      console.error("Result target not found!")
      return
    }

    this.resultTarget.style.display = 'block'

    if (this.isEligibleValue) {
      console.log("Creating eligible result")
      this.resultTarget.innerHTML = this.createEligibleResult()
      // Activer le bouton "Continuer"
      const proceedBtn = document.getElementById('proceed-btn')
      if (proceedBtn) {
        proceedBtn.disabled = false
        proceedBtn.classList.remove('btn-secondary')
        proceedBtn.classList.add('btn-success')
      }
    } else {
      console.log("Creating ineligible result")
      this.resultTarget.innerHTML = this.createIneligibleResult()
      // Désactiver le bouton "Continuer"
      const proceedBtn = document.getElementById('proceed-btn')
      if (proceedBtn) {
        proceedBtn.disabled = true
        proceedBtn.classList.remove('btn-success')
        proceedBtn.classList.add('btn-secondary')
      }
    }
  }

  hideResult() {
    this.resultTarget.style.display = 'none'
  }

  showActions() {
    this.actionsTarget.style.display = 'block'
  }

  hideActions() {
    this.actionsTarget.style.display = 'none'
  }

  createEligibleResult() {
    return `
      <div class="alert alert-success border-0 shadow-sm" role="alert">
        <div class="d-flex align-items-center">
          <i class="bi bi-check-circle-fill text-success fs-2 me-3"></i>
          <div class="flex-grow-1">
            <h6 class="alert-heading mb-2 text-success">
              ✅ Félicitations ! Votre entreprise est éligible
            </h6>
            <p class="mb-2">
              Votre entreprise répond à tous les critères d'éligibilité pour bénéficier des aides aux entreprises de la Région de Bruxelles-Capitale.
            </p>
            <div class="row small text-muted">
              <div class="col-md-6">
                <i class="bi bi-geo-alt-fill text-primary me-1"></i>
                <strong>Localisation :</strong> Bruxelles-Capitale ✓
              </div>
              <div class="col-md-6">
                <i class="bi bi-building text-primary me-1"></i>
                <strong>Taille :</strong> PME (< 250 employés) ✓
              </div>
            </div>
            <div class="row small text-muted mt-1">
              <div class="col-md-6">
                <i class="bi bi-briefcase text-primary me-1"></i>
                <strong>Secteur :</strong> Activité éligible ✓
              </div>
              <div class="col-md-6">
                <i class="bi bi-currency-euro text-primary me-1"></i>
                <strong>Finalité :</strong> Économique ✓
              </div>
            </div>
            <div class="row small text-muted mt-1">
              <div class="col-md-12">
                <i class="bi bi-shield-check text-primary me-1"></i>
                <strong>Conformité :</strong> Obligations légales respectées ✓
              </div>
            </div>
          </div>
        </div>
        <hr class="my-3">
        <div class="d-flex justify-content-between align-items-center">
          <small class="text-muted">
            <i class="bi bi-info-circle me-1"></i>
            Vous pouvez maintenant continuer vers la simulation des aides
          </small>
          <span class="badge bg-success fs-6">ÉLIGIBLE</span>
        </div>
      </div>
    `
  }

  createIneligibleResult() {
    const failedCriteria = this.getFailedCriteria()

    return `
      <div class="alert alert-danger border-0 shadow-sm" role="alert">
        <div class="d-flex align-items-start">
          <i class="bi bi-x-circle-fill text-danger fs-2 me-3 mt-1"></i>
          <div class="flex-grow-1">
            <h6 class="alert-heading mb-2 text-danger">
              ❌ Votre entreprise n'est pas éligible
            </h6>
            <p class="mb-3">
              Selon vos réponses, votre entreprise ne remplit pas tous les critères d'éligibilité pour bénéficier des aides aux entreprises de Bruxelles-Capitale.
            </p>
            <div class="mb-3">
              <strong class="text-danger mb-2 d-block">Critère(s) non respecté(s) :</strong>
              <div class="ms-2">
                ${failedCriteria.map(criteria => `<div class="mb-2">${criteria}</div>`).join('')}
              </div>
            </div>
            <div class="bg-light p-3 rounded">
              <h6 class="text-primary mb-2">
                <i class="bi bi-lightbulb me-2"></i>Que faire ?
              </h6>
              <ul class="small mb-0">
                <li>Vérifiez si votre situation peut évoluer pour répondre aux critères</li>
                <li>Consultez <a href="https://economie-emploi.brussels" target="_blank" class="text-primary">economie-emploi.brussels</a> pour d'autres aides possibles</li>
                <li>Contactez un conseiller pour explorer les alternatives</li>
              </ul>
            </div>
          </div>
        </div>
        <hr class="my-3">
        <div class="d-flex justify-content-between align-items-center">
          <small class="text-muted">
            <i class="bi bi-info-circle me-1"></i>
            Cette évaluation est basée sur les critères officiels de Bruxelles Economie et Emploi
          </small>
          <span class="badge bg-danger fs-6">NON ÉLIGIBLE</span>
        </div>
      </div>
    `
  }

  getFailedCriteria() {
    const criteria = []

    if (this.answersValue.location_bruxelles === false) {
      criteria.push("❌ <strong>Localisation :</strong> Votre entreprise doit être située en Région de Bruxelles-Capitale (19 communes)")
    }

    if (this.answersValue.is_pme === false) {
      criteria.push("❌ <strong>Taille d'entreprise :</strong> Votre entreprise doit être une PME (moins de 250 employés)")
    }

    if (this.answersValue.eligible_sector === false) {
      criteria.push("❌ <strong>Secteur d'activité :</strong> Votre activité doit être dans un secteur éligible selon les codes NACE-BEL 2025")
    }

    if (this.answersValue.economic_purpose === false) {
      criteria.push("❌ <strong>Finalité économique :</strong> Votre entreprise doit avoir une finalité économique et commerciale (pas d'ASBL)")
    }

    if (this.answersValue.regulatory_compliance === false) {
      criteria.push("❌ <strong>Conformité réglementaire :</strong> Vous devez être en ordre avec vos obligations légales (comptes annuels à jour, règle de minimis respectée)")
    }

    return criteria
  }

  // Méthode appelée quand l'utilisateur clique sur "Éligibilité Validée - Continuez"
  enableSimulation() {
    if (this.isEligibleValue) {
      // Déclencher l'événement pour permettre l'accès à la simulation
      const event = new CustomEvent('eligibility:validated', {
        detail: { eligible: true, answers: this.answersValue }
      })

      document.dispatchEvent(event)

      // Changer le style du test d'éligibilité pour montrer qu'il est validé
      const card = this.element.closest('.card')
      if (card) {
        const header = card.querySelector('.card-header')
        header.classList.remove('bg-primary')
        header.classList.add('bg-success')

        const badge = header.querySelector('.badge')
        badge.classList.remove('text-primary')
        badge.classList.add('text-success')
      }

      console.log("Eligibility validated, simulation enabled")
    }
  }
}
