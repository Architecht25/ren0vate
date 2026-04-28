import { Controller } from "@hotwired/stimulus"

// Contrôleur de navigation wizard pour la page pré-login Flandre
// Gère la progression entre les 4 étapes : Profil → Éligibilité → Revenus → Primes
export default class extends Controller {
  static targets = ["panel", "navStep", "progressFill"]
  static values = { currentStep: { type: Number, default: 1 }, totalSteps: { type: Number, default: 4 } }

  connect() {
    this.showStep(this.currentStepValue)

    // Profil sélectionné → passer à l'étape 2
    document.addEventListener("userType:selected", () => this.goToStep(2))

    // Éligibilité validée (eligible) → passer à l'étape 3 ou 4
    document.addEventListener("flandre:eligibility:done", (e) => {
      if (e.detail && e.detail.eligible) {
        const cat = e.detail.categorie
        // Si cat déjà précise (1, 2 ou 3), skip l'étape affinage
        if (cat && cat.toString() !== "4") {
          this.goToStep(4)
          this.updatePrimesCards(cat.toString())
        } else {
          this.goToStep(3)
        }
      }
    })

    // Catégorie affinée → passer aux primes
    document.addEventListener("flandre:category:refined", (e) => {
      this.goToStep(4)
      const cat = e.detail?.categorie
      if (cat) {
        window.categorieId = cat.toString()
        this.updatePrimesCards(cat.toString())
      }
    })
  }

  goToStep(step) {
    if (step < 1 || step > this.totalStepsValue) return
    this.currentStepValue = step
    this.showStep(step)
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  // Bouton "Retour" dans les panels
  prevStep() {
    this.goToStep(this.currentStepValue - 1)
  }

  // Clic sur un numéro de nav (seulement les étapes atteintes)
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
        bubble.classList.remove("bg-light", "text-muted", "bg-success", "text-white")
        bubble.classList.add("bg-primary", "text-white")
        bubble.style.transform = "scale(1.15)"
        if (label) { label.classList.replace("text-muted", "text-primary"); label.classList.add("fw-semibold") }
      } else if (navNum < step) {
        bubble.classList.remove("bg-light", "text-muted", "bg-primary", "text-white")
        bubble.classList.add("bg-success", "text-white")
        bubble.style.transform = "scale(1)"
        bubble.innerHTML = '<i class="bi bi-check2"></i>'
        if (label) { label.classList.remove("text-primary", "fw-semibold"); label.classList.add("text-success") }
      } else {
        bubble.classList.remove("bg-primary", "bg-success", "text-white", "fw-semibold")
        bubble.classList.add("bg-light", "text-muted")
        bubble.style.transform = "scale(1)"
        if (label) { label.classList.remove("text-primary", "text-success", "fw-semibold"); label.classList.add("text-muted") }
      }
    })

    if (this.hasProgressFillTarget) {
      const pct = ((step - 1) / (this.totalStepsValue - 1)) * 100
      this.progressFillTarget.style.width = `${pct}%`
    }
  }

  updatePrimesCards(categorie) {
    const cat = categorie.toString()
    const cat1Only = ['warmtepomp', 'warmtepompboiler']
    const isCat1 = cat === '1'
    const isCat2 = cat === '2'
    const isCat34 = ['3', '4'].includes(cat)

    document.querySelectorAll('[data-controller*="prime-card"]').forEach(card => {
      const slug = card.dataset.slug

      // Catégorie 1 : uniquement pompe à chaleur et chauffe-eau thermodynamique
      if (isCat1) {
        card.style.display = cat1Only.includes(slug) ? '' : 'none'
        return
      }

      // Catégorie 2 : uniquement pompe à chaleur et chauffe-eau thermodynamique
      if (isCat2) {
        card.style.display = cat1Only.includes(slug) ? '' : 'none'
        return
      }

      // Catégorie 3 ou 4 : toutes les cartes sont visibles
      if (isCat34) {
        card.style.display = ''
        return
      }

      // Fallback : cacher
      card.style.display = 'none'
    })

    // Mettre à jour le label affiché
    const label = document.getElementById('primes-categorie-label')
    if (label) label.textContent = `Catégorie ${cat} — simulation indicative`

    // Propager aux contrôleurs prime-card pour recalcul
    document.dispatchEvent(new CustomEvent('category:changed', { detail: { categorie: cat } }))
  }
}
