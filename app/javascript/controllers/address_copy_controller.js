import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="address-copy"
export default class extends Controller {
  static targets = ["rueExploitation", "numeroExploitation", "codePostalExploitation", "communeExploitation"]

  connect() {
    console.log("Address copy controller connected")
  }

  toggle(event) {
    const checkbox = event.target
    const isChecked = checkbox.checked

    if (isChecked) {
      // Copier les valeurs du siège social vers l'exploitation
      this.copyAddressFromSocial()
      // Désactiver les champs d'exploitation
      this.toggleExploitationFields(true)
    } else {
      // Réactiver les champs d'exploitation
      this.toggleExploitationFields(false)
      // Optionnel : vider les champs d'exploitation
      this.clearExploitationFields()
    }
  }

  copyAddressFromSocial() {
    // Récupérer les valeurs des champs du siège social
    const rueSocial = document.querySelector('#property_rue')?.value || ''
    const numeroSocial = document.querySelector('#property_numero')?.value || ''
    const codePostalSocial = document.querySelector('#property_code_postal')?.value || ''
    const communeSocial = document.querySelector('#property_commune')?.value || ''

    // Copier vers les champs d'exploitation
    if (this.hasRueExploitationTarget) {
      this.rueExploitationTarget.value = rueSocial
    }
    if (this.hasNumeroExploitationTarget) {
      this.numeroExploitationTarget.value = numeroSocial
    }
    if (this.hasCodePostalExploitationTarget) {
      this.codePostalExploitationTarget.value = codePostalSocial
    }
    if (this.hasCommuneExploitationTarget) {
      this.communeExploitationTarget.value = communeSocial
    }
  }

  toggleExploitationFields(disabled) {
    if (this.hasRueExploitationTarget) {
      this.rueExploitationTarget.disabled = disabled
    }
    if (this.hasNumeroExploitationTarget) {
      this.numeroExploitationTarget.disabled = disabled
    }
    if (this.hasCodePostalExploitationTarget) {
      this.codePostalExploitationTarget.disabled = disabled
    }
    if (this.hasCommuneExploitationTarget) {
      this.communeExploitationTarget.disabled = disabled
    }
  }

  clearExploitationFields() {
    if (this.hasRueExploitationTarget) {
      this.rueExploitationTarget.value = ''
    }
    if (this.hasNumeroExploitationTarget) {
      this.numeroExploitationTarget.value = ''
    }
    if (this.hasCodePostalExploitationTarget) {
      this.codePostalExploitationTarget.value = ''
    }
    if (this.hasCommuneExploitationTarget) {
      this.communeExploitationTarget.value = ''
    }
  }
}
