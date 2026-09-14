import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result", "formCard", "validateButton", "questionCounter", "progressBar"]

  connect() {
    if (this.hasResultTarget) {
      this.resultTarget.style.display = "none"
    }
    if (this.hasValidateButtonTarget) {
      this.validateButtonTarget.style.display = "none"
    }

    // Mode wizard : une question à la fois
    this.wizardMode = this.element.dataset.wizardMode === "true"
    if (this.wizardMode && this.hasFormCardTarget) {
      this.currentQuestionIndex = 0
      this.showCurrentQuestion()
    }
  }

  // Navigation question précédente
  prevQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--
      this.showCurrentQuestion()
    }
  }

  showCurrentQuestion() {
    const cards = this.formCardTargets
    cards.forEach((card, i) => {
      if (i === this.currentQuestionIndex) {
        card.classList.remove("d-none", "question-answered")
        card.classList.add("question-active")
      } else if (i < this.currentQuestionIndex) {
        card.classList.remove("d-none", "question-active")
        card.classList.add("question-answered")
      } else {
        card.classList.add("d-none")
        card.classList.remove("question-active", "question-answered")
      }
    })
    this.updateQuestionCounter()
  }

  updateQuestionCounter() {
    const total = this.formCardTargets.length
    const current = this.currentQuestionIndex + 1
    if (this.hasQuestionCounterTarget) {
      this.questionCounterTarget.textContent = `Question ${current} / ${total}`
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${Math.round((this.currentQuestionIndex / total) * 100)}%`
    }
  }

  // Avancer à la question suivante (wizard mode)
  advanceWizard(validateMethod) {
    setTimeout(() => {
      const total = this.formCardTargets.length
      if (this.currentQuestionIndex < total - 1) {
        this.currentQuestionIndex++
        this.showCurrentQuestion()
      } else {
        validateMethod.call(this)
      }
    }, 350)
  }

  // ========== MÉTHODES WALLONIE ==========

  // WALLONIE PARTICULIER
  handleAnswerWallonieParticulier(event) {

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

    // Mode wizard : avancer à la question suivante
    if (this.wizardMode) {
      this.advanceWizard(this.validateTestWallonieParticulier)
      return
    }

    // Mode classique : vérifier si toutes les questions sont répondues
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
          "💳 Renseignez-vous sur les prêts à taux avantageux pour la rénovation"
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
      recommendations.push("🏠 Travaux de toiture uniquement éligibles avec vos revenus");
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
    // Aussi stocker pour le calculateur avec une catégorie par défaut R2
    localStorage.setItem('selectedWallonieCategory', 'wallonie_r2');

    this.showResultWallonieParticulier(message, true, recommendations);
  }

  showResultWallonieParticulier(message, isEligible = true, recommendations = []) {
    // Pour les particuliers, utiliser la méthode finale avec affinage activé
    this.showFinalResultWallonie(message, isEligible, recommendations, true);
  }

  // WALLONIE ENTREPRISE
  handleAnswerWallonieEntreprise(event) {

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

    let message = "✅ Votre entreprise est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-primary'>Entreprise</span>";

    let recommendations = [
      "🏢 En tant qu'entreprise, vous avez accès aux primes spécifiques aux professionnels",
      "📋 Inscription BCE obligatoire pour l'entreprise et l'entrepreneur",
      "💼 Primes calculées selon la grille tarifaire entreprise"
    ];

    localStorage.setItem("wallonie_categorie", "entreprise");
    // Pas de selectedWallonieCategory pour les entreprises
    this.showResultWallonieEntreprise(message, true, recommendations);
  }

  showResultWallonieEntreprise(message, isEligible = true, recommendations = []) {
    // Pour les entreprises, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE SYNDIC
  handleAnswerWallonieSyndic(event) {

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

    // Mode wizard : avancer à la question suivante
    if (this.wizardMode) {
      this.advanceWizard(this.validateTestWallonieSyndic)
      return
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

    let message = "✅ Votre copropriété est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-danger'>R5 - Syndic/Copropriété</span>";

    let recommendations = [
      "🏢 En tant que syndic, vous gérez les demandes pour la copropriété",
      "👥 La demande doit être faite au nom de la copropriété",
      "📋 Minimum 2 unités requises, immeuble à dominante résidentielle",
      "💰 Catégorie R5 appliquée automatiquement pour les syndics"
    ];

    // Définir explicitement la catégorie R5 pour les syndics
    localStorage.setItem("wallonie_categorie", "R5");
    localStorage.setItem("wallonie_profile_type", "syndic");
    // Aussi stocker pour le calculateur
    localStorage.setItem('selectedWallonieCategory', 'wallonie_r5');
    this.showResultWallonieSyndic(message, true, recommendations);
  }

  showResultWallonieSyndic(message, isEligible = true, recommendations = []) {
    // Pour les syndics, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE ASBL
  handleAnswerWallonieAsbl(event) {

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

    let message = "✅ Votre ASBL est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-info'>ASBL</span>";

    let recommendations = [
      "🏛️ En tant qu'ASBL, vous avez accès aux primes spécifiques aux associations",
      "📋 Activités d'intérêt général requises",
      "⚖️ Pas d'usage par des collectivités publiques autorisé"
    ];

    localStorage.setItem("wallonie_categorie", "asbl");
    // Pas de selectedWallonieCategory pour les ASBL
    this.showResultWallonieAsbl(message, true, recommendations);
  }

  showResultWallonieAsbl(message, isEligible = true, recommendations = []) {
    // Pour les ASBL, pas d'affinage - résultat direct
    this.showFinalResultWallonie(message, isEligible, recommendations, false);
  }

  // WALLONIE BAILLEUR
  handleAnswerWallonieBailleur(event) {

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

    // Mode wizard : avancer à la question suivante
    if (this.wizardMode) {
      this.advanceWizard(this.validateTestWallonieBailleur)
      return
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

    let message = "✅ Votre organisme de logement social est éligible aux primes Wallonie !";
    message += "<br><br><strong>Catégorie :</strong> <span class='badge bg-info'>Bailleur Social</span>";

    let recommendations = [
      "🏠 En tant que bailleur social reconnu, vous avez accès aux primes spécifiques",
      "🏛️ Statut de bailleur social reconnu par la Région wallonne requis",
      "👥 Travaux destinés au logement social uniquement"
    ];

    localStorage.setItem("wallonie_categorie", "bailleur");
    // Pas de selectedWallonieCategory pour les bailleurs
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
        // Pour les particuliers, l'avancement du wizard se fait après l'affinage (wallonie:category:refined)
      } else if (isEligible) {
        // Non-particuliers : avancer directement vers les primes
        document.dispatchEvent(new CustomEvent("wallonie:eligibility:done", { detail: { eligible: true } }))
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

  // Méthode basique pour la compatibilité
  showResult(message, isEligible = true) {
    this.showFinalResultWallonie(message, isEligible, [], false);
  }
}
