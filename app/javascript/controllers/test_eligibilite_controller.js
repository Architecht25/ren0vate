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
  const userType = localStorage.getItem("userType")

  const totalGroups = new Set([...form.querySelectorAll("input[type=radio]")].map(i => i.name)).size;
  const responses = [...form.querySelectorAll("input[type=radio]:checked")];
  const answeredGroups = new Set(responses.map(r => r.name));

  console.log("🧮 totalGroups attendus :", totalGroups);
  console.log("✅ Groupes de réponses cochées :", answeredGroups.size, [...answeredGroups]);

  // Inéligibilités immédiates
  if (userType === "entreprise") {
    this.showResult("❌ Les entreprises ne sont pas éligibles aux primes à la rénovation.", false)
    return
  }

  const annee = form.querySelector('input[name="annee"]:checked')?.value
  if (annee === "apres") {
    this.showResult("❌ Logement trop récent (après 1 janvier 2006).", false)
    return
  }

  const type = form.querySelector('input[name="type"]:checked')?.value
  if (type === "appartement") {
    this.showResult("❌ Pour un appartement, vous devrez passer obligatoirement par votre syndic pour la préparation et l'introduction de votre demande.", false)
  }

  const demolition = form.querySelector('input[name="demolition"]:checked')?.value
  if (demolition === "oui") {
    this.showResult("❌ Les logements reconstruits avec TVA à 6% ne sont pas éligibles.", false)
    return
  }

  const travaux = form.querySelector('input[name="travaux"]:checked')?.value
  if (travaux === "non") {
    this.showResult("❌ VOs devez prévoir des travaux éligibles pour bénéficier des primes.", false)
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

    ["userType", "usage", "proprietaire", "autre_bien", "annee", "type", "copro", "peb", "domicile", "demolition", "travaux", "protege"]
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
    const peb = get("peb");
    const domicile = get("domicile");
    const demolition = get("demolition");
    const travaux = get("travaux");

    console.log("📋 Réponses récupérées :", {
      userType, usage, proprietaire, autre_bien, copro, protege,
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
    if (usage === "non_habite") {
      message += " (Usage non résidentiel → Catégorie 1)";
      categorie = 1;
    }
    if (proprietaire === "non") {
      message += " (Pas propriétaire → uniquement PAC/boiler)";
      categorie = 1;
    }
    if (autre_bien === "oui") {
      message += " (Propriétaire d un autre bien → Catégorie 1)";
      categorie = 1;
    }
    // if (copro === "privee") {
    //   message += " (Parties privatives d'une copropriété → passer par le syndic)";
    //   categorie = 1;
    // }
    if (protege === "oui") {
      message += " (Client protégé → Catégorie 4)";
      categorie = 4;
    }

    // Valeur par défaut
    if (!categorie) {
      categorie = 4;
      message += " (Votre catégorie est comprise entre 1 et 4, à confirmer selon vos revenus à l'étape suivante)";
    }

    // PEB
    if (peb === "ef") {
      if (domicile === "oui") {
        message += " (Accès à la carte PEB)";
      } else {
        message += " (Catégorie 1 + carte PEB)";
      }
    } else {
      message += " (Pas de carte PEB)";
    }

    // if (type === "appartement" && copro === "commune") {
    //   message += " (Parties communes = demande via syndic)";
    // }

    // Résumé visuel
    message += `<br><br><strong>Catégorie :</strong> ${categorie}`;

    // Stocker dans localStorage
    const testData = {
      userType, usage, proprietaire, autre_bien, annee,
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
