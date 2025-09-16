import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "inputTransition", "resultTransition",
    "inputDigitalisation", "resultDigitalisation",
    "inputConsultance", "resultConsultance",
    "inputConsultanceTransition", "resultConsultanceTransition",
    "inputAccessibilite", "resultAccessibilite",
    "inputEquipement", "resultEquipement",
    "inputImmobilier", "resultImmobilier",
    "inputRecrutement", "resultRecrutement",
    "inputFormation", "resultFormation",
    "inputConseil", "resultConseil",
    "inputCoworking", "resultCoworking",
    // Nouveaux targets ajoutés pour couvrir tous les inputs
    "inputInvestissementsTransition", "resultInvestissementsTransition",
    "inputMobiliteVeloCargo", "resultMobiliteVeloCargo",
    "inputMobiliteUtilitaireElectrique", "resultMobiliteUtilitaireElectrique",
    "inputMobiliteUtilitaireRetrofit", "resultMobiliteUtilitaireRetrofit",
    "inputMaterielTravaux", "resultMaterielTravaux",
    "inputConformite", "resultConformite",
    "inputSecurisation", "resultSecurisation",
    "total"
  ]

  static values = {
    slug: String
  }

  connect() {
    console.log(`🎯 Contrôleur Bruxelles Entreprise Card connecté - ${this.slugValue}`)

    // Charger les données d'aides depuis le script JSON
    this.loadAidesData()

    // Initialiser les event listeners
    this.setupEventListeners()

    // Calculer les totaux initiaux
    this.calculateTotals()
  }

  disconnect() {
    console.log(`👋 Contrôleur Bruxelles Entreprise Card déconnecté - ${this.slugValue}`)
  }

  loadAidesData() {
    try {
      // Récupérer les données depuis le script JSON injecté dans le template
      const scriptElement = document.getElementById('bruxelles-entreprise-data')
      if (scriptElement) {
        this.aidesData = JSON.parse(scriptElement.textContent)
        console.log(`📊 Aides chargées pour Bruxelles entreprise:`, Object.keys(this.aidesData).length, 'catégories')
      } else {
        console.error('❌ Script #bruxelles-entreprise-data non trouvé')
        this.aidesData = {}
      }
    } catch (error) {
      console.error('❌ Erreur chargement aides:', error)
      this.aidesData = {}
    }
  }

  setupEventListeners() {
    // Ajouter des event listeners sur tous les inputs
    const inputTargets = [
      'inputTransition', 'inputDigitalisation', 'inputConsultance', 'inputConsultanceTransition',
      'inputAccessibilite', 'inputEquipement', 'inputImmobilier', 'inputRecrutement',
      'inputFormation', 'inputConseil', 'inputCoworking'
    ]

    inputTargets.forEach(targetName => {
      if (this.hasTarget(targetName)) {
        this[`${targetName}Target`].addEventListener('input', (event) => {
          this.onInputChange(event, targetName)
        })
      }
    })
  }

  // Méthode appelée par les data-action dans le template
  handleInput(event) {
    console.log('🎯 handleInput appelé:', event.target.name || event.target.id)

    // Détecter le type d'input depuis l'élément
    const inputElement = event.target
    const montantInvesti = parseFloat(inputElement.value) || 0

    // Utiliser le slug directement depuis l'attribut data-bruxelles-entreprise-card-slug
    const aideSlug = inputElement.getAttribute('data-bruxelles-entreprise-card-slug')

    if (aideSlug) {
      console.log(`🎯 Slug trouvé dans data attribute: ${aideSlug}`)
      const montantPrime = this.calculatePrime(aideSlug, montantInvesti)

      // Trouver l'élément de résultat correspondant dans le même container
      const resultElement = this.findResultElement(inputElement)
      if (resultElement) {
        resultElement.textContent = `${Math.round(montantPrime).toLocaleString()} €`
        console.log(`✅ Résultat mis à jour: ${Math.round(montantPrime)} €`)
      } else {
        console.log('❌ Élément de résultat non trouvé')
      }

      // Recalculer les totaux
      this.calculateTotals()
    } else {
      console.log('❌ Pas de slug trouvé dans data-bruxelles-entreprise-card-slug')
    }
  }

  onInputChange(event, targetName) {
    const montantInvesti = parseFloat(event.target.value) || 0
    const resultTargetName = targetName.replace('input', 'result')

    console.log(`💰 Input changé: ${targetName} = ${montantInvesti}€`)

    // Mapper le target vers le slug de l'aide
    const aideSlug = this.mapTargetToSlug(targetName)

    if (aideSlug && this.hasTarget(resultTargetName)) {
      const montantPrime = this.calculatePrime(aideSlug, montantInvesti)
      this[`${resultTargetName}Target`].textContent = `${Math.round(montantPrime).toLocaleString()} €`

      // Recalculer les totaux
      this.calculateTotals()
    }
  }

  mapTargetToSlug(targetName) {
    const mapping = {
      'inputTransition': 'bruxelles_transition_consultance',
      'inputDigitalisation': 'bruxelles_prime_digitalisation',
      'inputConsultance': 'bruxelles_prime_consultance',
      'inputConsultanceTransition': 'bruxelles_transition_consultance',
      'inputAccessibilite': 'bruxelles_prime_accessibilite',
      'inputEquipement': 'bruxelles_prime_materiel_travaux',
      'inputImmobilier': 'bruxelles_prime_immobilier',
      'inputRecrutement': 'bruxelles_prime_recrutement',
      'inputFormation': 'bruxelles_prime_formation',
      'inputConseil': 'bruxelles_prime_consultance',
      'inputCoworking': 'bruxelles_prime_consultance', // Pas de coworking spécifique
      'inputInvestissementsTransition': 'bruxelles_investissements_transition_economique',
      'inputMobiliteVeloCargo': 'bruxelles_mobilite_velo_cargo',
      'inputMobiliteUtilitaireElectrique': 'bruxelles_mobilite_utilitaire_electrique',
      'inputMobiliteUtilitaireRetrofit': 'bruxelles_mobilite_utilitaire_retrofit',
      'inputMaterielTravaux': 'bruxelles_prime_materiel_travaux',
      'inputConformite': 'bruxelles_prime_conformite_normes',
      'inputSecurisation': 'bruxelles_prime_securisation'
    }

    return mapping[targetName]
  }

  calculatePrime(aideSlug, montantInvesti) {
    console.log(`🧮 Calcul pour aide: ${aideSlug}, montant: ${montantInvesti}€`)

    // Trouver l'aide dans les données (structure par catégorie)
    let aide = null
    for (const [categorie, aides] of Object.entries(this.aidesData)) {
      if (aides[aideSlug]) {
        aide = aides[aideSlug]
        break
      }
    }

    if (!aide) {
      console.error(`❌ Prime non trouvée: ${aideSlug}`)
      return 0
    }

    console.log(`✅ Aide trouvée:`, aide)

    // Obtenir les paramètres d'entreprise depuis le controller coordinateur
    const coordinatorController = this.getCoordinatorController()
    const tailleEntreprise = coordinatorController?.hasTailleEntrepriseTarget ? coordinatorController.tailleEntrepriseTarget.value : null
    const ageEntreprise = coordinatorController?.hasAgeEntrepriseTarget ? coordinatorController.ageEntrepriseTarget.value : null

    // Calculer la prime en fonction du taux_aide et des plafonds
    const tauxAide = aide.taux_aide || 25.0
    let montantPrime = montantInvesti * (tauxAide / 100)

    // Appliquer le plafond si défini
    if (aide.montant_max) {
      montantPrime = Math.min(montantPrime, aide.montant_max)
    }

    // Vérifier le montant minimum adaptatif
    const montantMinAdaptatif = this.getAdaptiveMinimumInvestment(aideSlug, tailleEntreprise, ageEntreprise)
    if (montantMinAdaptatif && montantInvesti < montantMinAdaptatif) {
      console.log(`❌ Montant investi (${montantInvesti}€) inférieur au minimum requis (${montantMinAdaptatif}€)`)
      montantPrime = 0
    } else {
      // Vérifier le montant minimum de prime (fallback)
      if (aide.montant_min && montantPrime < aide.montant_min) {
        montantPrime = 0
      }
    }

    console.log(`💰 Calcul final: ${montantInvesti}€ × ${tauxAide}% = ${Math.round(montantPrime)}€`)
    return montantPrime
  }

  getCriteresEntreprise() {
    // Pour l'instant, critères par défaut
    // TODO: récupérer depuis les inputs du formulaire
    return {
      petiteEntreprise: true,    // < 50 employés
      zoneDifficile: false,      // zone de revitalisation urbaine
      premiereStat: false        // première fois que l'entreprise demande cette aide
    }
  }

  calculateTotals() {
    // Calculer le total par catégorie et global
    const categories = {
      transition: ['resultTransition', 'resultConsultanceTransition'],
      investissements: ['resultEquipement', 'resultImmobilier', 'resultAccessibilite'],
      recrutement: ['resultRecrutement', 'resultFormation'],
      services: ['resultDigitalisation', 'resultConsultance', 'resultConseil', 'resultCoworking']
    }

    let totalGlobal = 0

    // Calculer totaux par catégorie
    Object.entries(categories).forEach(([categorie, targets]) => {
      let totalCategorie = 0

      targets.forEach(targetName => {
        if (this.hasTarget(targetName)) {
          const value = this.parseResultValue(this[`${targetName}Target`].textContent)
          totalCategorie += value
        }
      })

      totalGlobal += totalCategorie

      // Afficher le total de la catégorie si l'élément existe
      const totalElement = document.querySelector(`[data-total="${categorie}"]`)
      if (totalElement) {
        totalElement.textContent = `${totalCategorie.toLocaleString()} €`
      }
    })

    // Afficher le total global
    if (this.hasTarget('total')) {
      this.totalTarget.textContent = `${totalGlobal.toLocaleString()} €`
    }

    console.log(`📊 Total calculé: ${totalGlobal.toLocaleString()}€`)
  }

  parseResultValue(text) {
    // Extraire le nombre du texte "1.234 €"
    const cleanText = text.replace(/[€\s.]/g, '').replace(',', '.')
    return parseFloat(cleanText) || 0
  }

  // Mapper l'input HTML vers un slug d'aide
  mapInputToSlug(inputElement) {
    const name = inputElement.name || inputElement.id || ''

    // Mappings basés sur les noms d'inputs dans le template et les vrais slugs DB
    const mapping = {
      'inputTransition': 'bruxelles_transition_consultance',
      'inputConsultanceTransition': 'bruxelles_transition_consultance',
      'inputDigitalisation': 'bruxelles_prime_digitalisation',
      'inputConsultance': 'bruxelles_prime_consultance',
      'inputAccessibilite': 'bruxelles_prime_accessibilite',
      'inputEquipement': 'bruxelles_prime_materiel_travaux',
      'inputImmobilier': 'bruxelles_prime_immobilier',
      'inputRecrutement': 'bruxelles_prime_recrutement',
      'inputFormation': 'bruxelles_prime_formation',
      'inputConseil': 'bruxelles_prime_consultance',
      'inputCoworking': 'bruxelles_prime_consultance'
    }

    return mapping[name] || null
  }

  // Trouver l'élément de résultat correspondant à un input
  findResultElement(inputElement) {
    // Récupérer le target name de l'input
    const inputTarget = inputElement.getAttribute('data-bruxelles-entreprise-card-target')

    if (inputTarget && inputTarget.startsWith('input')) {
      // Remplacer 'input' par 'result' pour trouver le target correspondant
      const resultTargetName = inputTarget.replace('input', 'result')

      // Chercher l'élément avec ce target dans le même contrôleur
      const resultElement = document.querySelector(`[data-bruxelles-entreprise-card-target="${resultTargetName}"]`)

      console.log(`🔍 Recherche résultat: ${inputTarget} → ${resultTargetName}`, resultElement ? '✅ trouvé' : '❌ non trouvé')

      return resultElement
    }

    // Fallback: chercher dans le même container
    const container = inputElement.closest('.input-group, .col-12')
    if (container) {
      return container.querySelector('.input-group-text, [data-target*="result"]')
    }

    return null
  }

  hasTarget(targetName) {
    return this.targets.findAll(targetName).length > 0
  }

  getCoordinatorController() {
    // Récupérer le controller coordinateur (parent)
    const coordinatorElement = this.element.closest('[data-controller*="bruxelles-entreprise-cartes"]')
    if (coordinatorElement) {
      return this.application.getControllerForElementAndIdentifier(coordinatorElement, 'bruxelles-entreprise-cartes')
    }
    return null
  }

  getAdaptiveMinimumInvestment(aideSlug, tailleEntreprise, ageEntreprise) {
    switch (aideSlug) {
      case 'bruxelles_prime_materiel_travaux':
        return this.calculateMinimumForMaterielTravaux(tailleEntreprise, ageEntreprise)
      case 'bruxelles_prime_immobilier':
        return 100000
      case 'bruxelles_prime_conformite_normes':
        return 5000
      case 'bruxelles_prime_securisation':
        return 2000
      case 'bruxelles_prime_accessibilite':
        return 1000
      case 'bruxelles_investissements_transition_economique':
        return 2000
      case 'bruxelles_mobilite_velo_cargo':
        return 500
      case 'bruxelles_prime_consultance':
        return 500
      case 'bruxelles_prime_digitalisation':
        return 500
      default:
        return null // Utiliser le montant par défaut des données JSON
    }
  }

  calculateMinimumForMaterielTravaux(tailleEntreprise, ageEntreprise) {
    // Déterminer si c'est une entreprise "starter" (< 4 ans)
    const isStarter = ageEntreprise === "moins_4_ans" || ageEntreprise === "moins_3_ans"

    // Si c'est une starter, minimum 5.000€ indépendamment de la taille
    if (isStarter) {
      return 5000
    }

    // Sinon, selon la taille d'entreprise
    switch (tailleEntreprise) {
      case "tpe":
      case "micro":
        return 7500  // Micro > 4 ans
      case "pme":
      case "petite":
        return 15000 // Petite > 4 ans
      case "moyenne":
        return 50000 // Moyenne > 4 ans
      default:
        return 5000  // Valeur par défaut
    }
  }
}
