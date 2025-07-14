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
  }

  // Gestion du changement de type de logement
  typeLogementChanged() {
    this.calculerMontant()
  }

  // Gestion du changement de label final
  labelFinalChanged() {
    this.calculerMontant()
  }

  // Gestion du changement de ventilation
  ventilationChanged() {
    this.calculerMontant()
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
    const totalSpan = document.querySelector("#total-primes-affiche")
    if (!totalSpan) return

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

    console.log("Total mis à jour:", { totalPrimesNormales, montantPEB, totalFinal })
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
}
