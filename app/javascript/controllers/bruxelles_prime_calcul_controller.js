import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionTitle", "totalGeneral", "categoryDisplay", "categoryBadge", "categoryDescription"]

  connect() {
    console.log("🎯 Bruxelles Prime Calcul controller connected")
    this.setupPrimesData()
    this.updateTotalGlobal()
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Écouter les changements de catégorie depuis l'affinage
    document.addEventListener('bruxelles:category:changed', (event) => {
      console.log("🎯 Catégorie Bruxelles changée reçue:", event.detail.categorie)
      this.changeCategory(event.detail.categorie)
    })
  }

  setupPrimesData() {
    // Récupérer les données de primes depuis le localStorage ou depuis la page
    const primesDataElement = document.getElementById('bruxelles-primes-data')
    if (primesDataElement) {
      try {
        this.primesData = JSON.parse(primesDataElement.textContent)
        console.log("Primes Bruxelles chargées:", this.primesData)
      } catch (error) {
        console.error("Erreur parsing primes data:", error)
        this.primesData = {}
      }
    }

    // Récupérer la catégorie depuis l'éligibilité
    this.currentCategory = this.getCurrentCategory()
    console.log("Catégorie Bruxelles actuelle:", this.currentCategory)

    this.updateSectionTitle()
  }

  getCurrentCategory() {
    // Vérifier localStorage pour la catégorie déterminée par l'éligibilité
    const storedCategory = localStorage.getItem("bruxellesCategorieEstimee")
    const profileType = localStorage.getItem("profileType")
    
    if (storedCategory) {
      return this.mapStoredCategoryToInternal(storedCategory, profileType)
    }
    
    return "bruxelles_cat3" // Catégorie par défaut
  }

  mapStoredCategoryToInternal(storedCategory, profileType) {
    // Mapper les catégories stockées (1,2,3) vers les catégories internes
    const categoryMap = {
      "1": "bruxelles_cat1", // Entreprises, ASBL
      "2": "bruxelles_cat2", // Syndics
      "3": "bruxelles_cat3"  // AIS, Particuliers (revenus faibles)
    }
    
    return categoryMap[storedCategory] || "bruxelles_cat3"
  }

  mapStoredCategoryToDisplay(storedCategory, profileType) {
    // Mapper les catégories stockées vers l'affichage
    const categoryMap = {
      "1": "Catégorie I",
      "2": "Catégorie II", 
      "3": "Catégorie III"
    }
    
    const baseCategory = categoryMap[storedCategory] || "Catégorie III"
    
    // Ajouter le contexte du profil pour clarification
    const profileLabels = {
      "particulier": "Particulier",
      "entreprise": "Entreprise", 
      "syndic": "Syndic",
      "bailleur": "AIS",
      "asbl": "ASBL"
    }
    
    const profileLabel = profileLabels[profileType] || ""
    
    return profileLabel ? `${baseCategory} (${profileLabel})` : baseCategory
  }

  updateSectionTitle() {
    if (this.hasSectionTitleTarget) {
      const categoryDisplayMap = {
        'bruxelles_cat1': 'Catégorie I (Entreprises/ASBL)',
        'bruxelles_cat2': 'Catégorie II (Syndics)',
        'bruxelles_cat3': 'Catégorie III (Particuliers/AIS)'
      }
      this.sectionTitleTarget.textContent = `Vos primes RENOLUTION Bruxelles - ${categoryDisplayMap[this.currentCategory] || 'Catégorie I-III'}`
    }
  }

  updateTotalGlobal() {
    // Calcul du total de toutes les cartes Bruxelles
    let total = 0
    console.log("� Début calcul total global Bruxelles...")

    // Sélecteurs pour tous les totaux des cartes Bruxelles (13 cartes principales)
    const totalSelectors = [
      '[data-bruxelles-prime-card-target="totalPrimeA"]',      // Services et études
      '[data-bruxelles-prime-card-target="totalPrimeB"]',      // Toiture et charpente
      '[data-bruxelles-prime-card-target="totalPrimeC"]',      // Isolation thermique
      '[data-bruxelles-prime-card-target="totalPrimeD"]',      // Étanchéité à l'air
      '[data-bruxelles-prime-card-target="totalPrimeE"]',      // Ventilation
      '[data-bruxelles-prime-card-target="totalPrimeF"]',      // Chauffage et eau chaude
      '[data-bruxelles-prime-card-target="totalPrimeG"]',      // Systèmes de régulation
      '[data-bruxelles-prime-card-target="totalPrimeH"]',      // Menuiseries extérieures
      '[data-bruxelles-prime-card-target="totalPrimeI"]',      // Protection solaire
      '[data-bruxelles-prime-card-target="totalPrimeJ"]',      // Systèmes d'éclairage
      '[data-bruxelles-prime-card-target="totalPrimeKL"]',     // Énergies renouvelables
      '[data-bruxelles-prime-card-target="totalPrimeM"]',      // Électroménager
      '[data-bruxelles-prime-card-target="totalPrimeZ"]'       // Autres travaux
    ]

    // Calculer le total en parcourant tous les éléments
    totalSelectors.forEach(selector => {
      const element = document.querySelector(selector)
      if (element) {
        const montantText = element.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
        const montant = parseFloat(montantText) || 0
        total += montant
        console.log(`✅ ${selector}: ${montant}€ (texte: "${element.textContent}")`)
      } else {
        console.log(`❌ ${selector}: élément non trouvé`)
      }
    })

    console.log(`🎯 Total global Bruxelles calculé: ${total}€`)

    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = `${total.toLocaleString('fr-BE')} €`
      console.log(`📝 Total affiché: ${this.totalGeneralTarget.textContent}`)
      
      // Animation de mise à jour
      this.totalGeneralTarget.classList.add('updated')
      setTimeout(() => {
        this.totalGeneralTarget.classList.remove('updated')
      }, 300)
    } else {
      console.log("❌ Target totalGeneral non trouvé!")
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('bruxelles:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    console.log("🔄 Carte mise à jour - recalcul du total global")
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedBruxellesCategory', newCategory)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes
    const cards = this.element.querySelectorAll('[data-controller~="bruxelles-prime-card"]')
    cards.forEach(card => {
      const controller = this.application.getControllerForElementAndIdentifier(card, 'bruxelles-prime-card')
      if (controller && controller.recalculate) {
        controller.recalculate()
      }
    })

    // Déclencher aussi les cartes via attribut data-controller contenant bruxelles-prime-card
    const allBruxellesCards = document.querySelectorAll('[data-controller*="bruxelles-prime-card"]')
    allBruxellesCards.forEach(card => {
      // Émettre un événement pour que toutes les cartes se mettent à jour
      card.dispatchEvent(new CustomEvent('bruxelles:category:changed', {
        detail: { categorie: newCategory }
      }))
    })
  }

  getPrimesData() {
    return this.primesData || {}
  }
}
