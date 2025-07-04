import Swal from 'sweetalert2'
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
      console.log("👤 Controller user-type connecté et qui montre qu'il est bien connecté")
    }


  select(event) {
    const userType = event.currentTarget.dataset.user
    localStorage.setItem("user-type", userType)

    const region = localStorage.getItem("region")
    const testSection = document.getElementById("eligibility-test")

    setTimeout(() => {
      const region = localStorage.getItem("region")
      const userType = localStorage.getItem("user-type")

      if (!testSection) {
        console.warn("❌ testSection introuvable")
        return
      }


      if (region === "flandre" && userType === "entreprise") {
        Swal.fire({
          icon: 'warning',
          title: '⚠️ Attention',
          text: 'Les entreprises ne sont pas éligibles aux primes',
        })
      }

      if (region === "flandre" && userType === "syndic") {
      Swal.fire({
          icon: 'warning',
          title: '⚠️ Attention',
          text: 'Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction dedemandes.',
        })
      }

      if (region === "flandre" && userType === "bailleur") {
      Swal.fire({
        icon: 'warning',
        title: '⚠️ Attention',
        text: 'Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
        })
      }

      if (region === "flandre" && userType) {
        console.log("✅ Test affiché via setTimeout")
        testSection.classList.remove("d-none")
      } else {
        console.log("❌ Conditions pas remplies – test non affiché")
      }
    }, 100)
  }
}
