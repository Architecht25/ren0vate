import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const userType = event.currentTarget.dataset.user
    localStorage.setItem("userType", userType)

    const region = localStorage.getItem("region")
    const testSection = document.getElementById("eligibility-test")

    console.log("🧪 Lancement du setTimeout...")

    setTimeout(() => {
      const region = localStorage.getItem("region")
      const userType = localStorage.getItem("userType")

      console.log("⏳ Timeout enclenché")
      console.log("📦 testSection trouvé :", testSection)
      console.log("📍 Région (localStorage):", region)
      console.log("👤 userType:", userType)

      if (!testSection) {
        console.warn("❌ testSection introuvable")
        return
      }

      if (region === "flandre" && userType === "entreprise") {
        alert("❌ Les entreprises ne sont pas éligibles aux primes.")
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
