import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionTitle", "totalGeneral", "categoryDisplay", "categoryBadge", "categoryDescription"]

  connect() {
    console.log("🎯 Bruxelles Prime Calcul controller connected")
    this.setupPrimesData()
    this.setupEventListeners()
    this.updateTotalGlobal()
  }

  setupEventListeners() {
    // Écouter les changements de catégorie depuis l'affinage
    document.addEventListener('bruxelles:category:changed', (event) => {
      console.log("🎯 Catégorie Bruxelles changée reçue:", event.detail.categorie)
      this.changeCategory(event.detail.categorie)
    })

    // Écouter les mises à jour des cartes enfants
    document.addEventListener('bruxelles:card:updated', () => {
      this.updateTotalGlobal()
    })
  }

  setupPrimesData() {
    // Récupérer les données de primes depuis le DOM
    const primesDataElement = document.getElementById('bruxelles-primes-data')
    if (primesDataElement) {
      try {
        this.primesData = JSON.parse(primesDataElement.textContent)
        console.log("✅ Données primes Bruxelles chargées:", Object.keys(this.primesData).length, "primes")
      } catch (error) {
        console.error("❌ Erreur parsing primes data:", error)
        this.primesData = {}
      }
    } else {
      console.warn("⚠️ Element bruxelles-primes-data non trouvé")
      this.primesData = {}
    }

    // Déterminer la catégorie actuelle
    this.currentCategory = this.getCurrentCategory()
    console.log("🎯 Catégorie Bruxelles actuelle:", this.currentCategory)

    // Mettre à jour l'affichage
    this.updateSectionTitle()
  }

  getCurrentCategory() {
    // 1. Vérifier localStorage pour la catégorie déterminée par l'éligibilité
    const storedCategory = localStorage.getItem("bruxellesCategorieEstimee")
    const profileType = localStorage.getItem("profileType")

    if (storedCategory) {
      return this.mapStoredCategoryToInternal(storedCategory, profileType)
    }

    // 2. Pour les tests : forcer catégorie 3 (primes maximales) si pas d'autre info
    console.log("🧪 Mode test : application catégorie 3 (primes maximales)")
    localStorage.setItem("bruxellesCategorieEstimee", "3")
    return "bruxelles_cat3"
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
    // Calculer le total en parcourant toutes les cartes actives
    let total = 0
    console.log("🔄 Calcul du total global Bruxelles...")

    // Sélectionner toutes les cartes Bruxelles avec leur target total
    const cardElements = this.element.querySelectorAll('[data-controller*="bruxelles-prime-card"]')

    cardElements.forEach(cardElement => {
      const totalElement = cardElement.querySelector('[data-bruxelles-prime-card-target="total"]')
      if (totalElement) {
        const montantText = totalElement.textContent.replace(/[€\s\.]/g, '').replace(',', '.')
        const montant = parseFloat(montantText) || 0
        total += montant

        if (montant > 0) {
          console.log(`✅ Carte ${cardElement.dataset.bruxellesPrimeCardSlugValue || 'unknown'}: ${montant}€`)
        }
      }
    })

    console.log(`🎯 Total global Bruxelles: ${total}€`)

    // Mettre à jour l'affichage du total
    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = `${total.toLocaleString('fr-BE')} €`

      // Animation visuelle
      this.totalGeneralTarget.classList.add('updated')
      setTimeout(() => {
        this.totalGeneralTarget.classList.remove('updated')
      }, 300)
    }

    // Émettre un événement pour notifier le changement de total
    document.dispatchEvent(new CustomEvent('bruxelles:total:calculated', {
      detail: { total, category: this.currentCategory }
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

    // Déclencher le recalcul de toutes les cartes Bruxelles
    const bruxellesCards = this.element.querySelectorAll('[data-controller*="bruxelles-prime-card"]')
    bruxellesCards.forEach(cardElement => {
      // Émettre un événement pour que chaque carte se mette à jour
      cardElement.dispatchEvent(new CustomEvent('bruxelles:category:changed', {
        detail: { categorie: newCategory }
      }))
    })

    // Recalculer le total après que toutes les cartes se soient mises à jour
    setTimeout(() => {
      this.updateTotalGlobal()
    }, 100)
  }

  getPrimesData() {
    return this.primesData || {}
  }
}
