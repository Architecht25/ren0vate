// === 1. app/javascript/controllers/categorie_controller.js ===
import { Controller } from "@hotwired/stimulus"
import { choixCategorie } from "logic/categorie_choix_logic"

export default class extends Controller {
  static targets = ["situation", "revenu1", "revenu2", "enfants", "resultat", "texte"]

  calculer() {
    const profil = {
      revenuAnnuel:
        parseFloat(this.revenu1Target.value || 0) +
        parseFloat(this.revenu2Target.value || 0),
      statut: this.getStatut(this.situationTarget.value),
      personnesACharge: parseInt(this.enfantsTarget.value || 0),
      autreBienEnPleinePropriete: false,
      loueViaWoonmaatschappij: false
    }

    const cat = choixCategorie(profil)
    const catNum = cat.id.slice(-1)
    sessionStorage.setItem("categorie", catNum)

    this.texteTarget.textContent = `Catégorie ${cat.id.toUpperCase()} – ${cat.description}`
    this.resultatTarget.className = `alert alert-${this.getColor(cat.id)} mt-4`
  }

  getStatut(situation) {
    if (situation === "isole") return "seul"
    if (["isole_avec_enfant", "couple"].includes(situation)) return "seul_avec_charge_ou_couple_sans_charge"
    return ""
  }

  getColor(id) {
    return {
      categorie_4: "success",
      categorie_3: "primary",
      categorie_2: "info",
      categorie_1: "warning"
    }[id] || "secondary"
  }
}
