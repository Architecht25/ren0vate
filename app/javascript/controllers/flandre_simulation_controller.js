import { Controller } from "@hotwired/stimulus"

// Contrôleur dédié aux simulations Flandre post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "totalGeneral",
    "sectionTitle",
    "currentCategory",
    "selectedPrimesSummary"
  ]

  static values = {
    simulationId: Number,
    category: String
  }

  connect() {
    console.log("🎯 Flandre Simulation controller connected")
    console.log("📊 Simulation ID:", this.simulationIdValue)
    console.log("🔍 Element:", this.element)

    this.currentCategory = this.getCurrentCategory()
    this.setupPrimesData()
    this.setupGroupesPlafond()
    this.setupAutoSaveListeners()

    // Debug: vérifier quelles cartes sont présentes
    setTimeout(() => {
      console.log("🔍 Debug: vérification des cartes présentes...")
      const cartesSlugs = [
        'isolation_toiture',
        'isolation_murs_cat12',
        'isolation_murs_cat34',
        'isolation_sol',
        'ramen_deuren',
        'warmtepomp',
        'warmtepompboiler',
        'voorbereiding_isolatie',
        'voorbereiding_sanitair_elec',
        'renovation_toiture',
        'renovation_murs',
        'renovation_sol'
      ]

      cartesSlugs.forEach(slug => {
        const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
        if (carteElement) {
          console.log(`✅ Carte trouvée: ${slug}`)
          const resultTarget = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
          console.log(`   - Target result: ${resultTarget ? 'TROUVÉ' : 'MANQUANT'}`)
        } else {
          console.log(`❌ Carte manquante: ${slug}`)
        }
      })

      this.updateTotalGlobal()
      this.debouncedAutoSave() // Déclencher l'auto-save
    }, 1000)
  }

  setupAutoSaveListeners() {
    // Écouter tous les changements d'inputs dans les cartes Flandre
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('input, select')) {
        this.debouncedAutoSave();
      }
    });

    this.element.addEventListener('change', (e) => {
      if (e.target.matches('input, select')) {
        this.debouncedAutoSave();
      }
    });
  }

  getCurrentCategory() {
    // Utiliser la catégorie de la simulation au lieu du localStorage
    return this.categoryValue || 'flandre_cat2'
  }

  setupPrimesData() {
    try {
      // Récupérer les données de primes depuis le script JSON injecté
      const primesScript = document.getElementById('flandre-primes-data')
      if (primesScript) {
        this.primesData = JSON.parse(primesScript.textContent)
        console.log("📊 Données de primes Flandre chargées:", Object.keys(this.primesData).length, "primes")

        // Déclencher le recalcul de toutes les cartes après chargement des données
        setTimeout(() => {
          this.triggerCardsRecalculation()
        }, 100)
      } else {
        console.warn("⚠️ Script de données primes Flandre non trouvé")
        this.primesData = {}
      }
    } catch (error) {
      console.error("❌ Erreur lors du chargement des données primes Flandre:", error)
      this.primesData = {}
    }
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
      toiture: { "1": 0, "2": 0, "3": 4025, "4": 5750 },
      murs:    { "1": 0, "2": 0, "3": 3500, "4": 5000 },
      sol:     { "1": 0, "2": 0, "3": 1050, "4": 1500 }
    };

    console.log("🏗️ Configuration des groupes de plafond Flandre initialisée")
  }

  triggerCardsRecalculation() {
    console.log("🔄 Déclenchement du recalcul de toutes les cartes Flandre")
    const flandreCards = this.element.querySelectorAll('[data-controller*="flandre-simulation-card"]')
    flandreCards.forEach(cardElement => {
      // Déclencher un événement pour forcer le recalcul
      cardElement.dispatchEvent(new CustomEvent('flandre:force:recalculate', {
        detail: { reason: 'primes_data_loaded' }
      }))
    })
  }

  getPrimesData() {
    return this.primesData || {}
  }

  get simulationId() {
    return this.simulationIdValue ||
           parseInt(window.location.pathname.match(/\/simulations\/(\d+)/)?.[1]) ||
           null
  }

  updateTotalGlobal() {
    let total = 0
    console.log("🔄 Calcul du total global Flandre...")

    // Slugs des cartes Flandre principales (correspondant aux cartes HTML)
    const cartesSlugs = [
      'isolation_toiture',
      'isolation_murs_cat12',
      'isolation_murs_cat34',
      'isolation_sol',
      'ramen_deuren',
      'warmtepomp',
      'warmtepompboiler',
      'voorbereiding_isolatie',
      'voorbereiding_sanitair_elec',
      'renovation_toiture',
      'renovation_murs',
      'renovation_sol'
    ]

    let cartesFoundCount = 0
    let cartesWithTotal = 0

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        cartesFoundCount++
        console.log(`✅ Carte ${slug} trouvée`)

        const totalElement = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
        if (totalElement) {
          cartesWithTotal++
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
          if (montant > 0) {
            console.log(`✅ Carte ${slug}: ${montant}€ (texte: "${totalElement.textContent}")`)
          } else {
            console.log(`⚪ Carte ${slug}: 0€ (texte: "${totalElement.textContent}")`)
          }
        } else {
          console.log(`❌ Carte ${slug}: élément result non trouvé`)
          // Debug plus profond
          const allTargets = carteElement.querySelectorAll('[data-flandre-simulation-card-target]')
          console.log(`   Targets trouvés:`, Array.from(allTargets).map(el => el.dataset.flandreSimulationCardTarget))
        }
      } else {
        console.log(`❌ Carte ${slug}: carte non trouvée dans le DOM`)
      }
    })

    console.log(`📊 Résumé: ${cartesFoundCount}/${cartesSlugs.length} cartes trouvées, ${cartesWithTotal} avec target result`)

    // Ajouter le montant PEB s'il est visible
    let montantPEB = 0
    console.log("🔍 Recherche de la carte PEB...")

    // Plusieurs sélecteurs possibles pour PEB
    const pebSelectors = [
      '[data-peb-target="resultatContainer"]',
      '[data-controller="peb"] [data-peb-target="resultatContainer"]',
      '.alert[data-peb-target="resultatContainer"]'
    ]

    let pebContainer = null
    for (const selector of pebSelectors) {
      pebContainer = document.querySelector(selector)
      if (pebContainer) {
        console.log(`✅ Conteneur PEB trouvé avec sélecteur: ${selector}`)
        break
      }
    }

    if (pebContainer && !pebContainer.classList.contains('d-none')) {
      console.log("✅ Conteneur PEB visible")
      const pebMontant = pebContainer.querySelector('[data-peb-target="montantCalcule"]')
      if (pebMontant) {
        const montantText = pebMontant.textContent.trim()
        console.log(`🔍 Texte PEB brut: "${montantText}"`)

        // Améliorer le parsing du montant PEB
        const cleanText = montantText.replace(/[€\s\.]/g, '').replace(',', '.')
        montantPEB = parseFloat(cleanText) || 0

        if (montantPEB > 0) {
          total += montantPEB
          console.log(`🏢 Prime PEB: ${montantPEB}€`)
        } else {
          console.log(`⚪ Prime PEB: 0€ (texte: "${montantText}")`)
        }
      } else {
        console.log("❌ Élément montantCalcule PEB non trouvé")
      }
    } else {
      if (!pebContainer) {
        console.log("❌ Conteneur PEB non trouvé dans le DOM")
      } else {
        console.log("❌ Conteneur PEB masqué (classe d-none)")
      }
    }

    console.log(`🎯 Total global Flandre calculé: ${total}€${montantPEB > 0 ? ` (dont PEB: ${montantPEB}€)` : ''}`)

    // Mettre à jour l'affichage du total
    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`
      console.log(`📝 Total affiché: ${this.totalGeneralTarget.textContent}`)

      // Animation visuelle
      this.totalGeneralTarget.classList.add('updated')
      setTimeout(() => {
        this.totalGeneralTarget.classList.remove('updated')
      }, 300)
    } else {
      console.log("❌ Target totalGeneral non trouvé!")
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('flandre:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))

    // Mettre à jour le résumé des primes sélectionnées
    this.updateSelectedPrimesSummary()
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    console.log("🔄 Carte mise à jour - recalcul du total global")
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedFlandreCategory', newCategory)
    // Mettre à jour aussi la catégorie estimée pour cohérence
    const categoryNumber = newCategory.replace('flandre_cat', '')
    localStorage.setItem('flandreCategorieEstimee', categoryNumber)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes Flandre
    const flandreCards = this.element.querySelectorAll('[data-controller*="flandre-simulation-card"]')
    flandreCards.forEach(cardElement => {
      // Émettre un événement pour que chaque carte se mette à jour
      cardElement.dispatchEvent(new CustomEvent('flandre:category:changed', {
        detail: { categorie: newCategory }
      }))
    })

    // Recalculer le total après que toutes les cartes se soient mises à jour
    setTimeout(() => {
      this.updateTotalGlobal()
    }, 100)

    // Mettre à jour l'affichage de la catégorie
    this.updateCategoryDisplay(newCategory)
  }

  updateSectionTitle() {
    if (!this.hasSectionTitleTarget) return

    const categoryNames = {
      'flandre_cat1': 'Catégorie I (revenus très modestes)',
      'flandre_cat2': 'Catégorie II (revenus modestes)',
      'flandre_cat3': 'Catégorie III (revenus moyens-élevés)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Flandre • ${categoryName}`
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées
    const cartesSlugs = [
      'isolation_toiture',
      'isolation_murs_cat12',
      'isolation_murs_cat34',
      'isolation_sol',
      'ramen_deuren',
      'warmtepomp',
      'warmtepompboiler',
      'voorbereiding_isolatie',
      'voorbereiding_sanitair_elec',
      'renovation_toiture',
      'renovation_murs',
      'renovation_sol'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace(/[€\s\.]/g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0

          if (montant > 0) {
            // Trouver le titre de la carte
            const titleElement = carteElement.querySelector('h6, h5, .card-title')
            const title = titleElement ? titleElement.textContent.trim() : slug

            selectedPrimes.push({
              title: title.replace(/Prime\s*/i, '').trim(),
              amount: montant
            })
          }
        }
      }
    })

    // Générer le HTML du résumé
    let summaryHTML = ''
    if (selectedPrimes.length > 0) {
      summaryHTML = selectedPrimes.map(prime =>
        `<div class="d-flex justify-content-between align-items-center py-1 border-bottom">
          <span class="small">${prime.title}</span>
          <span class="badge bg-secondary">${prime.amount.toLocaleString('fr-FR')} €</span>
        </div>`
      ).join('')
    } else {
      summaryHTML = '<p class="text-muted small mb-0">Aucune prime sélectionnée</p>'
    }

    this.selectedPrimesSummaryTarget.innerHTML = summaryHTML
  }

  // AUTO-SAVE POUR SIMULATIONS POST-LOGIN

  // Méthode d'auto-save complète
  autoSave() {
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

    if (!this.simulationId) return;

    // Collecter toutes les données des inputs
    const userInputs = {};
    const allInputs = this.element.querySelectorAll('input[data-slug], select[data-slug]');

    allInputs.forEach(input => {
      const slug = input.dataset.slug;
      if (slug) {
        let value = null;

        if (input.type === 'checkbox') {
          value = input.checked ? 1 : 0;
        } else if (input.type === 'number') {
          value = parseFloat(input.value) || 0;
        } else if (input.tagName === 'SELECT') {
          value = input.value;
        } else {
          value = input.value;
        }

        if (value !== null && value !== '' && value !== '0') {
          userInputs[slug] = value;
        }
      }
    });

    // Sauvegarder via API
    if (Object.keys(userInputs).length > 0) {
      console.log('💾 Sauvegarde Flandre des données:', Object.keys(userInputs).length, 'saisies');

      // Calculer le total côté client pour l'envoyer aussi
      const calculatedTotal = this.calculateCurrentTotal();

      fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user_inputs: userInputs,
          calculated_total: calculatedTotal
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          console.log("✅ Auto-save Flandre réussi:", data.total_amount, "€");

          // Distribuer les montants calculés aux cartes individuelles
          this.updateCardsWithCalculatedAmounts(data.updated_cards);

          // Déclencher l'événement pour mettre à jour le composant d'économie
          this.dispatchSavingsUpdateEvent(data);

          this.showSaveIndicator('success', data.total_amount);
        } else {
          console.error("❌ Erreur auto-save Flandre:", data.error);
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Flandre:", error);
        this.showSaveIndicator('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    // Utiliser la même logique que updateTotalGlobal
    const cartesSlugs = [
      'isolation_toiture',
      'isolation_murs_cat12',
      'isolation_murs_cat34',
      'isolation_sol',
      'ramen_deuren',
      'warmtepomp',
      'warmtepompboiler',
      'voorbereiding_isolatie',
      'voorbereiding_sanitair_elec',
      'renovation_toiture',
      'renovation_murs',
      'renovation_sol'
    ]

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
        }
      }
    })

    console.log(`📊 Total calculé côté client: ${total} €`)
    return total;
  }

  // Sauvegarde débounced pour éviter trop d'appels
  debouncedAutoSave() {
    clearTimeout(this.saveTimeout);
    this.saveTimeout = setTimeout(() => this.autoSave(), 1000);
  }

  // Indicateur visuel de sauvegarde
  showSaveIndicator(status, amount = null) {
    const indicator = document.getElementById('save-indicator') || this.createSaveIndicator();

    const message = status === 'success'
      ? `Simulation sauvegardée ! Total calculé: ${amount}€`
      : 'Erreur sauvegarde simulation'

    indicator.className = `position-fixed top-0 end-0 m-3 alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show`;
    indicator.style.zIndex = '9999';
    indicator.innerHTML = `
      <i class="bi bi-${status === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
      ${message}
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

  // Méthode pour mettre à jour l'affichage de la catégorie
  updateCategoryDisplay(category) {
    if (!this.hasCurrentCategoryTarget) return

    const categoryNames = {
      'flandre_cat1': 'Catégorie I',
      'flandre_cat2': 'Catégorie II',
      'flandre_cat3': 'Catégorie III'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

    console.log(`📋 Catégorie affichée: ${categoryName}`)
  }

  // Méthode appelée par les actions des cartes (compatibilité)
  saveUserInput() {
    this.debouncedAutoSave()
  }

  // Distribuer les montants calculés aux cartes individuelles
  updateCardsWithCalculatedAmounts(updatedCards) {
    if (!updatedCards) return

    // Parcourir toutes les catégories dans la réponse
    Object.keys(updatedCards).forEach(categoryKey => {
      const categoryData = updatedCards[categoryKey]
      if (!categoryData.primes) return

      // Parcourir toutes les primes de cette catégorie
      categoryData.primes.forEach(prime => {
        const slug = prime.slug
        const calculatedAmount = prime.calculated_amount || 0

        // Trouver la carte correspondante et mettre à jour son span
        const cardElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-flandre-simulation-card-target="result"]')
          if (resultSpan) {
            const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
            resultSpan.textContent = `${formattedAmount} €`
            console.log(`💰 Carte ${slug} mise à jour: ${formattedAmount}€`)
          }
        }
      })
    })

    // Recalculer le total global après mise à jour des cartes
    this.updateTotalGlobal()
  }

  // Nouvelle méthode pour déclencher l'événement de mise à jour du composant d'économie
  dispatchSavingsUpdateEvent(data) {
    const event = new CustomEvent('savings:update', {
      detail: {
        total_amount: data.total_amount,
        savings_data: data.savings_data
      },
      bubbles: true
    });

    document.dispatchEvent(event);
    console.log("💰 Événement savings:update déclenché", data.savings_data);
  }

  // Méthode pour calculer le montant avec plafond de groupe
  calculateMontantAvecPlafond(slug, montantPropose) {
    const currentCategory = this.categorieValue || window.flandreCurrentCategory || "3"

    if (["1", "2"].includes(currentCategory)) {
      return { montant: montantPropose, resteDisponible: Infinity }
    }

    let groupe = null

    for (const [g, slugs] of Object.entries(this.groupesPlafond || {})) {
      if (slugs.includes(slug)) {
        groupe = g
        break
      }
    }

    if (!groupe) return { montant: montantPropose, resteDisponible: Infinity }

    const plafond = this.plafondsParGroupeEtCategorie[groupe][currentCategory] || Infinity
    const slugsGroupe = this.groupesPlafond[groupe]

    const totalDejaAffiche = slugsGroupe.reduce((somme, s) => {
      if (s === slug) return somme // on ignore la carte en cours
      const span = document.querySelector(`[data-flandre-simulation-card-slug-value="${s}"] [data-flandre-simulation-card-target="result"]`)
      const val = parseFloat(span?.textContent.replace(/[€\s\.]/g, '').replace(',', '.') || 0)
      return somme + (isNaN(val) ? 0 : val)
    }, 0)

    const plafondRestant = plafond - totalDejaAffiche
    const montantFinal = Math.min(montantPropose, plafondRestant)

    return { montant: montantFinal, resteDisponible: plafondRestant }
  }
}
