# =====================================================
# PRIME E : Toiture
# =====================================================

puts "🏠 Création des primes E - Toiture..."

Prime.find_or_initialize_by(slug: "bruxelles_structure_toiture").update!(
  titre: "E1 - Structure de la toiture - Bruxelles",
  ordre_affichage: 14,
  icon_name: "layers",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "30% des coûts éligibles HTVA - Cat. I (défaut)"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 40,
      "condition": "40% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime E1 = 30%-40%-50% coûts éligibles HTVA selon catégorie revenus. Travaux structure portante toiture : charpente, chevronnage, gîtage, lattage, voligeage, panneautage, renforcement pour toiture verte/stockante. Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : maisons/appartements 50.000€, bâtiments non-résidentiels/parties communes 200.000€. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Structure toiture) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, description précise travaux, prix HTVA/TVA) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution E1 - Structure portante toiture et renforcement pour toitures vertes",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 40%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 50%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/structure_toiture.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_couverture_etancheite").update!(
  titre: "E2 - Couverture et étanchéité - Bruxelles",
  ordre_affichage: 15,
  icon_name: "droplet-off",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 60,
      "condition": "60€/m² toiture - Cat. I (défaut) + Bonus matériau durable 20€/m² si bardeaux bois/tuiles céramiques/ardoises naturelles/EPDM"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 70,
      "condition": "70€/m² toiture - Cat. II (revenus moyens) + Bonus matériau durable 20€/m² si bardeaux bois/tuiles céramiques/ardoises naturelles/EPDM"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 80,
      "condition": "80€/m² toiture - Cat. III (faibles revenus) + Bonus matériau durable 20€/m² si bardeaux bois/tuiles céramiques/ardoises naturelles/EPDM"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Bâtiments résidentiels uniquement, construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. CONDITION OBLIGATOIRE : Prime Isolation thermique toiture doit être introduite simultanément et accordée. Surface couverture/étanchéité ≤ surface isolation accordée (remontées toiture plate max 10% surface isolée). Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime E2 = 60€-70€-80€/m² selon catégorie revenus + Bonus matériau durable 20€/m² (bardeaux bois, tuiles céramiques, ardoises naturelles pour toitures pentes, EPDM pour toitures plates). Travaux placement/remplacement étanchéité toitures plates/inclinées et couverture (sous-toiture, tuiles rives/faitières, arêtiers terre cuite, solins, démontage ancienne couverture). OBLIGATOIRE : cumul avec prime Isolation thermique toiture. Surfaces renseignées sur attestation isolation. Minimum 250€/adresse. Maximum 90% montant facturé.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Couverture/étanchéité/isolation thermique toiture) + factures détaillées libellées au nom du demandeur (adresse chantier, dates facturation/livraison/prestation, numéro facture, description précise type matériau couverture/étanchéité et surface, prix unitaire HTVA, escomptes/rabais, taux TVA, montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  specifique: "Bruxelles - Renolution E2 - Étanchéité et couverture avec bonus matériaux durables - Obligatoirement couplée à isolation thermique",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface toiture m² (60€ + bonus 20€ si matériau durable)",
    "bruxelles_cat2": "Surface toiture m² (70€ + bonus 20€ si matériau durable)",
    "bruxelles_cat3": "Surface toiture m² (80€ + bonus 20€ si matériau durable)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/couverture_etancheite.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_toiture").update!(
  titre: "E3 - Isolation thermique de la toiture - Bruxelles",
  ordre_affichage: 16,
  icon_name: "thermometer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 35,
      "condition": "35€/m² surface isolée - Cat. I (défaut) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 55,
      "condition": "55€/m² surface isolée - Cat. II (revenus moyens) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 75,
      "condition": "75€/m² surface isolée - Cat. III (faibles revenus) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Tous bâtiments (résidentiels et non-résidentiels), construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Coefficient résistance thermique R ≥ 4,00 m²K/W sur entièreté surface isolée. Film pare-vapeur/freine-vapeur obligatoire côté intérieur. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime E3 = 35€-55€-75€/m² selon catégorie revenus + Bonus matériau naturel 10€/m² (isolants ≥85% renouvelables : cellulose, liège, fibres végétales/animales). Travaux placement isolation toitures plates/inclinées et sol grenier non aménageable si toiture non isolée. R = e/λ ≥ 4,00. Si multicouches adjacentes : R total = somme R individuels. Bonus Z10 : +10%/+20% si ≥3 primes E3/F1/G1/G2/H1/J4/M1/M2 simultanées. Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : 50.000€ (maisons/appartements), 200.000€ (non-résidentiels/parties communes).",
  document: "Attestation entrepreneur (Informations générales + Volet technique Couverture/étanchéité/isolation thermique toiture) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type/marque/modèle isolant, surface isolée, épaisseur isolant, valeur R m²K/W, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  specifique: "Bruxelles - Renolution E3 - Isolation toiture avec bonus matériaux naturels et bonus travaux multiples Z10",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface isolée m² (35€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat2": "Surface isolée m² (55€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat3": "Surface isolée m² (75€ + bonus 10€ si matériau naturel)"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_thermique_toiture_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_accessoires_toiture").update!(
  titre: "E4 - Accessoires de toiture - Bruxelles",
  ordre_affichage: 17,
  icon_name: "wind",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "30% des coûts éligibles HTVA - Cat. I (défaut)"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 40,
      "condition": "40% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime E4 = 30%-40%-50% coûts éligibles HTVA selon catégorie revenus. Travaux aménagement accessoires toitures inclinées/plates : corniches, descentes eau, avaloirs, structure/étanchéité lucarnes (chien-assis max 3m²), fenêtres toiture, tourelles, gouttières, planches rives/couvre-murs, démolition/reconstruction souches cheminée extérieures (hors cimentage). Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : maisons/appartements 50.000€, bâtiments non-résidentiels/parties communes 200.000€. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Accessoires toiture) + factures détaillées libellées au nom du demandeur (adresse chantier, dates facturation/livraison/prestation, numéro facture, nom entrepreneur/société, numéro TVA/entreprise, description précise quantité/nature fournitures/services, prix unitaire HTVA, escomptes/rabais, taux TVA, montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution E4 - Aménagement accessoires toitures inclinées et plates",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 40%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 50%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/accessoires_toiture.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_toiture_vegetale").update!(
  titre: "E5 - Toiture végétalisée ou stockante en eau - Bruxelles",
  ordre_affichage: 18,
  icon_name: "tree",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2_variable",
      "montants": {
        "stockante": 5,
        "extensive": 10,
        "semi_intensive": 20,
        "intensive": 30
      },
      "condition": "Cat. I (défaut) : Stockante 5€/m², Extensive 10€/m², Semi-intensive 20€/m², Intensive 30€/m²"
    },
    "bruxelles_cat2": {
      "type": "montant_m2_variable",
      "montants": {
        "stockante": 10,
        "extensive": 15,
        "semi_intensive": 30,
        "intensive": 40
      },
      "condition": "Cat. II (revenus moyens) : Stockante 10€/m², Extensive 15€/m², Semi-intensive 30€/m², Intensive 40€/m²"
    },
    "bruxelles_cat3": {
      "type": "montant_m2_variable",
      "montants": {
        "stockante": 15,
        "extensive": 20,
        "semi_intensive": 40,
        "intensive": 50
      },
      "condition": "Cat. III (faibles revenus) : Stockante 15€/m², Extensive 20€/m², Semi-intensive 40€/m², Intensive 50€/m²"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Bâtiments résidentiels uniquement, construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. OBLIGATOIRE : toiture isolée avec R ≥ 4,00 m²K/W. Pente minimale 2%. Conditions techniques selon type : Extensive (substrat 5-10cm), Semi-intensive (substrat 10-25cm), Intensive (substrat ≥25cm), Stockante (gravier ≥5cm + régulateur débit + trop-plein). Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime E5 = montants variables selon type toiture. Stockante : 5€-10€-15€/m² (lutte ruissellement, couche gravier avec régulation). Végétalisée Extensive : 10€-15€-20€/m² (biodiversité, substrat 5-10cm). Semi-intensive : 20€-30€-40€/m² (substrat 10-25cm). Intensive : 30€-40€-50€/m² (véritable jardin, substrat ≥25cm). Avantages : inertie thermique, protection UV étanchéité, filtration eau, biodiversité. OBLIGATOIRE : isolation R≥4,00. Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : 50.000€ (résidentiel), 200.000€ (parties communes).",
  document: "Attestation entrepreneur (Informations générales + Volet technique Toiture végétalisée/stockante) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, technique utilisée, surface toiture, type matériau différentes couches, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution E5 - Toitures écologiques avec montants différenciés par type et performance environnementale",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface m² (préciser type : stockante 5€, extensive 10€, semi-intensive 20€, intensive 30€)",
    "bruxelles_cat2": "Surface m² (préciser type : stockante 10€, extensive 15€, semi-intensive 30€, intensive 40€)",
    "bruxelles_cat3": "Surface m² (préciser type : stockante 15€, extensive 20€, semi-intensive 40€, intensive 50€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/toiture_vegetale_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes E (Toiture) créées avec succès"
