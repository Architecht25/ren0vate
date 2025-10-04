// Stimulus controller for aides entreprise cards functionality
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "aideSelectorTransition", "detailsContainerTransition",
    "aideSelectorInvestissement", "detailsContainerInvestissement",
    "aideSelectorRh", "detailsContainerRh",
    "aideSelectorExpertise", "detailsContainerExpertise"
  ]

  connect() {
    console.log("Aides entreprise controller connected")
  }

  showAideDetails(event) {
    const selectedAide = event.target.value

    // Find the corresponding details container for this selector
    const selector = event.target
    const selectorTarget = selector.getAttribute('data-aides-entreprise-target')

    // Determine which container to use based on the selector
    let detailsContainer
    if (selectorTarget === 'aideSelectorTransition') {
      detailsContainer = this.detailsContainerTransitionTarget
    } else if (selectorTarget === 'aideSelectorInvestissement') {
      detailsContainer = this.detailsContainerInvestissementTarget
    } else if (selectorTarget === 'aideSelectorRh') {
      detailsContainer = this.detailsContainerRhTarget
    } else if (selectorTarget === 'aideSelectorExpertise') {
      detailsContainer = this.detailsContainerExpertiseTarget
    }

    if (!detailsContainer) {
      console.error("Could not find details container for selector:", selectorTarget)
      return
    }

    if (!selectedAide) {
      detailsContainer.style.display = 'none'
      return
    }

    // Hide all aide details within this container
    const allAideDetails = detailsContainer.querySelectorAll('.aide-details')
    allAideDetails.forEach(detail => {
      detail.style.display = 'none'
    })

    // Show selected aide details
    const selectedDetails = detailsContainer.querySelector(`[data-aide="${selectedAide}"]`)
    if (selectedDetails) {
      selectedDetails.style.display = 'block'
      detailsContainer.style.display = 'block'

      // Scroll to details with smooth animation
      setTimeout(() => {
        detailsContainer.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        })
      }, 100)
    }

    console.log(`Showing details for aide: ${selectedAide} in container: ${selectorTarget}`)
  }

  calculerAide(event) {
    event.preventDefault()

    // Get the currently selected aide from any of the selectors
    let selectedAide = null
    let activeSelector = null

    // Check all possible selectors
    if (this.hasAideSelectorTransitionTarget && this.aideSelectorTransitionTarget.value) {
      selectedAide = this.aideSelectorTransitionTarget.value
      activeSelector = this.aideSelectorTransitionTarget
    } else if (this.hasAideSelectorInvestissementTarget && this.aideSelectorInvestissementTarget.value) {
      selectedAide = this.aideSelectorInvestissementTarget.value
      activeSelector = this.aideSelectorInvestissementTarget
    } else if (this.hasAideSelectorRhTarget && this.aideSelectorRhTarget.value) {
      selectedAide = this.aideSelectorRhTarget.value
      activeSelector = this.aideSelectorRhTarget
    } else if (this.hasAideSelectorExpertiseTarget && this.aideSelectorExpertiseTarget.value) {
      selectedAide = this.aideSelectorExpertiseTarget.value
      activeSelector = this.aideSelectorExpertiseTarget
    }

    if (!selectedAide) {
      this.showNotification("Veuillez d'abord sélectionner une aide", "warning")
      return
    }

    // Open calculator modal or redirect to calculator page
    this.openCalculatorModal(selectedAide)
  }

  simulerAide(event) {
    event.preventDefault()
    this.calculerAide(event) // Same functionality
  }

  telechargerGuide(event) {
    event.preventDefault()

    // Get the currently selected aide from any of the selectors
    let selectedAide = null

    if (this.hasAideSelectorTransitionTarget && this.aideSelectorTransitionTarget.value) {
      selectedAide = this.aideSelectorTransitionTarget.value
    } else if (this.hasAideSelectorInvestissementTarget && this.aideSelectorInvestissementTarget.value) {
      selectedAide = this.aideSelectorInvestissementTarget.value
    } else if (this.hasAideSelectorRhTarget && this.aideSelectorRhTarget.value) {
      selectedAide = this.aideSelectorRhTarget.value
    } else if (this.hasAideSelectorExpertiseTarget && this.aideSelectorExpertiseTarget.value) {
      selectedAide = this.aideSelectorExpertiseTarget.value
    }

    if (!selectedAide) {
      this.showNotification("Veuillez d'abord sélectionner une aide", "warning")
      return
    }

    // Generate PDF guide for the selected aide
    this.generatePDFGuide(selectedAide)
  }

  contactExpert(event) {
    event.preventDefault()

    // Open contact form for expert consultation
    this.openContactModal()
  }

  rechercherFormation(event) {
    event.preventDefault()

    // Open formation search interface
    window.open('https://www.bruxellesformation.brussels', '_blank')
  }

  trouverConsultant(event) {
    event.preventDefault()

    // Open consultant search interface
    this.openConsultantSearch()
  }

  openCalculatorModal(aideType) {
    // Create and show calculator modal
    const modalHTML = this.generateCalculatorModal(aideType)
    document.body.insertAdjacentHTML('beforeend', modalHTML)

    const modal = new bootstrap.Modal(document.getElementById('calculatorModal'))
    modal.show()

    // Clean up modal when closed
    document.getElementById('calculatorModal').addEventListener('hidden.bs.modal', function() {
      this.remove()
    })
  }

  generateCalculatorModal(aideType) {
    const aideInfo = this.getAideInfo(aideType)

    return `
      <div class="modal fade" id="calculatorModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">
                <i class="bi bi-calculator me-2"></i>Calculateur - ${aideInfo.title}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Montant des dépenses éligibles (€)</label>
                  <input type="number" class="form-control" id="montantDepenses" placeholder="Ex: 10000">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Taille de l'entreprise</label>
                  <select class="form-select" id="tailleEntreprise">
                    <option value="micro">Micro-entreprise</option>
                    <option value="petite">Petite entreprise</option>
                    <option value="moyenne">Moyenne entreprise</option>
                  </select>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Entreprise starter (< 4 ans)</label>
                  <select class="form-select" id="isStarter">
                    <option value="false">Non</option>
                    <option value="true">Oui</option>
                  </select>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Entreprise exemplaire</label>
                  <select class="form-select" id="isExemplaire">
                    <option value="none">Aucune</option>
                    <option value="environnemental">Environnementale</option>
                    <option value="social">Sociale</option>
                    <option value="both">Les deux</option>
                  </select>
                </div>
              </div>

              <div class="mt-4">
                <button type="button" class="btn btn-primary" onclick="this.closest('.modal-content').querySelector('.calculator-result').innerHTML = window.calculateAide('${aideType}')">
                  <i class="bi bi-calculator me-1"></i>Calculer
                </button>
              </div>

              <div class="calculator-result mt-3"></div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Fermer</button>
              <a href="https://monbee.brussels.be" target="_blank" class="btn btn-primary">
                <i class="bi bi-globe me-1"></i>Faire la demande
              </a>
            </div>
          </div>
        </div>
      </div>
    `
  }

  openContactModal() {
    const modalHTML = `
      <div class="modal fade" id="contactModal" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">
                <i class="bi bi-person-check me-2"></i>Contact Expert
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <form>
                <div class="mb-3">
                  <label class="form-label">Nom de l'entreprise</label>
                  <input type="text" class="form-control" required>
                </div>
                <div class="mb-3">
                  <label class="form-label">Contact</label>
                  <input type="text" class="form-control" required>
                </div>
                <div class="mb-3">
                  <label class="form-label">Email</label>
                  <input type="email" class="form-control" required>
                </div>
                <div class="mb-3">
                  <label class="form-label">Téléphone</label>
                  <input type="tel" class="form-control">
                </div>
                <div class="mb-3">
                  <label class="form-label">Type d'aide recherchée</label>
                  <select class="form-select">
                    <option>Transition économique</option>
                    <option>Investissements</option>
                    <option>Recrutement & Formation</option>
                    <option>Expertises & Services</option>
                  </select>
                </div>
                <div class="mb-3">
                  <label class="form-label">Message</label>
                  <textarea class="form-control" rows="3"></textarea>
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
              <button type="button" class="btn btn-primary">Envoyer la demande</button>
            </div>
          </div>
        </div>
      </div>
    `

    document.body.insertAdjacentHTML('beforeend', modalHTML)
    const modal = new bootstrap.Modal(document.getElementById('contactModal'))
    modal.show()

    document.getElementById('contactModal').addEventListener('hidden.bs.modal', function() {
      this.remove()
    })
  }

  openConsultantSearch() {
    const modalHTML = `
      <div class="modal fade" id="consultantModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">
                <i class="bi bi-search me-2"></i>Recherche de Consultant
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Domaine d'expertise</label>
                  <select class="form-select">
                    <option>Stratégie commerciale</option>
                    <option>Analyse financière</option>
                    <option>Études juridiques</option>
                    <option>Études techniques</option>
                    <option>Communication</option>
                    <option>Management</option>
                    <option>Digitalisation</option>
                  </select>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Budget approximatif</label>
                  <select class="form-select">
                    <option>< 5 000€</option>
                    <option>5 000€ - 10 000€</option>
                    <option>10 000€ - 20 000€</option>
                    <option>> 20 000€</option>
                  </select>
                </div>
                <div class="col-12">
                  <label class="form-label">Description du projet</label>
                  <textarea class="form-control" rows="3" placeholder="Décrivez votre besoin en consultance..."></textarea>
                </div>
              </div>

              <div class="mt-4">
                <h6>Suggestions de consultants :</h6>
                <div class="list-group">
                  <div class="list-group-item">
                    <div class="d-flex justify-content-between align-items-center">
                      <div>
                        <h6 class="mb-1">Cabinet ConseilPro</h6>
                        <p class="mb-1 small">Spécialisé en stratégie commerciale et marketing</p>
                        <small class="text-muted">★★★★★ (4.8/5) • 15 avis</small>
                      </div>
                      <button class="btn btn-outline-primary btn-sm">Contacter</button>
                    </div>
                  </div>
                  <div class="list-group-item">
                    <div class="d-flex justify-content-between align-items-center">
                      <div>
                        <h6 class="mb-1">Digital Solutions SPRL</h6>
                        <p class="mb-1 small">Expert en transformation digitale</p>
                        <small class="text-muted">★★★★☆ (4.5/5) • 8 avis</small>
                      </div>
                      <button class="btn btn-outline-primary btn-sm">Contacter</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Fermer</button>
              <button type="button" class="btn btn-primary">Rechercher plus</button>
            </div>
          </div>
        </div>
      </div>
    `

    document.body.insertAdjacentHTML('beforeend', modalHTML)
    const modal = new bootstrap.Modal(document.getElementById('consultantModal'))
    modal.show()

    document.getElementById('consultantModal').addEventListener('hidden.bs.modal', function() {
      this.remove()
    })
  }

  generatePDFGuide(aideType) {
    // Simulate PDF generation
    this.showNotification("Génération du guide PDF en cours...", "info")

    setTimeout(() => {
      this.showNotification("Guide PDF téléchargé avec succès!", "success")
    }, 2000)
  }

  getAideInfo(aideType) {
    const aideInfos = {
      'transition_consultance': { title: 'Prime Transition Consultance', baseRate: 50 },
      'investissements_transition': { title: 'Investissements Transition', baseRate: 10 },
      'mobilite_velo_cargo': { title: 'Mobilité Vélo Cargo', baseRate: 30 },
      'prime_materiel_travaux': { title: 'Prime Matériel ou Travaux', baseRate: 5 },
      'prime_formation': { title: 'Prime Formation', baseRate: 40 },
      'prime_consultance': { title: 'Prime Consultance', baseRate: 25 },
      'prime_digitalisation': { title: 'Prime Digitalisation', baseRate: 50 }
    }

    return aideInfos[aideType] || { title: 'Aide inconnue', baseRate: 0 }
  }

  showNotification(message, type = "info") {
    // Create notification toast
    const toastHTML = `
      <div class="toast align-items-center text-white bg-${type === 'success' ? 'success' : type === 'warning' ? 'warning' : type === 'danger' ? 'danger' : 'primary'} border-0" role="alert">
        <div class="d-flex">
          <div class="toast-body">
            <i class="bi bi-${type === 'success' ? 'check-circle' : type === 'warning' ? 'exclamation-triangle' : type === 'danger' ? 'x-circle' : 'info-circle'} me-2"></i>
            ${message}
          </div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
      </div>
    `

    // Add toast container if not exists
    let toastContainer = document.getElementById('toast-container')
    if (!toastContainer) {
      toastContainer = document.createElement('div')
      toastContainer.id = 'toast-container'
      toastContainer.className = 'toast-container position-fixed top-0 end-0 p-3'
      toastContainer.style.zIndex = '9999'
      document.body.appendChild(toastContainer)
    }

    // Add toast and show it
    toastContainer.insertAdjacentHTML('beforeend', toastHTML)
    const toastElement = toastContainer.lastElementChild
    const toast = new bootstrap.Toast(toastElement)
    toast.show()

    // Remove toast element after it's hidden
    toastElement.addEventListener('hidden.bs.toast', () => {
      toastElement.remove()
    })
  }
}

