import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "addButton", "additionalContainer"]

  connect() {

    this.entrepreneurCount = 1 // Commence à 1 car l'entrepreneur principal existe déjà
    this.initializeExistingEntrepreneurs()
    this.toggleRemoveButtons()
  }

  initializeExistingEntrepreneurs() {
    if (!this.hasAdditionalContainerTarget) {
      return
    }

    // Calculer le nombre actuel d'entrepreneurs additionnels
    const existingEntrepreneurs = this.additionalContainerTarget.querySelectorAll('.entrepreneur-item')
    this.entrepreneurCount = existingEntrepreneurs.length + 1 // +1 pour l'entrepreneur principal

    // Attacher les événements aux boutons de suppression existants
    existingEntrepreneurs.forEach(entrepreneur => {
      const removeButton = entrepreneur.querySelector('.remove-entrepreneur')
      if (removeButton) {
        removeButton.addEventListener('click', (e) => this.removeEntrepreneur(e))
      }
    })
  }

  addEntrepreneur(event) {
    event.preventDefault()

    if (!this.hasAdditionalContainerTarget) {
      return
    }

    this.entrepreneurCount++

    const newEntrepreneur = document.createElement('div')
    newEntrepreneur.innerHTML = this.getEntrepreneurTemplate(this.entrepreneurCount)

    // Extraire le contenu du div temporaire
    const entrepreneurElement = newEntrepreneur.firstElementChild
    this.additionalContainerTarget.appendChild(entrepreneurElement)

    // Ajouter l'événement de suppression au nouveau bouton
    const removeButton = entrepreneurElement.querySelector('.remove-entrepreneur')
    removeButton.addEventListener('click', (e) => this.removeEntrepreneur(e))

    this.toggleRemoveButtons()

    // Animation d'apparition
    entrepreneurElement.style.opacity = '0'
    setTimeout(() => {
      entrepreneurElement.style.transition = 'opacity 0.3s ease-in'
      entrepreneurElement.style.opacity = '1'
    }, 10)
  }

  removeEntrepreneur(event) {
    event.preventDefault()
    const entrepreneurItem = event.target.closest('.entrepreneur-item')
    entrepreneurItem.remove()
    this.entrepreneurCount--
    this.updateEntrepreneurNumbers()
    this.toggleRemoveButtons()
  }

  updateEntrepreneurNumbers() {
    const entrepreneurs = this.additionalContainerTarget.querySelectorAll('.entrepreneur-item')
    entrepreneurs.forEach((entrepreneur, index) => {
      const numberElement = entrepreneur.querySelector('h6')
      if (numberElement) {
        numberElement.innerHTML = `<i class="bi bi-hammer me-2"></i>Entrepreneur ${index + 2}`
      }
    })
  }

  toggleRemoveButtons() {
    const removeButtons = this.additionalContainerTarget.querySelectorAll('.remove-entrepreneur')
    if (removeButtons.length <= 1) {
      removeButtons.forEach(btn => btn.style.display = 'none')
    } else {
      removeButtons.forEach(btn => btn.style.display = 'inline-block')
    }
  }

  getEntrepreneurTemplate(number) {
    return `
      <div class="entrepreneur-item border rounded p-3 mb-3" style="background-color: #f8f9fa;">
        <div class="d-flex justify-content-between align-items-start mb-3">
          <h6 class="text-warning-emphasis mb-0 fw-semibold">
            <i class="bi bi-hammer me-2"></i>Entrepreneur ${number}
          </h6>
          <button type="button" class="btn btn-sm btn-outline-danger remove-entrepreneur">
            <i class="bi bi-trash"></i> Supprimer
          </button>
        </div>

        <!-- Première rangée : informations principales -->
        <div class="row g-2 mb-3">
          <div class="col">
            <label class="form-label">Nom</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][nom]" placeholder="Ex: Pierre Martin">
          </div>
          <div class="col">
            <label class="form-label">Entreprise</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][entreprise]" placeholder="Ex: Entreprise Martin SPRL">
          </div>
          <div class="col">
            <label class="form-label">N° TVA</label>
            <input type="text" class="form-control" name="additional_entrepreneurs[][numero_tva]" placeholder="Ex: BE0123456789">
          </div>
          <div class="col">
            <label class="form-label">Téléphone</label>
            <input type="tel" class="form-control" name="additional_entrepreneurs[][telephone]" placeholder="Ex: +32 123 45 67 89">
          </div>
          <div class="col">
            <label class="form-label">Email</label>
            <input type="email" class="form-control" name="additional_entrepreneurs[][email]" placeholder="Ex: contact@entreprise.be">
          </div>
        </div>

        <!-- Seconde rangée : montant du devis -->
        <div class="row">
          <div class="col-md-6">
            <div class="mb-3">
              <label class="form-label">Montant du devis entrepreneur</label>
              <div class="input-group">
                <input type="number" step="0.01" min="0" class="form-control" name="additional_entrepreneurs[][devis_montant]" placeholder="Ex: 25000.00">
                <span class="input-group-text">€</span>
              </div>
              <small class="form-text text-muted">
                Montant HT du devis pour comparer avec les factures
              </small>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
