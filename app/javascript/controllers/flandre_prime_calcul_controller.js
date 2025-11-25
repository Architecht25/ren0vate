import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionTitle", "totalGeneral", "selectedPrimesSummary", "currentCategory"]

  connect() {
    console.log("🎯 Contrôleur Flandre Prime Calcul connecté")
    this.setupPrimesData()
    this.setupGroupesPlafond()
    this.setupEventListeners()
    this.updateSectionTitle()
    this.setupAutoSaveRestore()
  }

  setupGroupesPlafond() {
    // Configuration des groupes de plafond pour Flandre
    this.groupesPlafond = {
      toiture: ["isolation_toiture", "renovation_toiture"],
      murs: ["isolation_murs_cat34", "renovation_murs"],
      sol: ["isolation_sol", "renovation_sol"]
    };

    // Plafonds par groupe et par catégorie pour Flandre
    this.plafondsParGroupeEtCategorie = {
      toiture: { "1": Infinity, "2": Infinity, "3": 4025, "4": 5750 },
      murs:    { "1": Infinity, "2": Infinity, "3": 3500, "4": 5000 },
      sol:     { "1": Infinity, "2": Infinity, "3": 1050, "4": 1500 }
    };
  }

  setupEventListeners() {
    // Écouter les événements de mise à jour des cartes enfants
    this.element.addEventListener('flandre:card:updated', this.cardUpdated.bind(this))

    // Écouter les changements de catégorie depuis le test d'éligibilité
    document.addEventListener('flandre:category:changed', (event) => {
      this.changeCategory(event.detail.category)
    })
  }

  setupPrimesData() {
    try {
      // Récupérer les données de primes depuis le script JSON injecté
      const primesScript = document.getElementById('flandre-primes-data')
      if (primesScript) {
        this.primesData = JSON.parse(primesScript.textContent)
        console.log("📊 Données de primes Flandre chargées:", Object.keys(this.primesData).length, "primes")
      } else {
        console.warn("⚠️ Script de données primes Flandre non trouvé")
        this.primesData = {}
      }

      // Récupérer les données de simulation
      const simulationScript = document.getElementById('simulation-category-data')
      if (simulationScript) {
        const simulationData = JSON.parse(simulationScript.textContent)
        this.currentCategory = simulationData.category || '1'
        this.simulationId = simulationData.simulationId
        console.log("🎯 Catégorie actuelle:", this.currentCategory, "Simulation ID:", this.simulationId)
      } else {
        this.currentCategory = '1'
        this.simulationId = null
      }

      // Exposer les données globalement
      window.flandreCurrentCategory = this.currentCategory
      window.flandrePrimesData = this.primesData
    } catch (error) {
      console.error("❌ Erreur lors du chargement des données Flandre:", error)
      this.primesData = {}
      this.currentCategory = '1'
    }
  }

  setupAutoSaveRestore() {
    // Restaurer les valeurs sauvegardées depuis la base de données
    if (this.simulationId) {
      // Récupérer les valeurs depuis les data attributes si elles existent
      const allCards = this.element.querySelectorAll('[data-controller*="flandre-prime-card"]')
      allCards.forEach(card => {
        const controller = this.application.getControllerForElementAndIdentifier(card, 'flandre-prime-card')
        if (controller) {
          // Laisser le temps au contrôleur de carte de se connecter
          setTimeout(() => controller.restoreValues(), 100)
        }
      })
    }
  }

  getCurrentCategory() {
    return this.currentCategory
  }

  getPrimesData() {
    return this.primesData
  }

  updateSectionTitle() {
    if (this.hasSectionTitleTarget) {
      const categoryNames = {
        '1': 'Catégorie 1',
        '2': 'Catégorie 2',
        '3': 'Catégorie 3',
        '4': 'Catégorie 4'
      }
      this.sectionTitleTarget.textContent = `Vos primes Flandre - ${categoryNames[this.currentCategory] || 'Catégorie 1'}`
    }
  }

  updateTotalGlobal() {
    if (!this.hasTotalGeneralTarget) return

    // Calculer le total de toutes les cartes avec application des plafonds
    let total = 0
    const cartesMontants = {}

    // Première passe : collecter tous les montants sans plafond
    const allResultElements = this.element.querySelectorAll('[data-flandre-prime-card-target="result"]')
    allResultElements.forEach(element => {
      const card = element.closest('[data-flandre-prime-card-slug-value]')
      if (card) {
        const slug = card.dataset.flandrePrimeCardSlugValue
        const value = parseFloat(element.textContent.replace(/[€\s,]/g, '.').replace(/[^\d.]/g, '')) || 0
        cartesMontants[slug] = value
        console.log(`📊 Trouvé carte ${slug}: ${value}€`)
      }
    })

    // Deuxième passe : appliquer les plafonds par groupe
    const montantsFinaux = this.appliquerPlafondsGroupes(cartesMontants)

    // Calculer le total final
    total = Object.values(montantsFinaux).reduce((sum, montant) => sum + montant, 0)

    this.totalGeneralTarget.textContent = `${total.toFixed(2)} €`
    console.log("💰 Total Flandre mis à jour avec plafonds:", total.toFixed(2), "€")

    // Déclencher l'auto-save vers la base de données
    this.saveToDatabase()
  }

  appliquerPlafondsGroupes(cartesMontants) {
    if (["1", "2"].includes(this.currentCategory)) {
      // Pas de plafonds pour les catégories 1 et 2
      return cartesMontants
    }

    const montantsFinaux = { ...cartesMontants }

    // Appliquer les plafonds par groupe
    for (const [groupe, slugs] of Object.entries(this.groupesPlafond)) {
      const plafond = this.plafondsParGroupeEtCategorie[groupe][this.currentCategory] || Infinity

      // Calculer le total du groupe
      const totalGroupe = slugs.reduce((sum, slug) => sum + (cartesMontants[slug] || 0), 0)

      if (totalGroupe > plafond) {
        // Réduire proportionnellement tous les montants du groupe
        const facteur = plafond / totalGroupe
        slugs.forEach(slug => {
          if (cartesMontants[slug]) {
            montantsFinaux[slug] = cartesMontants[slug] * facteur
          }
        })
        console.log(`⚖️ Plafond appliqué au groupe ${groupe}: ${totalGroupe.toFixed(2)}€ → ${plafond.toFixed(2)}€`)
      }
    }

    return montantsFinaux
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    this.updateTotalGlobal()
  }

  // Méthode pour calculer le montant d'une carte avec application du plafond de groupe
  calculateMontantAvecPlafond(slug, montantPropose) {
    if (["1", "2"].includes(this.currentCategory)) {
      return { montant: montantPropose, resteDisponible: Infinity }
    }

    let groupe = null

    for (const [g, slugs] of Object.entries(this.groupesPlafond)) {
      if (slugs.includes(slug)) {
        groupe = g
        break
      }
    }

    if (!groupe) return { montant: montantPropose, resteDisponible: Infinity }

    const plafond = this.plafondsParGroupeEtCategorie[groupe][this.currentCategory] || Infinity
    const slugsGroupe = this.groupesPlafond[groupe]

    const totalDejaAffiche = slugsGroupe.reduce((somme, s) => {
      if (s === slug) return somme // on ignore la carte en cours
      const span = document.querySelector(`[data-flandre-prime-card-slug-value="${s}"] [data-flandre-prime-card-target="result"]`)
      const val = parseFloat(span?.textContent.replace("€", "").replace(",", ".") || 0)
      return somme + (isNaN(val) ? 0 : val)
    }, 0)

    const plafondRestant = plafond - totalDejaAffiche
    const montantFinal = Math.min(montantPropose, plafondRestant)

    return { montant: montantFinal, resteDisponible: plafondRestant }
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    console.log("🔄 Changement de catégorie Flandre:", this.currentCategory, "→", newCategory)

    this.currentCategory = newCategory
    window.flandreCurrentCategory = newCategory

    this.updateSectionTitle()

    // Notifier toutes les cartes du changement de catégorie
    this.element.dispatchEvent(new CustomEvent('flandre:category:changed', {
      detail: { category: newCategory },
      bubbles: true
    }))

    // Recalculer après le changement
    setTimeout(() => this.updateTotalGlobal(), 100)
  }

  saveToDatabase() {
    // Vérifier si la restauration est en cours
    if (window.isRestoringValues) {
      console.log('🔄 Sauvegarde Flandre ignorée: restauration en cours');
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
      console.log('⚠️ Restauration Flandre bloquée depuis > 10s, forçage de la réinitialisation');
      window.isRestoringValues = false;
    }

    if (!this.simulationId) return

    // Collecter toutes les données des inputs
    const userInputs = {}
    const allInputs = this.element.querySelectorAll('input[data-slug], select[data-slug]')

    allInputs.forEach(input => {
      const slug = input.dataset.slug
      if (slug && input.value && input.value !== '0' && input.value !== '') {
        userInputs[slug] = input.value
      }
    })

    // Sauvegarder via API
    if (Object.keys(userInputs).length > 0) {
      console.log('💾 Sauvegarde Flandre des données:', Object.keys(userInputs).length, 'saisies');

      fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ user_inputs: userInputs })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          console.log("✅ Auto-save Flandre réussi:", data.total_amount, "€")
          this.showSaveIndicator('success');
        } else {
          console.error("❌ Erreur auto-save Flandre:", data.error)
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Flandre:", error)
        this.showSaveIndicator('error');
      })
    }
  }

  saveUserInput(event) {
    // Méthode appelée directement par les inputs pour un auto-save immédiat
    const input = event.target
    const slug = input.dataset.slug

    if (!slug || !this.simulationId) return

    // Vérifier si la restauration est en cours
    if (window.isRestoringValues) {
      console.log('🔄 Sauvegarde input Flandre ignorée: restauration en cours');
      return;
    }

    const userInputs = { [slug]: input.value }

    fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ user_inputs: userInputs })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        console.log(`💾 Auto-save ${slug}:`, input.value, "→", data.total_amount, "€")
      }
    })
    .catch(error => {
      console.error("❌ Erreur auto-save:", error)
    })
  }

  // Indicateur visuel de sauvegarde
  showSaveIndicator(status) {
    const indicator = document.getElementById('save-indicator') || this.createSaveIndicator();

    indicator.className = `position-fixed top-0 end-0 m-3 alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show`;
    indicator.style.zIndex = '9999';
    indicator.innerHTML = `
      <i class="bi bi-${status === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
      ${status === 'success' ? 'Simulation Flandre sauvegardée' : 'Erreur sauvegarde Flandre'}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Masquer automatiquement après 3 secondes
    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove();
      }
    }, 3000);
  }

  createSaveIndicator() {
    const indicator = document.createElement('div');
    indicator.id = 'save-indicator';
    document.body.appendChild(indicator);
    return indicator;
  }
}
