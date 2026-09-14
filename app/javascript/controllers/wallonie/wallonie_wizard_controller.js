import { Controller } from "@hotwired/stimulus"

// Contrôleur de navigation wizard pour la page pré-login Wallonie
// Gère la progression entre les 4 étapes : Profil → Éligibilité → Primes → CTA
export default class extends Controller {
  static targets = ["panel", "navStep", "progressFill"]
  static values = { currentStep: { type: Number, default: 1 }, totalSteps: { type: Number, default: 4 } }

  connect() {
    this.showStep(this.currentStepValue)

    // Éligibilité validée (éligible, pas d'affinage requis) → passer à l'étape 3
    document.addEventListener("wallonie:eligibility:done", (e) => {
      if (e.detail && e.detail.eligible) {
        this.goToStep(3)
      }
    })

    // Catégorie affinée (particuliers) → passer aux primes (étape 3)
    document.addEventListener("wallonie:category:refined", () => this.goToStep(3))
  }

  // Handler pour turbo:frame-render sur le frame "eligibility_content"
  // Déclenché quand un profil est sélectionné et que le questionnaire se charge
  onProfileSelected() {
    if (this.currentStepValue === 1) {
      this.goToStep(2)
    }
  }

  goToStep(step) {
    if (step < 1 || step > this.totalStepsValue) return
    this.currentStepValue = step
    this.showStep(step)
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  prevStep() {
    this.goToStep(this.currentStepValue - 1)
  }

  nextStep() {
    this.goToStep(this.currentStepValue + 1)
  }

  jumpToStep(event) {
    const step = parseInt(event.currentTarget.dataset.stepNumber)
    if (step <= this.currentStepValue) {
      this.goToStep(step)
    }
  }

  showStep(step) {
    this.panelTargets.forEach(panel => {
      const panelStep = parseInt(panel.dataset.wizardStep)
      if (panelStep === step) {
        panel.classList.remove("d-none")
        panel.classList.add("wizard-panel-enter")
        setTimeout(() => panel.classList.remove("wizard-panel-enter"), 400)
      } else {
        panel.classList.add("d-none")
      }
    })

    this.navStepTargets.forEach(navStep => {
      const navNum = parseInt(navStep.dataset.step)
      const bubble = navStep.querySelector(".wizard-nav-bubble")
      const label = navStep.querySelector(".wizard-nav-label")
      if (navNum === step) {
        bubble.classList.remove("bg-light", "text-muted", "bg-success-subtle", "text-success")
        bubble.classList.add("bg-success", "text-white")
        bubble.style.transform = "scale(1.15)"
        if (label) { label.classList.remove("text-muted", "text-success-subtle"); label.classList.add("text-success", "fw-semibold") }
      } else if (navNum < step) {
        bubble.classList.remove("bg-light", "text-muted", "bg-success", "text-white")
        bubble.classList.add("bg-success-subtle", "text-success")
        bubble.style.transform = "scale(1)"
        bubble.innerHTML = '<i class="bi bi-check2 text-success"></i>'
        if (label) { label.classList.remove("text-muted", "fw-semibold"); label.classList.add("text-success") }
      } else {
        bubble.classList.remove("bg-success", "bg-success-subtle", "text-white", "text-success", "fw-semibold")
        bubble.classList.add("bg-light", "text-muted")
        bubble.style.transform = "scale(1)"
        if (label) { label.classList.remove("text-success", "fw-semibold"); label.classList.add("text-muted") }
      }
    })

    if (this.hasProgressFillTarget) {
      const pct = ((step - 1) / (this.totalStepsValue - 1)) * 100
      this.progressFillTarget.style.width = `${pct}%`
    }
  }
}
