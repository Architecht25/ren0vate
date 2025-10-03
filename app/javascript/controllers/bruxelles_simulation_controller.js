import { Controller } from "@hotwired/stimulus"

// Contrôleur dédié aux simulations Bruxelles post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "totalGeneral",
    "totalGeneralSection",
    "sectionTitle",
    "currentCategory",
    "selectedPrimesSummary"
  ]

  static values = {
    simulationId: Number
  }

  connect() {
    console.log("🎯 Bruxelles Simulation controller connected")
    console.log("📊 Simulation ID:", this.simulationIdValue)

    this.primesData = []
    this.currentCategory = this.getCurrentCategory()
    this.backendCalculatedTotal = 0  // Stocker le total calculé par le backend
    this.setupAutoSaveListeners()

    // Charger les données des primes
    this.loadPrimesData()

    // Mettre à jour l'affichage de la catégorie
    this.updateCategoryDisplay(this.currentCategory)

    // Vérifier que les targets sont bien trouvés
    console.log("🔍 DEBUG - Vérification des targets:")
    console.log("  - hasTotalGeneralTarget:", this.hasTotalGeneralTarget)
    console.log("  - hasCurrentCategoryTarget:", this.hasCurrentCategoryTarget)
    console.log("  - hasSelectedPrimesSummaryTarget:", this.hasSelectedPrimesSummaryTarget)

    if (this.hasTotalGeneralTarget) {
      console.log("  - totalGeneralTarget element:", this.totalGeneralTarget)
      console.log("  - totalGeneralTarget innerHTML:", this.totalGeneralTarget.innerHTML)
    } else {
      console.log("❌ totalGeneralTarget NOT FOUND!")
      // Essayons de le trouver manuellement
      const manualSearch = document.querySelector('[data-bruxelles-simulation-target="totalGeneral"]')
      console.log("🔍 Recherche manuelle totalGeneral:", manualSearch)
    }

    // Déclencher le premier calcul
    setTimeout(() => {
      this.updateTotalGlobal()
      this.debouncedAutoSave() // Déclencher l'auto-save
    }, 500)
  }

  setupAutoSaveListeners() {
    // Écouter tous les changements d'inputs dans les cartes Bruxelles
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
    this.element.addEventListener('bruxelles:card-changed', (e) => {
      console.log(`🔄 Carte modifiée: ${e.detail.slug}`);
      this.debouncedAutoSave();
    });
  }

  getCurrentCategory() {
    // Récupérer la catégorie depuis localStorage ou par défaut
    return localStorage.getItem('selectedBruxellesCategory') || 'bruxelles_cat2'
  }

  get simulationId() {
    return this.simulationIdValue ||
           parseInt(window.location.pathname.match(/\/simulations\/(\d+)/)?.[1]) ||
           null
  }

  async loadPrimesData() {
    try {
      // Utiliser les données déjà injectées dans la page
      const scriptElement = document.getElementById('bruxelles-primes-data');
      if (scriptElement) {
        this.primesData = JSON.parse(scriptElement.textContent);
        console.log("✅ Données primes Bruxelles chargées depuis la page:", Object.keys(this.primesData).length, "primes");
        console.log("🎯 Catégorie Bruxelles actuelle:", this.currentCategory);
      } else {
        console.warn("❌ Script des données primes Bruxelles non trouvé");
        this.primesData = {};
      }
    } catch (error) {
      console.error("❌ Erreur chargement primes Bruxelles:", error);
      this.primesData = {};
    }
  }

  getPrimesData() {
    return this.primesData || {}
  }

  // Calculer le total pour déclencher le backend (inspiré de Flandre)
  calculateTotalForBackend(userInputs) {
    console.log('🧮 Calcul du total pour le backend avec inputs:', userInputs);

    // Si l'utilisateur a des inputs, on force le déclenchement
    const hasInputs = Object.keys(userInputs).length > 0;

    if (hasInputs) {
      console.log('💡 Inputs détectés, retour total=1 pour forcer le nouveau service');
      return 1; // Force > 0 pour déclencher BruxellesPostLoginCalculatorService
    }

    console.log('❌ Aucun input, retour total=0');
    return 0;
  }

  updateTotalGlobal() {
    // Utiliser le total calculé par le backend si disponible
    let total = this.backendCalculatedTotal || 0;
    console.log("🔄 Mise à jour du total global Bruxelles avec total backend:", total, "€");

    // Fallback: calculer depuis les spans si pas de total backend
    if (total === 0) {
      console.log("📊 Fallback: calcul depuis les spans...");

      // Slugs des cartes Bruxelles principales
      const cartesSlugs = [
        'bruxelles_prime_a_global',      // Services et études
        'bruxelles_prime_b_global',      // Installations de chantier
        'bruxelles_prime_c_global',      // Gros œuvre
        'bruxelles_prime_d_global',      // Humidité et nuisibles
        'bruxelles_prime_e_global',      // Toiture
        'bruxelles_prime_f_global',      // Façades
        'bruxelles_prime_g_global',      // Portes et fenêtres
        'bruxelles_prime_h_global',      // Sols et planchers
        'bruxelles_prime_i_global',      // Aménagement et équipements
        'bruxelles_prime_j_global',      // Chauffage et eau chaude
      'bruxelles_prime_kl_global',     // Sanitaires et électricité
      'bruxelles_prime_m_global',      // Ventilation
      'bruxelles_bonus_z1',            // Bonus Z1
      'bruxelles_bonus_z2',            // Bonus Z2
      'bruxelles_bonus_z3',            // Bonus Z3
      'bruxelles_bonus_z4',            // Bonus Z4
      'bruxelles_bonus_z5',            // Bonus Z5
      'bruxelles_bonus_z6',            // Bonus Z6
      'bruxelles_bonus_z7',            // Bonus Z7
      'bruxelles_bonus_z9',            // Bonus Z9
      'bruxelles_bonus_z10'            // Bonus Z10
    ]

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-bruxelles-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-bruxelles-simulation-card-target="total"]')
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
    } // Fermeture du bloc if (total === 0)

    console.log(`🎯 Total global Bruxelles calculé: ${total}€`)

    // TEST DIRECT - Forcer la mise à jour même sans Stimulus
    const directElement = document.querySelector('[data-bruxelles-simulation-target="totalGeneral"]')
    if (directElement) {
      console.log("✅ Element trouvé directement, mise à jour forcée!")
      directElement.textContent = `${total.toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €`
      console.log("✅ Mise à jour directe effectuée:", directElement.textContent)
    } else {
      console.log("❌ Element totalGeneral introuvable même en recherche directe!")
    }

    // Mettre à jour l'affichage du total (méthode Stimulus normale)
    if (this.hasTotalGeneralTarget) {
      console.log(`🎯 Mise à jour de TOUS les targets totalGeneral avec: ${total}€`);

      // Mettre à jour tous les éléments avec target totalGeneral
      this.totalGeneralTargets.forEach((element, index) => {
        element.textContent = `${total.toLocaleString('fr-FR', {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2
        })} €`;
        console.log(`📝 Element ${index + 1} mis à jour: ${element.textContent}`);

        // Animation visuelle
        element.classList.add('updated');
        setTimeout(() => {
          element.classList.remove('updated');
        }, 300);
      });
    } else {
      console.log("❌ Aucun target totalGeneral trouvé!")
      console.log("🔍 Targets disponibles:", this.targets);
    }

    // Mettre à jour aussi le target de la section total général
    if (this.hasTotalGeneralSectionTarget) {
      console.log(`🎯 Mise à jour du target totalGeneralSection avec: ${total}€`);
      this.totalGeneralSectionTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`
      console.log(`📝 Total affiché dans totalGeneralSectionTarget: ${this.totalGeneralSectionTarget.textContent}`);

      // Animation visuelle
      this.totalGeneralSectionTarget.classList.add('updated')
      setTimeout(() => {
        this.totalGeneralSectionTarget.classList.remove('updated')
      }, 300)
    } else {
      console.log("❌ Target totalGeneralSection non trouvé!")
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('bruxelles:total:calculated', {
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

  // Nouvelle méthode pour calculer le total global en additionnant les totaux des cartes
  updateTotalGlobalFromCards() {
    console.log("🧮 Calcul du total général depuis les totaux des cartes");

    let total = 0;

    // Méthode simple : chercher tous les totaux de cartes
    const allCardTotals = document.querySelectorAll('[data-bruxelles-simulation-card-target="total"]');

    allCardTotals.forEach((totalElement, index) => {
      const montantText = totalElement.textContent.trim();

      // Parser le montant (gérer les formats avec séparateurs)
      const cleanText = montantText.replace(/[€\s]/g, '').replace(/\./g, '').replace(',', '.');
      const montant = parseFloat(cleanText) || 0;

      if (montant > 0) {
        total += montant;
        console.log(`🧮 Carte ${index + 1}: ${montant}€ (texte: "${montantText}")`);
      }
    });

    console.log(`🎯 Total général calculé depuis les cartes: ${total}€`);

    // Mettre à jour l'affichage du total
    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`;
      console.log(`📝 Total général affiché: ${this.totalGeneralTarget.textContent}`);

      // Animation visuelle
      this.totalGeneralTarget.classList.add('updated');
      setTimeout(() => {
        this.totalGeneralTarget.classList.remove('updated');
      }, 300);
    } else {
      console.log("❌ Target totalGeneral non trouvé!");
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('bruxelles:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }));
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedBruxellesCategory', newCategory)
    // Mettre à jour aussi la catégorie estimée pour cohérence
    const categoryNumber = newCategory.replace('bruxelles_cat', '')
    localStorage.setItem('bruxellesCategorieEstimee', categoryNumber)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes Bruxelles
    const bruxellesCards = this.element.querySelectorAll('[data-controller*="bruxelles-simulation-card"]')
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
    // Mettre à jour aussi la catégorie estimée pour cohérence
    const categoryNumber = newCategory.replace('bruxelles_cat', '')
    localStorage.setItem('bruxellesCategorieEstimee', categoryNumber)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes Bruxelles
    const bruxellesCards = this.element.querySelectorAll('[data-controller*="bruxelles-simulation-card"]')
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

    // Mettre à jour l'affichage de la catégorie
    this.updateCategoryDisplay(newCategory)
  }

  updateSectionTitle() {
    if (!this.hasSectionTitleTarget) return

    const categoryNames = {
      'bruxelles_cat1': 'Catégorie I (revenus très modestes)',
      'bruxelles_cat2': 'Catégorie II (revenus modestes)',
      'bruxelles_cat3': 'Catégorie III (revenus moyens-élevés)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Bruxelles • ${categoryName}`
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées
    const cartesSlugs = [
      'bruxelles_prime_a_global', 'bruxelles_prime_b_global', 'bruxelles_prime_c_global',
      'bruxelles_prime_d_global', 'bruxelles_prime_e_global', 'bruxelles_prime_f_global',
      'bruxelles_prime_g_global', 'bruxelles_prime_h_global', 'bruxelles_prime_i_global',
      'bruxelles_prime_j_global', 'bruxelles_prime_kl_global', 'bruxelles_prime_m_global'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-bruxelles-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-bruxelles-simulation-card-target="total"]')
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
      console.log('🔄 Sauvegarde Bruxelles ignorée: restauration en cours');
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
      console.log('⚠️ Restauration Bruxelles bloquée depuis > 10s, forçage de la réinitialisation');
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
      console.log('💾 Sauvegarde Bruxelles des données:', Object.keys(userInputs).length, 'saisies');

      // Calculer le total pour forcer le déclenchement du backend
      const calculatedTotal = this.calculateTotalForBackend(userInputs);

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
          console.log("✅ Auto-save Bruxelles réussi:", data.total_amount, "€");

          // Stocker le total calculé par le backend
          this.backendCalculatedTotal = data.total_amount || 0;

          // Mettre à jour les spans individuels avec les détails du backend
          if (data.updated_cards) {
            this.updateIndividualPrimeDisplays(data.updated_cards);
          }

          // Mettre à jour le total général avec le vrai total backend
          this.updateTotalGlobal();

          // Déclencher l'événement pour mettre à jour le composant d'économie
          this.dispatchSavingsUpdateEvent(data);

          this.showSaveIndicator('success', data.total_amount);
        } else {
          console.error("❌ Erreur auto-save Bruxelles:", data.error);
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Bruxelles:", error);
        this.showSaveIndicator('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    // Utiliser la même logique que updateTotalGlobal
    const cartesSlugs = [
      'bruxelles_prime_a_global', 'bruxelles_prime_b_global', 'bruxelles_prime_c_global',
      'bruxelles_prime_d_global', 'bruxelles_prime_e_global', 'bruxelles_prime_f_global',
      'bruxelles_prime_g_global', 'bruxelles_prime_h_global', 'bruxelles_prime_i_global',
      'bruxelles_prime_j_global', 'bruxelles_prime_kl_global', 'bruxelles_prime_m_global',
      'bruxelles_bonus_z1', 'bruxelles_bonus_z2', 'bruxelles_bonus_z3', 'bruxelles_bonus_z4',
      'bruxelles_bonus_z5', 'bruxelles_bonus_z6', 'bruxelles_bonus_z7', 'bruxelles_bonus_z9',
      'bruxelles_bonus_z10'
    ]

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-bruxelles-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-bruxelles-simulation-card-target="total"]')
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

  // Méthode de distribution des résultats (inspirée de Flandre)
  updateCardsWithCalculatedAmounts(updatedCards) {
    console.log("🎯 Distribution des montants aux spans individuels:", updatedCards);

    if (!updatedCards) return

    Object.keys(updatedCards).forEach(categoryKey => {
      const categoryData = updatedCards[categoryKey]
      console.log(`🔍 Traitement catégorie: ${categoryKey}`, categoryData);

      if (!categoryData.primes) {
        console.log(`⚠️ Pas de propriété 'primes' dans ${categoryKey}`);
        return;
      }

      console.log(`📊 ${categoryData.primes.length} primes dans ${categoryKey}`);

      categoryData.primes.forEach(prime => {
        const slug = prime.slug
        const calculatedAmount = prime.calculated_amount || 0
        console.log(`💰 Prime trouvée: ${slug} = ${calculatedAmount}€`);

        // Trouver la carte correspondante pour Bruxelles
        const cardElement = document.querySelector(`[data-bruxelles-simulation-card-slug-value="${slug}"]`)

        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-bruxelles-simulation-card-target="total"]')

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

    // Calculer le total général après avoir mis à jour toutes les cartes
    console.log("🧮 Recalcul du total général après mise à jour des cartes");
    // TEMPORAIRE : Commenté pour éviter conflit avec backend total
    // setTimeout(() => {
    //   this.updateTotalGlobalFromCards();
    // }, 100); // Petit délai pour s'assurer que les DOM sont mis à jour
  }

  // Mettre à jour les spans individuels avec les données du backend
  updateIndividualPrimeDisplays(updatedCards) {
    console.log("🔄 Mise à jour des spans individuels:", updatedCards);

    // NOUVELLE MÉTHODE : Distribution directe aux spans (inspirée de Flandre)
    this.updateCardsWithCalculatedAmounts(updatedCards);

    // Créer un objet simplifié pour l'événement (ancienne méthode en backup)
    const primeUpdates = {};

    // Debug: afficher la structure des données
    console.log("🔍 Structure updated_cards:", Object.keys(updatedCards));

    // Parcourir chaque catégorie de primes
    Object.keys(updatedCards).forEach(categoryKey => {
      console.log(`🔍 Traitement catégorie: ${categoryKey}`);
      const categoryData = updatedCards[categoryKey];

      if (categoryData.primes) {
        console.log(`📊 ${categoryData.primes.length} primes dans ${categoryKey}`);
        categoryData.primes.forEach(prime => {
          console.log(`💰 Prime trouvée: ${prime.slug} = ${prime.calculated_amount}€`);

          // Stocker le montant pour l'événement - utiliser le slug exact de la prime
          primeUpdates[prime.slug] = prime.calculated_amount || 0;

          // Aussi chercher les contrôleurs qui pourraient correspondre à cette prime
          // Par exemple: bruxelles_audit_energetique_maison -> bruxelles_prime_a_global
          const potentialControllerSlugs = this.findControllerSlugsForPrime(prime.slug, categoryKey);
          potentialControllerSlugs.forEach(controllerSlug => {
            console.log(`🔗 Mapping ${prime.slug} vers contrôleur ${controllerSlug}`);
            primeUpdates[controllerSlug] = prime.calculated_amount || 0;
          });

          // Trouver le span correspondant à cette prime
          const primeElement = document.querySelector(`[data-slug="${prime.slug}"]`);
          if (primeElement) {
            // Trouver le span de résultat dans la même carte
            const card = primeElement.closest('[data-controller*="bruxelles-simulation-card"]');
            if (card) {
              // Chercher le span de résultat correspondant à cet input
              const targetName = primeElement.dataset.bruxellesSimulationCardTarget;
              if (targetName) {
                // Convertir inputXxx en resultXxx
                const resultTargetName = targetName.replace('input', 'result');
                const resultSpan = card.querySelector(`[data-bruxelles-simulation-card-target="${resultTargetName}"]`);

                if (resultSpan && prime.calculated_amount) {
                  const formattedAmount = `${prime.calculated_amount.toLocaleString('fr-FR')} €`;
                  resultSpan.textContent = formattedAmount;
                  console.log(`✅ Mis à jour ${prime.slug}: ${formattedAmount}`);

                  // Animation visuelle
                  resultSpan.classList.add('updated');
                  setTimeout(() => {
                    resultSpan.classList.remove('updated');
                  }, 300);
                }
              }
            }
          }
        });
      } else {
        console.log(`⚠️ Pas de propriété 'primes' dans ${categoryKey}`);
      }
    });

    console.log("🔥 primeUpdates préparé:", primeUpdates);
    console.log("🔥 Clés dans primeUpdates:", Object.keys(primeUpdates));
    console.log("🔥 Valeurs dans primeUpdates:", Object.values(primeUpdates));
    console.log("🔥 Structure détaillée de primeUpdates:");
    Object.keys(primeUpdates).forEach(key => {
      console.log(`🔥   '${key}': ${primeUpdates[key]}€`);
    });

    // Déclencher l'événement pour tous les contrôleurs enfants
    const event = new CustomEvent('bruxelles:prime-updated', {
      detail: primeUpdates,  // Envoyer directement primeUpdates, pas wrappé
      bubbles: true
    });
    document.dispatchEvent(event);
    console.log("📡 Événement bruxelles:prime-updated déclenché");
  }

  // Mapper les slugs de primes vers les slugs de contrôleurs
  findControllerSlugsForPrime(primeSlug, categoryKey) {
    const mapping = {
      // Catégorie audit
      'bruxelles_audit_energetique_maison': ['bruxelles_prime_a_global'],
      'bruxelles_audit_energetique_batiment': ['bruxelles_prime_a_global'],

      // Catégorie certificat
      'bruxelles_certificat_peb': ['bruxelles_prime_a_global'],

      // Autres mappings à ajouter selon les besoins
    };

    return mapping[primeSlug] || [];
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
      'bruxelles_cat1': 'Catégorie I',
      'bruxelles_cat2': 'Catégorie II',
      'bruxelles_cat3': 'Catégorie III'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

    console.log(`📋 Catégorie affichée: ${categoryName}`)
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
    console.log("💰 Événement savings:update déclenché (Bruxelles)", data.savings_data);
  }
}
