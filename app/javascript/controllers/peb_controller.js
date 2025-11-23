import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "labelInitial",
    "typeLogement",
    "ventilation",
    "labelFinal",
    "montantCalcule",
    "resultatContainer",
    "detailsContainer"
  ]

  static values = {
    categorie: String,
    valeursData: Object
  }

  connect() {
    console.log("PEB Controller connecté")
    console.log("Catégorie:", this.categorieValue)

    // Vérifier les targets
    console.log("Targets disponibles:", {
      labelInitial: this.hasLabelInitialTarget,
      typeLogement: this.hasTypeLogementTarget,
      ventilation: this.hasVentilationTarget,
      labelFinal: this.hasLabelFinalTarget,
      montantCalcule: this.hasMontantCalculeTarget,
      resultatContainer: this.hasResultatContainerTarget
    })

    // Écouter les événements des autres cartes pour mettre à jour le total
    this.element.addEventListener("prime:input", this.mettreAJourTotalPrimes.bind(this))

    // Données PEB en dur pour éviter les problèmes d'échappement
    this.valeursDataStatic = {
      "1": {
        "maison": {
          "A": { "avec_ventilation": 4000, "sans_ventilation": 3000 },
          "B": { "avec_ventilation": 3000, "sans_ventilation": 2000 },
          "C": { "avec_ventilation": 2000, "sans_ventilation": 1000 }
        },
        "appartement": {
          "A": { "avec_ventilation": 3000, "sans_ventilation": 2250 },
          "B": { "avec_ventilation": 2000, "sans_ventilation": 1500 }
        }
      },
      "2": {
        "maison": {
          "A": { "avec_ventilation": 5000, "sans_ventilation": 4000 },
          "B": { "avec_ventilation": 3750, "sans_ventilation": 3000 },
          "C": { "avec_ventilation": 2500, "sans_ventilation": 2000 }
        },
        "appartement": {
          "A": { "avec_ventilation": 3750, "sans_ventilation": 3000 },
          "B": { "avec_ventilation": 2500, "sans_ventilation": 2000 }
        }
      },
      "3": {
        "maison": {
          "A": { "avec_ventilation": 6000, "sans_ventilation": 5000 },
          "B": { "avec_ventilation": 4500, "sans_ventilation": 3750 },
          "C": { "avec_ventilation": 3000, "sans_ventilation": 2500 }
        },
        "appartement": {
          "A": { "avec_ventilation": 4500, "sans_ventilation": 3750 },
          "B": { "avec_ventilation": 3000, "sans_ventilation": 2500 }
        }
      },
      "4": {
        "maison": {
          "A": { "avec_ventilation": 7000, "sans_ventilation": 6000 },
          "B": { "avec_ventilation": 5250, "sans_ventilation": 4500 },
          "C": { "avec_ventilation": 3500, "sans_ventilation": 3000 }
        },
        "appartement": {
          "A": { "avec_ventilation": 5250, "sans_ventilation": 4500 },
          "B": { "avec_ventilation": 3500, "sans_ventilation": 3000 }
        }
      }
    }

    console.log("Données PEB chargées:", this.valeursDataStatic)
    this.calculerMontant()
  }

  // Gestion du changement de label initial
  labelInitialChanged() {
    this.calculerMontant()
    this.triggerAutoSave()
  }

  // Gestion du changement de type de logement
  typeLogementChanged() {
    this.calculerMontant()
    this.triggerAutoSave()
  }

  // Gestion du changement de label final
  labelFinalChanged() {
    this.calculerMontant()
    this.triggerAutoSave()
  }

  // Gestion du changement de ventilation
  ventilationChanged() {
    this.calculerMontant()
    this.triggerAutoSave()
  }

  // Mise à jour des options de label selon le type de logement
  updateLabelOptions() {
    const typeLogement = this.typeLogementTarget.value
    const categorie = this.categorieValue

    if (!typeLogement || !categorie || !this.valeursDataValue) return

    const optionsDisponibles = this.valeursDataValue[categorie]?.[typeLogement]

    if (optionsDisponibles) {
      // Réinitialiser les options
      this.labelFinalTarget.innerHTML = '<option value="">Sélectionnez un label</option>'

      // Ajouter les options disponibles
      Object.keys(optionsDisponibles).forEach(label => {
        const option = document.createElement('option')
        option.value = label
        option.textContent = `Label ${label}`
        this.labelFinalTarget.appendChild(option)
      })
    }
  }

  // Calcul du montant selon les paramètres sélectionnés
  calculerMontant() {
    const labelInitial = this.labelInitialTarget?.value
    const typeLogement = this.typeLogementTarget?.value
    const labelFinal = this.labelFinalTarget?.value
    const ventilation = this.ventilationTarget?.value
    const categorie = this.categorieValue

    console.log("Calcul PEB:", { labelInitial, typeLogement, labelFinal, ventilation, categorie })

    // Vérifier que tous les paramètres sont présents
    if (!labelInitial || !typeLogement || !labelFinal || !ventilation || !categorie) {
      console.log("Paramètres manquants pour le calcul PEB")
      this.afficherResultat(null)
      return
    }

    // Utiliser les données statiques
    const valeursData = this.valeursDataStatic

    if (!valeursData || Object.keys(valeursData).length === 0) {
      console.error("Données de valeurs PEB non disponibles ou vides")
      this.afficherResultat(null)
      return
    }

    console.log("Données PEB disponibles:", valeursData)

    // Naviguer dans la structure des données
    const montant = valeursData[categorie]?.[typeLogement]?.[labelFinal]?.[ventilation]

    console.log("Montant trouvé:", montant)

    if (montant) {
      this.afficherResultat(montant, {
        labelInitial,
        typeLogement,
        labelFinal,
        ventilation,
        categorie
      })
    } else {
      console.log("Aucun montant trouvé pour ces paramètres")
      this.afficherResultat(null)
    }
  }

  // Affichage du résultat
  afficherResultat(montant, details = null) {
    console.log("Affichage résultat PEB:", { montant, details })

    if (montant) {
      this.montantCalculeTarget.textContent = `${montant.toLocaleString('fr-BE')} €`
      this.resultatContainerTarget.classList.remove('d-none')
      console.log("Résultat PEB affiché:", montant)

      // Mettre à jour le total global des primes
      this.mettreAJourTotalPrimes()
    } else {
      console.log("Masquage du résultat PEB")
      this.resultatContainerTarget.classList.add('d-none')

      // Mettre à jour le total global des primes
      this.mettreAJourTotalPrimes()
    }
  }

  // Méthode pour mettre à jour le total global des primes
  mettreAJourTotalPrimes() {
    console.log("🔄 PEB: Mise à jour du total demandée")

    // D'abord essayer de déclencher via le controller parent Flandre
    let flandreController = document.querySelector('[data-controller*="flandre-simulation"]')
    if (!flandreController) {
      // Essayer d'autres sélecteurs
      flandreController = document.querySelector('[data-controller="flandre-simulation"]')
    }

    console.log("🔍 PEB: Controller Flandre trouvé:", !!flandreController)

    if (flandreController) {
      const controller = this.application.getControllerForElementAndIdentifier(flandreController, 'flandre-simulation')
      console.log("🔍 PEB: Instance controller trouvée:", !!controller)

      if (controller && typeof controller.updateTotalGlobal === 'function') {
        console.log("💰 PEB: Déclenchement updateTotalGlobal...")
        controller.updateTotalGlobal()
        console.log("💰 Total mis à jour via controller Flandre")
        return
      } else {
        console.log("❌ PEB: updateTotalGlobal non disponible")
      }
    }

    console.log("⚠️ PEB: Fallback vers mise à jour directe")
    // Fallback: mise à jour directe du span total (pour compatibilité)
    const totalSpan = document.querySelector("#total-primes-affiche")
    if (!totalSpan) {
      console.log("❌ PEB: Span total non trouvé")
      return
    }

    // Calculer le total des primes normales
    const totalPrimesNormales = Array.from(document.querySelectorAll(".prime-result"))
      .reduce((sum, el) => {
        const value = parseFloat(el.textContent.replace("€", "").replace(",", ".").replace(" ", "") || 0)
        return sum + (isNaN(value) ? 0 : value)
      }, 0)

    // Ajouter le montant PEB s'il est visible
    let montantPEB = 0
    if (this.hasResultatContainerTarget && !this.resultatContainerTarget.classList.contains('d-none')) {
      // Le montant PEB est au format "4.000 €", donc on supprime les points et espaces
      const montantText = this.montantCalculeTarget.textContent
        .replace("€", "")
        .replace(/\s/g, "") // supprimer tous les espaces
        .replace(/\./g, "") // supprimer tous les points (séparateurs de milliers)
      montantPEB = parseFloat(montantText) || 0
    }

    const totalFinal = totalPrimesNormales + montantPEB
    totalSpan.textContent = `${totalFinal.toFixed(2)} €`

    console.log("💰 Total mis à jour (fallback):", { totalPrimesNormales, montantPEB, totalFinal })
  }

  // Nouvelle méthode : Déclencher la sauvegarde automatique
  triggerAutoSave() {
    // Essayer de déclencher la sauvegarde via le contrôleur Flandre
    const flandreController = document.querySelector('[data-controller="flandre-simulation"]')

    if (flandreController) {
      const controller = this.application.getControllerForElementAndIdentifier(flandreController, 'flandre-simulation')

      if (controller && typeof controller.triggerSave === 'function') {
        console.log("💾 PEB: Déclenchement sauvegarde automatique...")

        // Délai pour permettre à l'affichage de se mettre à jour
        setTimeout(() => {
          controller.triggerSave()
        }, 500)
      }
    }
  }

  // Fonction utilitaire pour capitaliser la première lettre
  capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  // Réinitialiser tous les champs
  resetForm() {
    this.labelInitialTarget.value = ''
    this.typeLogementTarget.value = ''
    this.labelFinalTarget.value = ''
    this.ventilationTarget.value = ''
    this.afficherResultat(null)
  }

  // Validation des prérequis PEB
  validatePebRequirements() {
    const typeLogement = this.typeLogementTarget.value
    const labelFinal = this.labelFinalTarget.value

    // Logique de validation spécifique PEB
    // Ex: vérifier que le saut de label est suffisant
    if (typeLogement === 'appartement' && !['A', 'B'].includes(labelFinal)) {
      return {
        valid: false,
        message: "Pour un appartement, seuls les labels A et B sont éligibles"
      }
    }

    return { valid: true }
  }

  // Méthode pour restaurer les données PEB sauvegardées
  restoreData(pebData) {
    console.log("🔄 Restauration données PEB:", pebData)

    if (!pebData) {
      console.log("❌ Aucune donnée PEB à restaurer")
      return
    }

    try {
      // Restaurer les valeurs des selects
      if (pebData.label_initial && this.hasLabelInitialTarget) {
        this.labelInitialTarget.value = pebData.label_initial
        console.log(`✅ Label initial restauré: ${pebData.label_initial}`)
      }

      if (pebData.type_logement && this.hasTypeLogementTarget) {
        this.typeLogementTarget.value = pebData.type_logement
        console.log(`✅ Type logement restauré: ${pebData.type_logement}`)
      }

      if (pebData.ventilation && this.hasVentilationTarget) {
        this.ventilationTarget.value = pebData.ventilation
        console.log(`✅ Ventilation restaurée: ${pebData.ventilation}`)
      }

      if (pebData.label_final && this.hasLabelFinalTarget) {
        this.labelFinalTarget.value = pebData.label_final
        console.log(`✅ Label final restauré: ${pebData.label_final}`)
      }

      // Déclencher le calcul avec un délai pour laisser le temps à l'affichage
      setTimeout(() => {
        console.log("🔄 Recalcul PEB après restauration...")
        this.calculerMontant()
      }, 100)

      console.log("✅ Restauration PEB terminée")
    } catch (error) {
      console.error("❌ Erreur lors de la restauration PEB:", error)
    }
  }
}
