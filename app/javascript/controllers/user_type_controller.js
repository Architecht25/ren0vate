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
        alert("❌ Les entreprises ne sont pas éligibles aux primes.")
        return
      }

        if (region === "flandre" && userType === "syndic") {
        alert("❌ Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer l'introduction des demandes.")
        return
      }


        if (region === "flandre" && userType === "bailleur") {
        alert("❌ Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer l'introduction des demandes.")
        return
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
