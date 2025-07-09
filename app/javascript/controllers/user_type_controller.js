import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
  }

  select(event) {
    const userType = event.currentTarget.dataset.user
    localStorage.setItem("userType", userType)

    const region = localStorage.getItem("region")
    const testSection = document.getElementById("eligibility-test")

    setTimeout(() => {
      const region = localStorage.getItem("region")
      const userType = localStorage.getItem("userType")

      if (!testSection) {
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
            text: 'Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.',
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
        testSection.classList.remove("d-none")
      }
    }, 100)
  }
}
