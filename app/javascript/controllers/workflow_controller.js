import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step1", "step2", "step3", "progress"]
  static values = { currentStep: { type: Number, default: 1 } }

  connect() {
    this.initializeSteps()
    this.updateProgressIndicator()
  }

  initializeSteps() {
    // Afficher toutes les étapes dès le départ pour une meilleure visibilité
    if (this.hasStep1Target) {
      this.step1Target.classList.add('step-active')
      this.step1Target.classList.remove('step-disabled')
      this.step1Target.style.display = 'block'
    }
    if (this.hasStep2Target) {
      this.step2Target.classList.add('step-active')
      this.step2Target.classList.remove('step-disabled')
      this.step2Target.style.display = 'block'
    }
    if (this.hasStep3Target) {
      this.step3Target.classList.add('step-active')
      this.step3Target.classList.remove('step-disabled')
      this.step3Target.style.display = 'block'
    }
  }

  hideAllSteps() {
    // Masquer toutes les étapes
    for (let i = 1; i <= 3; i++) {
      const stepTarget = this[`step${i}Target`]
      if (stepTarget) {
        stepTarget.classList.remove('step-active')
        stepTarget.classList.add('step-disabled')
        stepTarget.style.display = 'none'
      }
    }
  }

  nextStep() {
    console.log(`Current step: ${this.currentStepValue}, moving to next step`)
    if (this.currentStepValue < 3) {
      this.currentStepValue++
      console.log(`New step: ${this.currentStepValue}`)
      this.activateCurrentStep()
      this.updateProgressIndicator()
    }
  }

  previousStep() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.deactivateStepsAfterCurrent()
      this.updateProgressIndicator()
    }
  }

  activateCurrentStep() {
    const currentStepTarget = this[`step${this.currentStepValue}Target`]
    console.log(`Activating step ${this.currentStepValue}`, currentStepTarget)
    if (currentStepTarget) {
      currentStepTarget.classList.remove('step-disabled')
      currentStepTarget.classList.add('step-active')
      currentStepTarget.style.display = 'block'
      console.log(`Step ${this.currentStepValue} activated, display set to block`)

      // Scroll vers l'étape active
      currentStepTarget.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      })
    } else {
      console.error(`No target found for step ${this.currentStepValue}`)
    }
  }

  deactivateStepsAfterCurrent() {
    for (let i = this.currentStepValue + 1; i <= 3; i++) {
      const stepTarget = this[`step${i}Target`]
      if (stepTarget) {
        stepTarget.classList.remove('step-active')
        stepTarget.classList.add('step-disabled')
        stepTarget.style.display = 'none'
      }
    }
  }

  goToStep(event) {
    const targetStep = parseInt(event.params.step)
    if (targetStep >= 1 && targetStep <= 3) {
      this.hideCurrentStep()
      this.currentStepValue = targetStep
      this.showCurrentStep()
      this.updateProgressIndicator()
    }
  }

  hideCurrentStep() {
    // Méthode conservée pour compatibilité mais adaptée
    const currentStepTarget = this[`step${this.currentStepValue}Target`]
    if (currentStepTarget) {
      currentStepTarget.classList.add('step-disabled')
      currentStepTarget.classList.remove('step-active')
      currentStepTarget.style.display = 'none'
    }
  }

  showCurrentStep() {
    // Méthode conservée pour compatibilité mais adaptée
    const currentStepTarget = this[`step${this.currentStepValue}Target`]
    if (currentStepTarget) {
      currentStepTarget.classList.remove('step-disabled')
      currentStepTarget.classList.add('step-active')
      currentStepTarget.style.display = 'block'
    }
  }

  updateProgressIndicator() {
    // Mettre à jour les indicateurs de progression
    for (let i = 1; i <= 3; i++) {
      const stepCircle = this.element.querySelector(`[data-step="${i}"]`)
      const stepConnector = this.element.querySelector(`[data-connector="${i}"]`)

      if (stepCircle) {
        stepCircle.classList.remove('active', 'completed')
        if (i < this.currentStepValue) {
          stepCircle.classList.add('completed')
        } else if (i === this.currentStepValue) {
          stepCircle.classList.add('active')
        }
      }

      if (stepConnector && i < 3) {
        stepConnector.classList.remove('completed')
        if (i < this.currentStepValue) {
          stepConnector.classList.add('completed')
        }
      }
    }

    // Émettre un événement pour notifier le changement d'étape
    this.dispatch("stepChanged", {
      detail: {
        currentStep: this.currentStepValue
      }
    })
  }
}
