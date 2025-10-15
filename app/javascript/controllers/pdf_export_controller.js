import { Controller } from "@hotwired/stimulus"

// Contrôleur pour exporter les données localStorage vers PDF
export default class extends Controller {
  static targets = ["exportButton"]

  connect() {
    console.log("🔄 Contrôleur PDF Export connecté")
  }

  // Export des données d'éligibilité uniquement
  exportEligibilite(event) {
    event.preventDefault()

    const region = this.detectRegion()
    const messages = this.getRegionSpecificMessages(region)
    const eligibiliteData = this.getEligibiliteData(region)

    if (!eligibiliteData || Object.keys(eligibiliteData).length === 0) {
      this.showError(messages.noEligibilite)
      return
    }

    this.downloadPDF('eligibilite', { data: JSON.stringify(eligibiliteData), region })
  }

  // Export des données de primes uniquement
  exportPrimes(event) {
    event.preventDefault()

    const region = this.detectRegion()
    const messages = this.getRegionSpecificMessages(region)
    const primesData = this.getPrimesData(region)

    if (!primesData || Object.keys(primesData).length === 0) {
      this.showError(messages.noPrimes)
      return
    }

    this.downloadPDF('primes', { data: JSON.stringify(primesData), region })
  }

  // Export complet (éligibilité + primes)
  exportComplet(event) {
    event.preventDefault()

    const region = this.detectRegion()
    const messages = this.getRegionSpecificMessages(region)
    const eligibiliteData = this.getEligibiliteData(region)
    const primesData = this.getPrimesData(region)

    if ((!eligibiliteData || Object.keys(eligibiliteData).length === 0) &&
        (!primesData || Object.keys(primesData).length === 0)) {
      this.showError(messages.noData)
      return
    }

    this.downloadPDF('complet', {
      eligibilite_data: JSON.stringify(eligibiliteData),
      primes_data: JSON.stringify(primesData),
      region
    })
  }

  // Détection automatique de la région basée sur l'URL ou les données
  detectRegion() {
    const path = window.location.pathname.toLowerCase()

    // Détection depuis l'URL en priorité (plus fiable sur les pages spécifiques)
    if (path.includes('flandre') || path.includes('vlaanderen')) {
      return 'flandre'
    } else if (path.includes('bruxelles') || path.includes('brussels')) {
      return 'bruxelles'
    } else if (path.includes('wallonie') || path.includes('wallon')) {
      return 'wallonie'
    }

    // Fallback: vérifier les données localStorage
    if (localStorage.getItem('eligibiliteRenovate')) return 'flandre'
    if (localStorage.getItem('eligibiliteBruxelles') || localStorage.getItem('eligibiliteBruxellesParticulier')) return 'bruxelles'
    if (localStorage.getItem('eligibiliteWallonieParticulier') ||
        localStorage.getItem('eligibiliteWallonieEntreprise') ||
        localStorage.getItem('eligibiliteWallonieSyndic') ||
        localStorage.getItem('eligibiliteWallonieAsbl') ||
        localStorage.getItem('eligibiliteWallonieBailleur')) return 'wallonie'

    return 'general'
  }

  // Messages d'erreur contextuels selon la région
  getRegionSpecificMessages(region) {
    const messages = {
      'flandre': {
        noEligibilite: "Aucune donnée d'éligibilité Flandre trouvée. Veuillez d'abord effectuer le test d'éligibilité sur cette page.",
        noPrimes: "Aucune donnée de calcul de primes Flandre trouvée. Veuillez d'abord calculer vos primes sur cette page.",
        noData: "Aucune donnée Flandre trouvée. Veuillez d'abord effectuer un test d'éligibilité et/ou un calcul de primes."
      },
      'bruxelles': {
        noEligibilite: "Aucune donnée d'éligibilité Bruxelles trouvée. Veuillez d'abord effectuer le test d'éligibilité sur cette page.",
        noPrimes: "Aucune donnée de calcul de primes Bruxelles trouvée. Veuillez d'abord calculer vos primes sur cette page.",
        noData: "Aucune donnée Bruxelles trouvée. Veuillez d'abord effectuer un test d'éligibilité et/ou un calcul de primes."
      },
      'wallonie': {
        noEligibilite: "Aucune donnée d'éligibilité Wallonie trouvée. Veuillez d'abord effectuer le test d'éligibilité sur cette page.",
        noPrimes: "Aucune donnée de calcul de primes Wallonie trouvée. Veuillez d'abord calculer vos primes sur cette page.",
        noData: "Aucune donnée Wallonie trouvée. Veuillez d'abord effectuer un test d'éligibilité et/ou un calcul de primes."
      },
      'general': {
        noEligibilite: "Aucune donnée d'éligibilité trouvée. Veuillez d'abord effectuer un test d'éligibilité.",
        noPrimes: "Aucune donnée de calcul de primes trouvée. Veuillez d'abord effectuer un calcul de primes.",
        noData: "Aucune donnée trouvée. Veuillez d'abord effectuer un test d'éligibilité et/ou un calcul de primes."
      }
    }

    return messages[region] || messages['general']
  }

