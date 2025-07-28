import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result", "incomeInput", "maritalInput", "childrenInput", "categoryDisplay", "categoryBadge", "categoryDescription"]

  connect() {
    console.log("🎯 Bruxelles Prime Calcul controller connected")
  }

  updateCategory(event) {
    // Récupérer les valeurs du formulaire
    const income = parseInt(this.incomeInputTarget.value) || 0
    const maritalStatus = this.maritalInputTarget.value
    const childrenCount = parseInt(this.childrenInputTarget.value) || 0

    if (income > 0 && maritalStatus) {
      const category = this.calculateCategory(income, maritalStatus, childrenCount)
      this.displayCategory(category)
    }
  }

  calculateCategory(income, maritalStatus, childrenCount) {
    // Seuils de revenus pour Bruxelles (valeurs indicatives 2024)
    const thresholds = {
      Z1: { single: 22090, married: 32390 },
      Z2: { single: 26510, married: 38900 },
      Z3: { single: 30930, married: 45410 },
      Z4: { single: 35350, married: 51920 },
      Z5: { single: 39770, married: 58430 },
      Z6: { single: 44190, married: 64940 },
      Z7: { single: 48610, married: 71450 },
      Z8: { single: 53030, married: 77960 },
      Z9: { single: 57450, married: 84470 },
      Z10: { single: 61870, married: 90980 }
    }

    // Ajustement pour les enfants (environ 4420€ par enfant)
    const childAdjustment = childrenCount * 4420
    const statusKey = maritalStatus === 'single' ? 'single' : 'married'

    // Trouver la catégorie appropriée
    for (const [category, limits] of Object.entries(thresholds)) {
      const adjustedLimit = limits[statusKey] + childAdjustment
      if (income <= adjustedLimit) {
        return {
          code: category,
          description: this.getCategoryDescription(category),
          maxIncome: adjustedLimit
        }
      }
    }

    // Si revenus trop élevés
    return {
      code: "Non éligible",
      description: "Revenus supérieurs aux plafonds RENOLUTION",
      maxIncome: null
    }
  }

  getCategoryDescription(category) {
    const descriptions = {
      Z1: "Revenus très faibles - Primes maximales",
      Z2: "Revenus faibles - Primes élevées",
      Z3: "Revenus modérés-bas - Primes importantes",
      Z4: "Revenus modérés - Primes substantielles",
      Z5: "Revenus moyens-bas - Primes moyennes",
      Z6: "Revenus moyens - Primes modérées",
      Z7: "Revenus moyens-élevés - Primes réduites",
      Z8: "Revenus élevés-bas - Primes minimales",
      Z9: "Revenus élevés - Primes très réduites",
      Z10: "Revenus très élevés - Primes limitées"
    }
    return descriptions[category] || "Catégorie inconnue"
  }

  displayCategory(category) {
    this.categoryDisplayTarget.style.display = "block"
    this.categoryBadgeTarget.textContent = category.code
    this.categoryDescriptionTarget.textContent = category.description

    // Couleur du badge selon la catégorie
    const badge = this.categoryBadgeTarget
    badge.className = "badge fs-6 me-2"

    if (category.code === "Non éligible") {
      badge.classList.add("bg-danger")
    } else {
      const categoryNum = parseInt(category.code.replace('Z', ''))
      if (categoryNum <= 3) {
        badge.classList.add("bg-success")
      } else if (categoryNum <= 6) {
        badge.classList.add("bg-warning")
      } else {
        badge.classList.add("bg-primary")
      }
    }
  }

  submitEligibility(event) {
    event.preventDefault()
    console.log("Submitting eligibility form for Bruxelles")

    const form = event.target
    const formData = new FormData(form)

    // Validation basique
    if (!this.validateForm(formData)) {
      return
    }

    // Soumission du formulaire
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Mise à jour du contenu avec Turbo
      const frame = document.getElementById('eligibility_content')
      if (frame) {
        frame.innerHTML = html
      }
    })
    .catch(error => {
      console.error('Erreur lors de la soumission:', error)
    })
  }

  validateForm(formData) {
    const income = formData.get('household_income')
    const maritalStatus = formData.get('marital_status')
    const propertyType = formData.get('property_type')

    if (!income || income <= 0) {
      alert('Veuillez indiquer vos revenus annuels')
      return false
    }

    if (!maritalStatus) {
      alert('Veuillez sélectionner votre situation familiale')
      return false
    }

    if (!propertyType) {
      alert('Veuillez sélectionner le type de logement')
      return false
    }

    return true
  }
}
