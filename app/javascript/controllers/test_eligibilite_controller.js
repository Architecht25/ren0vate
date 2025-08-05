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

  // WALLONIE PARTICULIER
  handleAnswerWallonieParticulier(event) {
    console.log("🎯 Test Eligibilité Wallonie Particulier - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteWallonieParticulier", JSON.stringify(testData));

    // Gestion des alertes conditionnelles pour la Wallonie
    this.handleConditionalAlertsWallonie(event.target.name, event.target.value);

    // Vérification immédiate des cas d'inéligibilité Wallonie Particulier
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le logement doit être situé en Wallonie (hors Communauté germanophone)", false);
      return;
    }

    const destination = testData["destination"];
    if (destination === "non") {
      this.showResult("❌ Le bien doit être destiné à être habité à au moins 50%", false);
      return;
    }

    const propriete = testData["propriete"];
    if (propriete === "non") {
      this.showResult("❌ Vous devez être propriétaire du logement (plein propriétaire, nu-propriétaire, usufruitier ou copropriétaire)", false);
      return;
    }

    const residence_principale = testData["residence_principale"];
    if (residence_principale === "non") {
      this.showResult("❌ Le logement doit être occupé comme résidence principale dans les 24 mois suivant l'introduction de la demande", false);
      return;
    }

    const age_logement = testData["age_logement"];
    if (age_logement === "non") {
      this.showResult("❌ Le logement doit avoir été construit il y a plus de 15 ans", false);
      return;
    }

    const factures_anciennes = testData["factures_anciennes"];
    if (factures_anciennes === "oui") {
      this.showResult("❌ Les factures de solde ne peuvent pas dater de plus de 2 ans", false);
      return;
    }

    // ❌ VÉRIFICATION R5 IMMÉDIATE : Si revenus trop élevés = INÉLIGIBLE
    const revenus = testData["revenus"];
    if (revenus === "oui") {
      this.showResult(
        "❌ Vos revenus dépassent le plafond d'éligibilité aux primes Wallonie<br><br>" +
        "<strong>Catégorie :</strong> <span class='badge bg-danger'>R5 - Non éligible</span><br><br>" +
        "💰 Avec des revenus supérieurs à 114.400€ (après déductions), vous n'êtes malheureusement plus éligible aux primes habitation de la Région wallonne.<br><br>" +
        "<strong>Alternatives possibles :</strong><br>" +
        "• Déductions fiscales fédérales pour travaux de rénovation<br>" +
        "• Prêts à taux avantageux pour la rénovation<br>" +
        "• Primes communales (si disponibles dans votre commune)",
        false
      );
      return;
    }

    // Vérifier si toutes les questions sont répondues
    this.checkIfAllAnsweredWallonieParticulier();
  }

  checkIfAllAnsweredWallonieParticulier() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestWallonieParticulier() {
    console.log("🎯 Validation du test d'éligibilité Wallonie Particulier");

    const testData = JSON.parse(localStorage.getItem("eligibiliteWallonieParticulier") || "{}");

    // Déterminer la catégorie R1-R5 selon les revenus
    const revenus = testData["revenus"];
    const travaux_toiture = testData["travaux_toiture"];

    // ❌ VÉRIFICATION R5 : Si revenus trop élevés = INÉLIGIBLE
    if (revenus === "oui") {
      // Revenus > 114.400€ = Catégorie R5 = INÉLIGIBLE
      this.showResultWallonieParticulier(
        "❌ Vos revenus dépassent le plafond d'éligibilité aux primes Wallonie<br><br>" +
        "<strong>Catégorie :</strong> <span class='badge bg-danger'>R5 - Non éligible</span><br><br>" +
        "💰 Avec des revenus supérieurs à 114.400€ (après déductions), vous n'êtes malheureusement plus éligible aux primes habitation de la Région wallonne.",
        false,
        [
          "📋 Revenus trop élevés selon les critères régionaux",
          "💡 Vous pouvez néanmoins bénéficier des déductions fiscales fédérales",
          "� Renseignez-vous sur les prêts à taux avantageux pour la rénovation"
        ]
      );
      return; // Arrêter le processus ici
    }

    // ✅ Si on arrive ici, l'utilisateur est éligible (R1-R4)
    let message = "✅ Vous êtes éligible aux primes habitation Wallonie !";
    let recommendations = [];

    // Revenus <= 114.400€ (R1-R4)
    if (travaux_toiture === "oui") {
      message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-success'>R1-R4 (toiture uniquement)</span>";
      recommendations.push("� Travaux de toiture uniquement éligibles avec vos revenus");
    } else {
      message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-success'>R1-R4 (tous travaux)</span>";
      recommendations.push("🎯 Tous les types de travaux sont éligibles avec vos revenus");
    }

    // Conseils sur l'audit
    const audit = testData["audit"];
    if (audit === "oui") {
      recommendations.push("📊 Votre audit énergétique vous donnera accès à des primes supplémentaires");
    } else {
      recommendations.push("💡 Conseil : Un audit énergétique peut débloquer des primes supplémentaires");
    }

    // Stocker la catégorie dans localStorage (seulement R1-R4 maintenant)
    localStorage.setItem("wallonie_categorie", "R1-R4");

    this.showResultWallonieParticulier(message, true, recommendations);
  }

  showResultWallonieParticulier(message, isEligible = true, recommendations = []) {
    // Pour les particuliers, utiliser la méthode finale avec affinage activé
    this.showFinalResultWallonie(message, isEligible, recommendations, true);
  }

  // WALLONIE ENTREPRISE
  handleAnswerWallonieEntreprise(event) {
    console.log("🎯 Test Eligibilité Wallonie Entreprise - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number], input[type=text]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs des champs texte et numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteWallonieEntreprise", JSON.stringify(testData));

    // Vérifications d'inéligibilité spécifiques aux entreprises
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ L'entreprise et le bâtiment doivent être situés en Wallonie", false);
      return;
    }

    const enregistrement_bce = testData["enregistrement_bce"];
    if (enregistrement_bce === "non") {
      this.showResult("❌ L'entreprise doit être inscrite à la BCE (Banque Carrefour des Entreprises)", false);
      return;
    }

    const destination = testData["destination"];
    if (destination === "non") {
      this.showResult("❌ Le bâtiment doit être destiné principalement à des activités professionnelles", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit avoir plus de 15 ans", false);
      return;
    }

    const entrepreneur = testData["entrepreneur"];
    if (entrepreneur === "non") {
      this.showResult("❌ L'entrepreneur réalisant les travaux doit être inscrit à la BCE", false);
      return;
    }

    this.checkIfAllAnsweredWallonieEntreprise();
  }

  checkIfAllAnsweredWallonieEntreprise() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestWallonieEntreprise() {
    console.log("🎯 Validation du test d'éligibilité Wallonie Entreprise");

    let message = "✅ Votre entreprise est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-primary'>Entreprise</span>";

    let recommendations = [
      "🏢 En tant qu'entreprise, vous avez accès aux primes spécifiques aux professionnels",
      "📋 Inscription BCE obligatoire pour l'entreprise et l'entrepreneur",
      "💼 Primes calculées selon la grille tarifaire entreprise"
    ];

    localStorage.setItem("wallonie_categorie", "entreprise");
    this.showResultWallonieEntreprise(message, true, recommendations);
  }

  showResultWallonieEntreprise(message, isEligible = true, recommendations = []) {
    // Pour les entreprises, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE SYNDIC
  handleAnswerWallonieSyndic(event) {
    console.log("🎯 Test Eligibilité Wallonie Syndic - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteWallonieSyndic", JSON.stringify(testData));

    // Vérifications spécifiques aux syndics
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ L'immeuble doit être situé en Wallonie", false);
      return;
    }

    const usage_residentiel = testData["usage_residentiel"];
    if (usage_residentiel === "non") {
      this.showResult("❌ L'immeuble doit être principalement résidentiel (au moins 80% logement)", false);
      return;
    }

    const age_immeuble = testData["age_immeuble"];
    if (age_immeuble === "non") {
      this.showResult("❌ L'immeuble doit avoir plus de 15 ans", false);
      return;
    }

    const minimum_unites = testData["minimum_unites"];
    if (minimum_unites === "non") {
      this.showResult("❌ La copropriété doit compter au moins 2 unités", false);
      return;
    }

    this.checkIfAllAnsweredWallonieSyndic();
  }

  checkIfAllAnsweredWallonieSyndic() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestWallonieSyndic() {
    console.log("🎯 Validation du test d'éligibilité Wallonie Syndic");

    let message = "✅ Votre copropriété est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-warning'>Syndic/Copropriété</span>";

    let recommendations = [
      "🏢 En tant que syndic, vous gérez les demandes pour la copropriété",
      "👥 La demande doit être faite au nom de la copropriété",
      "📋 Minimum 2 unités requises, immeuble à dominante résidentielle"
    ];

    localStorage.setItem("wallonie_categorie", "syndic");
    this.showResultWallonieSyndic(message, true, recommendations);
  }

  showResultWallonieSyndic(message, isEligible = true, recommendations = []) {
    // Pour les syndics, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE ASBL
  handleAnswerWallonieAsbl(event) {
    console.log("🎯 Test Eligibilité Wallonie ASBL - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteWallonieAsbl", JSON.stringify(testData));

    // Vérifications spécifiques aux ASBL
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ L'ASBL et le bâtiment doivent être situés en Wallonie", false);
      return;
    }

    const enregistrement_bce = testData["enregistrement_bce"];
    if (enregistrement_bce === "non") {
      this.showResult("❌ L'ASBL doit être enregistrée à la BCE", false);
      return;
    }

    const activites_interet_general = testData["activites_interet_general"];
    if (activites_interet_general === "non") {
      this.showResult("❌ L'ASBL doit exercer des activités d'intérêt général", false);
      return;
    }

    const usage_collectivite = testData["usage_collectivite"];
    if (usage_collectivite === "oui") {
      this.showResult("❌ Le bâtiment ne peut pas être utilisé par une collectivité publique", false);
      return;
    }

    const autorisation_travaux = testData["autorisation_travaux"];
    if (autorisation_travaux === "non") {
      this.showResult("❌ Vous devez être propriétaire ou avoir l'autorisation écrite du propriétaire", false);
      return;
    }

    this.checkIfAllAnsweredWallonieAsbl();
  }

  checkIfAllAnsweredWallonieAsbl() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestWallonieAsbl() {
    console.log("🎯 Validation du test d'éligibilité Wallonie ASBL");

    let message = "✅ Votre ASBL est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-info'>ASBL</span>";

    let recommendations = [
      "🏛️ En tant qu'ASBL, vous avez accès aux primes spécifiques aux associations",
      "📋 Activités d'intérêt général requises",
      "⚖️ Pas d'usage par des collectivités publiques autorisé"
    ];

    localStorage.setItem("wallonie_categorie", "asbl");
    this.showResultWallonieAsbl(message, true, recommendations);
  }

  showResultWallonieAsbl(message, isEligible = true, recommendations = []) {
    // Pour les ASBL, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE BAILLEUR
  handleAnswerWallonieBailleur(event) {
    console.log("🎯 Test Eligibilité Wallonie Bailleur - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteWallonieBailleur", JSON.stringify(testData));

    // Vérifications spécifiques aux bailleurs sociaux
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le logement doit être situé en Wallonie", false);
      return;
    }

    const statut_bailleur = testData["statut_bailleur"];
    if (statut_bailleur === "non") {
      this.showResult("❌ Vous devez être reconnu comme bailleur social par la Région wallonne", false);
      return;
    }

    const destination_sociale = testData["destination_sociale"];
    if (destination_sociale === "non") {
      this.showResult("❌ Le bien doit être destiné au logement social", false);
      return;
    }

    const age_logement = testData["age_logement"];
    if (age_logement === "non") {
      this.showResult("❌ Le logement doit avoir plus de 15 ans", false);
      return;
    }

    const entrepreneur = testData["entrepreneur"];
    if (entrepreneur === "non") {
      this.showResult("❌ L'entrepreneur chargé des travaux doit être inscrit à la BCE", false);
      return;
    }

    this.checkIfAllAnsweredWallonieBailleur();
  }

  checkIfAllAnsweredWallonieBailleur() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestWallonieBailleur() {
    console.log("🎯 Validation du test d'éligibilité Wallonie Bailleur");

    let message = "✅ Votre organisme de logement social est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-info'>Bailleur Social</span>";

    let recommendations = [
      "🏠 En tant que bailleur social reconnu, vous avez accès aux primes spécifiques",
      "🏛️ Statut de bailleur social reconnu par la Région wallonne requis",
      "👥 Travaux destinés au logement social uniquement"
    ];

    localStorage.setItem("wallonie_categorie", "bailleur");
    this.showResultWallonieBailleur(message, true, recommendations);
  }

  showResultWallonieBailleur(message, isEligible = true, recommendations = []) {
    // Pour les bailleurs, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // Méthode générale pour afficher les résultats Wallonie
  showFinalResultWallonie(message, isEligible = true, recommendations = [], showAffinage = false) {
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }

    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    if (this.hasResultTarget) {
      let content = `
        <div class="alert ${isEligible ? 'alert-success' : 'alert-danger'}">
          <h5 class="alert-heading">
            <i class="bi bi-${isEligible ? 'check-circle' : 'x-circle'} me-2"></i>
            Résultat du test d'éligibilité Wallonie
          </h5>
          <p class="mb-0">${message}</p>
        </div>
      `;

      if (recommendations.length > 0) {
        content += `
          <div class="alert alert-info mt-3">
            <h6 class="alert-heading">
              <i class="bi bi-lightbulb me-2"></i>
              Informations importantes
            </h6>
            <ul class="mb-0">
              ${recommendations.map(rec => `<li>${rec}</li>`).join('')}
            </ul>
          </div>
        `;
      }

      content += `
        <div class="btn-group mt-3">
          <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        </div>
      `;

      this.resultTarget.innerHTML = content;
      this.resultTarget.style.display = "block";

      // Si demandé ET éligible, afficher le formulaire d'affinage de catégorie (seulement pour particuliers)
      if (isEligible && showAffinage) {
        this.showAffinageWallonieParticulier();
      }
    }
  }

  showAffinageWallonieParticulier() {
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

  handleConditionalAlertsWallonie(questionName, value) {
    // Gestion des alertes d'information spécifiques à la Wallonie
    const alertsMap = {
      'audit': {
        condition: value === 'non',
        elementId: 'audit_wallonie_info'
      },
      'entrepreneur': {
        condition: value === 'non',
        elementId: 'entrepreneur_wallonie_info'
      }
    };

    // Pour chaque alerte configurée
    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element) {
        // Afficher l'alerte si c'est la bonne question ET la bonne condition
        // Masquer l'alerte si c'est la bonne question MAIS pas la bonne condition
        if (questionName === key) {
          element.style.display = config.condition ? 'block' : 'none';
        }
      }
    });
  }

  // ========== MÉTHODES BRUXELLES ==========

  handleAnswerBruxelles(event) {
    console.log("🎯 Test Eligibilité Bruxelles - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteBruxelles", JSON.stringify(testData));

    // Vérification immédiate des cas d'inéligibilité Bruxelles
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResultBruxelles("❌ Le logement doit être situé en Région de Bruxelles Capitale", false);
      return;
    }

    const age_logement = testData["age_logement"];
    if (age_logement === "non") {
      this.showResultBruxelles("❌ Le bâtiment doit avoir été construit il y a plus de 10 ans", false);
      return;
    }

    const destination = testData["destination"];
    if (destination === "non") {
      this.showResultBruxelles("❌ Le bien doit être destiné à être habité (maison, appartement, immeuble à logement)", false);
      return;
    }

    const entrepreneur = testData["entrepreneur"];
    if (entrepreneur === "non") {
      this.showResultBruxelles("❌ Les travaux doivent être réalisés par un professionnel inscrit à la Banque Carrefour des Entreprises", false);
      return;
    }

    const reconstruction = testData["reconstruction"];
    if (reconstruction === "oui") {
      this.showResultBruxelles("❌ Les reconstructions assimilées à du neuf ne sont pas éligibles", false);
      return;
    }

    const propriete = testData["propriete"];
    if (propriete === "non") {
      this.showResultBruxelles("❌ Vous devez être propriétaire ou copropriétaire du bien (min. 1%)", false);
      return;
    }

    const compte_bancaire = testData["compte_bancaire"];
    if (compte_bancaire === "non") {
      this.showResultBruxelles("❌ Un compte bancaire belge est requis pour le virement de la prime", false);
      return;
    }

    const factures_recentes = testData["factures_recentes"];
    if (factures_recentes === "oui") {
      this.showResultBruxelles("❌ Les travaux doivent être réalisés après l'introduction de la demande", false);
      return;
    }

    const performance_energetique = testData["performance_energetique"];
    if (performance_energetique === "non") {
      this.showResultBruxelles("❌ Les travaux doivent viser à améliorer la performance énergétique", false);
      return;
    }

    // Si on arrive ici, vérifier si toutes les questions sont répondues
    this.checkAllAnsweredBruxelles(testData);
  }

  checkAllAnsweredBruxelles(testData) {
    const requiredQuestions = [
      "localisation", "age_logement", "destination", "entrepreneur", "reconstruction",
      "propriete", "compte_bancaire", "client_protege", "audit", "peb_classe",
      "factures_recentes", "performance_energetique", "types_travaux", "copropriete"
    ];

    const allAnswered = requiredQuestions.every(question => testData[question] !== undefined);

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    }
  }

  validateTestBruxelles() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles");

    const form = this.formTarget;
    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxelles") || "{}");

    // Déterminer la catégorie selon les critères Bruxelles
    const client_protege = testData["client_protege"];
    const audit = testData["audit"];
    const peb_classe = testData["peb_classe"];

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles !";
    let recommendations = [];

    // Client protégé = catégorie de revenus la plus favorable
    if (client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
    }

    // Audit énergétique
    if (audit === "oui") {
      recommendations.push("📊 Votre audit énergétique vous donnera accès à des primes spécifiques");
    } else {
      recommendations.push("💡 Conseil : Un audit énergétique peut débloquer des primes supplémentaires");
    }

    // Classe PEB
    if (peb_classe === "oui") {
      recommendations.push("🏠 Votre logement classe E, F ou G vous donne accès aux primes RENOLUTION");
    }

    const copropriete = testData["copropriete"];
    if (copropriete === "oui") {
      recommendations.push("🏢 En copropriété, la demande doit être collective via l'ACP/syndic");
    }

    this.showResultBruxelles(message, true, recommendations);
  }

  showResultBruxelles(message, isEligible = true, recommendations = []) {
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }

    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    if (this.hasResultTarget) {
      let content = `
        <div class="alert ${isEligible ? 'alert-success' : 'alert-danger'}">
          <h5 class="alert-heading">
            <i class="bi bi-${isEligible ? 'check-circle' : 'x-circle'} me-2"></i>
            Résultat du test d'éligibilité Bruxelles
          </h5>
          <p class="mb-0">${message}</p>
        </div>
      `;

      if (recommendations.length > 0) {
        content += `
          <div class="alert alert-info mt-3">
            <h6 class="alert-heading">
              <i class="bi bi-lightbulb me-2"></i>
              Recommandations personnalisées
            </h6>
            <ul class="mb-0">
              ${recommendations.map(rec => `<li>${rec}</li>`).join('')}
            </ul>
          </div>
        `;
      }

      content += `
        <div class="btn-group mt-3">
          <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        </div>
      `;

      this.resultTarget.innerHTML = content;
      this.resultTarget.style.display = "block";

      // Si éligible, afficher le formulaire d'affinage de catégorie
      if (isEligible) {
        this.showAffinageBruxellesParticulier();
      }
    }
  }

  handleAnswerBruxellesParticulier(event) {
    console.log("🎯 Test Eligibilité Bruxelles Particulier - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesParticulier", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlerts(event.target.name, event.target.value);

    // Vérification immédiate des cas d'inéligibilité Bruxelles Particulier
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien concerné par la demande doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel inscrit à la Banque Carrefour des Entreprises qui dispose de l'accès réglementé à la profession", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ou ajouts considérés comme nouvelle construction ne sont pas éligibles", false);
      return;
    }

    const compte_belge = testData["compte_belge"];
    if (compte_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis pour le virement de la prime", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec une facture de solde émise dans les 12 mois précédant la demande", false);
      return;
    }

    // Vérification appartement + parties communes
    const proprietaire_appartement = testData["proprietaire_appartement"];
    const parties_communes = testData["parties_communes"];
    if (proprietaire_appartement === "oui" && parties_communes === "oui") {
      this.showResult("❌ Pour les travaux concernant les parties communes d'un immeuble, la demande doit être faite au nom de l'ACP (Association des Copropriétaires)", false);
      return;
    }

    const domiciliation = testData["domiciliation"];
    if (domiciliation === "non") {
      this.showResult("❌ Vous devez être domicilié à l'adresse du chantier au plus tard avant l'introduction de la demande", false);
      return;
    }

    // Vérifier si toutes les questions sont répondues
    this.checkIfAllAnsweredBruxellesParticulier();
  }

  handleConditionalAlerts(questionName, value) {
    // Gestion des alertes d'information
    const alertsMap = {
      'primes_recues': {
        condition: value === 'oui',
        elementId: 'primes_recues_warning'
      },
      'bim': {
        condition: value === 'oui',
        elementId: 'bim_info'
      },
      'ris': {
        condition: value === 'oui',
        elementId: 'ris_info'
      },
      'client_protege': {
        condition: value === 'oui',
        elementId: 'client_protege_info'
      },
      'vente_bien': {
        condition: value === 'oui',
        elementId: 'vente_bien_warning'
      },
      'permis_urbanisme': {
        condition: value === 'non',
        elementId: 'permis_urbanisme_info'
      },
      'parties_communes': {
        condition: value === 'oui',
        elementId: 'parties_communes_warning'
      }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element) {
        element.style.display = (questionName === key && config.condition) ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    this.handleConditionalSections(questionName, value);
  }

  handleConditionalSections(questionName, value) {
    // Appartement -> Parties communes
    if (questionName === 'proprietaire_appartement') {
      const appartementDetails = document.getElementById('appartement_parties_communes');
      if (appartementDetails) {
        appartementDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }

    // Indépendant -> Détails
    if (questionName === 'independant') {
      const independantDetails = document.getElementById('independant_details');
      if (independantDetails) {
        independantDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }

    // Usage professionnel -> Surfaces
    if (questionName === 'usage_professionnel') {
      const usageDetails = document.getElementById('usage_professionnel_details');
      if (usageDetails) {
        usageDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesParticulier() {
    const form = this.formTarget;

    // Obtenir tous les noms de questions uniques de base
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    let questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    // Questions de base obligatoires
    const baseQuestions = [
      'localisation', 'age_batiment', 'professionnel_agree', 'nouvelle_construction',
      'compte_belge', 'travaux_realises', 'primes_recues', 'proprietaire_appartement',
      'proprietaire_maison', 'bim', 'ris', 'client_protege', 'independant',
      'domiciliation', 'vente_bien', 'permis_urbanisme', 'bien_classe', 'petit_patrimoine'
    ];

    // Obtenir les réponses actuelles
    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Vérifier les questions de base
    let allBaseAnswered = baseQuestions.every(name => {
      const input = form.querySelector(`input[name="${name}"]:checked`);
      return input !== null;
    });

    // Vérifications conditionnelles
    let conditionalAnswered = true;

    // Si propriétaire appartement = oui, vérifier parties_communes
    if (testData.proprietaire_appartement === 'oui') {
      conditionalAnswered = conditionalAnswered && (testData.parties_communes !== undefined);
    }

    // Si indépendant = oui, vérifier les sous-questions
    if (testData.independant === 'oui') {
      conditionalAnswered = conditionalAnswered &&
        (testData.tva_deductible !== undefined) &&
        (testData.usage_professionnel !== undefined);

      // Si usage professionnel = oui, vérifier les surfaces
      if (testData.usage_professionnel === 'oui') {
        const surfaceTotale = form.querySelector('input[name="surface_totale"]');
        const surfacePro = form.querySelector('input[name="surface_professionnelle"]');
        conditionalAnswered = conditionalAnswered &&
          (surfaceTotale && surfaceTotale.value.trim() !== '') &&
          (surfacePro && surfacePro.value.trim() !== '');
      }
    }

    const allAnswered = allBaseAnswered && conditionalAnswered;

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesParticulier() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Particulier");

    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxellesParticulier") || "{}");
    console.log("🎯 Données récupérées:", testData);

    // Logique simple côté client comme pour la Wallonie
    const client_protege = testData["client_protege"];

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles !";
    let recommendations = [];

    // Client protégé = catégorie de revenus la plus favorable
    if (client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
      message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-success'>Client protégé (Catégorie 3)</span>";

      // Stocker la catégorie dans localStorage pour la suite
      localStorage.setItem("bruxelles_categorie", "3");
      localStorage.setItem("bruxellesCategorieEstimee", "3");
    } else {
      message += "<br><br><strong>Prochaine étape :</strong> Calculez votre catégorie de revenus pour connaître vos primes exactes";
    }

    console.log("🎯 Message final:", message);
    console.log("🎯 Recommandations:", recommendations);

    this.showResultBruxellesParticulier(message, true, recommendations);
  }

  showResultBruxellesParticulier(message, isEligible = true, recommendations = []) {
    console.log("🎯 showResultBruxellesParticulier appelée", { message, isEligible, recommendations });

    // Pour les particuliers, utiliser la méthode finale avec affinage activé
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }

  showAffinageBruxellesParticulier() {
    // Afficher le bloc d'affinage de catégorie Bruxelles (même approche que Wallonie)
    const affinageBloc = document.getElementById("affinage-categorie-bruxelles")
    if (affinageBloc) {
      affinageBloc.style.display = "block"

      // Scroll smooth vers le bloc d'affinage
      setTimeout(() => {
        affinageBloc.scrollIntoView({ behavior: 'smooth' })
      }, 500)
    }
  }

  // Méthode pour afficher le résultat final sans affinage (pour entreprises, syndics, etc.)
  showFinalResultBruxelles(message, isEligible = true, recommendations = [], showAffinage = false) {
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }

    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    if (this.hasResultTarget) {
      let content = `
        <div class="alert ${isEligible ? 'alert-success' : 'alert-danger'}">
          <h5 class="alert-heading">
            <i class="bi bi-${isEligible ? 'check-circle' : 'x-circle'} me-2"></i>
            Résultat du test d'éligibilité Bruxelles
          </h5>
          <p class="mb-0">${message}</p>
        </div>
      `;

      if (recommendations.length > 0) {
        content += `
          <div class="alert alert-info mt-3">
            <h6 class="alert-heading">
              <i class="bi bi-lightbulb me-2"></i>
              Informations importantes
            </h6>
            <ul class="mb-0">
              ${recommendations.map(rec => `<li>${rec}</li>`).join('')}
            </ul>
          </div>
        `;
      }

      content += `
        <div class="btn-group mt-3">
          <button type="button" class="btn btn-secondary" onclick="location.reload()">🔄 Recommencer</button>
        </div>
      `;

      this.resultTarget.innerHTML = content;
      this.resultTarget.style.display = "block";

      // Si demandé ET éligible, afficher le formulaire d'affinage de catégorie (seulement pour particuliers)
      if (isEligible && showAffinage) {
        this.showAffinageBruxellesParticulier();
      }
    }
  }

  handleAnswerBruxellesEntreprise(event) {
    console.log("🎯 Test Eligibilité Bruxelles Entreprise - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number], input[type=text]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs des champs texte et numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesEntreprise", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlertsEntreprise(event.target.name, event.target.value);

    // Vérification immédiate des cas d'inéligibilité Bruxelles Entreprise
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien concerné par la demande doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel inscrit à la Banque Carrefour des Entreprises qui dispose de l'accès réglementé à la profession", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ou ajouts considérés comme nouvelle construction ne sont pas éligibles", false);
      return;
    }

    const compte_belge = testData["compte_belge"];
    if (compte_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis pour le virement de la prime", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec une facture de solde émise dans les 12 mois précédant la demande", false);
      return;
    }

    const enregistrement_bce = testData["enregistrement_bce"];
    if (enregistrement_bce === "non") {
      this.showResult("❌ Pour introduire une demande de prime en tant que société, cette dernière doit être inscrite à la BCE", false);
      return;
    }

    // Vérifier si toutes les questions sont répondues
    this.checkIfAllAnsweredBruxellesEntreprise();
  }

  handleConditionalAlertsEntreprise(questionName, value) {
    // Gestion des alertes d'information
    const alertsMap = {
      'primes_recues': {
        condition: value === 'oui',
        elementId: 'primes_recues_warning'
      }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element) {
        element.style.display = (questionName === key && config.condition) ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    this.handleConditionalSectionsEntreprise(questionName, value);
  }

  handleConditionalSectionsEntreprise(questionName, value) {
    // Propriétaire immeuble -> Détails
    if (questionName === 'proprietaire_immeuble') {
      const immeubleDetails = document.getElementById('immeuble_details');
      if (immeubleDetails) {
        immeubleDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }

    // Usage collectivité -> Détails collectivité
    if (questionName === 'usage_collectivite') {
      const collectiviteDetails = document.getElementById('collectivite_details');
      if (collectiviteDetails) {
        collectiviteDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }

    // TVA déductible -> Pourcentage
    if (questionName === 'tva_deductible') {
      const tvaPourcentage = document.getElementById('tva_pourcentage');
      if (tvaPourcentage) {
        tvaPourcentage.style.display = value === 'oui' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesEntreprise() {
    const form = this.formTarget;

    // Questions de base obligatoires
    const baseQuestions = [
      'localisation', 'age_batiment', 'professionnel_agree', 'nouvelle_construction',
      'compte_belge', 'travaux_realises', 'primes_recues', 'proprietaire_immeuble',
      'proprietaire_appartement', 'proprietaire_maison', 'enregistrement_bce',
      'bail_ais', 'tva_deductible', 'de_minimis', 'bien_classe', 'petit_patrimoine'
    ];

    // Obtenir les réponses actuelles
    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Vérifier les questions de base
    let allBaseAnswered = baseQuestions.every(name => {
      const input = form.querySelector(`input[name="${name}"]:checked`);
      return input !== null;
    });

    // Vérifications conditionnelles
    let conditionalAnswered = true;

    // Si propriétaire immeuble = oui, vérifier les sous-questions
    if (testData.proprietaire_immeuble === 'oui') {
      conditionalAnswered = conditionalAnswered &&
        (testData.logement_80_pourcent !== undefined) &&
        (testData.usage_collectivite !== undefined);

      // Vérifier quantité appartements
      const quantiteAppartements = form.querySelector('input[name="quantite_appartements"]');
      conditionalAnswered = conditionalAnswered &&
        (quantiteAppartements && quantiteAppartements.value.trim() !== '');

      // Si usage collectivité = oui, vérifier nom et code Nacebel
      if (testData.usage_collectivite === 'oui') {
        const nomCollectivite = form.querySelector('input[name="nom_collectivite"]');
        const codeNacebel = form.querySelector('input[name="code_nacebel"]');
        conditionalAnswered = conditionalAnswered &&
          (nomCollectivite && nomCollectivite.value.trim() !== '') &&
          (codeNacebel && codeNacebel.value.trim() !== '');
      }
    }

    // Si TVA déductible = oui, vérifier pourcentage
    if (testData.tva_deductible === 'oui') {
      const pourcentageTva = form.querySelector('input[name="pourcentage_tva"]');
      conditionalAnswered = conditionalAnswered &&
        (pourcentageTva && pourcentageTva.value.trim() !== '');
    }

    const allAnswered = allBaseAnswered && conditionalAnswered;

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesEntreprise() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Entreprise");

    let message = "✅ Votre entreprise est éligible aux primes RENOLUTION Bruxelles !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-primary'>Catégorie 1</span>";

    let recommendations = [
      "🏢 En tant qu'entreprise, vous êtes automatiquement en catégorie 1",
      "📋 Assurez-vous que votre entreprise est bien inscrite à la BCE",
      "💼 Les montants des primes correspondent à la grille tarifaire entreprise"
    ];

    // Stocker la catégorie dans localStorage pour la suite
    localStorage.setItem("bruxelles_categorie", "1");
    localStorage.setItem("bruxellesCategorieEstimee", "1");

    this.showResultBruxellesEntreprise(message, true, recommendations);
  }

  showResultBruxellesEntreprise(message, isEligible = true, recommendations = []) {
    // Pour les entreprises, pas d'affinage - résultat direct
    this.showFinalResultBruxelles(message, isEligible, recommendations, false);
  }

  // SYNDIC
  handleAnswerBruxellesSyndic(event) {
    console.log("🎯 Test Eligibilité Bruxelles Syndic - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteBruxellesSyndic", JSON.stringify(testData));

    // Vérification immédiate des cas d'inéligibilité Bruxelles Syndic
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ L'immeuble doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const usage_residentiel = testData["usage_residentiel"];
    if (usage_residentiel === "non") {
      this.showResult("❌ L'immeuble doit être principalement résidentiel (au moins 80% logement)", false);
      return;
    }

    const age_immeuble = testData["age_immeuble"];
    if (age_immeuble === "non") {
      this.showResult("❌ L'immeuble doit avoir été construit il y a plus de 10 ans", false);
      return;
    }

    const minimum_unites = testData["minimum_unites"];
    if (minimum_unites === "non") {
      this.showResult("❌ La copropriété doit compter au moins 2 unités", false);
      return;
    }

    // Vérifier si toutes les questions sont répondues
    this.checkIfAllAnsweredBruxellesSyndic();
  }

  checkIfAllAnsweredBruxellesSyndic() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesSyndic() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Syndic");

    let message = "✅ Votre copropriété est éligible aux primes RENOLUTION Bruxelles !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-warning'>Catégorie 2</span>";

    let recommendations = [
      "🏢 En tant que syndic/copropriété, vous êtes automatiquement en catégorie 2",
      "👥 La demande doit être faite au nom de l'ACP (Association des Copropriétaires)",
      "📋 Minimum 2 unités requises pour être éligible"
    ];

    // Stocker la catégorie dans localStorage pour la suite
    localStorage.setItem("bruxelles_categorie", "2");
    localStorage.setItem("bruxellesCategorieEstimee", "2");

    this.showResultBruxellesSyndic(message, true, recommendations);
  }

  showResultBruxellesSyndic(message, isEligible = true, recommendations = []) {
    // Pour les syndics, pas d'affinage - résultat direct
    this.showFinalResultBruxelles(message, isEligible, recommendations, false);
  }

  // BAILLEUR
  handleAnswerBruxellesBailleur(event) {
    console.log("🎯 Test Eligibilité Bruxelles Bailleur - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteBruxellesBailleur", JSON.stringify(testData));

    // Vérification immédiate des cas d'inéligibilité Bruxelles Bailleur
    const agrement_ais = testData["agrement_ais"];
    if (agrement_ais === "non") {
      this.showResult("❌ Un agrément AIS (Agence Immobilière Sociale) est requis", false);
      return;
    }

    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Les logements doivent être situés en Région de Bruxelles-Capitale", false);
      return;
    }

    const logement_social = testData["logement_social"];
    if (logement_social === "non") {
      this.showResult("❌ Vous devez gérer au moins un logement destiné au logement social", false);
      return;
    }

    const compte_belge = testData["compte_belge"];
    if (compte_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis pour le versement des primes", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesBailleur();
  }

  checkIfAllAnsweredBruxellesBailleur() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesBailleur() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Bailleur");

    let message = "✅ Votre organisme de logement social est éligible aux primes RENOLUTION Bruxelles !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-success'>Catégorie 3 (AIS)</span>";

    let recommendations = [
      "🏠 En tant qu'AIS (Agence Immobilière Sociale), vous êtes en catégorie 3",
      "📋 Agrément AIS requis pour l'éligibilité",
      "🎯 Primes spécifiques au logement social"
    ];

    // Stocker la catégorie dans localStorage pour la suite
    localStorage.setItem("bruxelles_categorie", "3");
    localStorage.setItem("bruxellesCategorieEstimee", "3");

    this.showResultBruxellesBailleur(message, true, recommendations);
  }

  showResultBruxellesBailleur(message, isEligible = true, recommendations = []) {
    // Pour les bailleurs sociaux, pas d'affinage - résultat direct
    this.showFinalResultBruxelles(message, isEligible, recommendations, false);
  }

  // ASBL
  handleAnswerBruxellesAsbl(event) {
    console.log("🎯 Test Eligibilité Bruxelles ASBL - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteBruxellesAsbl", JSON.stringify(testData));

    // Gestion des sections conditionnelles
    this.handleConditionalSectionsAsbl(event.target.name, event.target.value);

    // Vérification immédiate des cas d'inéligibilité Bruxelles ASBL
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ L'ASBL et le bâtiment doivent être situés en Région de Bruxelles-Capitale", false);
      return;
    }

    const autres_primes = testData["autres_primes"];
    if (autres_primes === "oui") {
      this.showResult("❌ Vous ne pouvez pas cumuler cette prime avec d'autres primes d'énergie pour le même bâtiment", false);
      return;
    }

    const usage_collectivite = testData["usage_collectivite"];
    if (usage_collectivite === "oui") {
      this.showResult("❌ Ce bâtiment ne peut pas être utilisé par une collectivité ou administration publique", false);
      return;
    }

    const enregistrement_bce = testData["enregistrement_bce"];
    if (enregistrement_bce === "non") {
      this.showResult("❌ L'ASBL doit être enregistrée à la BCE (Banque Carrefour des Entreprises)", false);
      return;
    }

    const autorisation_travaux = testData["autorisation_travaux"];
    if (autorisation_travaux === "non") {
      this.showResult("❌ Vous devez être propriétaire du bâtiment ou avoir l'autorisation écrite du propriétaire pour réaliser les travaux", false);
      return;
    }

    const travaux_commences = testData["travaux_commences"];
    if (travaux_commences === "oui") {
      this.showResult("❌ Les travaux ne doivent pas avoir commencé avant l'introduction de la demande de prime", false);
      return;
    }

    const tva_deduction = testData["tva_deduction"];
    if (tva_deduction === "oui") {
      this.showResult("❌ Si vous pouvez déduire la TVA sur les travaux, vous n'êtes pas éligible à cette prime", false);
      return;
    }

    const activites_interet_general = testData["activites_interet_general"];
    if (activites_interet_general === "non") {
      this.showResult("❌ L'ASBL doit exercer des activités d'intérêt général reconnues", false);
      return;
    }

    const utilisation_reguliere = testData["utilisation_reguliere"];
    if (utilisation_reguliere === "non") {
      this.showResult("❌ Le bâtiment doit être utilisé de manière régulière et continue pour les activités de l'ASBL", false);
      return;
    }

    const batiment_conforme = testData["batiment_conforme"];
    if (batiment_conforme === "non") {
      this.showResult("❌ Le bâtiment doit être conforme à la réglementation en vigueur (permis d'urbanisme, normes de sécurité, accessibilité)", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesAsbl();
  }

  handleConditionalSectionsAsbl(questionName, value) {
    // Section déduction TVA si ASBL a un numéro TVA
    if (questionName === 'numero_tva') {
      const tvaDeductionSection = document.getElementById('asbl_tva_deduction_section');
      if (tvaDeductionSection) {
        tvaDeductionSection.style.display = value === 'oui' ? 'block' : 'none';

        // Reset la question de déduction si on cache la section
        if (value === 'non') {
          const tvaDeductionInputs = document.querySelectorAll('input[name="tva_deduction"]');
          tvaDeductionInputs.forEach(input => input.checked = false);
        }
      }
    }
  }

  checkIfAllAnsweredBruxellesAsbl() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesAsbl() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles ASBL");

    let message = "✅ Votre ASBL est éligible aux primes RENOLUTION Bruxelles !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-info'>Catégorie 1 (ASBL)</span>";

    let recommendations = [
      "🏛️ En tant qu'ASBL, vous êtes en catégorie 1 comme les entreprises",
      "📋 Activités d'intérêt général reconnues requises",
      "⚖️ Pas de déduction TVA autorisée pour cette prime"
    ];

    // Stocker la catégorie dans localStorage pour la suite
    localStorage.setItem("bruxelles_categorie", "1");
    localStorage.setItem("bruxellesCategorieEstimee", "1");

    this.showResultBruxellesAsbl(message, true, recommendations);
  }

  showResultBruxellesAsbl(message, isEligible = true, recommendations = []) {
    // Pour les ASBL, pas d'affinage - résultat direct
    this.showFinalResultBruxelles(message, isEligible, recommendations, false);
  }

  // ========== NOUVEAUX PROFILS BRUXELLES ==========

  // PARTICULIER BAILLEUR
  handleAnswerBruxellesParticulierBailleur(event) {
    console.log("🎯 Test Eligibilité Bruxelles Particulier Bailleur - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesParticulierBailleur", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlertsBailleur(event.target.name, event.target.value);

    // Vérifications d'inéligibilité
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel agréé", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ne sont pas éligibles", false);
      return;
    }

    const compte_bancaire_belge = testData["compte_bancaire_belge"];
    if (compte_bancaire_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec facture dans les 12 mois", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesParticulierBailleur();
  }

  handleConditionalAlertsBailleur(questionName, value) {
    const alertsMap = {
      'primes_anterieures': { condition: value === 'oui', elementId: 'primes_anterieures_info' },
      'bim': { condition: value === 'oui', elementId: 'bim_info' },
      'ris': { condition: value === 'oui', elementId: 'ris_info' },
      'client_protege': { condition: value === 'oui', elementId: 'client_protege_info' },
      'permis_urbanisme': { condition: value === 'non', elementId: 'permis_urbanisme_info' },
      'peb': { condition: value === 'non', elementId: 'peb_info' }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element && questionName === key) {
        element.style.display = config.condition ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    if (questionName === 'type_propriete') {
      const immeubleDetails = document.getElementById('immeuble_details');
      if (immeubleDetails) {
        immeubleDetails.style.display = value === 'immeuble_complet' ? 'block' : 'none';
      }
    }

    if (questionName === 'activite_professionnelle') {
      const activiteDetails = document.getElementById('activite_details');
      if (activiteDetails) {
        activiteDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesParticulierBailleur() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    let allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    // Vérifications conditionnelles
    if (testData.type_propriete === 'immeuble_complet') {
      const nbAppartements = form.querySelector('input[name="nb_appartements"]');
      allAnswered = allAnswered && nbAppartements && nbAppartements.value.trim() !== '';
      allAnswered = allAnswered && testData.composition_immeuble !== undefined;
    }

    if (testData.activite_professionnelle === 'oui') {
      allAnswered = allAnswered && testData.tva_applicable !== undefined;
    }

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesParticulierBailleur() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Particulier Bailleur");

    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxellesParticulierBailleur") || "{}");

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles en tant que particulier bailleur !";
    let recommendations = [];

    // Vérifier les avantages
    if (testData.bim === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le statut BIM");
    }
    if (testData.ris === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le RIS");
    }
    if (testData.client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
    }

    if (testData.type_propriete === 'immeuble_complet') {
      recommendations.push("🏢 Propriétaire d'immeuble complet - primes spécifiques applicables");
    }

    message += "<br><br><strong>Profil :</strong> <span class='badge bg-primary'>Particulier Bailleur</span>";

    localStorage.setItem("bruxelles_categorie", "particulier_bailleur");
    this.showResultBruxellesParticulierBailleur(message, true, recommendations);
  }

  showResultBruxellesParticulierBailleur(message, isEligible = true, recommendations = []) {
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }

  // PARTICULIER INDIVISION
  handleAnswerBruxellesParticulierIndivision(event) {
    console.log("🎯 Test Eligibilité Bruxelles Particulier Indivision - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    localStorage.setItem("eligibiliteBruxellesParticulierIndivision", JSON.stringify(testData));

    // Gestion des alertes
    this.handleConditionalAlertsIndivision(event.target.name, event.target.value);

    // Vérifications d'inéligibilité
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel agréé", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ne sont pas éligibles", false);
      return;
    }

    const compte_bancaire_belge = testData["compte_bancaire_belge"];
    if (compte_bancaire_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec facture dans les 12 mois", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesParticulierIndivision();
  }

  handleConditionalAlertsIndivision(questionName, value) {
    const alertsMap = {
      'primes_anterieures': { condition: value === 'oui', elementId: 'primes_anterieures_info' }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element && questionName === key) {
        element.style.display = config.condition ? 'block' : 'none';
      }
    });
  }

  checkIfAllAnsweredBruxellesParticulierIndivision() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesParticulierIndivision() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Particulier Indivision");

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles en tant que particulier en indivision !";
    message += "<br><br><strong>Profil :</strong> <span class='badge bg-info'>Particulier Indivision</span>";

    let recommendations = [
      "👥 En tant que copropriétaire en indivision, vous pouvez demander les primes individuellement",
      "📋 Attention à la règle des 10 ans pour les primes identiques",
      "⚖️ Chaque indivisaire peut faire sa demande selon sa quote-part"
    ];

    localStorage.setItem("bruxelles_categorie", "particulier_indivision");
    this.showResultBruxellesParticulierIndivision(message, true, recommendations);
  }

  showResultBruxellesParticulierIndivision(message, isEligible = true, recommendations = []) {
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }

  // LOCATAIRE
  handleAnswerBruxellesLocataire(event) {
    console.log("🎯 Test Eligibilité Bruxelles Locataire - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesLocataire", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlertsLocataire(event.target.name, event.target.value);

    // Vérifications d'inéligibilité
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel agréé", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ne sont pas éligibles", false);
      return;
    }

    const compte_bancaire_belge = testData["compte_bancaire_belge"];
    if (compte_bancaire_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec facture dans les 12 mois", false);
      return;
    }

    const accord_proprietaire = testData["accord_proprietaire"];
    if (accord_proprietaire === "non") {
      this.showResult("❌ L'accord écrit du propriétaire est obligatoire pour les locataires", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesLocataire();
  }

  handleConditionalAlertsLocataire(questionName, value) {
    const alertsMap = {
      'primes_anterieures': { condition: value === 'oui', elementId: 'primes_anterieures_info' },
      'bim': { condition: value === 'oui', elementId: 'bim_info' },
      'ris': { condition: value === 'oui', elementId: 'ris_info' },
      'client_protege': { condition: value === 'oui', elementId: 'client_protege_info' },
      'permis_urbanisme': { condition: value === 'non', elementId: 'permis_urbanisme_info' }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element && questionName === key) {
        element.style.display = config.condition ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    if (questionName === 'type_propriete') {
      const immeubleDetails = document.getElementById('immeuble_details');
      if (immeubleDetails) {
        immeubleDetails.style.display = value === 'immeuble_complet' ? 'block' : 'none';
      }
    }

    if (questionName === 'activite_professionnelle') {
      const activiteDetails = document.getElementById('activite_details');
      if (activiteDetails) {
        activiteDetails.style.display = value === 'oui' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesLocataire() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    let allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    // Vérifications conditionnelles
    if (testData.type_propriete === 'immeuble_complet') {
      const nbAppartements = form.querySelector('input[name="nb_appartements"]');
      allAnswered = allAnswered && nbAppartements && nbAppartements.value.trim() !== '';
      allAnswered = allAnswered && testData.composition_immeuble !== undefined;
    }

    if (testData.activite_professionnelle === 'oui') {
      allAnswered = allAnswered && testData.pourcentage_activite !== undefined;
    }

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesLocataire() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Locataire");

    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxellesLocataire") || "{}");

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles en tant que locataire !";
    let recommendations = [];

    // Vérifier les avantages
    if (testData.bim === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le statut BIM");
    }
    if (testData.ris === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le RIS");
    }
    if (testData.client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
    }

    recommendations.push("📝 En tant que locataire, l'accord écrit du propriétaire est obligatoire");
    recommendations.push("🏠 Certains travaux spécifiques sont accessibles aux locataires");

    message += "<br><br><strong>Profil :</strong> <span class='badge bg-success'>Locataire</span>";

    localStorage.setItem("bruxelles_categorie", "locataire");
    this.showResultBruxellesLocataire(message, true, recommendations);
  }

  showResultBruxellesLocataire(message, isEligible = true, recommendations = []) {
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }

  // EMPHYTEOTE
  handleAnswerBruxellesEmphyteote(event) {
    console.log("🎯 Test Eligibilité Bruxelles Emphythéote - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesEmphyteote", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlertsEmphyteote(event.target.name, event.target.value);

    // Vérifications d'inéligibilité
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel agréé", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ne sont pas éligibles", false);
      return;
    }

    const compte_bancaire_belge = testData["compte_bancaire_belge"];
    if (compte_bancaire_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec facture dans les 12 mois", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesEmphyteote();
  }

  handleConditionalAlertsEmphyteote(questionName, value) {
    const alertsMap = {
      'primes_anterieures': { condition: value === 'oui', elementId: 'primes_anterieures_info' },
      'bim': { condition: value === 'oui', elementId: 'bim_info' },
      'ris': { condition: value === 'oui', elementId: 'ris_info' },
      'client_protege': { condition: value === 'oui', elementId: 'client_protege_info' },
      'permis_urbanisme': { condition: value === 'non', elementId: 'permis_urbanisme_info' }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element && questionName === key) {
        element.style.display = config.condition ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    if (questionName === 'type_propriete') {
      const immeubleDetails = document.getElementById('immeuble_details');
      if (immeubleDetails) {
        immeubleDetails.style.display = value === 'immeuble_complet' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesEmphyteote() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    let allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    // Vérifications conditionnelles
    if (testData.type_propriete === 'immeuble_complet') {
      const nbAppartements = form.querySelector('input[name="nb_appartements"]');
      allAnswered = allAnswered && nbAppartements && nbAppartements.value.trim() !== '';
      allAnswered = allAnswered && testData.composition_immeuble !== undefined;
    }

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesEmphyteote() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Emphythéote");

    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxellesEmphyteote") || "{}");

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles en tant qu'emphythéote !";
    let recommendations = [];

    // Vérifier les avantages
    if (testData.bim === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le statut BIM");
    }
    if (testData.ris === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le RIS");
    }
    if (testData.client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
    }

    if (testData.type_propriete === 'immeuble_complet') {
      recommendations.push("🏢 Propriétaire d'immeuble complet via bail emphytéotique");
    }

    recommendations.push("📜 En tant qu'emphythéote, vous avez les mêmes droits qu'un propriétaire pour les primes");

    message += "<br><br><strong>Profil :</strong> <span class='badge bg-warning'>Emphythéote</span>";

    localStorage.setItem("bruxelles_categorie", "emphyteote");
    this.showResultBruxellesEmphyteote(message, true, recommendations);
  }

  showResultBruxellesEmphyteote(message, isEligible = true, recommendations = []) {
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }

  // COPROPRIETAIRE
  handleAnswerBruxellesCoproprietaire(event) {
    console.log("🎯 Test Eligibilité Bruxelles Copropriétaire - Réponse:", event.target.name, "=", event.target.value);

    const form = this.formTarget;
    const responses = [...form.querySelectorAll("input[type=radio]:checked")];
    const inputValues = [...form.querySelectorAll("input[type=number]")];

    const testData = responses.reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    // Ajouter les valeurs numériques
    inputValues.forEach(input => {
      if (input.value) {
        testData[input.name] = input.value;
      }
    });

    localStorage.setItem("eligibiliteBruxellesCoproprietaire", JSON.stringify(testData));

    // Gestion des alertes conditionnelles
    this.handleConditionalAlertsCoproprietaire(event.target.name, event.target.value);

    // Vérifications d'inéligibilité
    const localisation = testData["localisation"];
    if (localisation === "non") {
      this.showResult("❌ Le bien doit être situé en Région de Bruxelles-Capitale", false);
      return;
    }

    const age_batiment = testData["age_batiment"];
    if (age_batiment === "non") {
      this.showResult("❌ Le bâtiment doit être âgé d'au moins 10 ans", false);
      return;
    }

    const professionnel_agree = testData["professionnel_agree"];
    if (professionnel_agree === "non") {
      this.showResult("❌ Les travaux doivent être réalisés par un professionnel agréé", false);
      return;
    }

    const nouvelle_construction = testData["nouvelle_construction"];
    if (nouvelle_construction === "oui") {
      this.showResult("❌ Les nouvelles constructions ne sont pas éligibles", false);
      return;
    }

    const compte_bancaire_belge = testData["compte_bancaire_belge"];
    if (compte_bancaire_belge === "non") {
      this.showResult("❌ Un compte bancaire belge est requis", false);
      return;
    }

    const travaux_realises = testData["travaux_realises"];
    if (travaux_realises === "non") {
      this.showResult("❌ Les travaux doivent être réalisés avec facture dans les 12 mois", false);
      return;
    }

    this.checkIfAllAnsweredBruxellesCoproprietaire();
  }

  handleConditionalAlertsCoproprietaire(questionName, value) {
    const alertsMap = {
      'primes_anterieures': { condition: value === 'oui', elementId: 'primes_anterieures_info' },
      'bim': { condition: value === 'oui', elementId: 'bim_info' },
      'ris': { condition: value === 'oui', elementId: 'ris_info' },
      'client_protege': { condition: value === 'oui', elementId: 'client_protege_info' },
      'permis_urbanisme': { condition: value === 'non', elementId: 'permis_urbanisme_info' }
    };

    Object.entries(alertsMap).forEach(([key, config]) => {
      const element = document.getElementById(config.elementId);
      if (element && questionName === key) {
        element.style.display = config.condition ? 'block' : 'none';
      }
    });

    // Gestion des sections conditionnelles
    if (questionName === 'type_propriete') {
      const immeubleDetails = document.getElementById('immeuble_details');
      if (immeubleDetails) {
        immeubleDetails.style.display = value === 'immeuble_complet' ? 'block' : 'none';
      }
    }
  }

  checkIfAllAnsweredBruxellesCoproprietaire() {
    const form = this.formTarget;
    const radioInputs = Array.from(form.querySelectorAll("input[type='radio']"));
    const questionNames = [...new Set(radioInputs.map(input => input.name))].filter(name => name !== "profile_type");

    const testData = [...form.querySelectorAll("input[type=radio]:checked")].reduce((acc, response) => {
      acc[response.name] = response.value;
      return acc;
    }, {});

    let allAnswered = questionNames.every(name => {
      return form.querySelector(`input[name="${name}"]:checked`) !== null;
    });

    // Vérifications conditionnelles
    if (testData.type_propriete === 'immeuble_complet') {
      const nbAppartements = form.querySelector('input[name="nb_appartements"]');
      allAnswered = allAnswered && nbAppartements && nbAppartements.value.trim() !== '';
      allAnswered = allAnswered && testData.composition_immeuble !== undefined;
    }

    if (allAnswered && this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "block";
    } else if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none";
    }
  }

  validateTestBruxellesCoproprietaire() {
    console.log("🎯 Validation du test d'éligibilité Bruxelles Copropriétaire");

    const testData = JSON.parse(localStorage.getItem("eligibiliteBruxellesCoproprietaire") || "{}");

    let message = "✅ Vous êtes éligible aux primes RENOLUTION Bruxelles en tant que copropriétaire !";
    let recommendations = [];

    // Vérifier les avantages
    if (testData.bim === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le statut BIM");
    }
    if (testData.ris === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées avec le RIS");
    }
    if (testData.client_protege === "oui") {
      recommendations.push("✨ Vous bénéficiez de primes majorées en tant que client protégé");
    }

    if (testData.type_propriete === 'immeuble_complet') {
      recommendations.push("🏢 Propriétaire d'immeuble complet - primes spécifiques applicables");
    }

    recommendations.push("👥 En tant que copropriétaire, vous pouvez demander les primes pour votre quote-part");
    recommendations.push("🏛️ Pour les parties communes, la demande doit être collective via l'ACP");

    message += "<br><br><strong>Profil :</strong> <span class='badge bg-info'>Copropriétaire</span>";

    localStorage.setItem("bruxelles_categorie", "coproprietaire");
    this.showResultBruxellesCoproprietaire(message, true, recommendations);
  }

  showResultBruxellesCoproprietaire(message, isEligible = true, recommendations = []) {
    this.showFinalResultBruxelles(message, isEligible, recommendations, true);
  }
}