  // Récupération des données d'éligibilité selon la région
  getEligibiliteData(region) {
    let data = {}

    switch(region) {
      case 'flandre':
        const flandreData = localStorage.getItem('eligibiliteRenovate')
        if (flandreData) {
          try {
            data = JSON.parse(flandreData)
          } catch(e) {
            console.error('Erreur parsing données Flandre:', e)
          }
        }

        // Ajouter les données d'affinage Flandre
        const flandreCat = localStorage.getItem('categorie') || localStorage.getItem('categorieEstimee')
        if (flandreCat) data.categorie_revenus = flandreCat

        const flandreStatut = localStorage.getItem('statut_familial')
        if (flandreStatut) data.statut_familial = flandreStatut

        const flandrePersonnes = localStorage.getItem('personnes_charge')
        if (flandrePersonnes) data.personnes_charge = flandrePersonnes

        const flandreRevenu = localStorage.getItem('revenu_net')
        if (flandreRevenu) data.revenu_net = flandreRevenu

        break

      case 'bruxelles':
        const bruxellesData = localStorage.getItem('eligibiliteBruxelles') ||
                             localStorage.getItem('eligibiliteBruxellesParticulier')
        if (bruxellesData) {
          try {
            data = JSON.parse(bruxellesData)
          } catch(e) {
            console.error('Erreur parsing données Bruxelles:', e)
          }
        }

        // Ajouter les données d'affinage Bruxelles
        const bruxellesCat = localStorage.getItem('bruxelles_categorie') || localStorage.getItem('bruxellesCategorieEstimee')
        if (bruxellesCat) data.bruxelles_categorie = bruxellesCat

        const bruxellesEnfants = localStorage.getItem('bruxelles_enfants_charge')
        if (bruxellesEnfants) data.bruxelles_enfants_charge = bruxellesEnfants

        const bruxellesStatut = localStorage.getItem('bruxelles_statut_familial')
        if (bruxellesStatut) data.bruxelles_statut_familial = bruxellesStatut

        const bruxellesRevenu = localStorage.getItem('bruxelles_revenu_estimation')
        if (bruxellesRevenu) data.bruxelles_revenu_estimation = bruxellesRevenu

        break

      case 'wallonie':
        // Essayer toutes les variantes Wallonie dans l'ordre de priorité
        const wallonieKeys = [
          'eligibiliteWallonieParticulier',
          'eligibiliteWallonieEntreprise',
          'eligibiliteWallonieSyndic',
          'eligibiliteWallonieAsbl',
          'eligibiliteWallonieBailleur'
        ]

        for (const key of wallonieKeys) {
          const wallonieData = localStorage.getItem(key)
          if (wallonieData) {
            try {
              data = JSON.parse(wallonieData)
              data._profile_type = key.replace('eligibiliteWallonie', '').toLowerCase()
              break
            } catch(e) {
              console.error(`Erreur parsing données Wallonie ${key}:`, e)
            }
          }
        }

        // Ajouter les données d'affinage Wallonie
        const wallonieCat = localStorage.getItem('wallonie_categorie') || localStorage.getItem('wallonieCategorieEstimee')
        if (wallonieCat) data.wallonie_categorie = wallonieCat

        const wallonieEnfants = localStorage.getItem('wallonie_enfants_charge')
        if (wallonieEnfants) data.wallonie_enfants_charge = wallonieEnfants

        const walloniePersonnesAgees = localStorage.getItem('wallonie_personnes_agees_charge')
        if (walloniePersonnesAgees) data.wallonie_personnes_agees_charge = walloniePersonnesAgees

        const wallonieStatut = localStorage.getItem('wallonie_statut_familial')
        if (wallonieStatut) data.wallonie_statut_familial = wallonieStatut

        const wallonieRevenuTranche = localStorage.getItem('wallonie_revenu_tranche')
        if (wallonieRevenuTranche) data.wallonie_revenu_tranche = wallonieRevenuTranche

        const wallonieRevenu = localStorage.getItem('wallonie_revenu_estimation')
        if (wallonieRevenu) data.wallonie_revenu_estimation = wallonieRevenu

        break
    }

    return data
  }

