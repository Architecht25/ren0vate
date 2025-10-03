import { Controller } from "@hotwired/stimulus"

// Contrôleur de carte dédié aux simulations Bruxelles post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "total", "status", "input", "selectEtude", "selectType", "description",
    // Targets de résultats individuels pour tous les inputs
    "resultAuditMaison", "resultAuditBatiment", "resultCertificatPeb",
    "resultEtudeAcoustique", "resultEtudeTotem", "resultSuiviArchitecte",
    "resultSuiviIngenieur", "resultSuiviExpertFacade", "resultProtectionEchafaudages",
    "resultStructurePortante", "resultGestionEgouts", "resultDemolitionPermeabilisation",
    "resultTraitementHumiditeSol", "resultTraitementFongiqueInsectes"
  ]
  static values = { slug: String }

  connect() {
    console.log(`🎯 Contrôleur Bruxelles Simulation Card connecté pour: ${this.slugValue}`)

    // Initialiser à 0€ en attendant les calculs
    this.updateResult(0)

    // Écouter les événements de mise à jour depuis le contrôleur parent
    document.addEventListener('bruxelles:prime-updated', this.handlePrimeUpdate.bind(this))
  }

  disconnect() {
    document.removeEventListener('bruxelles:prime-updated', this.handlePrimeUpdate.bind(this))
  }

  handlePrimeUpdate(event) {
    console.log(`🎯 Événement reçu dans ${this.slugValue}:`, event.detail);
    console.log(`🔍 Clés disponibles dans event.detail:`, Object.keys(event.detail));

    // Mettre à jour toutes les primes individuelles de cette carte
    let cardUpdated = false;

    Object.keys(event.detail).forEach(primeSlug => {
      // Chercher un target de résultat correspondant à ce slug
      const resultTargetName = this.getResultTargetForSlug(primeSlug);
      if (resultTargetName && this.targets.has(resultTargetName)) {
        const amount = event.detail[primeSlug];
        this.updateIndividualResult(resultTargetName, amount);
        cardUpdated = true;
        console.log(`💰 Prime ${primeSlug} mise à jour: ${amount}€ dans target ${resultTargetName}`);
      }
    });

    // Si au moins une prime de cette carte a été mise à jour, recalculer le total
    if (cardUpdated) {
      console.log(`🧮 Recalcul du total de la carte ${this.slugValue}`);
      this.updateCardTotal();
    } else {
      console.log(`⚠️ Aucune prime trouvée pour la carte ${this.slugValue}`);
    }
  }

  calculate() {
    console.log(`🔍 Calculate appelé pour ${this.slugValue}`)

    if (!this.slugValue) {
      console.warn("Pas de slug défini pour cette carte Bruxelles simulation")
      return
    }

    // Déclencher la sauvegarde automatique du parent qui se chargera du calcul
    this.triggerAutoSave()
  }

  triggerAutoSave() {
    // Déclencher un événement pour notifier le contrôleur parent
    const event = new CustomEvent('bruxelles:card-changed', {
      detail: { slug: this.slugValue },
      bubbles: true
    })
    this.element.dispatchEvent(event)
  }

  calculateForfait(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Parcourir tous les inputs pour les primes forfaitaires
    Object.keys(inputs).forEach(inputKey => {
      const value = inputs[inputKey]
      if (value && value > 0) {
        const montant = categoryData.forfait || categoryData.montant || 0
        total += montant * value
      }
    })

    return Math.round(total)
  }

  calculateVariable(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Parcourir tous les inputs pour les primes variables
    Object.keys(inputs).forEach(inputKey => {
      const value = inputs[inputKey]
      if (value && value > 0) {
        const montantParUnite = categoryData.montant_par_unite || categoryData.montant || 0
        total += montantParUnite * value
      }
    })

    return Math.round(total)
  }

  calculateComposite(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Logique composite spécifique selon le slug pour Bruxelles
    if (this.slugValue.includes('bruxelles_prime_a_global')) {
      // Services et études
      const audit = inputs.audit_energetique || false
      const conseil = inputs.conseil_energie || false

      if (audit) total += categoryData.audit_energetique || 0
      if (conseil) total += categoryData.conseil_energie || 0
    } else if (this.slugValue.includes('bruxelles_prime_c_global')) {
      // Gros œuvre
      const surface = parseFloat(inputs.surface_isolation) || 0
      const montantParM2 = categoryData.montant_par_m2 || 0
      total = surface * montantParM2
    } else if (this.slugValue.includes('bruxelles_prime_j_global')) {
      // Chauffage et eau chaude
      const typeInstallation = inputs.type_installation || 'standard'
      const puissance = parseFloat(inputs.puissance) || 0

      const montantBase = categoryData.montant_base || 0
      const montantParKw = categoryData.montant_par_kw || 0

      total = montantBase + (puissance * montantParKw)
    } else {
      // Logique composite générique
      Object.keys(inputs).forEach(inputKey => {
        const value = inputs[inputKey]
        if (value && value > 0) {
          const montant = categoryData.montant || 0
          total += montant * value
        }
      })
    }

    return Math.round(total)
  }

  getInputValues() {
    const inputs = {}

    // Récupérer toutes les valeurs des inputs dans cette carte
    const allInputs = this.element.querySelectorAll('input, select')
    allInputs.forEach(input => {
      if (input.name || input.dataset.slug) {
        const key = input.name || input.dataset.slug
        if (input.type === 'checkbox') {
          inputs[key] = input.checked ? 1 : 0
        } else if (input.type === 'number') {
          inputs[key] = parseFloat(input.value) || 0
        } else {
          inputs[key] = input.value
        }
      }
    })

    return inputs
  }

  updateResult(amount) {
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `${amount.toLocaleString('fr-FR')} €`

      // Animation visuelle
      this.totalTarget.classList.add('updated')
      setTimeout(() => {
        this.totalTarget.classList.remove('updated')
      }, 300)
    }

    // Mettre à jour le statut
    if (this.hasStatusTarget) {
      if (amount > 0) {
        this.statusTarget.innerHTML = '<i class="bi bi-check-circle text-success me-2"></i>Prime calculée'
        this.statusTarget.className = 'badge bg-success'
      } else {
        this.statusTarget.innerHTML = '<i class="bi bi-dash-circle text-muted me-2"></i>Non applicable'
        this.statusTarget.className = 'badge bg-secondary'
      }
    }
  }

  getParentController() {
    // Chercher le contrôleur parent bruxelles-simulation pour les simulations
    const parentElement = this.element.closest('[data-controller*="bruxelles-simulation"]')
    if (parentElement) {
      // Vérifier si l'élément a bien l'attribut data-controller avec bruxelles-simulation
      const controllerAttr = parentElement.getAttribute('data-controller')
      if (controllerAttr && controllerAttr.includes('bruxelles-simulation')) {
        try {
          const parentController = this.application.getControllerForElementAndIdentifier(parentElement, 'bruxelles-simulation')
          if (parentController) {
            console.log(`✅ Parent controller trouvé pour ${this.slugValue}`)
            return parentController
          } else {
            console.log(`⏳ Parent element trouvé mais controller pas encore connecté pour ${this.slugValue}`)
          }
        } catch (error) {
          console.warn(`❌ Erreur lors de la récupération du parent controller pour ${this.slugValue}:`, error)
        }
      }
    } else {
      console.log(`❌ Parent element non trouvé pour ${this.slugValue}`)
    }
    return null
  }

  notifyParentController() {
    // Notifier le contrôleur parent qu'une carte a été mise à jour
    const parentController = this.getParentController()
    if (parentController && typeof parentController.cardUpdated === 'function') {
      parentController.cardUpdated()
    }
  }

  // Actions pour les différents types d'inputs
  onInputChange() {
    this.calculate()
  }

  onSelectChange() {
    this.calculate()
  }

  calculateAudit() { this.calculate() }
  calculateBonus() { this.calculate() }
  calculateSurface() { this.calculate() }
  onTypeChange() { this.calculate() }
  onEtudeChange() { this.calculate() }

  // Nouvelles méthodes pour gérer les totaux par carte
  getResultTargetForSlug(slug) {
    // Mapping des slugs vers les targets de résultat
    const slugToTargetMap = {
      'bruxelles_audit_energetique_maison': 'resultAuditMaison',
      'bruxelles_audit_energetique_batiment': 'resultAuditBatiment',
      'bruxelles_certificat_peb': 'resultCertificatPeb',
      'bruxelles_etude_acoustique': 'resultEtudeAcoustique',
      'bruxelles_etude_totem': 'resultEtudeTotem',
      'bruxelles_suivi_architecte': 'resultSuiviArchitecte',
      'bruxelles_suivi_ingenieur_stabilite': 'resultSuiviIngenieur',
      'bruxelles_suivi_expert_facade': 'resultSuiviExpertFacade',
      'bruxelles_protection_echafaudages': 'resultProtectionEchafaudages',
      'bruxelles_structure_portante': 'resultStructurePortante',
      'bruxelles_gestion_egouts': 'resultGestionEgouts',
      'bruxelles_demolition_permeabilisation': 'resultDemolitionPermeabilisation',
      'bruxelles_traitement_humidite_sol': 'resultTraitementHumiditeSol',
      'bruxelles_traitement_fongique_insectes': 'resultTraitementFongiqueInsectes',
      // TODO: Ajouter d'autres mappings selon les cartes
    };

    return slugToTargetMap[slug];
  }

  updateIndividualResult(targetName, amount) {
    try {
      const target = this[targetName + 'Target'];
      if (target) {
        target.textContent = `${amount} €`;
        console.log(`✅ Target ${targetName} mis à jour: ${amount}€`);
      }
    } catch (error) {
      console.warn(`⚠️ Target ${targetName} non trouvé:`, error);
    }
  }

  updateCardTotal() {
    if (!this.hasTotalTarget) {
      console.log(`⚠️ Pas de totalTarget pour ${this.slugValue}`);
      return;
    }

    let total = 0;
    console.log(`🧮 Début calcul total pour carte ${this.slugValue}`);

    // Parcourir tous les targets de résultat pour additionner les montants
    const resultTargets = [
      'resultAuditMaison',
      'resultAuditBatiment',
      'resultCertificatPeb',
      'resultEtudeAcoustique',
      'resultEtudeTotem',
      'resultSuiviArchitecte',
      'resultSuiviIngenieur',
      'resultSuiviExpertFacade',
      'resultProtectionEchafaudages',
      'resultStructurePortante',
      'resultGestionEgouts',
      'resultDemolitionPermeabilisation',
      'resultTraitementHumiditeSol',
      'resultTraitementFongiqueInsectes',
      // TODO: Ajouter d'autres targets selon les cartes
    ];

    resultTargets.forEach(targetName => {
      try {
        if (this.targets.has(targetName)) {
          const target = this[targetName + 'Target'];
          if (target) {
            const text = target.textContent.trim();
            const amount = parseFloat(text.replace(/[€\s,]/g, '')) || 0;
            total += amount;
            console.log(`🧮 ${targetName}: ${text} → ${amount}€ (total: ${total}€)`);
          }
        }
      } catch (error) {
        // Target optionnel, pas de problème s'il n'existe pas
        console.log(`🔍 Target ${targetName} non trouvé (normal)`);
      }
    });

    this.totalTarget.textContent = `${total} €`;
    console.log(`🧮 Total carte ${this.slugValue} mis à jour: ${total}€`);

    // Animation visuelle
    this.totalTarget.classList.add('updated');
    setTimeout(() => {
      this.totalTarget.classList.remove('updated');
    }, 300);

    // Mettre à jour le statut
    if (this.hasStatusTarget) {
      if (total > 0) {
        this.statusTarget.innerHTML = '<i class="bi bi-check-circle text-success me-2"></i>Primes calculées';
        this.statusTarget.className = 'badge bg-success';
      } else {
        this.statusTarget.innerHTML = '<i class="bi bi-dash-circle text-muted me-2"></i>Aucune prime';
        this.statusTarget.className = 'badge bg-secondary';
      }
    }
  }
}
