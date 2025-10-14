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

        const wallonieStatut = localStorage.getItem('wallonie_statut_familial')
        if (wallonieStatut) data.wallonie_statut_familial = wallonieStatut

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

    return inputs
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
