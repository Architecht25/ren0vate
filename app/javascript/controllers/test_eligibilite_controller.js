import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "formCard"]

  connect() {
    console.log("✅ Contrôleur test-eligibilite connecté")
    if (this.hasResultTarget) {
    this.resultTarget.style.display = "none"
  }
  }

  handleAnswer(event) {
    console.log("🚀 handleAnswer déclenché", event.target.name, event.target.value)

    const form = this.formTarget
    const userType = localStorage.getItem("user-type")

    const totalGroups = new Set([...form.querySelectorAll("input[type=radio]")].map(i => i.name)).size;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const answeredGroups = new Set(responses.map(r => r.name));

    console.log("🧮 totalGroups attendus :", totalGroups);
    console.log("✅ Groupes de réponses cochées :", answeredGroups.size, [...answeredGroups]);

    // Inéligibilités immédiates
    if (userType === "entreprise") {
      this.showResult("❌ Les entreprises ne sont pas éligibles aux primes à la rénovation depuis le 1er juillet 2025.", false)
      return
    }

    if (userType === "syndic") {
      this.showResult("❌ Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer l'introduction des demandes.", false)
      return
    }

    if (userType === "bailleur") {
      this.showResult("❌ Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer l'introduction des demandes.", false)
      return
    }

    const usage = form.querySelector('input[name="usage"]:checked')?.value
    if (usage === "non") {
      this.showResult("❌ Pour prétendre aux primes à la rénovation, votre bien doit être obligatoirement destiné au logement.", false)
      return
    }

    const proprietaire = form.querySelector('input[name="propriétaire"]:checked')?.value
    if (proprietaire === "non") {
      this.showResult("❌ Si vous n'êtes pas propriétaire, donc ayant 0% de propriété, alors vous ne pouvez pas prétendre aux primes à la rénovation.", false)
      return
    }

    const annee = form.querySelector('input[name="annee"]:checked')?.value
    if (annee === "non") {
      this.showResult("❌ Logement est trop récent pour pouvoir bénéficier des primes à la rénovation.", false)
      return
    }

    const appartement_copro = form.querySelector('input[name="appartement-copro"]:checked')?.value
    if (appartement_copro === "oui") {
      this.showResult("❌ La demande de primes doit être gérer et introduite par votre syndic de copropriété.", false)
    }

    // const type = form.querySelector('input[name="type"]:checked')?.value
    // if (type === "non") {
    //   this.showResult("❌ Si le logement n'est pas une maison, ni un appartement (vma ou non), il s'agit alors d'un autre type de bien non sousmis à primes.", false)
    // }

    const demolition = form.querySelector('input[name="demolition"]:checked')?.value
    if (demolition === "oui") {
      this.showResult("❌ Les logements reconstruits et qui bénéficient d'une TVA à 6% ne sont pas éligibles.", false)
      return
    }

    const travaux = form.querySelector('input[name="travaux"]:checked')?.value
    if (travaux === "non") {
      this.showResult("❌ VOs devez prévoir des travaux éligibles pour bénéficier des primes actuelles.", false)
      return
    }

    // Vérifie que toutes les questions sont cochées
    const radioGroups = Array.from(form.querySelectorAll("input[type='radio']"))
    const réponsesParQuestion = radioGroups.reduce((acc, input) => {
      if (!acc[input.name]) acc[input.name] = false
      if (input.checked) acc[input.name] = true
      return acc
    }, {})

    const toutRempli = Object.values(réponsesParQuestion).every(val => val)

    if (!toutRempli) {
      console.log("⚠️ Toutes les questions ne sont pas encore répondues.")
      return
    }

    // ✅ Appel du vrai calcul maintenant que tout est rempli
    this.calculateResult()
  }


  calculateResult() {
    console.log("🧪 TEST DES VARIABLES DANS calculateResult()");

    ["userType", "usage", "appartement", "appartement-copro", "immeuble-appartements", "proprietaire", "autre_bien", "annee", "type", "copro", "peb", "domicile", "demolition", "travaux", "protege"]
    .forEach(name => {
      const value = this.formTarget.querySelector(`[name="${name}"]:checked`)?.value;
      console.log(`➡️ ${name} =`, value);
    });

    const form = this.formTarget;
    let message = "✅ Vous êtes éligible aux primes.";
    let categorie = null;

    const get = name => form.querySelector(`[name="${name}"]:checked`)?.value;

    const userType = localStorage.getItem("userType");
    const usage = get("usage");
    const proprietaire = get("proprietaire");
    const autre_bien = get("autre_bien");
    const copro = get("copro");
    const protege = get("protege");
    const annee = get("annee");
    const type = get("type");
    const appartement = get("appartement");
    const appartement_copro = get("appartement_copro");
    const immeuble_appartements = get("immeuble-appartements");
    const peb = get("peb");
    const domicile = get("domicile");
    const demolition = get("demolition");
    const travaux = get("travaux");

    console.log("📋 Réponses récupérées :", {
      userType, usage, proprietaire, appartement, appartement_copro, immeuble_appartements, autre_bien, copro, protege,
      annee, type, peb, domicile, demolition, travaux
    });

    // Cas particuliers
    if (userType === "syndic") {
      message += " (Syndic de copropriété → Catégorie 1)";
      categorie = 1;
    }
    if (userType === "bailleur_social") {
      message += " (Bailleur social → Catégorie 4)";
      categorie = 4;
    }
    if (userType === "asbl") {
      message += " (ASBL/coopérative → Catégorie 1)";
      categorie = 1;
    }
    if (usage === "non") {
      message += " (Usage non résidentiel → Catégorie 1)";
      categorie = 1;
    }
    // if (proprietaire === "non") {
    //   message += " (Pas propriétaire → uniquement PAC/boiler)";
    //   categorie = 1;
    // }
    if (autre_bien === "oui") {
      message += " (Propriétaire d un autre bien → Catégorie 1)";
      categorie = 1;
    }
    if (protege === "oui") {
      message += " (Client protégé → Catégorie 4)";
      categorie = 4;
    }
    if (appartement === "oui" && proprietaire === "oui") {
      message += " (Appartement → catégorie 1)";
      categorie = 1;
    }
    if (appartement_copro === "oui") {
      message += "(Appartement → catégorie 1)";
      categorie = 1;
    }
    if (immeuble_appartements === "oui") {
      message += "(Immeuble à appartements → catégorie 1)";
      categorie = 1;
    }

    // PEB
    if (peb === "oui") {
      if (domicile === "oui") {
        message += " (Accès à la carte PEB)";
      } else {
        message += " (Catégorie 1 + carte PEB)";
      }
    } else {
      message += " (Pas de carte PEB)";
    }

    // Valeur par défaut
    if (!categorie) {
      categorie = 4;
    }

    // Résumé visuel
    let categorieAffichee;

    if (categorie === 4) {
      categorieAffichee = `<span class="badge bg-warning text-dark">entre 1 et 4</span> <small>(à confirmer selon vos revenus et votre ménage)</small>`;
    } else {
      categorieAffichee = `<span class="badge bg-primary">catégorie ${categorie}</span>`;
    }

    message += `<br><br><strong>Catégorie :</strong> ${categorieAffichee}`;

    if (categorie === 4) {
      const blocAffinage = document.getElementById("affinage-categorie")
      if (blocAffinage) {
        blocAffinage.style.display = "block"
      }
    }

    // Stocker dans localStorage
    const testData = {
      userType, usage, proprietaire, appartement, immeuble_appartements, autre_bien, annee,
      type, copro, peb, domicile, demolition,
      travaux, categorie
    };
    localStorage.setItem("eligibiliteRenovate", JSON.stringify(testData));

    // Log et affichage
    console.log("✅ Résultat final :", message);
    this.showResult(message, true);
  }

  showResult(message, isEligible = true) {
    this.formTarget.style.display = "none"
    this.resultTarget.innerHTML = `
      <p>${message}</p>
      <div class="btn-group mt-3">
        <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        ${isEligible ? `<a href="/simulation" class="btn btn-primary">🎯 Accéder au simulateur</a>` : ""}
      </div>
    `
    this.resultTarget.style.display = "block"
  }
}
