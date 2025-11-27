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

    // Vérifier si nous sommes sur une page avec des cartes de primes
    const hasCards = this.element.querySelector('[data-flandre-simulation-card-slug-value]')

    if (!hasCards) {
      console.log("⚠️ Aucune carte de prime trouvée, arrêt du controller Flandre")
      return
    }

    console.log("✅ Cartes de primes détectées, initialisation du controller")

    // Protection contre les auto-saves trop fréquents
    this.lastAutoSaveTime = 0
    this.minAutoSaveInterval = 5000 // Minimum 5 secondes entre les auto-saves

    this.currentCategory = this.getCurrentCategory()
    this.setupPrimesData()
    this.setupGroupesPlafond()

    // Restaurer les données sauvegardées
    this.restoreSavedData()

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
    // Vérifier si nous avons des cartes de primes sur cette page
    const hasCards = this.element.querySelector('[data-flandre-simulation-card-slug-value]')

    if (!hasCards) {
      console.log("⚠️ Pas de cartes de primes sur cette page, calcul du total ignoré")
      return
    }

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

          // Parser le montant des cartes (format: "1.275,00€" ou "320,00€")
          let montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '')

          // Si c'est au format "1.275,00" (avec points de milliers), convertir en "1275.00"
          if (montantText.match(/^\d{1,3}(\.\d{3})*,\d{2}$/)) {
            // Retirer les points de milliers et remplacer virgule par point
            const parts = montantText.split(',')
            const decimales = parts[1] // Partie après la virgule = décimales
            const entier = parts[0].replace(/\./g, '') // Partie avant la virgule sans points
            montantText = entier + '.' + decimales
          } else {
            // Format simple, juste remplacer virgule par point
            montantText = montantText.replace(',', '.')
          }

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

        // Parser le montant PEB (format: "200.00 €")
        // Supprimer € et espaces, garder le point décimal
        let cleanText = montantText.replace(/[€\s]/g, '')

        // Si c'est au format "1.234.56" (avec points de milliers), convertir en "1234.56"
        if (cleanText.match(/^\d{1,3}(\.\d{3})*\.\d{2}$/)) {
          // Retirer les points de milliers mais garder le point décimal
          const parts = cleanText.split('.')
          const decimales = parts.pop() // Dernière partie = décimales
          const entier = parts.join('') // Parties précédentes = entier
          cleanText = entier + '.' + decimales
        }

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

    // Ajouter le montant Amiante s'il est visible
    let montantAmiante = 0
    console.log("🔍 Recherche de la carte Amiante...")

    const amianteContainer = document.querySelector('[data-controller="amiante"]')
    if (amianteContainer) {
      console.log("✅ Conteneur Amiante trouvé")
      const amianteMontant = amianteContainer.querySelector('[data-amiante-target="result"]')
      if (amianteMontant) {
        const montantText = amianteMontant.textContent.trim()
        console.log(`🔍 Texte Amiante brut: "${montantText}"`)

        // Parser le montant amiante (format: "4000.00 €")
        // Supprimer € et espaces, garder le point décimal
        let cleanText = montantText.replace(/[€\s]/g, '')

        // Si c'est au format "1.234.56" (avec points de milliers), convertir en "1234.56"
        if (cleanText.match(/^\d{1,3}(\.\d{3})*\.\d{2}$/)) {
          // Retirer les points de milliers mais garder le point décimal
          const parts = cleanText.split('.')
          const decimales = parts.pop() // Dernière partie = décimales
          const entier = parts.join('') // Parties précédentes = entier
          cleanText = entier + '.' + decimales
        }

        montantAmiante = parseFloat(cleanText) || 0

        if (montantAmiante > 0) {
          total += montantAmiante
          console.log(`☣️ Prime Amiante: ${montantAmiante}€`)
        } else {
          console.log(`⚪ Prime Amiante: 0€ (texte: "${montantText}")`)
        }
      } else {
        console.log("❌ Élément result Amiante non trouvé")
      }
    } else {
      console.log("❌ Conteneur Amiante non trouvé dans le DOM")
    }

    const totalMessage = []
    if (montantPEB > 0) totalMessage.push(`PEB: ${montantPEB}€`)
    if (montantAmiante > 0) totalMessage.push(`Amiante: ${montantAmiante}€`)

    console.log(`🎯 Total global Flandre calculé: ${total}€${totalMessage.length > 0 ? ` (dont ${totalMessage.join(', ')})` : ''}`)

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

    // Déclencher l'auto-save pour sauvegarder le nouveau total incluant PEB et amiante
    if (this.simulationIdValue) {
      console.log("💾 Déclenchement auto-save après mise à jour total global")
      this.debouncedAutoSave()
    }
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
    // Protection contre les auto-saves trop fréquents
    const now = Date.now()
    if (now - this.lastAutoSaveTime < this.minAutoSaveInterval) {
      console.log("🚫 Auto-save ignoré: trop fréquent (< 5 secondes)")
      return
    }

    // Vérifier si nous avons des cartes de primes sur cette page
    const hasCards = this.element.querySelector('[data-flandre-simulation-card-slug-value]')

    if (!hasCards) {
      console.log("⚠️ Pas de cartes de primes sur cette page, auto-save ignoré")
      return
    }

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

    this.lastAutoSaveTime = now

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

      fetch(`/fr/simulations/${this.simulationIdValue}/update_prime_inputs`, {
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

          // Encart de confirmation supprimé
        } else {
          console.error("❌ Erreur auto-save Flandre:", data.error);
          // Encart d'erreur supprimé
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Flandre:", error);
        // Encart d'erreur supprimé
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

    // Calculer le total des cartes normales
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
        if (totalElement) {
          // Parser le montant des cartes (format: "1.275,00€" ou "320,00€")
          let montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '')

          // Si c'est au format "1.275,00" (avec points de milliers), convertir en "1275.00"
          if (montantText.match(/^\d{1,3}(\.\d{3})*,\d{2}$/)) {
            // Retirer les points de milliers et remplacer virgule par point
            const parts = montantText.split(',')
            const decimales = parts[1] // Partie après la virgule = décimales
            const entier = parts[0].replace(/\./g, '') // Partie avant la virgule sans points
            montantText = entier + '.' + decimales
          } else {
            // Format simple, juste remplacer virgule par point
            montantText = montantText.replace(',', '.')
          }

          const montant = parseFloat(montantText) || 0
          total += montant
        }
      }
    })

    // Ajouter le montant PEB s'il est visible
    const pebSelectors = [
      '[data-peb-target="resultatContainer"]',
      '[data-controller="peb"] [data-peb-target="resultatContainer"]',
      '.alert[data-peb-target="resultatContainer"]'
    ]

    let pebContainer = null
    for (const selector of pebSelectors) {
      pebContainer = document.querySelector(selector)
      if (pebContainer) break
    }

    if (pebContainer && !pebContainer.classList.contains('d-none')) {
      const pebMontantElement = pebContainer.querySelector('.fw-bold')
      if (pebMontantElement) {
        let montantText = pebMontantElement.textContent.replace(/[€\s]/g, '')

        // Format français "4.000,00" vers "4000.00"
        if (montantText.match(/^\d{1,3}(\.\d{3})*,\d{2}$/)) {
          const parts = montantText.split(',')
          const decimales = parts[1]
          const entier = parts[0].replace(/\./g, '')
          montantText = entier + '.' + decimales
        } else {
          montantText = montantText.replace(',', '.')
        }

        const montantPEB = parseFloat(montantText) || 0
        total += montantPEB
      }
    }

    // Ajouter le montant amiante s'il est visible
    const amianteContainer = document.querySelector('[data-amiante-target="resultatContainer"]')
    if (amianteContainer && !amianteContainer.classList.contains('d-none')) {
      const amianteMontantElement = amianteContainer.querySelector('.fw-bold')
      if (amianteMontantElement) {
        let montantText = amianteMontantElement.textContent.replace(/[€\s]/g, '')

        // Format français "1.000,00" vers "1000.00"
        if (montantText.match(/^\d{1,3}(\.\d{3})*,\d{2}$/)) {
          const parts = montantText.split(',')
          const decimales = parts[1]
          const entier = parts[0].replace(/\./g, '')
          montantText = entier + '.' + decimales
        } else {
          montantText = montantText.replace(',', '.')
        }

        const montantAmiante = parseFloat(montantText) || 0
        total += montantAmiante
      }
    }

    console.log(`💰 Total complet calculé côté client (primes + PEB + amiante): ${total} €`)
    return total;
  }

  // Sauvegarde débounced pour éviter trop d'appels
  debouncedAutoSave() {
    clearTimeout(this.saveTimeout);
    // Augmentation du délai à 3 secondes pour éviter les appels trop fréquents
    this.saveTimeout = setTimeout(() => this.autoSave(), 3000);
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

  // Nouvelle méthode : Sauvegarder et calculer toutes les données Flandre (PEB/Amiante inclus)
  async saveAndCalculateAll() {
    console.log("💾 Sauvegarde et calcul de toutes les données Flandre")

    const pebData = this.collectPebData()
    const amianteData = this.collectAmianteData()
    const primesData = this.collectPrimesData()

    const userInputs = {}

    if (pebData && this.isValidPebData(pebData)) {
      userInputs.peb = pebData
    }

    if (amianteData && this.isValidAmianteData(amianteData)) {
      userInputs.amiante = amianteData
    }

    if (primesData && Object.keys(primesData).length > 0) {
      userInputs.primes = primesData
    }

    console.log("📊 Données à envoyer:", userInputs)

    if (Object.keys(userInputs).length === 0) {
      console.log("⚠️ Aucune donnée valide à sauvegarder")
      return
    }

    try {
      const response = await fetch(`/fr/simulations/${this.simulationIdValue}/update_prime_inputs`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({
          user_inputs: userInputs
        })
      })

      if (response.ok) {
        const result = await response.json()
        console.log("✅ Réponse serveur:", result)

        if (result.success) {
          // Mettre à jour les cartes avec les résultats serveur
          this.updateCardsFromServerResponse(result)
          // Le total global sera recalculé automatiquement par updateCardsFromServerResponse
          console.log("✅ Données sauvegardées et calculées avec succès")
        } else {
          console.error("❌ Erreur serveur:", result.message)
        }
      } else {
        console.error("❌ Erreur HTTP:", response.status)
      }
    } catch (error) {
      console.error("❌ Erreur lors de la sauvegarde:", error)
    }
  }

  // Collecter les données PEB
  collectPebData() {
    const labelInitial = document.getElementById('label_initial_peb')?.value
    const typeLogement = document.getElementById('type_logement_peb')?.value
    const ventilation = document.getElementById('ventilation_peb')?.value
    const labelFinal = document.getElementById('label_final_peb')?.value

    // Récupérer la catégorie depuis l'élément PEB ou la simulation
    const pebElement = document.querySelector('[data-controller="peb"]')
    const categorie = pebElement?.dataset?.pebCategorieValue || this.categoryValue || '3'

    if (!labelInitial || !typeLogement || !ventilation || !labelFinal) {
      return null
    }

    return {
      label_initial: labelInitial,
      type_logement: typeLogement,
      ventilation: ventilation,
      label_final: labelFinal,
      categorie: categorie
    }
  }

  // Collecter les données Amiante
  collectAmianteData() {
    const surfaceToiture = parseFloat(document.getElementById('surface_toiture_amiante')?.value) || 0
    const surfaceMurs = parseFloat(document.getElementById('surface_murs_amiante')?.value) || 0

    if (surfaceToiture <= 0 && surfaceMurs <= 0) {
      return null
    }

    return {
      surface_toiture: surfaceToiture,
      surface_murs: surfaceMurs
    }
  }

  // Collecter les données des primes normales
  collectPrimesData() {
    const primesData = {}

    // Rechercher tous les éléments de prime avec une valeur
    const primeInputs = document.querySelectorAll('[data-flandre-simulation-card-target="input"]')

    primeInputs.forEach(input => {
      const value = parseFloat(input.value) || 0
      if (value > 0) {
        const card = input.closest('[data-flandre-simulation-card-slug-value]')
        const slug = card?.dataset?.flandreSimulationCardSlugValue

        if (slug) {
          primesData[slug] = {
            value: value,
            type: input.dataset.type || null
          }
        }
      }
    })

    return primesData
  }

  // Valider les données PEB
  isValidPebData(data) {
    return data &&
           data.label_initial &&
           data.type_logement &&
           data.ventilation &&
           data.label_final &&
           data.categorie
  }

  // Valider les données Amiante
  isValidAmianteData(data) {
    return data &&
           (data.surface_toiture > 0 || data.surface_murs > 0)
  }

  // Restaurer les données sauvegardées depuis la base de données
  async restoreSavedData() {
    console.log("🔄 === DÉBUT RESTAURATION ===")
    console.log("🔍 simulationIdValue:", this.simulationIdValue)

    if (!this.simulationIdValue) {
      console.log("⚠️ Pas de simulation ID pour la restauration")
      return
    }

    try {
      console.log("📡 Envoi requête de restauration...")
      const response = await fetch(`/fr/simulations/${this.simulationIdValue}/restore_prime_inputs`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      console.log("📥 Réponse reçue, status:", response.status)

      if (response.ok) {
        const result = await response.json()
        console.log("✅ Données brutes reçues:", result)

        if (result.success && result.user_inputs) {
          console.log("🎯 user_inputs trouvés:", result.user_inputs)

          // Restaurer les données PEB
          if (result.user_inputs.peb) {
            console.log("🏠 Restauration PEB:", result.user_inputs.peb)
            this.restorePebData(result.user_inputs.peb)
          }

          // Restaurer les données Amiante
          if (result.user_inputs.amiante) {
            console.log("☣️ Restauration Amiante:", result.user_inputs.amiante)
            this.restoreAmianteData(result.user_inputs.amiante)
          }

          // Restaurer les autres données de primes
          Object.keys(result.user_inputs).forEach(slug => {
            if (slug !== 'peb' && slug !== 'amiante') {
              console.log(`🔧 Restauration prime ${slug}:`, result.user_inputs[slug])
              this.restorePrimeInput(slug, result.user_inputs[slug])
            }
          })

          // Recalculer après restauration
          setTimeout(() => {
            this.updateTotalGlobal()
          }, 500)
        }
      } else {
        console.log("⚠️ Erreur lors de la restauration:", response.status)
      }
    } catch (error) {
      console.error("❌ Erreur restauration:", error)
    }
  }

  // Restaurer les données PEB
  restorePebData(pebData) {
    console.log("🏠 Restauration données PEB:", pebData)

    // Trouver et déclencher le controller PEB
    const pebController = this.application.getControllerForElementAndIdentifier(
      this.element.querySelector('[data-controller*="peb"]'), 'peb'
    )

    if (pebController && pebController.restoreData) {
      pebController.restoreData(pebData)
    }
  }

  // Restaurer les données Amiante
  restoreAmianteData(amianteData) {
    console.log("🏗️ Restauration données Amiante:", amianteData)

    // Trouver et déclencher le controller Amiante
    const amianteController = this.application.getControllerForElementAndIdentifier(
      this.element.querySelector('[data-controller*="amiante"]'), 'amiante'
    )

    if (amianteController && amianteController.restoreData) {
      amianteController.restoreData(amianteData)
    }
  }

  // Restaurer une donnée de prime normale
  restorePrimeInput(slug, value) {
    console.log(`🔄 Restauration ${slug}:`, value)

    // Chercher l'input dans la carte correspondante
    const cardElement = this.element.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
    if (cardElement) {
      const input = cardElement.querySelector('[data-flandre-simulation-card-target="input"]')
      if (input) {
        input.value = value
        console.log(`✅ Valeur ${value} restaurée pour ${slug}`)
        // Déclencher les événements pour mettre à jour l'affichage et recalculer
        input.dispatchEvent(new Event('input', { bubbles: true }))
      } else {
        console.warn(`❌ Input non trouvé pour ${slug}`)
      }
    } else {
      console.warn(`❌ Carte non trouvée pour ${slug}`)
    }
  }

  // Méthode pour mettre à jour le total général affiché
  updateTotalGeneral(totalAmount) {
    console.log(`🎯 Mise à jour du total général: ${totalAmount}€`)

    if (this.hasTotalGeneralTarget) {
      // Formater le montant avec séparateurs de milliers
      const formattedAmount = new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(totalAmount || 0)

      this.totalGeneralTarget.textContent = formattedAmount
      console.log(`✅ Total général mis à jour: ${formattedAmount}`)
    } else {
      console.error(`❌ Target totalGeneral non trouvé!`)
    }
  }

  // Méthode publique pour déclencher la sauvegarde depuis les contrôleurs PEB/Amiante
  triggerSave() {
    this.saveAndCalculateAll()
  }
}
