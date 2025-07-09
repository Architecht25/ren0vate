import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    console.log('🎯 UserType controller connecté !')
    }


  select(event) {
    const userType = event.currentTarget.dataset.user
    console.log('🎯 User type sélectionné:', userType)
    localStorage.setItem("userType", userType)

    const region = localStorage.getItem("region")
    console.log('🌍 Région stockée:', region)
    const testSection = document.getElementById("eligibility-test")

    setTimeout(() => {
      const region = localStorage.getItem("region")
      const userType = localStorage.getItem("userType")

      console.log('✅ Vérification après timeout:', { region, userType })

      if (!testSection) {
        console.warn("❌ testSection introuvable")
        return
      }


      if (region === "flandre" && userType === "entreprise") {
        console.log('⚠️ Attention: Les entreprises ne sont pas éligibles aux primes')
        Swal.fire({
          icon: 'warning',
          title: '⚠️ Attention',
          text: 'Les entreprises ne sont pas éligibles aux primes',
        })
      }

      if (region === "flandre" && userType === "syndic") {
        console.log('⚠️ Attention: Les syndicats de copropriété doivent passer par une EnergieHuis')
        Swal.fire({
            icon: 'warning',
            title: '⚠️ Attention',
            text: 'Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
          })
      }

      if (region === "flandre" && userType === "bailleur") {
        console.log('⚠️ Attention: Les bailleurs sociaux doivent passer par une EnergieHuis')
        Swal.fire({
          icon: 'warning',
          title: '⚠️ Attention',
          text: 'Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
          })
      }

      if (region === "flandre" && userType) {
        console.log('✅ Affichage du test d\'éligibilité')
        testSection.classList.remove("d-none")
      } else {
        console.log("❌ Conditions pas remplies – test non affiché")
      }
    }, 100)
  }
}
