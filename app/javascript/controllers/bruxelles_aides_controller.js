import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoriesContainer", "detailsContainer", "loadingSpinner", "categoryCard"]

  connect() {
    console.log("🏢 Bruxelles Aides controller connected")
    this.loadCategories()
  }

  async loadCategories() {
    try {
      this.showLoading()

      const response = await fetch('/api/bruxelles_aides/categories', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.displayCategories(data.data.categories)
      } else {
        this.showError('Erreur lors du chargement des catégories d\'aides')
      }
    } catch (error) {
      console.error('Erreur chargement catégories:', error)
      this.showError('Erreur de connexion')
    } finally {
      this.hideLoading()
    }
  }

  displayCategories(categories) {
    this.categoriesContainerTarget.innerHTML = ""

    categories.forEach(category => {
      const categoryCard = this.createCategoryCard(category)
      this.categoriesContainerTarget.appendChild(categoryCard)
    })
  }

  createCategoryCard(category) {
    const card = document.createElement('div')
    card.className = 'col-md-6 col-lg-4 mb-4'
    card.innerHTML = `
      <div class="card h-100 shadow-sm border-0 category-card"
           style="cursor: pointer; transition: transform 0.2s, box-shadow 0.2s;"
           data-category-id="${category.id}"
           data-action="click->bruxelles-aides#selectCategory">
        <div class="card-body text-center p-4">
          <div class="category-icon mb-3" style="font-size: 3rem;">
            ${category.icon}
          </div>
          <h5 class="card-title text-${category.color} fw-bold mb-3">
            ${category.name}
          </h5>
          <p class="card-text text-muted mb-3">
            ${category.description}
          </p>
          <div class="badge bg-${category.color} bg-opacity-10 text-${category.color} mb-3">
            ${category.nombre_aides} aide${category.nombre_aides > 1 ? 's' : ''} disponible${category.nombre_aides > 1 ? 's' : ''}
          </div>
          <div class="mt-auto">
            <button class="btn btn-outline-${category.color} btn-sm w-100">
              <i class="fas fa-arrow-right me-2"></i>
              Voir les détails
            </button>
          </div>
        </div>
      </div>
    `

    // Ajouter les effets hover
    const cardElement = card.querySelector('.category-card')
    cardElement.addEventListener('mouseenter', () => {
      cardElement.style.transform = 'translateY(-5px)'
      cardElement.style.boxShadow = '0 10px 25px rgba(0,0,0,0.15)'
    })
    cardElement.addEventListener('mouseleave', () => {
      cardElement.style.transform = 'translateY(0)'
      cardElement.style.boxShadow = ''
    })

    return card
  }

  async selectCategory(event) {
    const categoryId = event.currentTarget.dataset.categoryId

    // Effet visuel de sélection
    this.highlightSelectedCategory(event.currentTarget)

    try {
      this.showDetailsLoading()

      const response = await fetch(`/api/bruxelles_aides/categories/${categoryId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.displayCategoryDetails(data.data.category)
        this.scrollToDetails()
      } else {
        this.showDetailsError('Erreur lors du chargement des détails')
      }
    } catch (error) {
      console.error('Erreur chargement détails:', error)
      this.showDetailsError('Erreur de connexion')
    }
  }

  highlightSelectedCategory(selectedCard) {
    // Retirer la sélection précédente
    this.categoriesContainerTarget.querySelectorAll('.category-card').forEach(card => {
      card.classList.remove('border-primary', 'border-3')
    })

    // Ajouter la sélection à la carte actuelle
    selectedCard.classList.add('border-primary', 'border-3')
  }

  displayCategoryDetails(category) {
    this.detailsContainerTarget.innerHTML = `
      <div class="card shadow-lg border-0">
        <div class="card-header bg-${category.color} text-white py-4">
          <div class="row align-items-center">
            <div class="col">
              <h3 class="card-title mb-0">
                <span style="font-size: 2rem; margin-right: 1rem;">${category.icon}</span>
                ${category.name}
              </h3>
              <p class="mb-0 opacity-90">${category.description}</p>
            </div>
            <div class="col-auto">
              <span class="badge bg-white text-${category.color} fs-6">
                ${category.aides.length} aide${category.aides.length > 1 ? 's' : ''}
              </span>
            </div>
          </div>
        </div>
        <div class="card-body p-0">
          ${this.createAidesAccordion(category.aides, category.color)}
        </div>
      </div>
    `

    this.detailsContainerTarget.style.display = 'block'
  }

  createAidesAccordion(aides, color) {
    const accordionId = `accordion-${Date.now()}`

    let accordionHtml = `<div class="accordion accordion-flush" id="${accordionId}">`

    aides.forEach((aide, index) => {
      const collapseId = `collapse-${accordionId}-${index}`

      accordionHtml += `
        <div class="accordion-item">
          <h2 class="accordion-header" id="heading-${accordionId}-${index}">
            <button class="accordion-button ${index === 0 ? '' : 'collapsed'}"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="#${collapseId}"
                    aria-expanded="${index === 0 ? 'true' : 'false'}"
                    aria-controls="${collapseId}">
              <div class="w-100">
                <div class="d-flex justify-content-between align-items-center">
                  <span class="fw-bold text-${color}">${aide.name}</span>
                  <div class="ms-3">
                    <span class="badge bg-${color} bg-opacity-10 text-${color} me-2">
                      ${aide.taux}
                    </span>
                    <small class="text-muted">Max: ${aide.plafond}</small>
                  </div>
                </div>
                <small class="text-muted d-block mt-1">${aide.description}</small>
              </div>
            </button>
          </h2>
          <div id="${collapseId}"
               class="accordion-collapse collapse ${index === 0 ? 'show' : ''}"
               aria-labelledby="heading-${accordionId}-${index}"
               data-bs-parent="#${accordionId}">
            <div class="accordion-body">
              ${this.createAideDetails(aide, color)}
            </div>
          </div>
        </div>
      `
    })

    accordionHtml += '</div>'
    return accordionHtml
  }

  createAideDetails(aide, color) {
    let detailsHtml = `
      <div class="row">
        <div class="col-md-6">
          <h6 class="text-${color} fw-bold mb-3">
            <i class="fas fa-info-circle me-2"></i>Informations principales
          </h6>
          <ul class="list-unstyled">
            <li class="mb-2">
              <strong>Taux de prime:</strong> <span class="text-${color}">${aide.taux}</span>
            </li>
            <li class="mb-2">
              <strong>Plafond:</strong> ${aide.plafond}
            </li>
    `

    if (aide.duree || aide.duree_min) {
      detailsHtml += `
            <li class="mb-2">
              <strong>Durée:</strong> ${aide.duree || aide.duree_min}
            </li>
      `
    }

    if (aide.statut) {
      const statutClass = aide.statut === 'Suspendu' ? 'danger' : 'success'
      detailsHtml += `
            <li class="mb-2">
              <strong>Statut:</strong> <span class="badge bg-${statutClass}">${aide.statut}</span>
            </li>
      `
    }

    detailsHtml += `
          </ul>
        </div>
        <div class="col-md-6">
    `

    if (aide.conditions && aide.conditions.length > 0) {
      detailsHtml += `
          <h6 class="text-${color} fw-bold mb-3">
            <i class="fas fa-check-circle me-2"></i>Conditions d'éligibilité
          </h6>
          <ul class="list-unstyled">
      `
      aide.conditions.forEach(condition => {
        detailsHtml += `
            <li class="mb-2">
              <i class="fas fa-check text-success me-2"></i>
              <small>${condition}</small>
            </li>
        `
      })
      detailsHtml += '</ul>'
    }

    detailsHtml += `
        </div>
      </div>
    `

    if (aide.exemples && aide.exemples.length > 0) {
      detailsHtml += `
        <div class="row mt-4">
          <div class="col-12">
            <h6 class="text-${color} fw-bold mb-3">
              <i class="fas fa-lightbulb me-2"></i>Exemples d'applications
            </h6>
            <div class="row">
      `

      aide.exemples.forEach(exemple => {
        detailsHtml += `
              <div class="col-md-6 mb-2">
                <div class="badge bg-light text-dark border w-100 text-start p-2">
                  <i class="fas fa-arrow-right text-${color} me-2"></i>
                  ${exemple}
                </div>
              </div>
        `
      })

      detailsHtml += `
            </div>
          </div>
        </div>
      `
    }

    if (aide.documents && aide.documents.length > 0) {
      detailsHtml += `
        <div class="row mt-4">
          <div class="col-12">
            <h6 class="text-${color} fw-bold mb-3">
              <i class="fas fa-file-alt me-2"></i>Documents requis
            </h6>
            <div class="row">
      `

      aide.documents.forEach(document => {
        detailsHtml += `
              <div class="col-md-6 mb-2">
                <div class="d-flex align-items-center">
                  <i class="fas fa-file text-${color} me-2"></i>
                  <small>${document}</small>
                </div>
              </div>
        `
      })

      detailsHtml += `
            </div>
          </div>
        </div>
      `
    }

    if (aide.info) {
      detailsHtml += `
        <div class="alert alert-info mt-4">
          <i class="fas fa-info-circle me-2"></i>
          ${aide.info}
        </div>
      `
    }

    return detailsHtml
  }

  scrollToDetails() {
    setTimeout(() => {
      this.detailsContainerTarget.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }, 100)
  }

  showLoading() {
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.style.display = 'block'
    }
  }

  hideLoading() {
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.style.display = 'none'
    }
  }

  showDetailsLoading() {
    this.detailsContainerTarget.innerHTML = `
      <div class="text-center p-5">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Chargement...</span>
        </div>
        <p class="mt-3 text-muted">Chargement des détails...</p>
      </div>
    `
    this.detailsContainerTarget.style.display = 'block'
  }

  showError(message) {
    this.categoriesContainerTarget.innerHTML = `
      <div class="col-12">
        <div class="alert alert-danger">
          <i class="fas fa-exclamation-triangle me-2"></i>
          ${message}
        </div>
      </div>
    `
  }

  showDetailsError(message) {
    this.detailsContainerTarget.innerHTML = `
      <div class="alert alert-danger">
        <i class="fas fa-exclamation-triangle me-2"></i>
        ${message}
      </div>
    `
    this.detailsContainerTarget.style.display = 'block'
  }
}