  // Récupération des données de primes selon la région
  getPrimesData(region) {
    let data = {}

    // Données communes stockées
    const totalPrimes = localStorage.getItem('total_primes')
    const detailsPrimes = localStorage.getItem('details_primes')

    if (totalPrimes) {
      data.total_primes = totalPrimes
    }

    if (detailsPrimes) {
      try {
        data.primes_calculees = JSON.parse(detailsPrimes)
      } catch(e) {
        console.error('Erreur parsing détails primes:', e)
      }
    }

    // Données spécifiques par région
    switch(region) {
      case 'bruxelles':
        const bruxellesCategory = localStorage.getItem('selectedBruxellesCategory')
        const bruxellesCategoryEstimee = localStorage.getItem('bruxellesCategorieEstimee')
        if (bruxellesCategory || bruxellesCategoryEstimee) {
          data.categories = {
            selected_category: bruxellesCategory,
            estimated_category: bruxellesCategoryEstimee
          }
        }
        break

      case 'wallonie':
        const wallonieCategory = localStorage.getItem('selectedWallonieCategory')
        const wallonieCat = localStorage.getItem('wallonie_categorie')
        if (wallonieCategory || wallonieCat) {
          data.categories = {
            selected_category: wallonieCategory,
            wallonie_category: wallonieCat
          }
        }
        break
    }

    // Essayer de récupérer les inputs utilisateur depuis le DOM si disponibles
    const userInputs = this.collectUserInputsFromDOM()
    if (Object.keys(userInputs).length > 0) {
      data.user_inputs = userInputs
    }

    // Collecter les totaux par section
    const sectionTotals = this.collectSectionTotals()
    if (Object.keys(sectionTotals).length > 0) {
      data.section_totals = sectionTotals
    }

    // Collecter les détails de chaque prime individuelle
    const individualPrimes = this.collectIndividualPrimes()
    if (individualPrimes && individualPrimes.length > 0) {
      data.individual_primes = individualPrimes
    }

    return data
  }

