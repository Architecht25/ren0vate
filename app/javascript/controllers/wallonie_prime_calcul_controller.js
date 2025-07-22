import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="wallonie-prime-calcul"
export default class extends Controller {
  static targets = ["sectionTitle", "grandTotal"]

  connect() {
    console.log("Wallonie Prime Calcul Controller connected")
    this.setupPrimesData()
    this.updateTotalGlobal()
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Écouter les changements de catégorie depuis l'affinage
    document.addEventListener('wallonie:category:changed', (event) => {
      console.log("🎯 Catégorie changée reçue:", event.detail.categorie)
      this.changeCategory(event.detail.categorie)
    })
  }

  setupPrimesData() {
    // Récupérer les données de primes depuis le localStorage ou depuis la page
    const primesDataElement = document.getElementById('wallonie-primes-data')
    if (primesDataElement) {
      try {
        this.primesData = JSON.parse(primesDataElement.textContent)
        console.log("Primes Wallonie chargées:", this.primesData)
      } catch (error) {
        console.error("Erreur parsing primes data:", error)
        this.primesData = {}
      }
    }

    // Récupérer la catégorie de revenus depuis le localStorage
    let storedCategory = localStorage.getItem('selectedWallonieCategory') || 'wallonie_r3'

    // S'assurer que la catégorie a le bon format (avec préfixe wallonie_)
    if (!storedCategory.startsWith('wallonie_')) {
      storedCategory = 'wallonie_' + storedCategory
    }

    this.currentCategory = storedCategory
    console.log("Catégorie Wallonie actuelle:", this.currentCategory)

    this.updateSectionTitle()
  }

  updateSectionTitle() {
    if (this.hasSectionTitleTarget) {
      const categoryMap = {
        'wallonie_r1': 'R1 (Revenus très faibles)',
        'wallonie_r2': 'R2 (Revenus faibles)',
        'wallonie_r3': 'R3 (Revenus moyens)',
        'wallonie_r4': 'R4 (Revenus élevés)',
        'wallonie_r5': 'R5 (Revenus très élevés)'
      }
      this.sectionTitleTarget.textContent = `Vos primes Wallonie - ${categoryMap[this.currentCategory] || 'Catégorie R1-R5'}`
    }
  }

  updateTotalGlobal() {
    // Calcul du total de toutes les cartes
    let total = 0
    console.log("🔍 Début calcul total global...")

    // Sélecteurs pour tous les totaux des cartes
    const totalSelectors = [
      '[data-wallonie-prime-card-target="resultAudit"]',          // Audit énergétique
      '[data-wallonie-prime-card-target="totalToiture"]',        // Total Toiture
      '[data-wallonie-prime-card-target="totalMurs"]',           // Total Murs
      '[data-wallonie-prime-card-target="totalSols"]',           // Total Sols
      '[data-wallonie-prime-card-target="totalVentilation"]',    // Total Ventilation
      '[data-wallonie-prime-card-target="totalChaudiere"]',      // Total Chaudière
      '[data-wallonie-prime-card-target="totalAmeliorationChauffage"]', // Total Amélioration Chauffage
      '[data-wallonie-prime-card-target="totalEauChaudeSanitaire"]',    // Total Eau Chaude Sanitaire
      '[data-wallonie-prime-card-target="resultMenuiseries"]',   // Menuiseries & Vitrages
      '[data-wallonie-prime-card-target="resultElectricite"]',   // Installation électrique
      '[data-wallonie-prime-card-target="resultGaz"]'            // Installation gaz
    ]

    // Calculer le total en parcourant tous les éléments
    totalSelectors.forEach(selector => {
      const element = document.querySelector(selector)
      if (element) {
        const montantText = element.textContent.replace('€', '').replace(/\s/g, '').replace(',', '.')
        const montant = parseFloat(montantText) || 0
        total += montant
        console.log(`✅ ${selector}: ${montant}€ (texte: "${element.textContent}")`)
      } else {
        console.log(`❌ ${selector}: élément non trouvé`)
      }
    })

    console.log(`🎯 Total global calculé: ${total}€`)

    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`
      console.log(`📝 Total affiché: ${this.grandTotalTarget.textContent}`)
    } else {
      console.log("❌ Target grandTotal non trouvé!")
    }
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedWallonieCategory', newCategory)
    this.updateSectionTitle()

    // Déclencher le recalcul de toutes les cartes
    const cards = this.element.querySelectorAll('[data-controller~="wallonie-prime-card"]')
    cards.forEach(card => {
      const controller = this.application.getControllerForElementAndIdentifier(card, 'wallonie-prime-card')
      if (controller && controller.recalculate) {
        controller.recalculate()
      }
    })
  }

  getCurrentCategory() {
    return this.currentCategory
  }

  getPrimesData() {
    return this.primesData
  }
}
