import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "typeLogement",
    "labelFinal", 
    "ventilation",
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
    this.calculerMontant()
  }

  // Gestion du changement de type de logement
  typeLogementChanged() {
    this.calculerMontant()
    this.updateLabelOptions()
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
    const typeLogement = this.typeLogementTarget?.value
    const labelFinal = this.labelFinalTarget?.value
    const ventilation = this.ventilationTarget?.value
    const categorie = this.categorieValue

    // Vérifier que tous les paramètres sont présents
    if (!typeLogement || !labelFinal || !ventilation || !categorie) {
      this.afficherResultat(null)
      return
    }

    // Récupérer les données de valeurs
    const valeursData = this.valeursDataValue
    if (!valeursData) {
      console.error("Données de valeurs PEB non disponibles")
      return
    }

    // Naviguer dans la structure des données
    const montant = valeursData[categorie]?.[typeLogement]?.[labelFinal]?.[ventilation]

    if (montant) {
      this.afficherResultat(montant, {
        typeLogement,
        labelFinal,
        ventilation,
        categorie
      })
    } else {
      this.afficherResultat(null)
    }
  }

  // Affichage du résultat
  afficherResultat(montant, details = null) {
    if (montant) {
      this.montantCalculeTarget.textContent = `${montant.toLocaleString('fr-BE')} €`
      this.resultatContainerTarget.classList.remove('d-none')
      
      // Afficher les détails si disponible
      if (details && this.hasDetailsContainerTarget) {
        this.detailsContainerTarget.innerHTML = `
          <div class="mt-3 p-3 bg-light rounded">
            <h6>Détails du calcul :</h6>
            <ul class="mb-0">
              <li><strong>Type de logement :</strong> ${this.capitalizeFirst(details.typeLogement)}</li>
              <li><strong>Label final :</strong> ${details.labelFinal}</li>
              <li><strong>Ventilation :</strong> ${details.ventilation.replace('_', ' ')}</li>
              <li><strong>Catégorie :</strong> ${details.categorie}</li>
            </ul>
          </div>
        `
      }
    } else {
      this.resultatContainerTarget.classList.add('d-none')
      if (this.hasDetailsContainerTarget) {
        this.detailsContainerTarget.innerHTML = ''
      }
    }
  }

  // Fonction utilitaire pour capitaliser la première lettre
  capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  // Réinitialiser tous les champs
  resetForm() {
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