  // Collecte des inputs utilisateur depuis le DOM actuel
  collectUserInputsFromDOM() {
    const inputs = {}

    // Chercher les checkboxes cochées
    document.querySelectorAll('input[type="checkbox"]:checked').forEach(checkbox => {
      if (checkbox.name && checkbox.name !== '') {
        inputs[checkbox.name] = true
      }
    })

    // Chercher les radios sélectionnés
    document.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
      if (radio.name && radio.value) {
        inputs[radio.name] = radio.value
      }
    })

    // Chercher les inputs de surface avec valeurs
    document.querySelectorAll('input[type="number"]').forEach(input => {
      if (input.value && parseFloat(input.value) > 0) {
        const label = this.getInputLabel(input)
        if (label) {
          inputs[label] = `${input.value} m²`
        }
      }
    })

    return inputs
  }

  // Aide pour obtenir le label d'un input
  getInputLabel(input) {
    // Chercher le label associé
    const label = document.querySelector(`label[for="${input.id}"]`)
    if (label) {
      return label.textContent.trim()
    }

    // Chercher dans le parent pour un label
    const parent = input.closest('.form-group, .mb-3, .form-floating')
    if (parent) {
      const parentLabel = parent.querySelector('label')
      if (parentLabel) {
        return parentLabel.textContent.trim()
      }
    }

    // Utiliser placeholder ou name comme fallback
    return input.placeholder || input.name || 'Champ non identifié'
  }

  // Collecte des totaux par section depuis le DOM
  collectSectionTotals() {
    const totals = {}

    // Totaux Wallonie
    const totalToiture = document.querySelector('[data-wallonie-prime-card-target="totalToiture"]')
    if (totalToiture && totalToiture.textContent.trim() !== '0 €') {
      totals['Total Toiture'] = totalToiture.textContent.trim()
    }

    const totalMurs = document.querySelector('[data-wallonie-prime-card-target="totalMurs"]')
    if (totalMurs && totalMurs.textContent.trim() !== '0 €') {
      totals['Total Murs'] = totalMurs.textContent.trim()
    }

    const totalSols = document.querySelector('[data-wallonie-prime-card-target="totalSols"]')
    if (totalSols && totalSols.textContent.trim() !== '0 €') {
      totals['Total Sols'] = totalSols.textContent.trim()
    }

    const totalVentilation = document.querySelector('[data-wallonie-prime-card-target="totalVentilation"]')
    if (totalVentilation && totalVentilation.textContent.trim() !== '0 €') {
      totals['Total Ventilation'] = totalVentilation.textContent.trim()
    }

    return totals
  }

  // Collecte des primes individuelles avec leurs valeurs calculées
  collectIndividualPrimes() {
    console.log('🔍 Starting collectIndividualPrimes...');

    const targetMappings = {
      // TOITURE (5 types)
      'inputCouverture': 'Remplacement couverture',
      'inputCharpente': 'Rénovation charpente',
      'inputEvacuation': 'Évacuation eaux pluviales',
      'inputIsolationThermique': 'Isolation thermique',
      'inputIsolationBiosource': 'Isolation biosourcée',

      // MURS (7 types)
      'inputInfiltration': 'Assèchement infiltration',
      'inputHumidite': 'Assèchement humidité',
      'inputRenforcement': 'Renforcement murs',
      'inputMerule': 'Traitement mérule',
      'inputRadon': 'Traitement radon',
      // Note: inputIsolationThermique et inputIsolationBiosource sont réutilisés mais seront différenciés par section

      // SOLS (4 types)
      'inputIsolationSols': 'Isolation sols',
      'inputSupports': 'Remplacement supports',
      'inputFinitionPlanchers': 'Finition planchers',
      // Note: inputIsolationBiosource est aussi réutilisé ici

      // VENTILATION (4 types)
      'inputVmcSimpleComplete': 'VMC simple flux complète',
      'inputVmcDoubleComplete': 'VMC double flux complète',
      'inputVmcSimplePartielle': 'VMC simple flux partielle',
      'inputVmcDoublePartielle': 'VMC double flux partielle',

      // CHAUDIÈRE (5 types)
      'inputPacEauChaude': 'PAC eau chaude',
      'inputPacChauffage': 'PAC chauffage/combinée',
      'inputChaudiereBiomasse': 'Chaudière biomasse',
      'inputPoeleBiomasse': 'Poêle biomasse',
      'inputChauffeEauSolaire': 'Chauffe-eau solaire',

      // AMÉLIORATIONS CHAUFFAGE (10 types) - Noms exacts basés sur les partials
      'inputIsolationConduites': 'Isolation conduites chauffage',
      'inputIsolationBallon500': 'Isolation ballon ≤500l',
      'inputIsolationBallonPlus500': 'Isolation ballon >500l',
      'inputCirculateurMax3Logements': 'Circulateur ≤3 logements',
      'inputCirculateurMin4Logements': 'Circulateur ≥4 logements',
      'inputRemplacementBallon500': 'Remplacement ballon ≤500l',
      'inputRemplacementBallonPlus500': 'Remplacement ballon >500l',
      'inputMin5VannesThermostatiques': 'Min 5 vannes thermostatiques',
      'inputVannesSupplementaires': 'Vannes supplémentaires',
      'inputThermostatAmbiance': 'Thermostat ambiance',

      // EAU CHAUDE SANITAIRE (6 types) - Noms exacts différents d'améliorations
      'inputRemplacementBallonSup': 'Remplacement ballon ECS >500l',
      'inputEchangeurPlaques': 'Échangeur à plaques',
      'inputIsolationBallonSup': 'Isolation ballon ECS >500l',
      // Note: inputRemplacementBallon500, inputIsolationConduites, inputIsolationBallon500 sont partagés avec améliorations

      // MENUISERIES (1 type)
      'inputMenuiseries': 'Surface vitrages',

      // AUDIT (1 type)
      'inputAudit': 'Audit énergétique',

      // INSTALLATIONS (2 types)
      'inputElectricite': 'Installation électrique',
      'inputGaz': 'Installation gaz'
    };

    const individualPrimes = [];

    // Parcourir tous les éléments avec data-wallonie-prime-card-target d'input
    document.querySelectorAll('[data-wallonie-prime-card-target^="input"]').forEach(inputElement => {
      const targetName = inputElement.getAttribute('data-wallonie-prime-card-target');

      if (targetMappings[targetName]) {
        const resultTarget = targetName.replace('input', 'result');
        const resultElement = document.querySelector(`[data-wallonie-prime-card-target="${resultTarget}"]`);

        let inputValue = '';
        let resultValue = '';

        // Récupérer la valeur d'input
        if (inputElement.tagName === 'SELECT') {
          const selectedOption = inputElement.options[inputElement.selectedIndex];
          inputValue = selectedOption ? selectedOption.text : inputElement.value;
        } else {
          inputValue = inputElement.value || '0';
        }

        // Récupérer la valeur de résultat
        if (resultElement) {
          resultValue = resultElement.textContent.trim();
        }

        // Seulement ajouter si il y a une valeur significative
        if (inputValue && inputValue !== '0' && inputValue !== 'Non' && resultValue && resultValue !== '0 €') {
          // Déterminer la section basée sur le contexte de la carte
          const card = inputElement.closest('[data-controller="wallonie-prime-card"]');
          let section = 'Travaux';

          if (card) {
            const slugValue = card.getAttribute('data-wallonie-prime-card-slug-value');
            if (slugValue) {
              if (slugValue.includes('toiture')) section = 'Travaux Toiture';
              else if (slugValue.includes('murs')) section = 'Travaux Murs';
              else if (slugValue.includes('sols')) section = 'Travaux Sols';
              else if (slugValue.includes('ventilation')) section = 'Ventilation';
              else if (slugValue.includes('chaudiere')) section = 'Systèmes Chauffage';
              else if (slugValue.includes('amelioration_chauffage')) section = 'Améliorations Chauffage';
              else if (slugValue.includes('eau_chaude_sanitaire')) section = 'Eau Chaude Sanitaire';
              else if (slugValue.includes('menuiseries')) section = 'Menuiseries';
              else if (slugValue.includes('audit')) section = 'Audit Énergétique';
              else if (slugValue.includes('installation_electrique')) section = 'Installation Électrique';
              else if (slugValue.includes('installation_gaz')) section = 'Installation Gaz';
            }

            // Si le slug n'est pas reconnu, essayer avec le titre de la carte
            if (section === 'Travaux') {
              const cardTitle = card.querySelector('.card-title, h6');
              if (cardTitle) {
                const title = cardTitle.textContent.trim().toLowerCase();
                if (title.includes('audit')) section = 'Audit Énergétique';
                else if (title.includes('toiture')) section = 'Travaux Toiture';
                else if (title.includes('murs')) section = 'Travaux Murs';
                else if (title.includes('sols')) section = 'Travaux Sols';
                else if (title.includes('ventilation')) section = 'Ventilation';
                else if (title.includes('chauffage') && title.includes('système')) section = 'Systèmes Chauffage';
                else if (title.includes('amélioration')) section = 'Améliorations Chauffage';
                else if (title.includes('eau chaude')) section = 'Eau Chaude Sanitaire';
                else if (title.includes('menuiseries')) section = 'Menuiseries';
                else if (title.includes('électrique')) section = 'Installation Électrique';
                else if (title.includes('gaz')) section = 'Installation Gaz';
              }
            }
          }

          individualPrimes.push({
            section: section,
            label: targetMappings[targetName],
            input_value: inputValue,
            result_value: resultValue,
            target: targetName
          });
        }
      }
    });

    console.log('📊 Individual primes collected:', individualPrimes);
    return individualPrimes;
  }

  // Fonction pour trouver le span de résultat associé à un input
  findAssociatedResultSpan(input) {
    // Chercher dans le même container parent
    const container = input.closest('.row, .col, .form-group, .mb-3')
    if (container) {
      // Chercher un span avec une classe de résultat
      const resultSpan = container.querySelector('.badge, .text-success, .text-primary, [class*="badge"]')
      if (resultSpan && resultSpan.textContent.includes('€')) {
        return resultSpan
      }
    }

    // Chercher dans les éléments suivants
    let nextElement = input.nextElementSibling
    while (nextElement) {
      if (nextElement.textContent.includes('€')) {
        return nextElement
      }
      nextElement = nextElement.nextElementSibling
    }

    return null
  }

  // Aide pour trouver le label d'une prime
  findPrimeLabel(element) {
    // Chercher dans la carte parent
    const card = element.closest('.card')
    if (card) {
      const title = card.querySelector('.card-title, h3, h4, h5')
      if (title) {
        return title.textContent.trim()
      }
    }

    // Chercher dans le conteneur parent
    const container = element.closest('.form-group, .mb-3, .prime-item')
    if (container) {
      const label = container.querySelector('label, .label, .prime-label')
      if (label) {
        return label.textContent.trim()
      }
    }

    // Chercher un label précédent
    const previousElement = element.previousElementSibling
    if (previousElement && (previousElement.tagName === 'LABEL' || previousElement.classList.contains('label'))) {
      return previousElement.textContent.trim()
    }

    return element.dataset.wallonieprimeCardTarget || 'Prime non identifiée'
  }

  // Téléchargement du PDF
  async downloadPDF(type, data) {
    try {
      // Afficher un indicateur de chargement
      this.showLoading(true)

      const response = await fetch(`/pdf_exports/${type}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify(data)
      })

      if (!response.ok) {
        throw new Error(`Erreur HTTP: ${response.status}`)
      }

      // Créer un blob PDF et déclencher le téléchargement
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `ren0vate_${type}_${data.region}_${new Date().toISOString().slice(0,10)}.pdf`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      window.URL.revokeObjectURL(url)

      this.showSuccess(`PDF ${type} exporté avec succès !`)

    } catch (error) {
      console.error('Erreur lors de l\'export PDF:', error)
      this.showError(`Erreur lors de l'export PDF: ${error.message}`)
    } finally {
      this.showLoading(false)
    }
  }

  // Affichage des messages
  showError(message) {
    // Utiliser SweetAlert2 si disponible, sinon alert
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'error',
        title: 'Erreur',
        text: message,
        confirmButtonColor: '#0066cc'
      })
    } else {
      alert(`❌ ${message}`)
    }
  }

  showSuccess(message) {
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'success',
        title: 'Succès',
        text: message,
        timer: 3000,
        showConfirmButton: false
      })
    } else {
      alert(`✅ ${message}`)
    }
  }

  showLoading(show) {
    const buttons = this.exportButtonTargets
    buttons.forEach(button => {
      if (show) {
        button.disabled = true
        button.innerHTML = button.innerHTML.replace(/📄|💾|📋/, '⏳')
      } else {
        button.disabled = false
        // Restaurer l'icône originale (basique)
        button.innerHTML = button.innerHTML.replace('⏳', '📄')
      }
    })

    if (show && typeof Swal !== 'undefined') {
      Swal.fire({
        title: 'Génération du PDF...',
        text: 'Veuillez patienter',
        allowOutsideClick: false,
        showConfirmButton: false,
        willOpen: () => {
          Swal.showLoading()
        }
      })
    } else if (!show && typeof Swal !== 'undefined' && Swal.isVisible()) {
      Swal.close()
    }
  }
}
