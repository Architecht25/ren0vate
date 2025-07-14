import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    console.log('🔗 UserType controller connecté !', this.element)
    console.log('📊 Element avec data-controller:', this.element.dataset.controller)
  }

  select(event) {
    const userType = event.currentTarget.dataset.user
    console.log('👤 Type utilisateur sélectionné:', userType)

    // Stocker le choix
    localStorage.setItem("userType", userType)
    localStorage.setItem("user-type", userType) // Pour compatibilité

    // Afficher les alertes immédiatement selon le type
    this.showUserTypeAlert(userType)

    // Afficher la section de test d'éligibilité
    const testSection = document.getElementById("eligibility-test")
    if (testSection) {
      testSection.classList.remove("d-none")
      console.log('📋 Section test d\'éligibilité affichée')
    }
  }

  showUserTypeAlert(userType) {
    // Vérifier si SweetAlert est disponible
    if (typeof Swal === 'undefined') {
      console.warn('⚠️ SweetAlert non disponible, utilisation d\'alert() standard')

      if (userType === "entreprise") {
        alert('⚠️ Attention\n\nLes entreprises ne sont pas éligibles aux primes')
        return
      }

      if (userType === "syndic") {
        alert('⚠️ Attention\n\nLes syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.')
        return
      }

      if (userType === "bailleur") {
        alert('⚠️ Attention\n\nLes bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.')
        return
      }

      return
    }

    // Utiliser SweetAlert si disponible
    if (userType === "entreprise") {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les entreprises ne sont pas éligibles aux primes',
        confirmButtonText: 'Compris'
      })
    }

    if (userType === "syndic") {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
        confirmButtonText: 'Compris'
      })
    }

    if (userType === "bailleur") {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
        confirmButtonText: 'Compris'
      })
    }

    if (userType === "prive") {
      console.log('✅ Utilisateur privé - éligible aux primes')
    }

    if (userType === "asbl") {
      console.log('✅ ASBL - éligible aux primes')
    }
  }
}
