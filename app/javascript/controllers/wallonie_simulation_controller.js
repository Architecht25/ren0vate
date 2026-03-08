import { Controller } from "@hotwired/stimulus"

// Contrôleur dédié aux simulations Wallonie post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "grandTotal",
    "sectionTitle",
    "currentCategory",
    "selectedPrimesSummary"
  ]

  static values = {
    simulationId: Number
  }

  connect() {
    console.log("🎯 Wallonie Simulation controller connected")
    console.log("📊 Simulation ID:", this.simulationIdValue)

    this.primesData = []
    this.backendCalculatedTotal = 0  // Stocker le total calculé par le backend
    this.currentCategory = this.getCurrentCategory()
    this.setupAutoSaveListeners()

    // Charger les données des primes
    this.loadPrimesData()

    // Restaurer les données sauvegardées
    this.restoreSavedData()

    // Déclencher le premier calcul
    setTimeout(() => {
      this.updateTotalGlobal()
    }, 500)
  }

  setupAutoSaveListeners() {
    // Écouter tous les changements d'inputs dans les cartes Wallonie
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

    // Écouter les événements des contrôleurs enfants
    this.element.addEventListener('wallonie:card-changed', (e) => {
      console.log(`🔄 Carte Wallonie modifiée: ${e.detail.slug}`);
      this.debouncedAutoSave();
    });
  }

  getCurrentCategory() {
    // Récupérer la catégorie depuis localStorage ou par défaut
    return localStorage.getItem('selectedWallonieCategory') || 'wallonie_r4'
  }

  get simulationId() {
    return this.simulationIdValue ||
           parseInt(window.location.pathname.match(/\/simulations\/(\d+)/)?.[1]) ||
           null
  }

  async loadPrimesData() {
    try {
      const response = await fetch('/assets/data/primes_wallonie.json')
      if (response.ok) {
        this.primesData = await response.json()
        console.log("✅ Données primes Wallonie chargées:", Object.keys(this.primesData).length, "primes")
        console.log("🎯 Catégorie Wallonie actuelle:", this.currentCategory)
      } else {
        console.error("❌ Erreur chargement primes Wallonie:", response.status)
      }
    } catch (error) {
      console.error("❌ Erreur chargement primes Wallonie:", error)
    }
  }

  getPrimesData() {
    return this.primesData || {}
  }

  updateTotalGlobal() {
    // Utiliser le total calculé par le backend si disponible
    let total = this.backendCalculatedTotal || 0;
    console.log("🔄 Mise à jour du total global Wallonie avec total backend:", total, "€");
    console.log("🔍 DEBUG - backendCalculatedTotal:", this.backendCalculatedTotal);

    // Si on a un total backend, on l'utilise directement (plus fiable)
    if (this.backendCalculatedTotal && this.backendCalculatedTotal > 0) {
      total = this.backendCalculatedTotal;
      console.log("✅ Utilisation du total backend fiable:", total, "€");
    } else {
      console.log("📊 Fallback: calcul depuis les spans (backend non disponible)...");

      // Slugs des cartes Wallonie principales (basés sur les logs de connexion)
      const cartesSlugs = [
        'wallonie_realisation_audit_logement',
        'wallonie_toiture_global',
        'wallonie_murs_global',
        'wallonie_sols_global',
        'wallonie_ventilation_global',
        'wallonie_chaudiere_global',
        'wallonie_amelioration_chauffage_global',
        'wallonie_eau_chaude_sanitaire_global',
        'wallonie_menuiseries_vitrages',
        'wallonie_installation_electrique',
        'wallonie_installation_gaz'
      ]

      // Calculer le total en parcourant toutes les cartes (utiliser les bons sélecteurs)
      cartesSlugs.forEach(slug => {
        const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
        if (carteElement) {
          const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
          if (totalElement) {
            const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
            const montant = parseFloat(montantText) || 0
            total += montant
            if (montant > 0) {
              console.log(`✅ Carte ${slug}: ${montant}€`)
            }
          } else {
            console.log(`❌ Carte ${slug}: élément total non trouvé`)
          }
        } else {
          console.log(`❌ Carte ${slug}: carte non trouvée`)
        }
      })
    }

    console.log(`🎯 Total global Wallonie calculé: ${total}€`)

    // Mettre à jour l'affichage du total
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`
      console.log(`📝 Total affiché: ${this.grandTotalTarget.textContent}`)

      // Animation visuelle
      this.grandTotalTarget.classList.add('updated')
      setTimeout(() => {
        this.grandTotalTarget.classList.remove('updated')
      }, 300)
    } else {
      console.log("❌ Target grandTotal non trouvé!")
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('wallonie:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))

    // Déclencher l'événement de mise à jour des économies
    this.dispatchSavingsUpdateEvent({
      total_amount: total,
      savings_data: null // sera calculé côté serveur lors du prochain appel AJAX
    });

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
    localStorage.setItem('selectedWallonieCategory', newCategory)
    // Mettre à jour aussi la catégorie estimée pour cohérence (extraire le numéro)
    const categoryNumber = newCategory.replace('wallonie_r', '')
    localStorage.setItem('wallonieCategorieEstimee', categoryNumber)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes Wallonie
    const wallonieCards = this.element.querySelectorAll('[data-controller*="wallonie-simulation-card"]')
    wallonieCards.forEach(cardElement => {
      // Émettre un événement pour que chaque carte se mette à jour
      cardElement.dispatchEvent(new CustomEvent('wallonie:category:changed', {
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
      'wallonie_r1': 'Revenus R1 (très modestes)',
      'wallonie_r2': 'Revenus R2 (modestes)',
      'wallonie_r3': 'Revenus R3 (moyens)',
      'wallonie_r4': 'Revenus R4 (moyens-supérieurs)',
      'wallonie_r5': 'Revenus R5 (élevés)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Wallonie • ${categoryName}`
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées (utiliser les bons slugs)
    const cartesSlugs = [
      'wallonie_realisation_audit_logement',
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global',
      'wallonie_menuiseries_vitrages',
      'wallonie_installation_electrique',
      'wallonie_installation_gaz'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
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
      console.log('🔄 Sauvegarde Wallonie ignorée: restauration en cours');
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
      console.log('⚠️ Restauration Wallonie bloquée depuis > 10s, forçage de la réinitialisation');
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
      console.log('💾 Sauvegarde Wallonie des données:', Object.keys(userInputs).length, 'saisies');

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
          console.log("✅ Auto-save Wallonie réussi:", data.total_amount, "€");

          // Stocker le total calculé par le backend
          this.backendCalculatedTotal = data.total_amount || 0;

          // Mettre à jour les spans individuels avec les détails du backend
          if (data.updated_cards) {
            this.updateIndividualPrimeDisplays(data.updated_cards);
            // Émettre un événement pour que les cartes enfants se mettent à jour
            this.emitPrimeUpdateEvent(data.updated_cards);
          }

          // Mettre à jour le total général avec le vrai total backend
          this.updateTotalGlobal();

          // Déclencher l'événement pour mettre à jour le composant d'économie
          this.dispatchSavingsUpdateEvent(data);

          this.showSaveIndicator('success', data.total_amount);
        } else {
          console.error("❌ Erreur auto-save Wallonie:", data.error);
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Wallonie:", error);
        this.showSaveIndicator('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    // Utiliser la même logique que updateTotalGlobal (slugs corrigés)
    const cartesSlugs = [
      'wallonie_realisation_audit_logement',
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global',
      'wallonie_menuiseries_vitrages',
      'wallonie_installation_electrique',
      'wallonie_installation_gaz'
    ]

    // Calculer le total en parcourant toutes les cartes (utiliser les bons sélecteurs)
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
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
      'wallonie_r1': 'Revenus R1',
      'wallonie_r2': 'Revenus R2',
      'wallonie_r3': 'Revenus R3',
      'wallonie_r4': 'Revenus R4',
      'wallonie_r5': 'Revenus R5'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

    console.log(`📋 Catégorie affichée: ${categoryName}`)
  }

  // Méthode appelée par les actions des cartes (compatibilité)
  saveUserInput() {
    this.debouncedSaveUserInputs()
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
    console.log("💰 Événement savings:update déclenché (Wallonie)", data.savings_data);
  }

  // Émettre un événement pour que les cartes enfants se mettent à jour
  emitPrimeUpdateEvent(updatedCards) {
    console.log("📡 Émission événement wallonie:prime-updated", updatedCards);

    // Préparer un objet plat avec tous les montants par slug
    const primeAmounts = {};

    Object.keys(updatedCards).forEach(key => {
      const value = updatedCards[key];

      // Si c'est un nombre direct (slug de prime), l'ajouter
      if (typeof value === 'number') {
        primeAmounts[key] = value;
      }
      // Si c'est un objet avec des primes (catégorie), traiter les primes
      else if (value && value.primes) {
        value.primes.forEach(prime => {
          primeAmounts[prime.slug] = prime.calculated_amount || 0;
        });
      }
    });

    // Émettre l'événement pour toutes les cartes
    const event = new CustomEvent('wallonie:prime-updated', {
      detail: primeAmounts,
      bubbles: true
    });

    document.dispatchEvent(event);
    console.log("📡 Événement wallonie:prime-updated émis avec:", primeAmounts);
  }

  // Mettre à jour les spans individuels avec les données du backend
  updateIndividualPrimeDisplays(updatedCards) {
    console.log("🔄 Mise à jour des spans individuels Wallonie:", updatedCards);

    if (!updatedCards) return

    Object.keys(updatedCards).forEach(categoryKey => {
      const categoryData = updatedCards[categoryKey]
      console.log(`🔍 Traitement catégorie: ${categoryKey}`, categoryData);

      // Si c'est un nombre direct (slug de prime), mettre à jour directement
      if (typeof categoryData === 'number') {
        const slug = categoryKey
        const calculatedAmount = categoryData
        console.log(`💰 Prime directe trouvée: ${slug} = ${calculatedAmount}€`);

        // Trouver la carte correspondante pour Wallonie
        const cardElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)

        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-wallonie-simulation-card-target="total"]')

          if (resultSpan) {
            const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
            resultSpan.textContent = `${formattedAmount} €`
            console.log(`✅ Span mis à jour pour ${slug}: ${formattedAmount} €`);
          } else {
            console.log(`⚠️ Span target 'total' non trouvé pour ${slug}`);
          }
        } else {
          console.log(`⚠️ Élément card non trouvé pour slug: ${slug}`);
        }
        return;
      }

      // Si c'est un objet avec des primes (catégorie), traiter les primes
      if (!categoryData.primes) {
        console.log(`⚠️ Pas de propriété 'primes' dans ${categoryKey} et ce n'est pas un nombre`);
        return;
      }

      console.log(`📊 ${categoryData.primes.length} primes dans ${categoryKey}`);

      categoryData.primes.forEach(prime => {
        const slug = prime.slug
        const calculatedAmount = prime.calculated_amount || 0
        console.log(`💰 Prime trouvée: ${slug} = ${calculatedAmount}€`);

        // Trouver la carte correspondante pour Wallonie (utiliser le bon sélecteur)
        const cardElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)

        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-wallonie-simulation-card-target="total"]')

          if (resultSpan) {
            const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
            resultSpan.textContent = `${formattedAmount} €`
            console.log(`✅ Span mis à jour pour ${slug}: ${formattedAmount} €`);
          } else {
            console.log(`⚠️ Span target 'total' non trouvé pour ${slug}`);
          }
        } else {
          console.log(`⚠️ Élément card non trouvé pour slug: ${slug}`);
        }
      })
    })
  }

  // RESTAURATION DES DONNÉES SAUVEGARDÉES
  async restoreSavedData() {
    console.log("🔄 === DÉBUT RESTAURATION WALLONIE ===")
    console.log("🔍 simulationIdValue:", this.simulationIdValue)

    if (!this.simulationIdValue) {
      console.log("⚠️ Pas de simulation ID pour la restauration Wallonie")
      return
    }

    // Marquer le début de la restauration pour éviter l'auto-save pendant
    window.isRestoringValues = true
    window.restorationStartTime = Date.now()

    try {
      console.log("📡 Envoi requête de restauration Wallonie...")
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
          console.log("🔍 Nombre de clés dans user_inputs:", Object.keys(result.user_inputs).length)
          console.log("🔍 Clés disponibles:", Object.keys(result.user_inputs))

          // Restaurer les données de primes Wallonie
          const inputKeys = Object.keys(result.user_inputs)
          if (inputKeys.length === 0) {
            console.warn("⚠️ Aucune donnée à restaurer (user_inputs vide)")
          }

          inputKeys.forEach(slug => {
            console.log(`🔧 Restauration prime Wallonie ${slug}:`, result.user_inputs[slug])
            this.restorePrimeInput(slug, result.user_inputs[slug])
          })

          // Restaurer le total si disponible
          if (result.total_amount) {
            this.backendCalculatedTotal = result.total_amount
            console.log("💰 Total backend restauré:", result.total_amount, "€")
          }

          // Restaurer les cartes mises à jour si disponibles
          if (result.updated_cards) {
            console.log("🔄 Restauration des cartes mises à jour:", result.updated_cards)
            this.updateIndividualPrimeDisplays(result.updated_cards)
            this.emitPrimeUpdateEvent(result.updated_cards)
          }

          // Recalculer après restauration
          setTimeout(() => {
            this.updateTotalGlobal()
            console.log("✅ === FIN RESTAURATION WALLONIE ===")
          }, 500)
        }
      } else {
        console.log("⚠️ Erreur lors de la restauration Wallonie:", response.status)
      }
    } catch (error) {
      console.error("❌ Erreur restauration Wallonie:", error)
    } finally {
      // Libérer le verrou de restauration après un délai
      setTimeout(() => {
        window.isRestoringValues = false
        console.log("🔓 Verrou de restauration Wallonie libéré")
      }, 1000)
    }
  }

  // Restaurer une donnée de prime Wallonie
  restorePrimeInput(slug, value) {
    console.log(`🔄 Restauration Wallonie ${slug}:`, value)

    // Chercher directement l'input par son data-slug (peu importe la carte parente)
    const input = this.element.querySelector(`input[data-slug="${slug}"], select[data-slug="${slug}"]`)

    if (input) {
      if (input.type === 'checkbox') {
        input.checked = (value == 1 || value === true)
      } else if (input.type === 'number' || input.type === 'text') {
        input.value = value
      } else if (input.tagName === 'SELECT') {
        input.value = value
      }

      console.log(`✅ Valeur ${value} restaurée pour ${slug} (type: ${input.type})`)

      // Déclencher les événements pour mettre à jour l'affichage et recalculer
      input.dispatchEvent(new Event('input', { bubbles: true }))
      input.dispatchEvent(new Event('change', { bubbles: true }))
    } else {
      // Si pas trouvé directement, chercher dans la carte correspondante (fallback)
      const cardElement = this.element.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (cardElement) {
        const inputs = cardElement.querySelectorAll('input[data-slug], select[data-slug]')

        inputs.forEach(inp => {
          if (inp.dataset.slug === slug) {
            if (inp.type === 'checkbox') {
              inp.checked = (value == 1 || value === true)
            } else {
              inp.value = value
            }
            console.log(`✅ Valeur ${value} restaurée pour ${slug} (via carte)`)
            inp.dispatchEvent(new Event('input', { bubbles: true }))
            inp.dispatchEvent(new Event('change', { bubbles: true }))
          }
        })
      } else {
        console.warn(`⚠️ Input non trouvé pour ${slug}`)
      }
    }
  }
}
