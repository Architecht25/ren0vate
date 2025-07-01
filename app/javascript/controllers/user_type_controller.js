import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const userType = event.currentTarget.dataset.user
    localStorage.setItem("userType", userType)

    const region = localStorage.getItem("region")
    const testSection = document.getElementById("eligibility-test")
    const allowedRegion = region === "flandre"

    console.log("🧪 Lancement du setTimeout...")

    setTimeout(() => {
      console.log("⏳ Timeout enclenché")
      const testSection = document.getElementById("eligibility-test")

      console.log("📦 testSection trouvé :", testSection)
      console.log("📍 Région (localStorage):", region)

      if (testSection && region === "flandre") {
        console.log("✅ Test affiché via setTimeout")
        testSection.classList.remove("d-none")

        const allSteps = testSection.querySelectorAll(".form-card")
        allSteps.forEach(card => card.classList.remove("active"))

        const firstStep = testSection.querySelector('[data-step="2"]')
        if (firstStep) firstStep.classList.add("active")
      } else {
        console.log("❌ Conditions pas remplies – test non affiché")
      }
    }, 100)


    console.log("🔍 testSection:", testSection)
    console.log("🧠 région:", region)
    console.log("👤 userType:", userType)
  }
}