// Global function for calculator (called from modal)
window.calculateAide = function(aideType) {
  const montant = parseFloat(document.getElementById('montantDepenses').value) || 0
  const taille = document.getElementById('tailleEntreprise').value
  const isStarter = document.getElementById('isStarter').value === 'true'
  const exemplaire = document.getElementById('isExemplaire').value

  if (montant <= 0) {
    return '<div class="alert alert-warning">Veuillez saisir un montant valide</div>'
  }

  // Basic calculation logic (simplified)
  const aideInfos = {
    'transition_consultance': { base: 50, max: 80 },
    'prime_formation': { base: 40, max: 80 },
    'prime_consultance': { base: 25, max: 70 },
    'prime_digitalisation': { base: 50, max: 80 },
    'prime_materiel_travaux': { base: 5, max: 30 }
  }

  const info = aideInfos[aideType] || { base: 25, max: 50 }
  let taux = info.base

  // Add bonuses
  if (isStarter) {
    if (taille === 'micro' || taille === 'petite') taux += 15
    else taux += 10
  }

  if (exemplaire === 'environnemental') {
    if (taille === 'micro' || taille === 'petite') taux += 15
    else taux += 10
  }

  if (exemplaire === 'social') {
    if (taille === 'micro' || taille === 'petite') taux += 15
    else taux += 10
  }

  if (exemplaire === 'both') {
    if (taille === 'micro' || taille === 'petite') taux += 30
    else taux += 20
  }

  // Cap at maximum
  taux = Math.min(taux, info.max)

  const aideCalculee = montant * taux / 100

  return `
    <div class="card bg-light">
      <div class="card-body">
        <h5 class="card-title text-success">Résultat du calcul</h5>
        <div class="row g-3">
          <div class="col-md-6">
            <strong>Dépenses éligibles :</strong><br>
            <span class="h5">${montant.toLocaleString('fr-BE')}€</span>
          </div>
          <div class="col-md-6">
            <strong>Taux d'aide :</strong><br>
            <span class="h5 text-primary">${taux}%</span>
          </div>
          <div class="col-12">
            <hr>
            <strong>Montant de l'aide :</strong><br>
            <span class="h3 text-success">${aideCalculee.toLocaleString('fr-BE')}€</span>
          </div>
        </div>
      </div>
    </div>
  `
}
