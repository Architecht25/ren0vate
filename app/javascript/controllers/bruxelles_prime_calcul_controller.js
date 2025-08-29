import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionTitle", "totalGeneral", "categoryDisplay", "categoryBadge", "categoryDescription", "selectedPrimesSummary", "currentCategory"]

  connect() {
    console.log("🎯 Bruxelles Prime Calcul controller connected")

    // Forcer la catégorie I par défaut pour harmoniser dev/prod
    if (!localStorage.getItem("bruxellesCategorieEstimee")) {
      localStorage.setItem("bruxellesCategorieEstimee", "1")
      console.log("🎯 Catégorie par défaut initialisée à I (bruxelles_cat1)")
    }

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

    // Ajouter les événements d'écoute pour les champs spécifiques
    this.addSpecificFieldListeners()
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

    // 2. Harmonisation : forcer catégorie I par défaut dans tous les environnements
    console.log("🎯 Mode par défaut : application catégorie I (harmonisé dev/prod)")
    localStorage.setItem("bruxellesCategorieEstimee", "1")
    return "bruxelles_cat1"
  }

  mapStoredCategoryToInternal(storedCategory, profileType) {
    // Mapper les catégories stockées (1,2,3) vers les catégories internes
    const categoryMap = {
      "1": "bruxelles_cat1", // Entreprises, ASBL
      "2": "bruxelles_cat2", // Syndics
      "3": "bruxelles_cat3"  // AIS, Particuliers (revenus faibles)
    }

    return categoryMap[storedCategory] || "bruxelles_cat1"
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
    // Mettre à jour aussi la catégorie estimée pour cohérence
    const categoryNumber = newCategory.replace('bruxelles_cat', '')
    localStorage.setItem('bruxellesCategorieEstimee', categoryNumber)
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

  addSpecificFieldListeners() {
    // Ajouter les événements d'écoute pour les champs spécifiques des cartes Bruxelles
    console.log("🎯 Ajout des événements d'écoute pour les champs spécifiques Bruxelles")

    // Attendre que le DOM soit prêt
    setTimeout(() => {
      // Carte I - Services et études - Audit maison
      const inputAuditMaison = document.querySelector('[data-bruxelles-prime-card-target="inputAuditMaison"]')
      if (inputAuditMaison) {
        inputAuditMaison.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_audit_energetique_maison', inputAuditMaison, '[data-bruxelles-prime-card-target="resultAuditMaison"]')
        })
        console.log("✅ Événement ajouté pour audit maison")
      }

      // Carte I - Services et études - Audit bâtiment
      const inputAuditBatiment = document.querySelector('[data-bruxelles-prime-card-target="inputAuditBatiment"]')
      if (inputAuditBatiment) {
        inputAuditBatiment.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_audit_energetique_batiment', inputAuditBatiment, '[data-bruxelles-prime-card-target="resultAuditBatiment"]')
        })
        console.log("✅ Événement ajouté pour audit bâtiment")
      }

      // Carte J - Isolation toiture
      const inputIsolationToiture = document.querySelector('[data-bruxelles-prime-card-target="inputIsolationToiture"]')
      if (inputIsolationToiture) {
        inputIsolationToiture.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_isolation_thermique_toiture', inputIsolationToiture, '[data-bruxelles-prime-card-target="resultIsolationToiture"]')
        })
        console.log("✅ Événement ajouté pour isolation toiture")
      }

      // Carte F - Isolation intérieure façade
      const inputIsolationInterieure = document.querySelector('[data-bruxelles-prime-card-target="inputIsolationInterieure"]')
      if (inputIsolationInterieure) {
        inputIsolationInterieure.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_isolation_interieure_facade', inputIsolationInterieure, '[data-bruxelles-prime-card-target="resultIsolationInterieure"]')
        })
        console.log("✅ Événement ajouté pour isolation intérieure façade")
      }

      // Carte M - Pompe à chaleur
      const inputPompeChaleurd = document.querySelector('[data-bruxelles-prime-card-target="inputPompeChaleurd"]')
      if (inputPompeChaleurd) {
        inputPompeChaleurd.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_pac_chauffage', inputPompeChaleurd, '[data-bruxelles-prime-card-target="resultPompeChaleurd"]')
        })
        console.log("✅ Événement ajouté pour pompe à chaleur")
      }

      // Carte I - Services et études - Étude acoustique
      const inputEtudeAcoustique = document.querySelector('[data-bruxelles-prime-card-target="inputEtudeAcoustique"]')
      if (inputEtudeAcoustique) {
        inputEtudeAcoustique.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_etude_acoustique', inputEtudeAcoustique, '[data-bruxelles-prime-card-target="resultEtudeAcoustique"]')
        })
        console.log("✅ Événement ajouté pour étude acoustique")
      }

      // NOTE: Gestion des 3 suivis professionnels supprimée - gérée par bruxelles_prime_card_controller

      // Carte C - Gros-œuvre - Structure portante
      const inputStructurePortante = document.querySelector('[data-bruxelles-prime-card-target="inputStructurePortante"]')
      if (inputStructurePortante) {
        inputStructurePortante.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_structure_portante', inputStructurePortante, '[data-bruxelles-prime-card-target="resultStructurePortante"]')
        })
        console.log("✅ Événement ajouté pour structure portante")
      }

      // NOTE: Gestion égouts supprimée - gérée par bruxelles_prime_card_controller

      // Carte D - Salubrité - Traitement humidité sol
      const inputTraitementHumiditeSol = document.querySelector('[data-bruxelles-prime-card-target="inputTraitementHumiditeSol"]')
      if (inputTraitementHumiditeSol) {
        inputTraitementHumiditeSol.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_traitement_humidite_sol', inputTraitementHumiditeSol, '[data-bruxelles-prime-card-target="resultTraitementHumiditeSol"]')
        })
        console.log("✅ Événement ajouté pour traitement humidité sol")
      }

      // Carte D - Salubrité - Traitement fongique et insectes
      const inputTraitementFongiqueInsectes = document.querySelector('[data-bruxelles-prime-card-target="inputTraitementFongiqueInsectes"]')
      if (inputTraitementFongiqueInsectes) {
        inputTraitementFongiqueInsectes.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_traitement_fongique_insectes', inputTraitementFongiqueInsectes, '[data-bruxelles-prime-card-target="resultTraitementFongiqueInsectes"]')
        })
        console.log("✅ Événement ajouté pour traitement fongique insectes")
      }

      // Carte E - Toiture - Accessoires toiture
      const inputAccessoiresToiture = document.querySelector('[data-bruxelles-prime-card-target="inputAccessoiresToiture"]')
      if (inputAccessoiresToiture) {
        inputAccessoiresToiture.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_accessoires_toiture', inputAccessoiresToiture, '[data-bruxelles-prime-card-target="resultAccessoiresToiture"]')
        })
        console.log("✅ Événement ajouté pour accessoires toiture")
      }

      // NOTE: Carte F - Façades (Bardage, Enduit, etc.) - Gérée par bruxelles_prime_card_controller comme carte composite

      // Carte I - Aménagement - Protection incendie
      const inputProtectionIncendie = document.querySelector('[data-bruxelles-prime-card-target="inputProtectionIncendie"]')
      if (inputProtectionIncendie) {
        inputProtectionIncendie.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_protection_incendie', inputProtectionIncendie, '[data-bruxelles-prime-card-target="resultProtectionIncendie"]')
        })
        console.log("✅ Événement ajouté pour protection incendie")
      }

      // Carte J - Chauffage - Régulation thermique
      const inputRegulationThermique = document.querySelector('[data-bruxelles-prime-card-target="inputRegulationThermique"]')
      if (inputRegulationThermique) {
        inputRegulationThermique.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_regulation_thermique', inputRegulationThermique, '[data-bruxelles-prime-card-target="resultRegulationThermique"]')
        })
        console.log("✅ Événement ajouté pour régulation thermique")
      }

      // Carte I - Services et études - Certificat PEB
      const inputCertificatPeb = document.querySelector('[data-bruxelles-prime-card-target="inputCertificatPeb"]')
      if (inputCertificatPeb) {
        inputCertificatPeb.addEventListener('change', () => {
          this.calculateSpecificPrime('bruxelles_certificat_peb', inputCertificatPeb, '[data-bruxelles-prime-card-target="resultCertificatPeb"]')
        })
        console.log("✅ Événement ajouté pour certificat PEB")
      }

      // Carte E - Toiture - Surface toiture
      const inputSurfaceToiture = document.querySelector('[data-bruxelles-prime-card-target="inputSurfaceToiture"]')
      if (inputSurfaceToiture) {
        inputSurfaceToiture.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_surface_toiture', inputSurfaceToiture, '[data-bruxelles-prime-card-target="resultSurfaceToiture"]')
        })
        console.log("✅ Événement ajouté pour surface toiture")
      }

      // Carte J - Chauffage - Radiateurs BT
      const inputRadiateursBt = document.querySelector('[data-bruxelles-prime-card-target="inputRadiateursBt"]')
      if (inputRadiateursBt) {
        inputRadiateursBt.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_radiateurs_bt', inputRadiateursBt, '[data-bruxelles-prime-card-target="resultRadiateursBt"]')
        })
        console.log("✅ Événement ajouté pour radiateurs BT")
      }

      // Carte I - Aménagement - Mise en conformité électrique
      const inputMiseConformiteElectrique = document.querySelector('[data-bruxelles-prime-card-target="inputMiseConformiteElectrique"]')
      if (inputMiseConformiteElectrique) {
        inputMiseConformiteElectrique.addEventListener('input', () => {
          this.calculateSpecificPrime('bruxelles_mise_en_conformite_electrique', inputMiseConformiteElectrique, '[data-bruxelles-prime-card-target="resultMiseConformiteElectrique"]')
        })
        console.log("✅ Événement ajouté pour mise en conformité électrique")
      }
    }, 500)
  }

  calculateSpecificPrime(primeSlug, inputElement, resultSelector) {
    console.log("🔍 Calcul spécifique Bruxelles pour:", primeSlug)

    const prime = this.primesData[primeSlug]
    if (!prime) {
      console.warn(`Prime Bruxelles non trouvée: ${primeSlug}`)
      return
    }

    const calculData = prime.valeurs_par_categorie[this.currentCategory]
    if (!calculData) {
      console.warn(`Données de calcul non trouvées pour ${primeSlug} - ${this.currentCategory}`)
      return
    }

    let montant = 0

    // Calculer selon le type (adapté au format Bruxelles)
    switch (calculData.type) {
      case 'montant_fixe':
        const isSelected = inputElement.value === "1" || inputElement.checked
        montant = isSelected ? calculData.montant : 0
        console.log(`💰 ${primeSlug}: ${montant}€ (sélectionné: ${isSelected}, montant base: ${calculData.montant}€)`)
        break
      case 'montant_m2':
        const surface = parseFloat(inputElement.value) || 0
        montant = surface * calculData.montant_m2
        console.log(`📐 ${primeSlug}: ${montant}€ (surface: ${surface}m² × ${calculData.montant_m2}€/m²)`)
        break
      case 'montant_unite':
        const quantite = parseFloat(inputElement.value) || 0
        montant = quantite * calculData.montant_unite
        console.log(`🔢 ${primeSlug}: ${montant}€ (quantité: ${quantite} × ${calculData.montant_unite}€/unité)`)
        break
      case 'pourcentage':
        const montantTravaux = parseFloat(inputElement.value) || 0
        const pourcentage = calculData.pourcentage || 0
        const montantMax = calculData.montant_max || Infinity

        // Vérifier s'il y a un calcul basé sur une autre prime
        if (calculData.base_calculation) {
          console.log(`📊 ${primeSlug}: Calcul basé sur ${calculData.base_calculation} - non implémenté pour l'instant`)
          montant = 0
        } else {
          // Calcul sur le montant saisi
          const calculResult = (montantTravaux * pourcentage) / 100
          montant = Math.min(calculResult, montantMax)
          console.log(`📊 ${primeSlug}: ${montant}€ (${montantTravaux}€ × ${pourcentage}%, max: ${montantMax}€)`)
        }
        break
      default:
        console.warn("Type de calcul Bruxelles non géré:", calculData.type)
    }

    // Mettre à jour le résultat spécifique
    const resultElement = document.querySelector(resultSelector)
    if (resultElement) {
      resultElement.textContent = `${montant.toLocaleString('fr-BE')} €`
      console.log("✨ Résultat Bruxelles mis à jour:", resultSelector, "→", montant, "€")
    }

    // Recalculer le total global
    this.updateTotalGlobal()
  }

  getPrimesData() {
    return this.primesData || {}
  }
}
