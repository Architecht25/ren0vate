import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "totalInvestment", "totalAids", "averageRate", "aidResult"
  ]

  connect() {
    console.log("🏢 Contrôleur Simulation Cards connecté")

    // Charger les données d'aides
    this.loadAidesData()

    // Initialiser les calculs
    this.updateTotals()
  }

  loadAidesData() {
    // Définir les données des aides directement dans le contrôleur pour l'instant
    this.aidesData = {
      "bruxelles_transition_consultance": {
        taux_aide: 25,
        montant_max: 20000,
        montant_min: 500
      },
      "bruxelles_investissements_transition_economique": {
        taux_aide: 30,
        montant_max: 100000,
        montant_min: 2000
      },
      "bruxelles_mobilite_velo_cargo": {
        taux_aide: 40,
        montant_max: 4000,
        montant_min: 500
      },
      "bruxelles_mobilite_utilitaire_electrique": {
        taux_aide: 25,
        montant_max: 15000,
        montant_min: 10000
      },
      "bruxelles_mobilite_utilitaire_retrofit": {
        taux_aide: 30,
        montant_max: 10000,
        montant_min: 5000
      },
      "bruxelles_prime_materiel_travaux": {
        taux_aide: 25,
        montant_max: 200000,
        montant_min: 5000
      },
      "bruxelles_prime_conformite_normes": {
        taux_aide: 30,
        montant_max: 50000,
        montant_min: 5000
      },
      "bruxelles_prime_securisation": {
        taux_aide: 40,
        montant_max: 15000,
        montant_min: 2000
      },
      "bruxelles_prime_immobilier": {
        taux_aide: 20,
        montant_max: 500000,
        montant_min: 100000
      },
      "bruxelles_prime_accessibilite": {
        taux_aide: 50,
        montant_max: 25000,
        montant_min: 1000
      },
      "bruxelles_prime_recrutement": {
        taux_aide: 100, // Montant fixe par ETP
        montant_fixe: 3000, // 3000€ par ETP
        montant_min: 1
      },
      "bruxelles_prime_formation": {
        taux_aide: 75,
        montant_max: 50000,
        montant_min: 500
      },
      "bruxelles_prime_consultance": {
        taux_aide: 50,
        montant_max: 15000,
        montant_min: 500
      },
      "bruxelles_prime_digitalisation": {
        taux_aide: 40,
        montant_max: 25000,
        montant_min: 500
      }
    }

    console.log("📊 Données d'aides chargées:", Object.keys(this.aidesData).length, "aides")
  }

  calculateAid(event) {
    const input = event.target
    const montantInvesti = parseFloat(input.value) || 0
    const aideSlug = input.getAttribute('data-aid-slug')

    console.log(`🧮 Calcul pour ${aideSlug}: ${montantInvesti}€`)

    if (!aideSlug || !this.aidesData[aideSlug]) {
      console.error(`❌ Aide non trouvée: ${aideSlug}`)
      return
    }

    const aide = this.aidesData[aideSlug]
    let montantAide = 0

    console.log(`📊 Données aide:`, aide)

    // Vérifier le montant minimum
    if (montantInvesti >= aide.montant_min) {
      if (aideSlug === 'bruxelles_prime_recrutement') {
        // Cas spécial pour le recrutement : montant fixe par ETP
        montantAide = montantInvesti * aide.montant_fixe
        console.log(`👥 Calcul recrutement: ${montantInvesti} ETP × ${aide.montant_fixe}€ = ${montantAide}€`)
      } else {
        // Calcul standard : pourcentage du montant investi
        montantAide = montantInvesti * (aide.taux_aide / 100)
        console.log(`💰 Calcul standard: ${montantInvesti}€ × ${aide.taux_aide}% = ${montantAide}€`)

        // Appliquer le plafond
        if (aide.montant_max) {
          const montantAvantPlafond = montantAide
          montantAide = Math.min(montantAide, aide.montant_max)
          if (montantAvantPlafond !== montantAide) {
            console.log(`🔒 Plafond appliqué: ${montantAvantPlafond}€ → ${montantAide}€ (max: ${aide.montant_max}€)`)
          }
        }
      }
    } else {
      console.log(`❌ Montant investi (${montantInvesti}€) inférieur au minimum requis (${aide.montant_min}€)`)
    }

    // Mettre à jour l'affichage du résultat
    this.updateAidResult(aideSlug, montantAide)

    // Recalculer les totaux
    this.updateTotals()

    console.log(`✅ Aide calculée finale: ${Math.round(montantAide)}€`)
  }

  updateAidResult(aideSlug, montantAide) {
    // Trouver l'élément de résultat correspondant
    const resultInput = this.element.querySelector(`[data-simulation-cards-entreprise-target="aidResult"][data-aid-slug="${aideSlug}"]`)

    if (resultInput) {
      // Formater le montant en français (avec espaces pour les milliers)
      resultInput.value = Math.round(montantAide).toLocaleString('fr-FR')
      console.log(`✅ Résultat affiché: ${Math.round(montantAide).toLocaleString('fr-FR')}€ pour ${aideSlug}`)
    } else {
      console.error(`❌ Élément de résultat non trouvé pour ${aideSlug}`)
      console.log(`🔍 Sélecteur utilisé: [data-simulation-cards-entreprise-target="aidResult"][data-aid-slug="${aideSlug}"]`)

      // Debug: afficher tous les éléments avec aidResult target
      const allResults = this.element.querySelectorAll(`[data-simulation-cards-entreprise-target="aidResult"]`)
      console.log(`🔍 Éléments aidResult trouvés:`, allResults.length)
      allResults.forEach((el, index) => {
        console.log(`  ${index + 1}. data-aid-slug="${el.getAttribute('data-aid-slug')}"`)
      })
    }
  }

  updateTotals() {
    let totalInvestissement = 0
    let totalAides = 0
    let nombreAides = 0

    // Parcourir toutes les cartes pour calculer les totaux
    this.element.querySelectorAll('.prime-card').forEach(card => {
      const aideSlug = card.getAttribute('data-aid-slug')
      const input = card.querySelector('input[type="number"]')
      const resultInput = card.querySelector('[data-simulation-cards-entreprise-target="aidResult"]')

      if (input && input.value && parseFloat(input.value) > 0) {
        const investissement = parseFloat(input.value)
        totalInvestissement += investissement

        if (resultInput && resultInput.value) {
          // Nettoyer la valeur (enlever les espaces et convertir)
          const aideValueText = resultInput.value.replace(/\s/g, '').replace(/[€,]/g, '')
          const aide = parseFloat(aideValueText) || 0
          if (aide > 0) {
            totalAides += aide
            nombreAides++
            console.log(`💰 Aide ajoutée: ${aide}€ pour ${aideSlug} (texte: "${resultInput.value}")`)
          }
        }
      }
    })

    // Calculer le taux moyen
    const tauxMoyen = totalInvestissement > 0 ? (totalAides / totalInvestissement) * 100 : 0

    // Mettre à jour l'affichage
    if (this.hasTotalInvestmentTarget) {
      this.totalInvestmentTarget.textContent = this.formatMontant(totalInvestissement)
    }

    if (this.hasTotalAidsTarget) {
      this.totalAidsTarget.textContent = this.formatMontant(totalAides)
    }

    if (this.hasAverageRateTarget) {
      this.averageRateTarget.textContent = `${tauxMoyen.toFixed(1)}%`
    }

    // Afficher/masquer le bouton d'accès à l'application
    const proceedBtn = document.getElementById('proceed-to-app-btn')
    if (proceedBtn) {
      if (totalAides > 0) {
        proceedBtn.style.display = 'block'
      } else {
        proceedBtn.style.display = 'none'
      }
    }

    console.log(`📊 Totaux mis à jour: ${this.formatMontant(totalInvestissement)} investis, ${this.formatMontant(totalAides)} aides (${tauxMoyen.toFixed(1)}%) - ${nombreAides} aides actives`)
  }

  formatMontant(montant) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(montant)
  }
}
