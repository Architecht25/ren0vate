import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
  }

  select(event) {
    const userType = event.currentTarget.dataset.user

    // Stocker le choix
    localStorage.setItem("userType", userType)
    localStorage.setItem("user-type", userType) // Pour compatibilité

    // Afficher les alertes immédiatement selon le type
    this.showUserTypeAlert(userType)

    // Afficher la section de test d'éligibilité
    const testSection = document.getElementById("eligibility-test")
    if (testSection) {
      testSection.classList.remove("d-none")
    }
  }

  showUserTypeAlert(userType) {
    // Vérifier si on est sur la page Wallonie - dans ce cas, ne pas bloquer les syndics et bailleurs
    const isWalloniePage = window.location.pathname.includes('/wallonie') ||
                          document.querySelector('[data-region="wallonie"]') !== null;

    // Vérifier si SweetAlert est disponible
    if (typeof Swal === 'undefined') {

      if (userType === "entreprise") {
        alert('⚠️ Attention\n\nLes entreprises ne sont pas éligibles aux primes')
        return
      }

      // Ne bloquer les syndics et bailleurs que si on n'est PAS sur Wallonie
      if (userType === "syndic" && !isWalloniePage) {
        alert('⚠️ Attention\n\nLes syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.')
        return
      }

      if (userType === "bailleur" && !isWalloniePage) {
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

    // Ne bloquer les syndics et bailleurs que si on n'est PAS sur Wallonie
    if (userType === "syndic" && !isWalloniePage) {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
        confirmButtonText: 'Compris'
      })
    }

    if (userType === "bailleur" && !isWalloniePage) {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
        confirmButtonText: 'Compris'
      })
    }

    if (userType === "prive") {
    }

    if (userType === "asbl") {
    }
  }
}
