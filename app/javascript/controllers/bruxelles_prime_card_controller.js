import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "total",
    // Inputs génériques pour les bonus
    "inputSurface", "inputSurfaceLimitee", "inputQuantiteLimitee", "inputSelect",
    // Carte I - Services et études
    "inputAuditMaison", "resultAuditMaison",
    "inputAuditBatiment", "resultAuditBatiment",
    // Carte J - Isolation toiture
    "inputIsolationToiture", "resultIsolationToiture",
    // Carte K - Isolation murs
    "inputIsolationMurs", "resultIsolationMurs",
    // Carte M - Pompe à chaleur
    "inputPompeChaleurd", "resultPompeChaleurd"
  ]
  static values = { slug: String }

  connect() {
    console.log("🎯 Contrôleur Bruxelles Prime Card connecté pour:", this.slugValue)

    // Écouter les changements de catégorie
    this.element.addEventListener('bruxelles:category:changed', this.recalculate.bind(this))

    // Calculer le montant initial
    this.calculate()
  }

  disconnect() {
    this.element.removeEventListener('bruxelles:category:changed', this.recalculate.bind(this))
  }

  calculate() {
    if (!this.slugValue) {
      console.warn("Pas de slug défini pour cette carte")
      return
    }

    // Récupérer le controller parent pour accéder aux données
    const parentController = this.getParentController()
    if (!parentController) {
      console.warn("Controller parent non trouvé")
      return
    }

    const currentCategory = parentController.getCurrentCategory()
    const primesData = parentController.getPrimesData()

    // Vérifier si c'est une carte composite (globale)
    if (this.isCompositeCard()) {
      this.calculateComposite(currentCategory, primesData)
      return
    }

    // Trouver la prime correspondante
    const prime = primesData[this.slugValue]
    if (!prime) {
      console.warn(`Prime non trouvée pour slug: ${this.slugValue}`)
      return
    }

    // Calculer selon le type de calcul
    const calculData = prime.valeurs_par_categorie[currentCategory]
    if (!calculData) {
      console.warn(`Données de calcul non trouvées pour ${currentCategory}`)
      // Vérifier si la prime existe pour d'autres catégories
      const availableCategories = Object.keys(prime.valeurs_par_categorie)
      if (availableCategories.length > 0) {
        console.info(`Prime ${this.slugValue} disponible seulement pour: ${availableCategories.join(', ')}`)
        // Afficher 0€ pour les primes non disponibles
        this.updateTotal(0)
        return
      }
      return
    }

    let total = 0

    // Logique de calcul selon le type
    switch (calculData.type) {
      case 'montant_fixe':
        total = this.calculateMontantFixe(calculData)
        break
      case 'montant_m2':
        total = this.calculateMontantM2(calculData)
        break
      case 'montant_m2_et_limite':
        total = this.calculateMontantM2AvecLimite(calculData)
        break
      case 'montant_unite':
        total = this.calculateMontantUnite(calculData)
        break
      case 'montant_unite_et_limite':
        total = this.calculateMontantUniteAvecLimite(calculData)
        break
      case 'pourcentage':
        total = this.calculatePourcentage(calculData)
        break
      case 'grille_variable':
        total = this.calculateGrilleVariable(calculData)
        break
      default:
        console.warn(`Type de calcul non reconnu: ${calculData.type}`)
    }

    // Mettre à jour l'affichage
    this.updateTotal(total)

    // Notifier le controller parent
    if (parentController.cardUpdated) {
      parentController.cardUpdated()
    }
  }

  calculateMontantFixe(calculData) {
    // Pour les montants fixes (audit par exemple)
    let firstInput = null

    // Essayer d'abord le target select générique
    if (this.hasInputSelectTarget) {
      firstInput = this.inputSelectTarget
    } else {
      firstInput = this.element.querySelector('input, select')
    }

    if (!firstInput) return 0

    const inputValue = firstInput.value
    const isSelected = inputValue === "1" || inputValue === 1 ||
                      (firstInput.type === 'checkbox' && firstInput.checked)

    return isSelected ? calculData.montant : 0
  }

  calculateMontantM2(calculData) {
    // Pour les calculs au m²
    let surfaceInput = null

    // Essayer d'abord les nouveaux targets génériques
    if (this.hasInputSurfaceTarget) {
      surfaceInput = this.inputSurfaceTarget
    } else {
      // Fallback vers l'ancienne méthode
      surfaceInput = this.element.querySelector('input[type="number"], input[placeholder*="m²"]')
    }

    if (!surfaceInput) {
      console.warn("❌ Aucun input trouvé pour montant_m2")
      return 0
    }

    const surface = parseFloat(surfaceInput.value) || 0
    const montantParM2 = calculData.montant_m2 || calculData.montant_par_m2 || 0

    console.log(`🔍 Calcul m²: surface=${surface}, montantParM2=${montantParM2}, input.value="${surfaceInput.value}"`)

    if (isNaN(surface) || isNaN(montantParM2)) {
      console.error("❌ Valeurs NaN détectées:", { surface, montantParM2, calculData })
      return 0
    }

    return surface * montantParM2
  }

  calculateMontantM2AvecLimite(calculData) {
    // Pour les calculs au m² avec plafond
    let surfaceInput = null

    // Essayer d'abord le target spécialisé pour les surfaces limitées
    if (this.hasInputSurfaceLimiteeTarget) {
      surfaceInput = this.inputSurfaceLimiteeTarget
    } else if (this.hasInputSurfaceTarget) {
      surfaceInput = this.inputSurfaceTarget
    } else {
      // Fallback vers l'ancienne méthode
      surfaceInput = this.element.querySelector('input[type="number"], input[placeholder*="m²"]')
    }

    if (!surfaceInput) return 0

    const surface = parseFloat(surfaceInput.value) || 0
    const montantParM2 = calculData.montant_m2 || calculData.montant_par_m2 || 0
    const plafondM2 = calculData.plafond_m2 || calculData.plafond_surface || 999
    const surfaceLimitee = Math.min(surface, plafondM2)

    return surfaceLimitee * montantParM2
  }

  calculatePourcentage(calculData) {
    // Cas spécial pour le bonus Z10 - travaux multiples
    if (this.slugValue === 'bruxelles_bonus_z10') {
      return this.calculateBonusTravauxMultiples(calculData)
    }

    if (calculData.base_calculation) {
      // Pourcentage basé sur une autre prime
      const baseAmount = this.getBaseCalculationAmount(calculData.base_calculation)
      return (baseAmount * calculData.pourcentage) / 100
    } else {
      // Pourcentage du montant saisi
      const montantInput = this.element.querySelector('input[type="number"]')
      if (!montantInput) return 0

      const montantTravaux = parseFloat(montantInput.value) || 0
      return (montantTravaux * calculData.pourcentage) / 100
    }
  }

  calculateBonusTravauxMultiples(calculData) {
    // Pour le bonus Z10, on applique le pourcentage sur le total des primes principales
    const selectInput = this.element.querySelector('select')
    if (!selectInput || selectInput.value !== "1") return 0

    // Récupérer le total des primes principales (hors bonus)
    const parentController = this.getParentController()
    if (!parentController) return 0

    const totalPrimesPrincipales = this.getTotalPrimesPrincipales()
    const pourcentage = calculData.pourcentage || 0

    console.log(`🎯 Bonus Z10: ${pourcentage}% sur ${totalPrimesPrincipales}€`)
    return (totalPrimesPrincipales * pourcentage) / 100
  }

  getTotalPrimesPrincipales() {
    // Calculer le total des primes principales (exclure les bonus Z1-Z10)
    let total = 0
    const parentElement = this.element.closest('[data-controller*="bruxelles-prime-calcul"]')
    if (!parentElement) return 0

    const cardElements = parentElement.querySelectorAll('[data-controller*="bruxelles-prime-card"]')

    cardElements.forEach(cardElement => {
      const slug = cardElement.dataset.bruxellesPrimeCardSlugValue || ''

      // Exclure les bonus Z1-Z10 pour éviter la double comptabilisation
      if (slug.includes('bonus_z')) return

      const totalElement = cardElement.querySelector('[data-bruxelles-prime-card-target="total"]')
      if (totalElement) {
        const montantText = totalElement.textContent.replace(/[€\s\.]/g, '').replace(',', '.')
        const montant = parseFloat(montantText) || 0
        total += montant
      }
    })

    return total
  }

  calculateGrilleVariable(calculData) {
    // Pour les calculs avec grille de prix variable (ex: égouts)
    if (!calculData.grille) return 0

    let total = 0
    // Chercher spécifiquement les inputs de la grille variable
    const inputs = this.element.querySelectorAll('input[data-bruxelles-prime-card-target="inputGestionEgouts"]')
    console.log(`🔍 Grille variable - ${inputs.length} inputs trouvés`)

    inputs.forEach((input, index) => {
      const quantity = parseFloat(input.value) || 0
      const grilleKeys = Object.keys(calculData.grille)
      const placeholder = input.placeholder

      console.log(`🔍 Input ${index}: "${placeholder}" = ${quantity}`)

      if (grilleKeys[index]) {
        const pricePerUnit = calculData.grille[grilleKeys[index]]
        const lineTotal = quantity * pricePerUnit
        total += lineTotal
        console.log(`✅ ${grilleKeys[index]} (${placeholder}): ${quantity} × ${pricePerUnit}€ = ${lineTotal}€`)
      } else {
        console.log(`❌ Pas de clé grille pour index ${index}`)
      }
    })

    console.log(`📊 Total grille variable: ${total}€`)
    return total
  }

  calculateMontantUnite(calculData) {
    // Pour les calculs à l'unité
    let quantiteInput = null

    // Essayer d'abord les nouveaux targets génériques
    if (this.hasInputQuantiteLimiteeTarget) {
      quantiteInput = this.inputQuantiteLimiteeTarget
    } else {
      quantiteInput = this.element.querySelector('input[type="number"]')
    }

    if (!quantiteInput) return 0

    const quantite = parseFloat(quantiteInput.value) || 0
    const montantParUnite = calculData.montant_unite || calculData.montant_par_unite || 0
    return quantite * montantParUnite
  }

  calculateMontantUniteAvecLimite(calculData) {
    // Pour les calculs à l'unité avec plafond
    const quantiteInput = this.element.querySelector('input[type="number"]')
    if (!quantiteInput) return 0

    const quantite = parseFloat(quantiteInput.value) || 0
    const montantParUnite = calculData.montant_unite || calculData.montant_par_unite || 0
    const plafondUnite = calculData.plafond_unite || calculData.plafond_quantite || 999
    const quantiteLimitee = Math.min(quantite, plafondUnite)
    return quantiteLimitee * montantParUnite
  }

  getBaseCalculationAmount(baseCalculation) {
    // Pour les calculs en pourcentage basés sur d'autres primes
    // Ex: "F6-H2-isolation" -> récupérer le montant de la prime d'isolation
    console.log("Calcul basé sur:", baseCalculation)
    // TODO: Implémenter la logique pour récupérer les montants d'autres primes
    return 1000 // Valeur temporaire
  }

  calculateComposite(currentCategory, primesData) {
    // Pour les cartes composites qui contiennent plusieurs primes
    console.log("🔄 Calcul composite pour:", this.slugValue, "catégorie:", currentCategory)
    let totalGlobal = 0

    // Définir les primes à calculer selon la carte
    const primesToCalculate = this.getCompositePrimes()
    console.log("📋 Primes à calculer:", primesToCalculate.length)

    primesToCalculate.forEach(compositeDefinition => {
      const { slug, inputSelector, resultSelector } = compositeDefinition
      console.log("🔍 Traitement de:", slug, "avec selector:", inputSelector)

      const prime = primesData[slug]

      if (!prime) {
        console.warn(`Prime composite non trouvée: ${slug}`)
        return
      }

      const calculData = prime.valeurs_par_categorie[currentCategory]
      if (!calculData) {
        console.warn(`Données de calcul composite non trouvées pour ${slug} - ${currentCategory}`)
        // Vérifier si la prime existe pour d'autres catégories
        const availableCategories = Object.keys(prime.valeurs_par_categorie)
        if (availableCategories.length > 0) {
          console.info(`Prime ${slug} disponible seulement pour: ${availableCategories.join(', ')}`)
        }
        return
      }

      // Trouver l'input correspondant
      const input = this.element.querySelector(inputSelector)
      if (!input) {
        console.warn(`Input non trouvé pour ${inputSelector}`)
        return
      }

      console.log("✅ Input trouvé:", input.tagName, "valeur:", input.value, "type calcul:", calculData.type)

      // Calculer selon le type
      let montant = 0
      switch (calculData.type) {
        case 'montant_fixe':
          const isSelected = input.value === "1" || input.checked
          montant = isSelected ? calculData.montant : 0
          console.log("💰 Montant fixe:", montant, "€ (sélectionné:", isSelected, "montant base:", calculData.montant, "€)")
          break
        case 'montant_m2':
          const surface = parseFloat(input.value) || 0
          const montantParM2 = calculData.montant_m2 || calculData.montant_par_m2 || 0
          montant = surface * montantParM2
          console.log("📐 Montant m²:", montant, "€ (surface:", surface, "m² × ", montantParM2, "€/m²)")

          if (isNaN(montant)) {
            console.error("❌ NaN détecté pour montant_m2:", {
              surface,
              montantParM2,
              inputValue: input.value,
              calculData,
              slug
            })
            montant = 0
          }
          break
        case 'montant_unite':
          const quantite = parseFloat(input.value) || 0
          const montantParUnite = calculData.montant_unite || calculData.montant_par_unite || 0
          montant = quantite * montantParUnite
          console.log("🔢 Montant unité:", montant, "€ (quantité:", quantite, "× ", montantParUnite, "€/unité)")
          break
        case 'pourcentage':
          const montantTravaux = parseFloat(input.value) || 0
          const pourcentage = calculData.pourcentage || 0
          const montantMax = calculData.montant_max || Infinity

          // Vérifier s'il y a un calcul basé sur une autre prime
          if (calculData.base_calculation) {
            console.log(`📊 ${slug}: Calcul basé sur ${calculData.base_calculation} - non implémenté pour l'instant`)
            montant = 0
          } else {
            // Calcul sur le montant saisi
            const calculResult = (montantTravaux * pourcentage) / 100
            montant = Math.min(calculResult, montantMax)
            console.log(`📊 Pourcentage: ${montant}€ (${montantTravaux}€ × ${pourcentage}%, max: ${montantMax}€)`)
          }
          break
        case 'grille_variable':
          // Calcul grille variable (ex: égouts)
          if (!calculData.grille) {
            console.warn(`Grille de prix manquante pour ${slug}`)
            montant = 0
          } else {
            // Extraire le nom du target depuis l'inputSelector
            const targetName = inputSelector.replace('[data-bruxelles-prime-card-target="', '').replace('"]', '')

            // Pour les égouts, sélectionner UNIQUEMENT les inputs dans la section des égouts
            let validInputs = []

            if (slug.includes('gestion_egouts')) {
              // Sélectionner spécifiquement les inputs de la section "Gestion égouts"
              const gestionEgoutsSection = this.element.querySelector('[data-bruxelles-prime-card-target="inputGestionEgouts"]')?.closest('.col-md-12')
              if (gestionEgoutsSection) {
                validInputs = Array.from(gestionEgoutsSection.querySelectorAll('input[data-bruxelles-prime-card-target="inputGestionEgouts"]'))
                console.log(`🎯 ${slug}: Trouvé ${validInputs.length} inputs spécifiques dans la section égouts`)
              }
            } else {
              // Pour les autres grilles variables, utiliser la sélection normale
              const grilleInputs = this.element.querySelectorAll(`input[data-bruxelles-prime-card-target="${targetName}"]`)
              validInputs = Array.from(grilleInputs)
            }

            let total = 0

            console.log(`🎯 ${slug}: ${validInputs.length} inputs valides trouvés`)

            // Associer chaque input à un élément de la grille
            const grilleKeys = Object.keys(calculData.grille)
            validInputs.forEach((inp, index) => {
              if (grilleKeys[index]) {
                const quantity = parseFloat(inp.value) || 0
                const pricePerUnit = calculData.grille[grilleKeys[index]]
                total += quantity * pricePerUnit
                console.log(`📊 ${grilleKeys[index]}: ${quantity} × ${pricePerUnit}€ = ${quantity * pricePerUnit}€ (placeholder: ${inp.placeholder})`)
              }
            })

            montant = total
            console.log(`📊 Total grille variable pour ${slug}: ${montant}€`)
          }
          break
        case 'montant_m2_et_limite':
          // Calcul montant m² avec limitation de surface
          const surfaceM2 = parseFloat(input.value) || 0
          const montantParM2Limite = calculData.montant_par_m2 || 0
          const plafondSurface = calculData.plafond_m2 || 100 // Défaut 100 m²
          const surfaceLimitee = Math.min(surfaceM2, plafondSurface)
          montant = surfaceLimitee * montantParM2Limite
          console.log(`📐 Montant m² avec limite: ${montant}€ (${surfaceLimitee}m² × ${montantParM2Limite}€/m², max: ${plafondSurface}m²)`)
          break
        case 'montant_unite_et_limite':
          // Calcul montant unité avec limitation de quantité
          const quantiteLimitee = parseFloat(input.value) || 0
          const montantParUniteLimite = calculData.montant_unite || calculData.montant_par_unite || 0
          const plafondQuantite = calculData.plafond_unite || calculData.plafond_quantite || 999
          const quantiteFinale = Math.min(quantiteLimitee, plafondQuantite)
          montant = quantiteFinale * montantParUniteLimite
          console.log(`🔢 Montant unité avec limite: ${montant}€ (${quantiteFinale} × ${montantParUniteLimite}€/unité, max: ${plafondQuantite})`)
          break
        // Ajouter d'autres types si nécessaire
        default:
          console.warn("Type de calcul non géré:", calculData.type)
      }

      // Mettre à jour le résultat spécifique
      const resultElement = this.element.querySelector(resultSelector)
      if (resultElement) {
        resultElement.textContent = `${montant.toLocaleString('fr-BE')} €`
        console.log(`✨ [${slug}] Résultat mis à jour: ${resultSelector} → ${montant}€`)

        // Debug spécifique pour les problèmes de façade
        if (slug.includes('facade')) {
          console.log(`🏠 FACADE DEBUG: slug="${slug}", input="${inputSelector}", result="${resultSelector}", montant=${montant}€`)
          console.log(`🏠 Element DOM trouvé:`, resultElement.outerHTML.substring(0, 100) + '...')
        }
      } else {
        console.warn(`❌ [${slug}] Element résultat non trouvé pour ${resultSelector} dans la carte ${this.slugValue}`)
        // Debug: lister tous les éléments avec data-bruxelles-prime-card-target
        const allTargets = this.element.querySelectorAll('[data-bruxelles-prime-card-target]')
        console.log(`🔍 Debug - Tous les targets trouvés dans cette carte:`, Array.from(allTargets).map(el => el.getAttribute('data-bruxelles-prime-card-target')))
      }

      totalGlobal += montant
    })

    console.log("🎯 Total global de la carte:", totalGlobal, "€")

    // Mettre à jour le total de la carte
    this.updateTotal(totalGlobal)

    // Notifier le parent
    const parentController = this.getParentController()
    if (parentController && parentController.cardUpdated) {
      parentController.cardUpdated()
    }
  }

  isCompositeCard() {
    // Vérifier si c'est une carte composite Bruxelles
    const compositeCards = [
      'bruxelles_prime_a_global',
      'bruxelles_prime_b_global',
      'bruxelles_prime_c_global',
      'bruxelles_prime_d_global',
      'bruxelles_prime_e_global',
      'bruxelles_prime_f_global',
      'bruxelles_prime_g_global',
      'bruxelles_prime_h_global',
      'bruxelles_prime_i_global',
      'bruxelles_prime_j_global',
      'bruxelles_prime_kl_global',
      'bruxelles_prime_m_global'
      // bruxelles_prime_z_global retiré temporairement
    ]
    return compositeCards.includes(this.slugValue)
  }

  getCompositePrimes() {
    // Définir les sous-primes selon la carte composite Bruxelles
    switch (this.slugValue) {
      case 'bruxelles_prime_a_global':
        // Prime A - Services et études (8 primes)
        return [
          { slug: 'bruxelles_audit_energetique_maison', inputSelector: '[data-bruxelles-prime-card-target="inputAuditMaison"]', resultSelector: '[data-bruxelles-prime-card-target="resultAuditMaison"]' },
          { slug: 'bruxelles_audit_energetique_batiment', inputSelector: '[data-bruxelles-prime-card-target="inputAuditBatiment"]', resultSelector: '[data-bruxelles-prime-card-target="resultAuditBatiment"]' },
          { slug: 'bruxelles_certificat_peb', inputSelector: '[data-bruxelles-prime-card-target="inputCertificatPeb"]', resultSelector: '[data-bruxelles-prime-card-target="resultCertificatPeb"]' },
          { slug: 'bruxelles_etude_acoustique', inputSelector: '[data-bruxelles-prime-card-target="inputEtudeAcoustique"]', resultSelector: '[data-bruxelles-prime-card-target="resultEtudeAcoustique"]' },
          { slug: 'bruxelles_etude_totem', inputSelector: '[data-bruxelles-prime-card-target="inputEtudeTotem"]', resultSelector: '[data-bruxelles-prime-card-target="resultEtudeTotem"]' },
          { slug: 'bruxelles_suivi_architecte', inputSelector: '[data-bruxelles-prime-card-target="inputSuiviArchitecte"]', resultSelector: '[data-bruxelles-prime-card-target="resultSuiviArchitecte"]' },
          { slug: 'bruxelles_suivi_ingenieur_stabilite', inputSelector: '[data-bruxelles-prime-card-target="inputSuiviIngenieur"]', resultSelector: '[data-bruxelles-prime-card-target="resultSuiviIngenieur"]' },
          { slug: 'bruxelles_suivi_expert_facade', inputSelector: '[data-bruxelles-prime-card-target="inputSuiviExpertFacade"]', resultSelector: '[data-bruxelles-prime-card-target="resultSuiviExpertFacade"]' }
        ]

      case 'bruxelles_prime_b_global':
        // Prime B - Installations de chantier (1 prime)
        return [
          { slug: 'bruxelles_protection_echafaudages', inputSelector: '[data-bruxelles-prime-card-target="inputProtectionEchafaudages"]', resultSelector: '[data-bruxelles-prime-card-target="resultProtectionEchafaudages"]' }
        ]

      case 'bruxelles_prime_c_global':
        // Prime C - Gros-œuvre & gestion de l'eau (4 primes)
        return [
          { slug: 'bruxelles_structure_portante', inputSelector: '[data-bruxelles-prime-card-target="inputStructurePortante"]', resultSelector: '[data-bruxelles-prime-card-target="resultStructurePortante"]' },
          { slug: 'bruxelles_gestion_egouts', inputSelector: '[data-bruxelles-prime-card-target="inputGestionEgouts"]', resultSelector: '[data-bruxelles-prime-card-target="resultGestionEgouts"]' },
          { slug: 'bruxelles_recuperation_eau_pluie', inputSelector: '[data-bruxelles-prime-card-target="inputRecuperationEauPluie"]', resultSelector: '[data-bruxelles-prime-card-target="resultRecuperationEauPluie"]' },
          { slug: 'bruxelles_demolition_permeabilisation', inputSelector: '[data-bruxelles-prime-card-target="inputDemolitionPermeabilisation"]', resultSelector: '[data-bruxelles-prime-card-target="resultDemolitionPermeabilisation"]' }
        ]

      case 'bruxelles_prime_d_global':
        // Prime D - Salubrité (2 primes)
        return [
          { slug: 'bruxelles_traitement_humidite_sol', inputSelector: '[data-bruxelles-prime-card-target="inputTraitementHumiditeSol"]', resultSelector: '[data-bruxelles-prime-card-target="resultTraitementHumiditeSol"]' },
          { slug: 'bruxelles_traitement_fongique_insectes', inputSelector: '[data-bruxelles-prime-card-target="inputTraitementFongiqueInsectes"]', resultSelector: '[data-bruxelles-prime-card-target="resultTraitementFongiqueInsectes"]' }
        ]

      case 'bruxelles_prime_e_global':
        // Prime E - Toiture (5 primes)
        return [
          { slug: 'bruxelles_structure_toiture', inputSelector: '[data-bruxelles-prime-card-target="inputStructureToiture"]', resultSelector: '[data-bruxelles-prime-card-target="resultStructureToiture"]' },
          { slug: 'bruxelles_isolation_toiture_etancheite', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationToitureEtancheite"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationToitureEtancheite"]' },
          { slug: 'bruxelles_isolation_thermique_toiture', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationThermiqueToiture"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationThermiqueToiture"]' },
          { slug: 'bruxelles_accessoires_toiture', inputSelector: '[data-bruxelles-prime-card-target="inputAccessoiresToiture"]', resultSelector: '[data-bruxelles-prime-card-target="resultAccessoiresToiture"]' },
          { slug: 'bruxelles_toiture_vegetale', inputSelector: '[data-bruxelles-prime-card-target="inputToitureVegetale"]', resultSelector: '[data-bruxelles-prime-card-target="resultToitureVegetale"]' }
        ]

      case 'bruxelles_prime_f_global':
        // Prime F - Façades (8 primes)
        return [
          { slug: 'bruxelles_isolation_interieure_facade', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationInterieure"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationInterieure"]' },
          { slug: 'bruxelles_isolation_exterieure_facade', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationExterieure"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationExterieure"]' },
          { slug: 'bruxelles_isolation_coulisse', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationCoulisse"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationCoulisse"]' },
          { slug: 'bruxelles_bardage_facade', inputSelector: '[data-bruxelles-prime-card-target="inputBardageFacade"]', resultSelector: '[data-bruxelles-prime-card-target="resultBardageFacade"]' },
          { slug: 'bruxelles_enduit_facade', inputSelector: '[data-bruxelles-prime-card-target="inputEnduitFacade"]', resultSelector: '[data-bruxelles-prime-card-target="resultEnduitFacade"]' },
          { slug: 'bruxelles_embellissement_facade_avant', inputSelector: '[data-bruxelles-prime-card-target="inputEmbellissementAvant"]', resultSelector: '[data-bruxelles-prime-card-target="resultEmbellissementAvant"]' },
          { slug: 'bruxelles_facades_arriere_laterales', inputSelector: '[data-bruxelles-prime-card-target="inputFacadesArriere"]', resultSelector: '[data-bruxelles-prime-card-target="resultFacadesArriere"]' },
          { slug: 'bruxelles_isolation_acoustique_murs', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationAcoustique"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationAcoustique"]' }
        ]

      case 'bruxelles_prime_g_global':
        // Prime G - Portes & fenêtres (4 primes)
        return [
          { slug: 'bruxelles_remplacement_fenetres_bois', inputSelector: '[data-bruxelles-prime-card-target="inputFenetresBois"]', resultSelector: '[data-bruxelles-prime-card-target="resultFenetresBois"]' },
          { slug: 'bruxelles_remplacement_fenetres_pvc_alu', inputSelector: '[data-bruxelles-prime-card-target="inputFenetresPvcAlu"]', resultSelector: '[data-bruxelles-prime-card-target="resultFenetresPvcAlu"]' },
          { slug: 'bruxelles_reparation_fenetres', inputSelector: '[data-bruxelles-prime-card-target="inputReparationFenetres"]', resultSelector: '[data-bruxelles-prime-card-target="resultReparationFenetres"]' },
          { slug: 'bruxelles_reparation_portes', inputSelector: '[data-bruxelles-prime-card-target="inputReparationPortes"]', resultSelector: '[data-bruxelles-prime-card-target="resultReparationPortes"]' }
        ]

      case 'bruxelles_prime_h_global':
        // Prime H - Sols & planchers (2 primes)
        return [
          { slug: 'bruxelles_isolation_thermique_sols', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationThermiqueSols"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationThermiqueSols"]' },
          { slug: 'bruxelles_isolation_acoustique_sols', inputSelector: '[data-bruxelles-prime-card-target="inputIsolationAcoustiqueSols"]', resultSelector: '[data-bruxelles-prime-card-target="resultIsolationAcoustiqueSols"]' }
        ]

      case 'bruxelles_prime_i_global':
        // Prime I - Aménagement intérieur (4 primes)
        return [
          { slug: 'bruxelles_escaliers', inputSelector: '[data-bruxelles-prime-card-target="inputEscaliers"]', resultSelector: '[data-bruxelles-prime-card-target="resultEscaliers"]' },
          { slug: 'bruxelles_emplacement_velo', inputSelector: '[data-bruxelles-prime-card-target="inputEmplacementVelo"]', resultSelector: '[data-bruxelles-prime-card-target="resultEmplacementVelo"]' },
          { slug: 'bruxelles_protection_incendie', inputSelector: '[data-bruxelles-prime-card-target="inputProtectionIncendie"]', resultSelector: '[data-bruxelles-prime-card-target="resultProtectionIncendie"]' },
          { slug: 'bruxelles_amenagement_pmr', inputSelector: '[data-bruxelles-prime-card-target="inputAmenagementPmr"]', resultSelector: '[data-bruxelles-prime-card-target="resultAmenagementPmr"]' }
        ]

      case 'bruxelles_prime_j_global':
        // Prime J - Chauffage et chauffe-eau
        return [
          { slug: 'bruxelles_pac_chauffage', inputSelector: '[data-bruxelles-prime-card-target="inputPacChauffage"]', resultSelector: '[data-bruxelles-prime-card-target="resultPacChauffage"]' },
          { slug: 'bruxelles_radiateurs_basse_temperature', inputSelector: '[data-bruxelles-prime-card-target="inputRadiateursBT"]', resultSelector: '[data-bruxelles-prime-card-target="resultRadiateursBT"]' },
          { slug: 'bruxelles_thermostat', inputSelector: '[data-bruxelles-prime-card-target="inputThermostat"]', resultSelector: '[data-bruxelles-prime-card-target="resultThermostat"]' },
          { slug: 'bruxelles_vannes_thermostatiques', inputSelector: '[data-bruxelles-prime-card-target="inputVannesThermostatiques"]', resultSelector: '[data-bruxelles-prime-card-target="resultVannesThermostatiques"]' },
          { slug: 'bruxelles_chauffe_eau_solaire', inputSelector: '[data-bruxelles-prime-card-target="inputChauffeEauSolaire"]', resultSelector: '[data-bruxelles-prime-card-target="resultChauffeEauSolaire"]' },
          { slug: 'bruxelles_chauffe_eau_pac', inputSelector: '[data-bruxelles-prime-card-target="inputChauffeEauPac"]', resultSelector: '[data-bruxelles-prime-card-target="resultChauffeEauPac"]' },
          { slug: 'bruxelles_raccordement_reseau_chaleur', inputSelector: '[data-bruxelles-prime-card-target="inputRaccordementReseau"]', resultSelector: '[data-bruxelles-prime-card-target="resultRaccordementReseau"]' }
        ]

      case 'bruxelles_prime_kl_global':
        // Prime KL - Sanitaires et électricité
        return [
          { slug: 'bruxelles_appareil_sanitaire', inputSelector: '[data-bruxelles-prime-card-target="inputAppareilSanitaire"]', resultSelector: '[data-bruxelles-prime-card-target="resultAppareilSanitaire"]' },
          { slug: 'bruxelles_mise_normes_electricite_gaz', inputSelector: '[data-bruxelles-prime-card-target="inputMiseNormesElecGaz"]', resultSelector: '[data-bruxelles-prime-card-target="resultMiseNormesElecGaz"]' }
        ]

      case 'bruxelles_prime_m_global':
        // Prime M - Ventilation
        return [
          { slug: 'bruxelles_ventilation_systeme_c', inputSelector: '[data-bruxelles-prime-card-target="inputVentilationC"]', resultSelector: '[data-bruxelles-prime-card-target="resultVentilationC"]' },
          { slug: 'bruxelles_ventilation_systeme_d', inputSelector: '[data-bruxelles-prime-card-target="inputVentilationD"]', resultSelector: '[data-bruxelles-prime-card-target="resultVentilationD"]' }
        ]

      // Prime B (protection échafaudages) est une prime simple, pas composite
      // Prime Z (bonus) retirée temporairement
      default:
        return []
    }
  }

  updateTotal(total) {
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `${total.toLocaleString('fr-BE')} €`

      // Ajouter une classe pour l'animation
      this.totalTarget.classList.add('updated')
      setTimeout(() => {
        this.totalTarget.classList.remove('updated')
      }, 300)
    }
  }

  getParentController() {
    // Trouver le controller parent bruxelles-prime-calcul
    let parent = this.element.parentElement
    while (parent) {
      if (parent.hasAttribute('data-controller') &&
          parent.getAttribute('data-controller').includes('bruxelles-prime-calcul')) {
        return this.application.getControllerForElementAndIdentifier(parent, 'bruxelles-prime-calcul')
      }
      parent = parent.parentElement
    }
    return null
  }

  // Méthode pour recalculer (appelée depuis le controller parent)
  recalculate() {
    this.calculate()
  }

  // Actions pour les événements de changement (compatibilité)
  calculateAudit() { this.calculate() }
  calculateToiture() { this.calculate() }
  calculateIsolation() { this.calculate() }
  calculateMenuiseries() { this.calculate() }
  calculateChauffage() { this.calculate() }
  calculateVentilation() { this.calculate() }
  calculateElectricite() { this.calculate() }
  calculateRenouvelables() { this.calculate() }
  calculateAutres() { this.calculate() }
}
