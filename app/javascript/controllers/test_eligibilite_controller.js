import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "formCard", "validateButton"]

  connect() {
    if (this.hasResultTarget) {
      this.resultTarget.style.display = "none"
    }
    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }
  }

  handleAnswer(event) {
    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteRenovate", JSON.stringify(testData));

    // Vérification immédiate des cas d'inéligibilité
    const usage = testData["usage"];
    if (usage === "non") {
      this.showResult("❌ Pour prétendre aux primes à la rénovation, votre bien doit être obligatoirement destiné au logement.", false);
      return;
    }

    const proprietaire = testData["propriétaire"];
    if (proprietaire === "non") {
      this.showResult("❌ Si vous n'êtes pas propriétaire, donc ayant 0% de propriété, alors vous ne pouvez pas prétendre aux primes à la rénovation.", false);
      return;
    }

    const annee = testData["annee"];
    if (annee === "non") {
      this.showResult("❌ Logement est trop récent pour pouvoir bénéficier des primes à la rénovation.", false);
      return;
    }

    const appartement_copro = testData["appartement-copro"];
    if (appartement_copro === "oui") {
      this.showResult("❌ La demande de primes doit être gérée et introduite par votre syndic de copropriété.", false);
      return;
    }

    const demolition = testData["demolition"];
    if (demolition === "oui") {
      this.showResult("❌ Les logements reconstruits et qui bénéficient d'une TVA à 6% ne sont pas éligibles.", false);
      return;
    }

    const facture_solde = testData["facture_solde"];
    if (facture_solde === "oui") {
      this.showResult("❌ La facture de solde de vos travaux doit dater de moins de 2 ans pour que les travaux soient éligibles aux primes.", false);
      return;
    }

    const travaux = testData["travaux"];
    if (travaux === "non") {
      this.showResult("❌ Vous devez prévoir des travaux éligibles pour bénéficier des primes actuelles.", false);
      return;
    }

    // Vérifier si toutes les questions sont répondues
    this.checkIfAllAnswered();
  }

  checkIfAllAnswered() {
    const form = this.formTarget;

    // Obtenir tous les noms de questions uniques
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))];

    // Vérifier que chaque question a une réponse cochée
    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTest() {
    this.calculateResult();
  }


  calculateResult() {

    ["userType", "usage", "appartement", "appartement-copro", "immeuble-appartements", "proprietaire", "autre_bien", "annee", "type", "copro", "peb", "domicile", "demolition", "travaux", "protege"]
    .forEach(name => {
      const value = this.formTarget.querySelector(`[name="${name}"]:checked`)?.value;
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
    localStorage.setItem("categorie", categorie.toString());

    // Log et affichage
    this.showResult(message, true);

    // Ajouter un bouton pour voir les primes correspondantes
    this.addViewPrimesButton(categorie);
  }

  showResult(message, isEligible = true) {
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }

    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    if (this.hasResultTarget) {
      this.resultTarget.innerHTML = `
        <p>${message}</p>
        <div class="btn-group mt-3">
          <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        </div>
      `
      this.resultTarget.style.display = "block"
    }
  }

  addViewPrimesButton(categorie) {
    // Ajouter le bouton dans la section résultat
    if (this.hasResultTarget) {
      const existingButton = this.resultTarget.querySelector('.btn-voir-primes');
      if (!existingButton) {
        const buttonContainer = this.resultTarget.querySelector('.btn-group');
        if (buttonContainer) {
          const viewPrimesBtn = document.createElement('button');
          viewPrimesBtn.className = 'btn btn-success btn-voir-primes';
          viewPrimesBtn.innerHTML = '🎯 Voir mes primes éligibles';
          viewPrimesBtn.addEventListener('click', () => {
            const cat = localStorage.getItem("categorie");

            // Mettre à jour la catégorie globale
            window.categorieId = cat;

            // Masquer le placeholder et afficher les cartes
            this.togglePrimesSection(true);

            // Mettre à jour le titre de la section primes
            this.updatePrimesSectionTitle(cat);

            // Déclencher la mise à jour des cartes
            this.updatePrimesCards(cat);
          });
          buttonContainer.appendChild(viewPrimesBtn);
        }
      }
    }
  }

  updatePrimesSectionTitle(categorie) {
    const titleElement = document.querySelector('.primes-section h4');
    if (titleElement) {
      titleElement.textContent = `Vos primes éligibles - Catégorie ${categorie}`;
    }
  }

  updatePrimesCards(categorie) {
    // Trouver toutes les cartes de primes
    const allPrimeCards = document.querySelectorAll('[data-controller*="prime-card"]');

    allPrimeCards.forEach(card => {
      const slug = card.dataset.slug;
      const prime = window.primes?.find(p => p.slug === slug);

      if (prime) {
        // Vérifier si cette prime est éligible pour cette catégorie
        const isEligible = prime.eligible_categories?.includes(categorie.toString());

        if (isEligible) {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      }
    });

    // Déclencher un événement pour que les contrôleurs prime-card se mettent à jour
    document.dispatchEvent(new CustomEvent('category:changed', {
      detail: { categorie }
    }));
  }

  togglePrimesSection(show = true) {
    const placeholder = document.getElementById("primes-placeholder");
    const primesSection = document.querySelector(".primes-section");

    if (placeholder && primesSection) {
      if (show) {
        placeholder.style.display = "none";
        primesSection.style.display = "block";
      } else {
        placeholder.style.display = "block";
        primesSection.style.display = "none";
      }
    }
  }

  // ========== MÉTHODES WALLONIE ==========

  handleAnswerWallonie(event) {
    console.log("🎯 Test Eligibilité Wallonie - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteWallonie", JSON.stringify(testData));

    // Vérification immédiate des cas d'inéligibilité Wallonie
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le logement doit être situé en Wallonie", false);
      return;
    }

    const destination = testData["destination"];
    if (destination === "non") {
      this.showResult("❌ Le bien doit être destiné à être habité à au moins 50%", false);
      return;
    }

    const propriete = testData["propriete"];
    if (propriete === "non") {
      this.showResult("❌ Vous devez être propriétaire du logement", false);
      return;
    }

    const residence_principale = testData["residence_principale"];
    if (residence_principale === "non") {
      this.showResult("❌ Le logement doit être occupé comme résidence principale dans les 24 mois", false);
      return;
    }

    const age_logement = testData["age_logement"];
    if (age_logement === "non") {
      this.showResult("❌ Le logement doit avoir plus de 15 ans", false);
      return;
    }

    const audit = testData["audit"];
    if (audit === "non") {
      this.showResult("❌ Un audit énergétique par un auditeur agréé est obligatoire", false);
      return;
    }

    const entrepreneur = testData["entrepreneur"];
    if (entrepreneur === "non") {
      this.showResult("❌ L'entrepreneur doit être inscrit à la Banque Carrefour des Entreprises", false);
      return;
    }

    const factures_anciennes = testData["factures_anciennes"];
    if (factures_anciennes === "oui") {
      this.showResult("❌ Les factures de solde ne peuvent pas dater de plus de 2 ans", false);
      return;
    }

    // Si on arrive ici, vérifier si toutes les questions sont répondues
    this.checkAllAnsweredWallonie(testData);
  }

  checkAllAnsweredWallonie(testData) {
    const requiredQuestions = ["localisation", "destination", "propriete", "residence_principale", "age_logement", "audit", "entrepreneur", "revenus", "factures_anciennes", "travaux_toiture"];

    const allAnswered = requiredQuestions.every(question => testData[question] !== undefined);

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    }
  }

  validateTestWallonie() {
    console.log("🚀 Validation finale du test Wallonie");

    const testData = JSON.parse(localStorage.getItem("eligibiliteWallonie") || "{}");

    // Déterminer la catégorie R1-R5 selon les revenus
    const revenus = testData["revenus"];
    const travaux_toiture = testData["travaux_toiture"];

    if (revenus === "non") {
      // Revenus <= 114.400€
      if (travaux_toiture === "oui") {
        this.showResultWallonie("✅ Éligible aux primes Wallonie - Catégorie R1-R4 (toiture uniquement)", true);
      } else {
        this.showResultWallonie("✅ Éligible aux primes Wallonie - Catégorie R1-R4 (tous travaux)", true);
      }
    } else {
      // Revenus > 114.400€
      this.showResultWallonie("✅ Éligible aux primes Wallonie - Catégorie R5", true);
    }
  }

  showResultWallonie(message, isEligible = true) {
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }

    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    if (this.hasResultTarget) {
      this.resultTarget.innerHTML = `
        <div class="alert alert-success">
          <h5 class="alert-heading">
            <i class="bi bi-check-circle me-2"></i>
            Résultat du test d'éligibilité
          </h5>
          <p class="mb-0">${message}</p>
        </div>
        <div class="btn-group mt-3">
          <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        </div>
      `
      this.resultTarget.style.display = "block"

      // Si éligible, afficher le formulaire d'affinage de catégorie
      if (isEligible) {
        this.showAffinageWallonie()
      }
    }
  }

  showAffinageWallonie() {
    // Afficher le bloc d'affinage de catégorie Wallonie
    const affinageBloc = document.getElementById("affinage-categorie-wallonie")
    if (affinageBloc) {
      affinageBloc.style.display = "block"

      // Scroll smooth vers le bloc d'affinage
      setTimeout(() => {
        affinageBloc.scrollIntoView({ behavior: 'smooth' })
      }, 500)
    }
  }
}
