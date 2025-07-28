import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    // Services et études
    "auditMaison", "auditBatiment", "auditLogement", "accompagnement", "conseiller",

    // Isolation et menuiseries
    "isolationToiture", "isolationMurs", "isolationSol", "fenetres", "portes",

    // Chauffage et ventilation
    "chaudiere", "pompeAChaleur", "ventilation", "solairethermique",

    // Électricité et divers
    "electrique", "photovoltaique", "autres",

    // Résultat
    "total", "surface"
  ]

  connect() {
    console.log("🎯 Contrôleur Bruxelles Prime Card connecté");

    this.currentCategory = "Z1"; // Catégorie par défaut

    // Écouter les changements de catégorie
    document.addEventListener('bruxelles:category:changed', this.updateCategory.bind(this));

    // Calculer le montant initial
    this.calculate();
  }

  disconnect() {
    document.removeEventListener('bruxelles:category:changed', this.updateCategory.bind(this));
  }

  updateCategory(event) {
    this.currentCategory = event.detail?.categorie || "Z1";
    console.log("🔄 Carte Prime Bruxelles - Nouvelle catégorie:", this.currentCategory);
    this.calculate();
  }

  calculate() {
    let total = 0;

    // Récupérer les valeurs des différents éléments
    const values = {
      // Services et études (forfaitaires)
      auditMaison: this.getTargetValue("auditMaison"),
      auditBatiment: this.getTargetValue("auditBatiment"),
      auditLogement: this.getTargetValue("auditLogement"),
      accompagnement: this.getTargetValue("accompagnement"),
      conseiller: this.getTargetValue("conseiller"),

      // Isolation (m²)
      isolationToiture: this.getTargetValue("isolationToiture"),
      isolationMurs: this.getTargetValue("isolationMurs"),
      isolationSol: this.getTargetValue("isolationSol"),

      // Menuiseries (m²)
      fenetres: this.getTargetValue("fenetres"),
      portes: this.getTargetValue("portes"),

      // Chauffage (forfaitaires ou unités)
      chaudiere: this.getTargetValue("chaudiere"),
      pompeAChaleur: this.getTargetValue("pompeAChaleur"),
      ventilation: this.getTargetValue("ventilation"),
      solairethermique: this.getTargetValue("solairethermique"),

      // Électricité
      electrique: this.getTargetValue("electrique"),
      photovoltaique: this.getTargetValue("photovoltaique"),

      // Autres
      autres: this.getTargetValue("autres")
    };

    // Calculer selon la catégorie de revenus Bruxelles (Z1 à Z10)
    total += this.calculateServicesEtudes(values);
    total += this.calculateIsolation(values);
    total += this.calculateMenuiseries(values);
    total += this.calculateChauffage(values);
    total += this.calculateElectricite(values);
    total += this.calculateAutres(values);

    // Afficher le résultat
    this.updateTotal(total);
  }

  calculateServicesEtudes(values) {
    let total = 0;

    // Barème simplifié pour Bruxelles - ajuster selon documentation officielle
    const multiplier = this.getCategoryMultiplier();

    if (values.auditMaison > 0) total += 650 * multiplier;
    if (values.auditBatiment > 0) total += 1200 * multiplier;
    if (values.auditLogement > 0) total += 450 * multiplier;
    if (values.accompagnement > 0) total += 500 * multiplier;
    if (values.conseiller > 0) total += 300 * multiplier;

    return total;
  }

  calculateIsolation(values) {
    let total = 0;
    const multiplier = this.getCategoryMultiplier();

    // Montants approximatifs - ajuster selon barème officiel
    total += values.isolationToiture * 25 * multiplier;
    total += values.isolationMurs * 30 * multiplier;
    total += values.isolationSol * 20 * multiplier;

    return total;
  }

  calculateMenuiseries(values) {
    let total = 0;
    const multiplier = this.getCategoryMultiplier();

    total += values.fenetres * 85 * multiplier;
    total += values.portes * 120 * multiplier;

    return total;
  }

  calculateChauffage(values) {
    let total = 0;
    const multiplier = this.getCategoryMultiplier();

    if (values.chaudiere > 0) total += 1500 * multiplier;
    if (values.pompeAChaleur > 0) total += 4500 * multiplier;
    if (values.ventilation > 0) total += 3500 * multiplier;
    if (values.solairethermique > 0) total += 2500 * multiplier;

    return total;
  }

  calculateElectricite(values) {
    let total = 0;
    const multiplier = this.getCategoryMultiplier();

    total += values.electrique * 50 * multiplier; // par point
    total += values.photovoltaique * 300 * multiplier; // par kWc

    return total;
  }

  calculateAutres(values) {
    // Pour les autres primes spécifiques
    return values.autres * this.getCategoryMultiplier();
  }

  getCategoryMultiplier() {
    // Facteur multiplicateur selon la catégorie de revenus
    // À ajuster selon le barème officiel Bruxelles
    const multipliers = {
      "Z1": 1.0,  // Revenus très faibles
      "Z2": 0.9,
      "Z3": 0.8,
      "Z4": 0.7,
      "Z5": 0.6,
      "Z6": 0.5,
      "Z7": 0.4,
      "Z8": 0.3,
      "Z9": 0.2,
      "Z10": 0.1, // Revenus élevés
      "I-III": 0.8 // Valeur par défaut pour les catégories I à III
    };

    return multipliers[this.currentCategory] || 0.8;
  }

  getTargetValue(targetName) {
    if (this.hasTarget(targetName)) {
      const target = this.targets.find(targetName);
      if (target) {
        const value = parseFloat(target.value) || 0;
        return Math.max(0, value); // Assurer une valeur positive
      }
    }
    return 0;
  }

  updateTotal(total) {
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `${Math.round(total).toLocaleString('fr-BE')} €`;

      // Ajouter une classe pour l'animation
      this.totalTarget.classList.add('updated');
      setTimeout(() => {
        this.totalTarget.classList.remove('updated');
      }, 300);
    }
  }
}
