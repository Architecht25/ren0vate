import { Controller } from "@hotwired/stimulus"

// Contrôleur dédié aux simulations Flandre post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "totalGeneral",
    "sectionTitle",
    "currentCategory",
    "selectedPrimesSummary",
    "saveStatus"
  ]

  static values = {
    simulationId: Number,
    category: String
  }

  connect() {

    // Vérifier si nous sommes sur une page avec des cartes de primes
    const hasCards = this.element.querySelector('[data-flandre-simulation-card-slug-value]')

    if (!hasCards) {
      return
    }


    // Protection contre les auto-saves trop fréquents
    this.lastAutoSaveTime = 0
    this.minAutoSaveInterval = 5000 // Minimum 5 secondes entre les auto-saves

    this.currentCategory = this.getCurrentCategory()
    this.setupPrimesData()
    this.setupGroupesPlafond()

    // Écouter les événements de mise à jour des cartes individuelles
    this.element.addEventListener('flandre:card:updated', (e) => {
      // Mettre à jour le total global quand une carte change
      this.updateTotalGlobal()
    })

    // Restaurer les données sauvegardées
    this.restoreSavedData()

    // Attendre que les données de primes soient chargées PUIS que les cartes se connectent
    // avant de faire le premier calcul du total
    setTimeout(() => {

      // Ne calculer le total que si nous ne sommes pas en train de restaurer
      if (!window.isRestoringValues) {
        this.updateTotalGlobal()
      } else {
      }
    }, 1500)
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

  // Normalise n'importe quel format de catégorie vers le numéro ("1".."4")
  normalizeCategoryNumber(raw) {
    if (!raw) return '4'
    const s = String(raw)
    // "flandre_cat3" -> "3", ou déjà "3" -> "3"
    const m = s.match(/(\d)$/)
    return m ? m[1] : '4'
  }

  getCurrentCategory() {
    // Retourne toujours le numéro de catégorie ("1".."4")
    return this.normalizeCategoryNumber(this.categoryValue)
  }

  setupPrimesData() {
    try {
      // Récupérer les données de primes depuis le script JSON injecté
      const primesScript = document.getElementById('flandre-primes-data')
      if (primesScript) {
        this.primesData = JSON.parse(primesScript.textContent)

        // Déclencher le recalcul de toutes les cartes après chargement des données
        setTimeout(() => {
          this.triggerCardsRecalculation()
        }, 100)
      } else {
        this.primesData = {}
      }
    } catch (error) {
      this.primesData = {}
    }
  }

  setupGroupesPlafond() {
    // Configuration des groupes de plafond pour Flandre
    this.groupesPlafond = {
      toiture: ["isolation_toiture", "renovation_toiture"],
      murs: ["isolation_murs", "renovation_murs"],
      sol: ["isolation_sol", "renovation_sol"]
    };

    // Plafonds par groupe et par catégorie pour Flandre
    this.plafondsParGroupeEtCategorie = {
      toiture: { "1": 0, "2": 0, "3": 4025, "4": 5750 },
      murs:    { "1": 0, "2": 0, "3": 3500, "4": 5000 },
      sol:     { "1": 0, "2": 0, "3": 1050, "4": 1500 }
    };

  }

  triggerCardsRecalculation() {
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
      return
    }


    // Slugs des cartes Flandre principales (correspondant aux cartes HTML)
    const cartesSlugs = [
      'isolation_toiture',
      'isolation_murs',
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
    const cartesMontants = {} // Objet pour collecter les montants avant application des plafonds

    // ÉTAPE 1: Collecter tous les montants des cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-flandre-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        cartesFoundCount++

        const totalElement = carteElement.querySelector('[data-flandre-simulation-card-target="result"]')
        if (totalElement) {
          cartesWithTotal++

          // Parser le montant des cartes (format: "1.275,00€" ou "320,00€")
          let montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').trim()

          // Si le texte est vide ou invalide, utiliser 0
          if (!montantText || montantText === '-' || montantText === '--') {
            montantText = '0'
          }

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

          // Parser et s'assurer que le montant est positif
          let montant = parseFloat(montantText) || 0

          // Protection contre les valeurs négatives (ne devrait jamais arriver)
          if (montant < 0) {
            montant = 0
          }

          cartesMontants[slug] = montant
          if (montant > 0) {
          } else {
          }
        } else {
          // Debug plus profond
          const allTargets = carteElement.querySelectorAll('[data-flandre-simulation-card-target]')
          cartesMontants[slug] = 0
        }
      } else {
        cartesMontants[slug] = 0
      }
    })


    // ÉTAPE 2: Appliquer les plafonds de groupe (catégories 3 et 4 uniquement)
    const montantsFinaux = this.appliquerPlafondsGroupes(cartesMontants)

    // ÉTAPE 3: Calculer le total après application des plafonds
    let total = Object.values(montantsFinaux).reduce((sum, montant) => sum + montant, 0)

    // Ajouter le montant PEB s'il est visible
    let montantPEB = 0

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
        break
      }
    }

    if (pebContainer && !pebContainer.classList.contains('d-none')) {
      const pebMontant = pebContainer.querySelector('[data-peb-target="montantCalcule"]')
      if (pebMontant) {
        const montantText = pebMontant.textContent.trim()

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
        } else {
        }
      } else {
      }
    } else {
      if (!pebContainer) {
      } else {
      }
    }

    // Ajouter le montant Amiante s'il est visible
    let montantAmiante = 0

    const amianteContainer = document.querySelector('[data-controller="amiante"]')
    if (amianteContainer) {
      const amianteMontant = amianteContainer.querySelector('[data-amiante-target="result"]')
      if (amianteMontant) {
        const montantText = amianteMontant.textContent.trim()

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
        } else {
        }
      } else {
      }
    } else {
    }

    const totalMessage = []
    if (montantPEB > 0) totalMessage.push(`PEB: ${montantPEB}€`)
    if (montantAmiante > 0) totalMessage.push(`Amiante: ${montantAmiante}€`)


    // Mettre à jour l'affichage du total
    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`

      // Animation visuelle
      this.totalGeneralTarget.classList.add('updated')
      setTimeout(() => {
        this.totalGeneralTarget.classList.remove('updated')
      }, 300)
    } else {
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('flandre:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))

    // Mettre à jour le résumé des primes sélectionnées
    this.updateSelectedPrimesSummary()

    // Déclencher l'auto-save pour sauvegarder le nouveau total incluant PEB et amiante
    if (this.simulationIdValue) {
      this.debouncedAutoSave()
    }
  }

  // Appliquer les plafonds de groupe (catégories 3 et 4 uniquement)
  appliquerPlafondsGroupes(cartesMontants) {
    const categoryNumber = this.normalizeCategoryNumber(this.currentCategory)

    if (["1", "2"].includes(categoryNumber)) {
      return cartesMontants
    }

    const montantsFinaux = { ...cartesMontants }

    // Appliquer les plafonds par groupe
    for (const [groupe, slugs] of Object.entries(this.groupesPlafond)) {
      const plafond = this.plafondsParGroupeEtCategorie[groupe][categoryNumber] || Infinity

      // Calculer le total du groupe AVANT application du plafond
      const totalGroupe = slugs.reduce((sum, slug) => sum + (cartesMontants[slug] || 0), 0)

      if (totalGroupe > plafond && plafond > 0) {
        // Réduire proportionnellement tous les montants du groupe
        const facteur = plafond / totalGroupe

        slugs.forEach(slug => {
          if (cartesMontants[slug] && cartesMontants[slug] > 0) {
            const montantOriginal = cartesMontants[slug]
            montantsFinaux[slug] = montantOriginal * facteur
          }
        })
      } else if (totalGroupe > 0) {
      }
    }

    return montantsFinaux
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    // Normaliser : on stocke toujours le numéro ("1".."4")
    const categoryNumber = this.normalizeCategoryNumber(newCategory)
    this.currentCategory = categoryNumber
    localStorage.setItem('selectedFlandreCategory', categoryNumber)
    localStorage.setItem('flandreCategorieEstimee', categoryNumber)
    this.updateSectionTitle()


    // Déclencher le recalcul de toutes les cartes Flandre
    const flandreCards = this.element.querySelectorAll('[data-controller*="flandre-simulation-card"]')
    flandreCards.forEach(cardElement => {
      // Émettre un événement avec le numéro normalisé
      cardElement.dispatchEvent(new CustomEvent('flandre:category:changed', {
        detail: { categorie: categoryNumber }
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
      'flandre_cat3': 'Catégorie III (revenus moyens-élevés)',
      'flandre_cat4': 'Catégorie IV (tous revenus)',
      '1': 'Catégorie I (revenus très modestes)',
      '2': 'Catégorie II (revenus modestes)',
      '3': 'Catégorie III (revenus moyens-élevés)',
      '4': 'Catégorie IV (tous revenus)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Flandre • ${categoryName}`
  }

  // Parse un montant affiché en format français ("4.000,00 €" → 4000.0)
  parseFrenchAmount(text) {
    const clean = text
      .replace(/[€\s]/g, '')          // retirer € et espaces
      .replace(/\.(?=\d{3}(,|$))/g, '') // retirer les points séparateurs de milliers
      .replace(',', '.')              // virgule décimale → point
    return parseFloat(clean) || 0
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées
    const cartesSlugs = [
      'isolation_toiture',
      'isolation_murs',
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
          const montant = this.parseFrenchAmount(totalElement.textContent)

          if (montant > 0) {
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

    // Ajouter la prime PEB si visible
    const pebContainer = document.querySelector('[data-peb-target="resultatContainer"]')
    if (pebContainer && !pebContainer.classList.contains('d-none')) {
      const pebMontantEl = pebContainer.querySelector('[data-peb-target="montantCalcule"]')
      if (pebMontantEl) {
        const montant = this.parseFrenchAmount(pebMontantEl.textContent)
        if (montant > 0) {
          selectedPrimes.push({ title: 'Prime PEB (label énergétique)', amount: montant })
        }
      }
    }

    // Ajouter la prime Amiante si non nulle
    const amianteResultEl = document.querySelector('[data-amiante-target="result"]')
    if (amianteResultEl) {
      const montant = this.parseFrenchAmount(amianteResultEl.textContent)
      if (montant > 0) {
        selectedPrimes.push({ title: 'Prime désamiantage', amount: montant })
      }
    }

    // Générer le HTML du résumé
    let summaryHTML = ''
    if (selectedPrimes.length > 0) {
      summaryHTML = selectedPrimes.map(prime =>
        `<div class="d-flex justify-content-between align-items-center py-1 border-bottom">
          <span class="small">${prime.title}</span>
          <span class="badge bg-secondary">${prime.amount.toLocaleString('fr-FR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })} €</span>
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
      return
    }

    // Vérifier si nous avons des cartes de primes sur cette page
    const hasCards = this.element.querySelector('[data-flandre-simulation-card-slug-value]')

    if (!hasCards) {
      return
    }

    // Vérifier si la restauration est en cours
    if (window.isRestoringValues) {
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
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

      // Calculer le total côté client pour l'envoyer aussi
      const calculatedTotal = this.calculateCurrentTotal();

      this.showSaveStatus('saving');

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

          // Distribuer les montants calculés aux cartes individuelles
          this.updateCardsWithCalculatedAmounts(data.updated_cards);

          this.showSaveStatus('saved');
        } else {
          this.showSaveStatus('error');
        }
      })
      .catch(error => {
        this.showSaveStatus('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    const cartesSlugs = [
      'isolation_toiture', 'isolation_murs', 'isolation_sol',
      'ramen_deuren', 'warmtepomp', 'warmtepompboiler',
      'voorbereiding_isolatie', 'voorbereiding_sanitair_elec',
      'renovation_toiture', 'renovation_murs', 'renovation_sol'
    ]

    cartesSlugs.forEach(slug => {
      const totalElement = document.querySelector(
        `[data-flandre-simulation-card-slug-value="${slug}"] [data-flandre-simulation-card-target="result"]`
      )
      if (totalElement) total += this.parseFrenchAmount(totalElement.textContent)
    })

    // PEB
    const pebContainer = document.querySelector('[data-peb-target="resultatContainer"]')
    if (pebContainer && !pebContainer.classList.contains('d-none')) {
      const pebEl = pebContainer.querySelector('[data-peb-target="montantCalcule"]')
      if (pebEl) total += this.parseFrenchAmount(pebEl.textContent)
    }

    // Amiante
    const amianteEl = document.querySelector('[data-amiante-target="result"]')
    if (amianteEl) total += this.parseFrenchAmount(amianteEl.textContent)

    return total;
  }

  // Sauvegarde débounced pour éviter trop d'appels
  debouncedAutoSave() {
    clearTimeout(this.saveTimeout);
    this.showSaveStatus('pending');
    // Augmentation du délai à 3 secondes pour éviter les appels trop fréquents
    this.saveTimeout = setTimeout(() => this.autoSave(), 3000);
  }

  // Afficher l'état de sauvegarde dans le panneau total
  showSaveStatus(state) {
    if (!this.hasSaveStatusTarget) return
    const el = this.saveStatusTarget
    clearTimeout(this.saveStatusTimer)
    el.classList.remove('d-none')
    if (state === 'pending') {
      el.innerHTML = '<small class="text-muted"><i class="bi bi-three-dots me-1"></i>Saisie en cours...</small>'
    } else if (state === 'saving') {
      el.innerHTML = '<small class="text-muted"><i class="bi bi-arrow-repeat spin me-1"></i>Sauvegarde...</small>'
    } else if (state === 'saved') {
      el.innerHTML = '<small style="color: var(--ren0vate-success);"><i class="bi bi-cloud-check me-1"></i>Sauvegardé</small>'
      this.saveStatusTimer = setTimeout(() => el.classList.add('d-none'), 4000)
    } else if (state === 'error') {
      el.innerHTML = '<small class="text-danger"><i class="bi bi-exclamation-circle me-1"></i>Erreur de sauvegarde</small>'
      this.saveStatusTimer = setTimeout(() => el.classList.add('d-none'), 6000)
    }
  }

  // Méthode pour mettre à jour l'affichage de la catégorie
  updateCategoryDisplay(category) {
    if (!this.hasCurrentCategoryTarget) return

    const categoryNames = {
      'flandre_cat1': 'Catégorie I',
      'flandre_cat2': 'Catégorie II',
      'flandre_cat3': 'Catégorie III',
      'flandre_cat4': 'Catégorie IV',
      '1': 'Catégorie I',
      '2': 'Catégorie II',
      '3': 'Catégorie III',
      '4': 'Catégorie IV'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

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
          }
        }
      })
    })

    // Recalculer le total global après mise à jour des cartes
    this.updateTotalGlobal()
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


    if (Object.keys(userInputs).length === 0) {
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

        if (result.success) {
          // Mettre à jour les cartes avec les résultats serveur
          this.updateCardsFromServerResponse(result)
          // Le total global sera recalculé automatiquement par updateCardsFromServerResponse
        } else {
        }
      } else {
      }
    } catch (error) {
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
    const toitureEl = document.getElementById('surface_toiture_amiante')
    const mursEl    = document.getElementById('surface_murs_amiante')

    // La carte n'est pas présente sur cette page
    if (!toitureEl && !mursEl) return null

    return {
      surface_toiture: parseFloat(toitureEl?.value) || 0,
      surface_murs:    parseFloat(mursEl?.value)    || 0
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
    return data !== null && data !== undefined
  }

  // Restaurer les données sauvegardées depuis la base de données
  async restoreSavedData() {

    if (!this.simulationIdValue) {
      return
    }

    // Activer le flag de restauration pour éviter les auto-saves concurrents
    window.isRestoringValues = true
    window.restorationStartTime = Date.now()

    try {
      const response = await fetch(`/fr/simulations/${this.simulationIdValue}/restore_prime_inputs`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })


      if (response.ok) {
        const result = await response.json()

        if (result.success && result.user_inputs) {

          // Restaurer les données PEB
          if (result.user_inputs.peb) {
            this.restorePebData(result.user_inputs.peb)
          }

          // Restaurer les données Amiante
          if (result.user_inputs.amiante) {
            this.restoreAmianteData(result.user_inputs.amiante)
          }

          // Restaurer les autres données de primes
          Object.keys(result.user_inputs).forEach(slug => {
            if (slug !== 'peb' && slug !== 'amiante') {
              this.restorePrimeInput(slug, result.user_inputs[slug])
            }
          })

          // Attendre que toutes les cartes aient recalculé, puis recalculer le total
          setTimeout(() => {
            window.isRestoringValues = false
            window.restorationStartTime = null

            // Force le recalcul de toutes les cartes
            this.triggerCardsRecalculation()

            // Puis mettre à jour le total
            setTimeout(() => {
              this.updateTotalGlobal()
            }, 200)
          }, 800)
        } else {
          // Désactiver le flag même en cas d'erreur
          window.isRestoringValues = false
          window.restorationStartTime = null
        }
      } else {
        window.isRestoringValues = false
        window.restorationStartTime = null
      }
    } catch (error) {
      window.isRestoringValues = false
      window.restorationStartTime = null
    }
  }

  // Restaurer les données PEB
  restorePebData(pebData) {

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

    // Chercher l'élément (input ou select) avec ce slug
    const element = this.element.querySelector(`[data-slug="${slug}"]`)

    if (element) {
      element.value = value

      // Déclencher les événements appropriés selon le type d'élément
      if (element.tagName === 'SELECT') {
        element.dispatchEvent(new Event('change', { bubbles: true }))
      } else {
        element.dispatchEvent(new Event('input', { bubbles: true }))
      }
    } else {
    }
  }

  // Méthode pour mettre à jour le total général affiché
  updateTotalGeneral(totalAmount) {

    if (this.hasTotalGeneralTarget) {
      // Formater le montant avec séparateurs de milliers
      const formattedAmount = new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(totalAmount || 0)

      this.totalGeneralTarget.textContent = formattedAmount
    } else {
    }
  }

  // Méthode publique pour déclencher la sauvegarde depuis les contrôleurs PEB/Amiante
  triggerSave() {
    this.saveAndCalculateAll()
  }
}
