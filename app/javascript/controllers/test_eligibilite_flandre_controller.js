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

    // Mode wizard : afficher une question à la fois
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

    // Mode wizard : avancer à la question suivante après 350ms
    if (this.wizardMode) {
      setTimeout(() => {
        const total = this.formCardTargets.length
        if (this.currentQuestionIndex < total - 1) {
          this.currentQuestionIndex++
          this.showCurrentQuestion()
        } else {
          // Dernière question répondue → valider automatiquement
          this.validateTest()
        }
      }, 350)
      return
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
    if (domicile === "non") {
      message += " (Pas de domicile principal → Catégorie 1)";
      categorie = 1;
    }

    // PEB
    if (peb === "oui") {
      if (domicile === "oui") {
        message += " (Accès à la carte PEB)";
      } else {
        message += " (Catégorie 1 + carte PEB)";
        categorie = 1;
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

    // Notifier le wizard de la progression
    document.dispatchEvent(new CustomEvent("flandre:eligibility:done", {
      detail: { eligible: true, categorie }
    }))

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
    const cat = categorie.toString()
    const cat12Only = ['warmtepomp', 'warmtepompboiler']
    const isCat12 = ['1', '2'].includes(cat)

    // Trouver toutes les cartes de primes
    const allPrimeCards = document.querySelectorAll('[data-controller*="prime-card"]');

    allPrimeCards.forEach(card => {
      const slug = card.dataset.slug;
      const prime = window.primes?.find(p => p.slug === slug);

      if (prime) {
        const isEligible = prime.eligible_categories?.includes(cat);
        // Pour cat 1/2 : uniquement pompe à chaleur et chauffe-eau thermodynamique
        const isAllowed = isCat12 ? cat12Only.includes(slug) : true;

        if (isEligible && isAllowed) {
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
}
