# Primes RENOLUTION pour la région de Bruxelles-Capitale (2024)
# Système à 3 catégories avec montants dégressifs selon les revenus

puts "🏢 Création des primes Bruxelles RENOLUTION..."

# Mode sécurisé : ne supprime que si pas en production ou si explicitement demandé
if Rails.env.development? || ENV['FORCE_PRIME_RESET'] == 'true'
  puts "🗑️  Nettoyage des primes Bruxelles existantes (#{Rails.env})..."
  Prime.where(region: "bruxelles").delete_all
else
  puts "🔒 Mode production : conservation des primes existantes"
end

# =====================================================
# PRIME A : Services et études préalables
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_maison").update!(
  titre: "A1 - Audit énergétique (maison unifamiliale) - Bruxelles",
  ordre_affichage: 1,
  icon_name: "clipboard-data",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"}
  }'),
  condition: "Audit énergétique pour maison unifamiliale. Bâtiment construit au moins 10 ans avant la demande. Réalisé par auditeur agréé Bruxelles Environnement ou ingénieur/architecte avec expertise reconnue, indépendant des entreprises de travaux. Basé sur consommations réelles des 3 dernières années. Respect du cahier des charges minimal.",
  conseil: "État des lieux pour détecter points faibles et forts du bâtiment. Aide à prioriser les travaux d'amélioration et découvrir le gain réel. Montant fixe 400€ pour maison unifamiliale, sans conditions de revenus. Cumulable avec toutes les Primes RENOLUTION et autres aides (dans limite de 100% des travaux).",
  document: "Attestation entrepreneur (informations générales) + copie audit énergétique conforme au cahier des charges + factures détaillées au nom du demandeur (adresse chantier, description précise, prix unitaire HT, TVA, date) + preuves paiement (extraits bancaires si ≥3000€, ou facture acquittée si <3000€)",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - RENOLUTION A1 - Services et études préalables",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/audit_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_batiment").update!(
  titre: "A1 - Audit énergétique (bâtiment complet) - Bruxelles",
  ordre_affichage: 2,
  icon_name: "building-check",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"}
  }'),
  condition: "Audit énergétique pour bâtiment dans son entièreté (immeuble à appartements ou bâtiment non résidentiel). Bâtiment construit au moins 10 ans avant la demande. Réalisé par auditeur agréé Bruxelles Environnement ou ingénieur/architecte avec expertise reconnue, indépendant des entreprises de travaux. Basé sur consommations réelles des 3 dernières années. Respect du cahier des charges minimal.",
  conseil: "État des lieux complet pour immeubles collectifs et bâtiments non résidentiels. Montant fixe 3000€ par bâtiment, sans conditions de revenus. Postes éligibles: prestations chargé d'études, mesures consommations énergétiques. Prime couvre max 90% du montant facturé. Cumulable avec autres Primes RENOLUTION et aides (limite 100% travaux).",
  document: "Attestation entrepreneur (informations générales) + copie audit énergétique conforme au cahier des charges + factures détaillées au nom du demandeur (adresse chantier, description précise, prix unitaire HT, TVA, date) + preuves paiement (extraits bancaires si ≥3000€, ou facture acquittée si <3000€)",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - RENOLUTION A1 - Services et études préalables",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/audit_batiment_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_acoustique").update!(
  titre: "A2 - Étude acoustique - Bruxelles",
  ordre_affichage: 3,
  icon_name: "volume-2",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 2, "montant_max": 500, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 2, "montant_max": 1000, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 2, "montant_max": 1500, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"}
  }'),
  condition: "Propriétaires occupants ou non-occupants de logements collectifs en copropriété ou AIS selon AGW. Obligatoire en complément des travaux d'isolation F6-H2. Bureau d'études agréé par Bruxelles Environnement avec section Acoustique. Avant travaux impactant l'acoustique du bâtiment.",
  conseil: "Prime A2 = 2% du montant le plus élevé entre primes F6-H2 octroyées ou coût travaux isolation acoustique. Délai traitement 90 jours max. Demande via formulaire en ligne ou courrier. Documents : rapport d'étude acoustique détaillé + facture bureau agréé + justificatifs propriété/copropriété/AIS.",
  document: "Rapport d'étude acoustique complet par bureau agréé Bruxelles Environnement (section Acoustique) + facture détaillée + justificatifs statut propriétaire/copropriété/AIS + preuve réalisation/projet travaux F6-H2",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A2 - Études acoustiques obligatoires pour travaux d'isolation en logements collectifs",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant primes F6-H2 ou coût travaux isolation acoustique",
    "bruxelles_cat2": "Montant primes F6-H2 ou coût travaux isolation acoustique",
    "bruxelles_cat3": "Montant primes F6-H2 ou coût travaux isolation acoustique"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/etude_acoustique_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_totem").update!(
  titre: "A3 - Étude matériaux de construction (TOTEM) - Bruxelles",
  ordre_affichage: 4,
  icon_name: "activity",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"}
  }'),
  condition: "Tous publics (particuliers et professionnels). Bâtiments résidentiels construits au moins 10 ans avant demande. Étude TOTEM réalisée par architecte ou expert chargé de l\'étude. Mission indépendante de la conception habituelle. Respect du cahier des charges minimal TOTEM. Facture adressée au demandeur.",
  conseil: "TOTEM évalue l\'impact environnemental du bâtiment sur son cycle de vie. Prime fixe 200€ par unité de logement, sans condition de revenus. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture de solde). Cumulable avec toutes autres primes RENOLUTION.",
  document: "Rapport d\'étude TOTEM conforme au cahier des charges minimal + factures détaillées libellées au nom du demandeur + preuves de paiement + attestation entrepreneur. Documents complémentaires si cumul avec autres primes RENOLUTION (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A3 - Évaluation impact environnemental matériaux via outil TOTEM belge",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre d\'unités de logement concernées",
    "bruxelles_cat2": "Nombre d\'unités de logement concernées",
    "bruxelles_cat3": "Nombre d\'unités de logement concernées"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/etude_totem.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# Suivi professionnel - 3 types distincts

Prime.find_or_initialize_by(slug: "bruxelles_suivi_architecte").update!(
  titre: "A4 - Suivi architecte - Bruxelles",
  ordre_affichage: 5,
  icon_name: "briefcase",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Mission d\'architecte inscrit à l\'Ordre via convention écrite précisant travaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 8% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec architecte + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel des travaux de rénovation par architecte",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_architecte.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_suivi_ingenieur_stabilite").update!(
  titre: "A4 - Suivi ingénieur stabilité - Bruxelles",
  ordre_affichage: 6,
  icon_name: "calculator",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Mission d\'ingénieur stabilité via convention écrite précisant travaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 2% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec ingénieur + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel des travaux de stabilité par ingénieur",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_ingenieur.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_suivi_expert_facade").update!(
  titre: "A4 - Suivi expert façade - Bruxelles",
  ordre_affichage: 7,
  icon_name: "home-building",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Étude façade par expert pour nettoyage/entretien définissant techniques adaptées sans dégradation matériaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 2% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec expert façade + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel étude façade nettoyage/entretien",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_certificat_peb").update!(
  titre: "A5 - Certificat PEB - Bruxelles",
  ordre_affichage: 8,
  icon_name: "certificate",
  unite: "€",
  type_de_valeur: "montant_fixe",
  eligible_categories: ["bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 150,
      "condition": "150€ par unité de logement - Uniquement catégorie III (ménages à faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants uniquement, catégorie III (ménages à faibles revenus). Unités de logement (maisons unifamiliales ou appartements) construites au moins 10 ans avant demande. Certificat PEB par certificateur PEB résidentiel agréé. Cumul obligatoire avec autre prime RENOLUTION pour atteindre minimum 250€.",
  conseil: "Prime A5 = 150€ par unité de logement pour ménages catégorie III uniquement. Obligatoirement cumuler avec autre prime RENOLUTION pour atteindre minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après réalisation certificat (max 12 mois après facture solde). Encourage anticipation obligation future PEB pour tous logements.",
  document: "Certificat PEB complet + attestation entrepreneur + factures détaillées du certificateur agréé (nom, n° agrément, n° TVA) + preuves de paiement + documents complémentaires si cumul avec autres primes RENOLUTION (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution A5 - Soutien ménages faibles revenus anticipation obligation PEB",
  placeholder: JSON.parse('{
    "bruxelles_cat3": "Nombre d\'unités de logement à certifier (150€/unité)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/certificat_peb.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat3", region: "bruxelles")&.id
)

# =====================================================
# PRIME B : Installations de chantier
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_protection_echafaudages").update!(
  titre: "B1 - Protection et échafaudage - Bruxelles",
  ordre_affichage: 9,
  icon_name: "ladder",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 20, "condition": "20€/m² échafaudage - Cat. I (défaut)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "30€/m² échafaudage - Cat. II (revenus moyens)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 40, "condition": "40€/m² échafaudage - Cat. III (faibles revenus)"}
  }'),
  condition: "Tous publics (particuliers et professionnels). Bâtiments résidentiels construits au moins 10 ans avant demande. Échafaudage nécessaire pour travaux Toiture (E) ou Façades (F) sauf isolation acoustique murs. Entreprise professionnelle BCE avec TVA et accès réglementé. Échafaudage suspendu conforme NBN EN 12810 et NBN EN 12811.",
  conseil: "Prime B1 obligatoirement liée à prime Toiture (E) ou Façades (F). Calcul par m² d\'échafaudage selon catégorie revenus (20€-30€-40€). Une seule fois/10 ans par emplacement et type travaux. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde).",
  document: "Attestation entrepreneur + attestation technique Protection/échafaudage + factures détaillées (type protection, surface concernée) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul primes (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution B1 - Soutien échafaudage travaux toiture/façades sécurisés",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface échafaudage en m² (20€/m²)",
    "bruxelles_cat2": "Surface échafaudage en m² (30€/m²)",
    "bruxelles_cat3": "Surface échafaudage en m² (40€/m²)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/echafaudage_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME C : Gros-œuvre & gestion de l'eau
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_structure_portante").update!(
  titre: "C1 - Structures portantes - Bruxelles",
  ordre_affichage: 8,
  icon_name: "columns",
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
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 70,
      "condition": "70% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Structure dans surface habitable uniquement. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C1 = 30%-50%-70% coûts éligibles HTVA selon catégorie revenus. Travaux stabilité immeuble : fondations, éléments structurels (métal/bois/béton), planchers, maçonneries portantes/soutènement, voutes/voussettes, ouverture/fermeture baies murs porteurs, dalles béton. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Structures portantes + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution C1 - Travaux stabilité et renforcement structures portantes",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 70%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/structure_portante.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_gestion_egouts").update!(
  titre: "C2 - Égouts - Bruxelles",
  ordre_affichage: 9,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "grille_variable",
      "grille": {
        "égout": 25,
        "chambre de visite": 80,
        "avaloir": 25,
        "chambre de disconnection": 165
      },
      "condition": "Cat. I (défaut) - Tarifs par élément évacuation eaux usées"
    },
    "bruxelles_cat2": {
      "type": "grille_variable",
      "grille": {
        "égout": 45,
        "chambre de visite": 130,
        "avaloir": 45,
        "chambre de disconnection": 275
      },
      "condition": "Cat. II (revenus moyens) - Tarifs par élément évacuation eaux usées"
    },
    "bruxelles_cat3": {
      "type": "grille_variable",
      "grille": {
        "égout": 70,
        "chambre de visite": 210,
        "avaloir": 70,
        "chambre de disconnection": 440
      },
      "condition": "Cat. III (faibles revenus) - Tarifs par élément évacuation eaux usées"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Conduites >90mm sous emprise bâtiment uniquement. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C2 évacuation eaux usées. Tarifs : égout (25-45-70€/m), chambre visite (80-130-210€/pièce), avaloir (25-45-70€/pièce), chambre disconnection (165-275-440€/pièce). Conduites >90mm intérieures enterrées sous emprise bâtiment. Chemisage autorisé. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Égouts + factures détaillées (quantités chambres visite/avaloirs/disconnection et mètres égouts) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution C2 - Travaux évacuation eaux usées sous emprise bâtiment",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection",
    "bruxelles_cat2": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection",
    "bruxelles_cat3": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/gestion_egouts.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_recuperation_eau_pluie").update!(
  titre: "C3 - Récupération d'eau de pluie - Bruxelles",
  ordre_affichage: 10,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 500, "condition": "500€/unité logement - Cat. I (défaut) + Bonus capacité tampon +100€ si ≥1000L"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 750, "condition": "750€/unité logement - Cat. II (revenus moyens) + Bonus capacité tampon +150€ si ≥1000L"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 1100, "condition": "1100€/unité logement - Cat. III (faibles revenus) + Bonus capacité tampon +200€ si ≥1000L"}
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Citerne ≥1000L/logement + pompe + raccordement ≥1 appareil sanitaire. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C3 écologique = 500€-750€-1100€/unité logement selon catégorie revenus. Bonus capacité tampon +100€-150€-200€ si volume ≥1000L non conservé après pluie (protection inondations). Citerne ≥1000L/logement. Pompe + raccordement mini 1 appareil sanitaire (WC, lavabo, douche, etc.). Terrassement/maçonnerie inclus si nouvelle citerne. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur + attestation technique Récupération eau pluie (C3) + factures détaillées (capacité citerne, pompe, raccordements) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution C3 - Économies eau et protection inondations via récupération eau pluie",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre unités logement (500€ + bonus tampon 100€ si applicable)",
    "bruxelles_cat2": "Nombre unités logement (750€ + bonus tampon 150€ si applicable)",
    "bruxelles_cat3": "Nombre unités logement (1100€ + bonus tampon 200€ si applicable)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/eau_pluie_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_demolition_permeabilisation").update!(
  titre: "C4 - Démolition pour perméabiliser le sol - Bruxelles",
  ordre_affichage: 11,
  icon_name: "water",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 60, "condition": "60€/m² surface perméabilisée - Cat. I (défaut)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 75, "condition": "75€/m² surface perméabilisée - Cat. II (revenus moyens)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "condition": "90€/m² surface perméabilisée - Cat. III (faibles revenus)"}
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Démolition annexes (dont dalle sol) supprimant surfaces imperméables. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C4 écologique = 60€-75€-90€/m² surface perméabilisée selon catégorie revenus. Augmentation perméabilité par démolition annexes (suppression surfaces imperméables). Création noues, bassins en eau, puits infiltration. Calcul par m² surface récupérée. Bénéfices : gestion eaux pluie, biodiversité, qualité de vie urbaine. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Démolition perméabilisation sol + factures détaillées (surface perméabilisée précisée) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution C4 - Perméabilisation sol biodiversité et gestion eaux pluviales",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface perméabilisée en m² (60€/m²)",
    "bruxelles_cat2": "Surface perméabilisée en m² (75€/m²)",
    "bruxelles_cat3": "Surface perméabilisée en m² (90€/m²)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/demolition_permeabilisation_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME D : Salubrité
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_traitement_humidite_sol").update!(
  titre: "D1 - Problème d'humidité - Bruxelles",
  ordre_affichage: 12,
  icon_name: "waves",
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
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 80,
      "condition": "80% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Techniques suppression humidité maçonneries (hors plafonnage/carrelage). Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime D1 = 30%-50%-80% coûts éligibles HTVA selon catégorie revenus. Techniques suppression humidité maçonneries : injection produits hydrofuges, insertion membrane étanche, protection murs enterrés (cimentage, revêtement étanche, drainage), cuvelage. EXCLUS : plafonnage et carrelage. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Problème humidité + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution D1 - Suppression humidité maçonneries techniques spécialisées",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 80%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/humidite_sol.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_traitement_fongique_insectes").update!(
  titre: "D2 - Champignons, moisissures et insectes - Bruxelles",
  ordre_affichage: 13,
  icon_name: "bug",
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
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 80,
      "condition": "80% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Travaux basés sur rapport laboratoire agréé obligatoire. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime D2 = 30%-50%-80% coûts éligibles HTVA selon catégorie revenus. Traitement zones contaminées et enlèvement parties dégradées : décapage enduits/plafonnages contaminés, traitement bois, enlèvement boiseries atteintes, injection/pulvérisation sels fongicides/insecticides maçonneries, forage murs et pose cartouches fongicides. OBLIGATOIRE : rapport laboratoire agréé. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur + attestation technique Champignons/moisissures/insectes + RAPPORT LABORATOIRE AGRÉÉ OBLIGATOIRE + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution D2 - Traitement scientifique contaminations biologiques",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 80%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/traitement_fongique.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME E : Toiture
# =====================================================

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
  échéances: "12 mois à partir de la date de facture de solde",
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
  échéances: "12 mois à partir de la date de facture de solde",
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
  échéances: "12 mois à partir de la date de facture de solde",
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
  échéances: "12 mois à partir de la date de facture de solde",
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
  échéances: "12 mois à partir de la date de facture de solde",
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

# =====================================================
# PRIME F : Façades
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_interieure_facade").update!(
  titre: "F1a - Isolation thermique des façades par l'intérieur - Bruxelles",
  ordre_affichage: 19,
  icon_name: "house",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 35,
      "condition": "35€/m² mur isolé - Cat. I (défaut) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 40,
      "condition": "40€/m² mur isolé - Cat. II (revenus moyens) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 45,
      "condition": "45€/m² mur isolé - Cat. III (faibles revenus) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Tous bâtiments (résidentiels et non-résidentiels), construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Coefficient résistance thermique R ≥ 2,00 m²K/W sur entièreté surface isolée. Murs délimitant volume chauffé en contact avec ambiance extérieure. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime F1a = 35€-40€-45€/m² selon catégorie revenus + Bonus matériau naturel 10€/m² (isolants ≥85% renouvelables : cellulose, liège, fibres végétales/animales). Isolation par intérieur : R≥2,00. Travaux fourniture/placement isolant + préparation support + structures secondaires maintien/protection + revêtement protecteur (pare-vapeur, plafonnage, protection intérieure). Bonus Z10 : +10%/+20% si ≥3 primes E3/F1/G1/G2/H1/J4/M1/M2 simultanées. Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : 50.000€ (maisons/appartements), 200.000€ (non-résidentiels/parties communes).",
  document: "Attestation entrepreneur (Informations générales + Volet technique Isolation thermique façades) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type/marque/modèle isolant, surface isolée, épaisseur isolant, valeur R m²K/W, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution F1a - Isolation intérieure façades avec bonus matériaux naturels et bonus travaux multiples Z10",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface isolée m² (35€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat2": "Surface isolée m² (40€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat3": "Surface isolée m² (45€ + bonus 10€ si matériau naturel)"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_interieure_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_exterieure_facade").update!(
  titre: "F1b - Isolation thermique des façades par l'extérieur - Bruxelles",
  ordre_affichage: 20,
  icon_name: "house-door",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 50,
      "condition": "50€/m² mur isolé - Cat. I (défaut) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 70,
      "condition": "70€/m² mur isolé - Cat. II (revenus moyens) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 90,
      "condition": "90€/m² mur isolé - Cat. III (faibles revenus) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Tous bâtiments (résidentiels et non-résidentiels), construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Coefficient résistance thermique R ≥ 3,50 m²K/W sur entièreté surface isolée. Murs délimitant volume chauffé en contact avec ambiance extérieure. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime F1b = 50€-70€-90€/m² selon catégorie revenus + Bonus matériau naturel 10€/m² (isolants ≥85% renouvelables : cellulose, liège, fibres végétales/animales). Isolation par extérieur : R≥3,50. Solution optimale performance thermique et suppression ponts thermiques. Travaux fourniture/placement isolant + préparation support + structures secondaires maintien/protection + revêtement protecteur + zinguerie protection (hors bardage/enduit). Bonus Z10 : +10%/+20% si ≥3 primes E3/F1/G1/G2/H1/J4/M1/M2 simultanées. Minimum 250€/adresse. Maximum 90% montant facturé.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Isolation thermique façades) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type/marque/modèle isolant, surface isolée, épaisseur isolant, valeur R m²K/W, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution F1b - Isolation extérieure façades avec bonus matériaux naturels et bonus travaux multiples Z10",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface isolée m² (50€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat2": "Surface isolée m² (70€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat3": "Surface isolée m² (90€ + bonus 10€ si matériau naturel)"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_exterieure_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_coulisse").update!(
  titre: "F1c - Isolation thermique des façades en coulisse - Bruxelles",
  ordre_affichage: 21,
  icon_name: "layers",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 20,
      "condition": "20€/m² mur isolé - Cat. I (défaut) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 25,
      "condition": "25€/m² mur isolé - Cat. II (revenus moyens) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 30,
      "condition": "30€/m² mur isolé - Cat. III (faibles revenus) + Bonus matériau naturel 10€/m² si isolant ≥85% renouvelable"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Tous bâtiments (résidentiels et non-résidentiels), construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. Coefficient résistance thermique R ≥ 1,00 m²K/W sur entièreté surface isolée. Murs délimitant volume chauffé en contact avec ambiance extérieure. Isolation par injection/insufflation dans coulisse existante. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime F1c = 20€-25€-30€/m² selon catégorie revenus + Bonus matériau naturel 10€/m² (isolants ≥85% renouvelables : cellulose, liège, fibres végétales/animales). Isolation en coulisse : R≥1,00. Solution économique pour murs creux sans démolition. Travaux fourniture/placement isolant + préparation support + structures secondaires maintien/protection + revêtement protecteur. Bonus Z10 : +10%/+20% si ≥3 primes E3/F1/G1/G2/H1/J4/M1/M2 simultanées. Minimum 250€/adresse. Maximum 90% montant facturé. Plafonds : 50.000€ (maisons/appartements), 200.000€ (non-résidentiels/parties communes).",
  document: "Attestation entrepreneur (Informations générales + Volet technique Isolation thermique façades) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type/marque/modèle isolant, surface isolée, épaisseur isolant, valeur R m²K/W, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution F1c - Isolation coulisse façades avec bonus matériaux naturels et bonus travaux multiples Z10",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface isolée m² (20€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat2": "Surface isolée m² (25€ + bonus 10€ si matériau naturel)",
    "bruxelles_cat3": "Surface isolée m² (30€ + bonus 10€ si matériau naturel)"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_coulisse_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bardage_facade").update!(
  titre: "F2 - façade Bardage - Bruxelles",
  ordre_affichage: 22,
  icon_name: "wall",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 40,
      "condition": "40€/m² mur avec bardage - Cat. I (défaut) + Bonus bardage durable 20€/m² si bois FSC/PEFC"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 45,
      "condition": "45€/m² mur avec bardage - Cat. II (revenus moyens) + Bonus bardage durable 20€/m² si bois FSC/PEFC"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 50,
      "condition": "50€/m² mur avec bardage - Cat. III (faibles revenus) + Bonus bardage durable 20€/m² si bois FSC/PEFC"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Bâtiments résidentiels uniquement, construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. CONDITION OBLIGATOIRE : Prime Isolation thermique façades par extérieur doit être introduite simultanément et accordée. Surface bardage ≤ surface isolation accordée (retours max 10% surface isolée). EXCLUSION : bardage PVC non éligible. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime F2 = 40€-45€-50€/m² selon catégorie revenus + Bonus bardage durable 20€/m² (bois certifié FSC/PEFC avec lien unique facture). Travaux placement/remplacement bardage (bois ou autre matériau hors PVC) sur isolant thermique surface extérieure murs : protection intempéries, ventilation, membranes asphalte/polymères, structure portante/réglage, habillage/ancrage, raccords/étanchéité/finitions. OBLIGATOIRE : cumul avec prime Isolation thermique façades par extérieur. Surfaces renseignées sur attestation isolation. Minimum 250€/adresse. Maximum 90% montant facturé.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Isolation thermique façades) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type matériau bardage, surface concernée, indication label PEFC/FSC si applicable, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution F2 - Bardage avec bonus bois durable - Obligatoirement couplé à isolation extérieure",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface bardage m² (40€ + bonus 20€ si bois FSC/PEFC)",
    "bruxelles_cat2": "Surface bardage m² (45€ + bonus 20€ si bois FSC/PEFC)",
    "bruxelles_cat3": "Surface bardage m² (50€ + bonus 20€ si bois FSC/PEFC)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bardage_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_enduit_facade").update!(
  titre: "F3 - Enduit - Bruxelles",
  ordre_affichage: 23,
  icon_name: "paintbrush",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2",
      "montant_m2": 40,
      "condition": "40€/m² mur avec enduit - Cat. I (défaut)"
    },
    "bruxelles_cat2": {
      "type": "montant_m2",
      "montant_m2": 45,
      "condition": "45€/m² mur avec enduit - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "montant_m2",
      "montant_m2": 50,
      "condition": "50€/m² mur avec enduit - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Disponible pour tous (particuliers et professionnels). Bâtiments résidentiels uniquement, construits au moins 10 ans avant demande. Si permis urbanisme requis, aucune prime pour unité neuve même si bâtiment principal >10 ans. CONDITION OBLIGATOIRE : Prime Isolation thermique façades par extérieur doit être introduite simultanément et accordée. Surface enduit ≤ surface isolation accordée (retours max 10% surface isolée). INCOMPATIBILITÉ : pas cumulable avec primes embellissement façade F4 et F5. Entreprise professionnelle BCE avec TVA et accès réglementé selon AR 29/01/2007.",
  conseil: "Prime F3 = 40€-45€-50€/m² selon catégorie revenus. Application enduit sur isolant thermique murs extérieurs : protection intempéries (pluie, vent, gel) tout en laissant respirer support. Types : cimentation, enduit parement avec liant chaux ou matériaux naturels. Travaux inclus : décapage enduit défectueux, évidement joints briques/rejointoiement, raccords/étanchéité/finitions. OBLIGATOIRE : cumul avec prime Isolation thermique façades par extérieur. Surfaces renseignées sur attestation isolation. Minimum 250€/adresse. Maximum 90% montant facturé.",
  document: "Attestation entrepreneur (Informations générales + Volet technique Isolation thermique façades) + factures détaillées libellées au nom du demandeur (adresse chantier, dates, type enduit finition utilisé, surface concernée, prix unitaire HTVA, taux/montant TVA, prix total) + preuves de paiement (<3000€ : extraits bancaires ou facture 'pour acquit', ≥3000€ : extraits bancaires uniquement) + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul avec autres primes.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution F3 - Enduit protection façades - Obligatoirement couplé à isolation extérieure - Incompatible primes embellissement",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface enduit m² (40€)",
    "bruxelles_cat2": "Surface enduit m² (45€)",
    "bruxelles_cat3": "Surface enduit m² (50€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/enduit_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_embellissement_facade_avant").update!(
  titre: "F4 - Embellissement façade avant - Bruxelles RENOLUTION",
  ordre_affichage: 24,
  icon_name: "brush",
  unite: "€/m² (+750€/logement cat III)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 50, "condition": "50€/m² surface de façade avant"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "condition": "50€/m² surface de façade avant"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "50€/m² surface de façade avant + 750€ par logement"}
  }'),
  condition: "Prime RENOLUTION F4 pour embellissement façade avant. Bâtiments en mitoyenneté, façade visible depuis espace public ou en recul max 12m. Propriétaire occupant inscrit 5 ans, propriétaire non-occupant avec AIS 9 ans. Bâtiments >10 ans, affectés logement >80% (copropriétés). Entièreté façade traitée obligatoire. Non cumulable avec prime Enduit F3.",
  conseil: "Travaux éligibles : nettoyage façade (techniques basse pression), produits hydrofuges/anti-graffiti perméables, enduit parement chaux/matériaux naturels (décapage, rejointoiement), peinture enduits/bétons/pierres/briques/bois/métal, châssis/portes (vernis, lasures, préparation), réparation moulures/enduits/balcons/loggias, volets (sauf PVC). Entreprise BCE obligatoire, min 250€, max 90% facturé, plafond 50.000€ (unifamilial) ou 200.000€ (collectif).",
  document: "Attestation entrepreneur (générale + volet technique F4), photos travaux réalisés, factures détaillées (adresse chantier, description précise, TVA), preuves paiement (extrait bancaire si ≥3000€), documents revenus si cat II/III, titre propriété, extrait cadastral. Demande sur IRISbox dans 12 mois après facture solde.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles RENOLUTION - Catégorie F4",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface façade en m²",
    "bruxelles_cat2": "Surface façade en m²",
    "bruxelles_cat3": "Surface façade en m² + nombre logements"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/embellissement_facade_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_facades_arriere_laterales").update!(
  titre: "F5 - Embellissement façade arrière et latérale - Bruxelles RENOLUTION",
  ordre_affichage: 25,
  icon_name: "house-gear",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 20, "condition": "20€/m² surface façades arrière et latérales"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "30€/m² surface façades arrière et latérales"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 40, "condition": "40€/m² surface façades arrière et latérales"}
  }'),
  condition: "Prime RENOLUTION F5 pour embellissement façades arrière et latérales. Bâtiments en mitoyenneté, façades visibles depuis espace public ou en recul max 12m. Propriétaire occupant inscrit 5 ans, propriétaire non-occupant avec AIS 9 ans. Bâtiments >10 ans, affectés logement >80% (copropriétés). Entièreté façades traitée obligatoire. Non cumulable avec prime Enduit F3.",
  conseil: "Travaux éligibles : nettoyage façades (techniques basse pression), produits hydrofuges/anti-graffiti perméables, enduit parement chaux/matériaux naturels (décapage, rejointoiement), peinture enduits/bétons/pierres/briques/bois/métal, châssis/portes (vernis, lasures, préparation), réparation moulures/enduits/balcons/loggias, volets (sauf PVC). Entreprise BCE obligatoire, min 250€, max 90% facturé, plafond 50.000€ (unifamilial) ou 200.000€ (collectif).",
  document: "Attestation entrepreneur (générale + volet technique F5), photos travaux réalisés, factures détaillées (adresse chantier, description précise, TVA), preuves paiement (extrait bancaire si ≥3000€), documents revenus si cat II/III, titre propriété, extrait cadastral. Demande sur IRISbox dans 12 mois après facture solde.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles RENOLUTION - Catégorie F5",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface façades en m²",
    "bruxelles_cat2": "Surface façades en m²",
    "bruxelles_cat3": "Surface façades en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/facades_arriere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_acoustique_murs").update!(
  titre: "F6 - Isolation acoustique des murs - Bruxelles RENOLUTION",
  ordre_affichage: 26,
  icon_name: "volume-high",
  unite: "€/m² (+10€/m² bonus naturel)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 30, "bonus_naturel": 10, "condition": "30€/m² surface isolée + bonus matériau naturel 10€/m²"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 60, "bonus_naturel": 10, "condition": "60€/m² surface isolée + bonus matériau naturel 10€/m²"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "bonus_naturel": 10, "condition": "90€/m² surface isolée + bonus matériau naturel 10€/m²"}
  }'),
  condition: "Prime RENOLUTION F6 pour isolation acoustique murs séparant deux logements. Propriétaire occupant inscrit 5 ans, propriétaire non-occupant avec AIS 9 ans. Bâtiments >10 ans, affectés logement >80% (copropriétés). Bonus matériau naturel si isolant ≥85% composants renouvelables (cellulose, liège, fibres végétales/animales).",
  conseil: "Combinez avec l’étude acoustique (A2) pour maximiser votre confort intérieur",
  document: "Attestation entrepreneur (générale + volet technique F6), factures détaillées (type/marque/modèle isolant, surface isolée, épaisseur), preuves paiement (extrait bancaire si ≥3000€), documents revenus si cat II/III, titre propriété, extrait cadastral. Demande sur IRISbox dans 12 mois après facture solde. Référentiel technique fiches 11-12 Code bonnes pratiques.",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles RENOLUTION - Catégorie F6",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface isolée en m²",
    "bruxelles_cat2": "Surface isolée en m²",
    "bruxelles_cat3": "Surface isolée en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/isolation_acoustique_murs.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)


# =====================================================
# PRIME G : Portes & fenêtres
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_bois").update!(
  titre: "G1 - Placement et remplacement de portes et fenêtres (bois) - Bruxelles",
  ordre_affichage: 27,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 100, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 120, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 140, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"}
  }'),
  condition: "Placement/remplacement portes d\'entrée et fenêtres en bois. Bâtiments ≥10 ans. Seules fenêtres verticales éligibles. Exigences techniques: Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes).",
  conseil: "Matériau écologique sans conditions. BONUS: +100€/m² si bois FSC/PEFC ou réemploi. +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) ou porte acoustique (Rw+Ctr ≥30 dB). Bonus Z10: +10%/20% si ≥3 primes combinées.",
  document: "Attestation entrepreneur (général + technique) + Factures détaillées avec surface, matériaux, valeurs Ug/Uw/Ud + Preuves paiement (>3000€: extraits bancaires) + Si FSC/PEFC: certification sur facture + Si réemploi: preuve achat + Si acoustique: valeurs Rw+Ctr sur facture",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution G1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes/fenêtres en m²",
    "bruxelles_cat2": "Surface portes/fenêtres en m²",
    "bruxelles_cat3": "Surface portes/fenêtres en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/fenetres_bois_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_pvc_alu").update!(
  titre: "G1 - Placement et remplacement de portes et fenêtres (PVC/métal) - Bruxelles",
  ordre_affichage: 28,
  icon_name: "window-desktop",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 40, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 55, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"}
  }'),
  condition: "RESTRICTIONS: PVC/métal éligibles UNIQUEMENT si remplacement à l\'identique (attestation entrepreneur obligatoire) OU si combiné avec primes A2,A4,C1,C2,C3,C4,D1,D2,E1,E4,F4,F5,F6,G3,H2,I1,I2,I3,K1,L1 (permis urbanisme requis). Exigences: Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes).",
  conseil: "Matériaux PVC/métal sous conditions strictes. BONUS: +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) ou porte acoustique (Rw+Ctr ≥30 dB). Bonus Z10: +10%/20% si ≥3 primes combinées. Privilégier le bois si possible.",
  document: "Attestation entrepreneur (général + technique) + Factures détaillées + Preuves paiement + OBLIGATOIRE: attestation remplacement à l\'identique OU permis urbanisme/PV copropriété si combiné avec autres primes + Si acoustique: valeurs Rw+Ctr sur facture",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution G1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes/fenêtres en m²",
    "bruxelles_cat2": "Surface portes/fenêtres en m²",
    "bruxelles_cat3": "Surface portes/fenêtres en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/fenetres_pvc_alu_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_fenetres").update!(
  titre: "G2 - Réparation et adaptation de fenêtres - Bruxelles",
  ordre_affichage: 29,
  icon_name: "tools",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 130, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 220, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 260, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"}
  }'),
  condition: "Réparation/adaptation châssis existants (SAUF PVC) + placement obligatoire double/triple vitrage. Fenêtres verticales uniquement. Bâtiments ≥10 ans. Exigence technique: Ug ≤ 1,2 W/m²K.",
  conseil: "Alternative économique au remplacement pour châssis de qualité. Conserve le patrimoine architectural. BONUS: +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) - logements uniquement. Bonus Z10: +10%/20% si ≥3 primes combinées (E3,F1,G1,G2,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général + technique spécifique G2) + Factures détaillées avec surface vitrages, valeur Ug, type matériaux + Preuves paiement (>3000€: extraits bancaires) + Si acoustique: valeur Rw+Ctr sur facture",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution G2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface fenêtres réparées en m²",
    "bruxelles_cat2": "Surface fenêtres réparées en m²",
    "bruxelles_cat3": "Surface fenêtres réparées en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/reparation_fenetres_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_portes").update!(
  titre: "G3 - Réparation de portes extérieures - Bruxelles",
  ordre_affichage: 30,
  icon_name: "door-closed",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 90, "condition": "Réparation portes extérieures façade en bois ou métal"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 150, "condition": "Réparation portes extérieures façade en bois ou métal"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 180, "condition": "Réparation portes extérieures façade en bois ou métal"}
  }'),
  condition: "Réparation portes extérieures façade en bois ou métal. LOGEMENTS uniquement (80% min. pour copropriétés). Bâtiments ≥10 ans. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Conservation patrimoine architectural. BONUS acoustique: +35€/m² pour portes solides/lourdes avec amélioration propriétés acoustiques. Bonus Z10: +10%/20% si ≥3 primes (E3,F1,G1,G2,G3,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général) + Factures détaillées avec description travaux + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété + Si revenus autres que cat.I: justificatifs",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution G3",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes réparées en m²",
    "bruxelles_cat2": "Surface portes réparées en m²",
    "bruxelles_cat3": "Surface portes réparées en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/reparation_portes_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME H : Sols & planchers
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_sols").update!(
  titre: "H1 - Isolation thermique de sols et planchers - Bruxelles",
  ordre_affichage: 31,
  icon_name: "square",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 35, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 40, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 45, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"}
  }'),
  condition: "Isolation sols/dalles délimitant volume chauffé + planchers sur espaces non chauffés. Bâtiments ≥10 ans. Exigences: R≥2,00 m²K/W (dalles sol) ou R≥3,50 m²K/W (plafonds cave, planchers vide ventilé). Matériaux ATG/ETA/CE/EPBD.",
  conseil: "Réduit 10% déperditions thermiques, améliore confort. Privilégier isolation par le bas si possible. BONUS matériaux durables: +10€/m² si isolants naturels ≥85% renouvelables atteignant R requis. Bonus Z10: +10%/20% si ≥3 primes (E3,F1,G1,G2,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général + technique H1) + Factures détaillées avec type/marque/modèle isolant, surface, épaisseur, valeur R + Preuves paiement (>3000€: extraits bancaires) + Si bonus durable: justificatifs matériaux naturels",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution H1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface sols/planchers isolés en m²",
    "bruxelles_cat2": "Surface sols/planchers isolés en m²",
    "bruxelles_cat3": "Surface sols/planchers isolés en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_sols_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_acoustique_sols").update!(
  titre: "H2 - Isolation acoustique de planchers et plafonds - Bruxelles",
  ordre_affichage: 32,
  icon_name: "volume-mute",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 30, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 60, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Isolation acoustique planchers/plafonds séparant 2 logements. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€. Techniques: chapes flottantes, complexes isolants, faux-plafonds acoustiques.",
  conseil: "Améliore confort, santé et bien-être. BONUS matériaux durables: +10€/m² si isolants naturels ≥85% renouvelables (cellulose, liège, fibres végétales/animales). Systèmes spécialisés: chapes flottantes, lambourdes, alternance couches, faux-plafonds antivibratiles.",
  document: "Attestation entrepreneur (général + technique H2) + Factures détaillées avec type/marque/modèle isolant, surface, épaisseur, systèmes techniques + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété + Si bonus durable: justificatifs matériaux naturels",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution H2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface planchers/plafonds isolés en m²",
    "bruxelles_cat2": "Surface planchers/plafonds isolés en m²",
    "bruxelles_cat3": "Surface planchers/plafonds isolés en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/isolation_acoustique_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME I : Aménagement intérieur
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_escaliers").update!(
  titre: "I1 - Escaliers intérieurs - Bruxelles",
  ordre_affichage: 33,
  icon_name: "ladder",
  unite: "€/marche",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 30, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 50, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 80, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Placement/remplacement escaliers intérieurs en bois, béton ou métal. EXCLUS: escaliers escamotables. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Améliore sécurité et accessibilité logement. Inclut revêtements, paliers, mains courantes, balustres, trémies, parapets massifs. Forfait calculé par marche pour faciliter estimation. Matériaux durables recommandés.",
  document: "Attestation entrepreneur (général + technique I1) + Factures détaillées avec nombre marches précis, matériaux utilisés + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution I1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de marches",
    "bruxelles_cat2": "Nombre de marches",
    "bruxelles_cat3": "Nombre de marches"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/escaliers_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_emplacement_velo").update!(
  titre: "I2 - Emplacements vélo - Bruxelles",
  ordre_affichage: 34,
  icon_name: "bicycle",
  unite: "€/emplacement (max 2/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Aménagement emplacements vélo sécurisés. MAX 2 emplacements/logement. Forfait unique 80€ toutes catégories. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Encourage mobilité douce et répond obligations urbanistiques. Forfait simple: 80€/emplacement, maximum 2 par logement. Inclut dispositifs fixation, arceaux, supports, parois. Améliore valeur immobilière et attractivité logement.",
  document: "Attestation entrepreneur (général) + Factures détaillées avec nombre précis emplacements, description aménagements + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution I2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre emplacements vélo (max 2/logement)",
    "bruxelles_cat2": "Nombre emplacements vélo (max 2/logement)",
    "bruxelles_cat3": "Nombre emplacements vélo (max 2/logement)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/emplacement_velo_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_protection_incendie").update!(
  titre: "I3 - Protection incendie (copropriétés) - Bruxelles",
  ordre_affichage: 35,
  icon_name: "shield-alert",
  unite: "% du coût HTVA",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    }
  }'),
  condition: "Pose ou mise à niveau d’éléments passifs ou actifs de protection incendie (portes coupe-feu, détecteurs, cloisons, revêtements RF, etc.)",
  conseil: "Sécurité incendie copropriétés. 20% coûts HTVA toutes catégories. Inclut: compartimentage, intervention plafonds, portes RF. Matériaux conformes normes REI. Document essentiel: avis SIAMU à fournir obligatoirement.",
  document: "Attestation entrepreneur (général + technique I3) + OBLIGATOIRE: Avis prévention incendie SIAMU + Factures détaillées avec description matériaux RF + Preuves paiement (>3000€: extraits bancaires) + Documents copropriété",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution I3",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant HTVA travaux éligibles",
    "bruxelles_cat2": "Montant HTVA travaux éligibles",
    "bruxelles_cat3": "Montant HTVA travaux éligibles"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/protection_incendie.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_amenagement_pmr").update!(
  titre: "I4 - Aménagements personnes handicapées - Bruxelles",
  ordre_affichage: 36,
  icon_name: "universal-access",
  unite: "€ forfaitaire",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Adaptation parties privatives/communes pour personnes handicapées. 7.500€/logement (privatif) ou 7.500€/bâtiment (communs). Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€. OBLIGATOIRE: attestation reconnaissance handicap.",
  conseil: "Accessibilité et adaptation logements. Forfait identique toutes catégories: 7.500€. Travaux selon cahier prescriptions techniques accessibilité. Inclut: adaptation logement, équipements spécifiques, voies accès, portes, sanitaires. Document essentiel: attestation handicap obligatoire.",
  document: "Attestation entrepreneur (général + technique I4) + OBLIGATOIRE: Attestation reconnaissance/allocation personnes handicapées + Factures détaillées travaux adaptation + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution I4",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait 7.500€ - Préciser si privatif ou commun",
    "bruxelles_cat2": "Forfait 7.500€ - Préciser si privatif ou commun",
    "bruxelles_cat3": "Forfait 7.500€ - Préciser si privatif ou commun"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/amenagement_pmr_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME J : Chauffage & chauffe-eau
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_pac_chauffage").update!(
  titre: "J4 - Chauffage via pompe à chaleur - Bruxelles",
  ordre_affichage: 37,
  icon_name: "flame",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 4500,
      "condition": "PAC air/eau : 4.500€ par logement - PAC eau/eau ou sol/eau : 5.800€ par logement"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 4750,
      "condition": "PAC air/eau : 4.750€ par logement - PAC eau/eau ou sol/eau : 6.150€ par logement"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 5000,
      "condition": "PAC air/eau : 5.000€ par logement - PAC eau/eau ou sol/eau : 6.500€ par logement"
    }
  }'),
  condition: "Bâtiment construit depuis au moins 10 ans. PAC ≤70kW : efficacité énergétique minimum A+ (Règlement UE 811/2013). PAC >70kW : efficacité saisonnière ≥110% (Règlement UE 813/2013). PAC basse température (<45°C) : efficacité saisonnière ≥125%. Installation par entreprise certifiée RESCert. Exclusions: PAC piscine privée, PAC air/air. Bonus sortie mazout disponible.",
  conseil: "Il est fortement recommandé que le bâtiment soit préalablement isolé pour optimiser les performances de la pompe à chaleur. Une PAC dans un bâtiment bien isolé permet un fonctionnement optimal et de meilleures économies d'énergie.",
  document: "Attestation entrepreneur (informations générales + volet technique J4). Si non-RESCert : rapport contrôle par installateur certifié. Factures détaillées (marque, modèle, n° série, puissance, n° RESCert). Preuves de paiement. Si bonus sortie mazout : photo poêle inactif ou attestation enlèvement/inertage cuve.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J4. Bonus sortie mazout: +300€/600€ (cat I), +350€/700€ (cat II), +500€/1000€ (cat III) selon chaudière/poêle. Bonus plusieurs travaux (Z10): +10% (cat I&II), +20% (cat III) si ≥3 primes combinées. Non résidentiel: 35% coûts éligibles.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "PAC air/eau: 4.500€ - PAC sol/eau: 5.800€",
    "bruxelles_cat2": "PAC air/eau: 4.750€ - PAC sol/eau: 6.150€",
    "bruxelles_cat3": "PAC air/eau: 5.000€ - PAC sol/eau: 6.500€"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/pac_chauffage.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_radiateurs_basse_temperature").update!(
  titre: "J5 - Radiateurs basse température - Bruxelles",
  ordre_affichage: 38,
  icon_name: "thermometer",
  unite: "€/radiateur",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 75,
      "condition": "75€ par radiateur basse température placé ou remplacé"
    },
    "bruxelles_cat2": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 125,
      "condition": "125€ par radiateur basse température placé ou remplacé"
    },
    "bruxelles_cat3": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 200,
      "condition": "200€ par radiateur basse température placé ou remplacé"
    }
  }'),
  condition: "Bâtiments résidentiels uniquement, construits depuis au moins 10 ans. Radiateurs dimensionnés pour régime 55°/45°C (température ambiante 20°C) ou inférieur selon norme EN 442 ou EN 16430. Marquage CE obligatoire. Installation adaptée existante requise (chaudière gaz condensation ou PAC).",
  conseil: "Optez pour des radiateurs basse température qui offrent une excellente diffusion de la chaleur et garantissent une économie de consommation de votre chaudière ou pompe à chaleur. Idéal en complément d'une PAC.",
  document: "Attestation entrepreneur (informations générales + volet technique J5). Factures détaillées (marque, modèle, nombre de radiateurs basse température). Preuves de paiement. Spécifications techniques conformes EN 442/EN 16430.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J5. EXCLUSIVEMENT bâtiments résidentiels. Non cumulable avec prime J6 (Régulation thermique). Radiateurs eau chaude basse température uniquement. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de radiateurs × 75€",
    "bruxelles_cat2": "Nombre de radiateurs × 125€",
    "bruxelles_cat3": "Nombre de radiateurs × 200€"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/radiateurs_bt.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_thermostat").update!(
  titre: "J6 - Régulation thermique : Thermostat/Optimiseur - Bruxelles",
  ordre_affichage: 39,
  icon_name: "sliders",
  unite: "€/unité",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_unite",
      "montant_par_unite": 40,
      "condition": "40€ par thermostat d\'ambiance ou optimiseur (max 1 par logement/copropriété)"
    },
    "bruxelles_cat2": {
      "type": "montant_unite",
      "montant_par_unite": 70,
      "condition": "70€ par thermostat d\'ambiance ou optimiseur (max 1 par logement/copropriété)"
    },
    "bruxelles_cat3": {
      "type": "montant_unite",
      "montant_par_unite": 100,
      "condition": "100€ par thermostat d\'ambiance ou optimiseur (max 1 par logement/copropriété)"
    }
  }'),
  condition: "Bâtiment construit depuis au moins 10 ans. Thermostat/optimiseur conforme à la réglementation PEB chauffage-climatisation. Équipé d'horloge et programmation minimum 7 jours. Optimiseur avec auto-adaptation selon températures extérieure/intérieure. Maximum 1 par logement ou copropriété.",
  conseil: "La régulation thermique est un moyen efficace pour optimiser vos consommations, que votre chaudière soit neuve ou ancienne. Elle permet de respecter les règles PEB chauffage et climatisation.",
  document: "Attestation entrepreneur (informations générales + volet technique J6). Factures détaillées (type, marque, modèle de régulation, nombre de pièces). Preuves de paiement. Conformité réglementation PEB.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J6. Non cumulable avec prime J5 (Radiateurs basse température). Thermostat filaire/sans fil avec horloge ou optimiseur thermique uniquement. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de thermostats × 40€",
    "bruxelles_cat2": "Nombre de thermostats × 70€",
    "bruxelles_cat3": "Nombre de thermostats × 100€"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/thermostat_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_vannes_thermostatiques").update!(
  titre: "J6 - Régulation thermique : Vannes thermostatiques - Bruxelles",
  ordre_affichage: 40,
  icon_name: "thermometer-half",
  unite: "€/pièce",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_unite",
      "montant_par_unite": 15,
      "condition": "15€ par pièce équipée de vannes thermostatiques"
    },
    "bruxelles_cat2": {
      "type": "montant_unite",
      "montant_par_unite": 25,
      "condition": "25€ par pièce équipée de vannes thermostatiques"
    },
    "bruxelles_cat3": {
      "type": "montant_unite",
      "montant_par_unite": 40,
      "condition": "40€ par pièce équipée de vannes thermostatiques"
    }
  }'),
  condition: "Bâtiment construit depuis au moins 10 ans. Vannes thermostatiques installées sur installation de chauffage existante. Régulation individuelle par radiateur. Installation complète respectant la réglementation PEB chauffage-climatisation.",
  conseil: "La régulation thermique par vannes thermostatiques optimise vos consommations et complète efficacement les thermostats d'ambiance pour un contrôle précis pièce par pièce.",
  document: "Attestation entrepreneur (informations générales + volet technique J6). Factures détaillées (type, marque, modèle de vannes, nombre de pièces équipées). Preuves de paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J6. Non cumulable avec prime J5 (Radiateurs basse température). Vannes thermostatiques pour régulation d'installation chauffage uniquement. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de pièces × 15€",
    "bruxelles_cat2": "Nombre de pièces × 25€",
    "bruxelles_cat3": "Nombre de pièces × 40€"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/vannes_thermostatiques_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_chauffe_eau_solaire").update!(
  titre: "J8 - Chauffe-eau solaire thermique - Bruxelles",
  ordre_affichage: 41,
  icon_name: "sun",
  unite: "€/logement ou installation",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 2500,
      "condition": "2.500€ par logement individuel ou installation non résidentielle"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 3000,
      "condition": "3.000€ par logement individuel ou installation non résidentielle"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 3500,
      "condition": "3.500€ par logement individuel ou installation non résidentielle"
    }
  }'),
  condition: "Bâtiment construit depuis au moins 10 ans. Installation minimum 2m² surface optique panneaux + ballon eau chaude. Capteurs plans/tubulaires orientés Sud (max 90° Est/Ouest), conformes EN-12975 label Solar Keymark. Système conforme EN-12976 (préfabriqué) ou EN-12977 (assemblé). Ballon classe A (Règlement UE 812/2013). Exclusion: piscines privées.",
  conseil: "Grâce aux panneaux solaires thermiques, vous pouvez couvrir 60% de vos besoins annuels en eau chaude sanitaire, même en Région de Bruxelles-Capitale où le soleil est suffisamment présent.",
  document: "Attestation entrepreneur (informations générales + volet technique J8). Si non-RESCert : rapport contrôle par installateur certifié. Factures détaillées (marque, modèle, caractéristiques stockage, puissance, collecteurs solaires, compteur chaleur, n° RESCert). Preuves de paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J8. Installation par entreprise certifiée RESCert solaire thermique (<50kWth). Compteur chaleur intégrateur obligatoire conforme AR 13/06/2006. Fraction solaire minimum 60% (installations individuelles). Garantie fonctionnement 2 ans minimum + GRS si >50m². Débitmètre + thermomètres + compteur énergie + compteur eau sanitaire requis.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "2.500€ par logement/installation",
    "bruxelles_cat2": "3.000€ par logement/installation",
    "bruxelles_cat3": "3.500€ par logement/installation"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/chauffe_eau_solaire.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_chauffe_eau_pac").update!(
  titre: "J9 - Chauffe-eau via pompe à chaleur - Bruxelles",
  ordre_affichage: 42,
  icon_name: "cloud-drizzle",
  unite: "€/logement",
  type_de_valeur: "forfait_logement",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 1400,
      "condition": "Installation d’un chauffe-eau alimenté par pompe à chaleur"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 1500,
      "condition": "Installation d’un chauffe-eau alimenté par pompe à chaleur"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 1600,
      "condition": "Installation d’un chauffe-eau alimenté par pompe à chaleur"
    }
  }'),
  condition: "Système de production d’eau chaude sanitaire basé sur une pompe à chaleur dédiée",
  conseil: "Vérifie la compatibilité avec le système de chauffage existant et l’isolation du ballon",
  document: "Attestation entrepreneur (informations générales + volet technique J9). Factures détaillées (marque, modèle, n° série, puissance installation). Preuves de paiement. Compteurs électriques de passage si requis.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J9. EXCLUSIVEMENT bâtiments résidentiels. Non cumulable avec J4 (PAC chauffage) pour même appareil combiné. Production ECS exclusivement. Installation par entreprise BCE avec accès réglementé. Compteurs électriques passage + respect PEB requis.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "1.400€ par logement",
    "bruxelles_cat2": "1.500€ par logement",
    "bruxelles_cat3": "1.600€ par logement"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/chauffe_eau_pac.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_raccordement_reseau_chaleur").update!(
  titre: "J10 - Réseau de chaleur - Bruxelles",
  ordre_affichage: 43,
  icon_name: "heat-wave",
  unite: "€/raccordement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 1000,
      "condition": "1.000€ par raccordement du bâtiment à un réseau de chaleur existant"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 1250,
      "condition": "1.250€ par raccordement du bâtiment à un réseau de chaleur existant"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 1500,
      "condition": "1.500€ par raccordement du bâtiment à un réseau de chaleur existant"
    }
  }'),
  condition: "Bâtiments résidentiels et non résidentiels construits depuis au moins 10 ans. Raccordement à réseau de chaleur existant uniquement. Maison unifamiliale, immeuble appartements ou bâtiment non résidentiel seulement (pas unités individuelles). Tuyaux distribution + accessoires calorifugés conformément PEB.",
  conseil: "Un réseau de chaleur fonctionne comme un chauffage central urbain : la chaleur est transportée par canalisations souterraines vers plusieurs bâtiments via une sous-station, évitant un système de production propre au bâtiment.",
  document: "Attestation entrepreneur (informations générales + volet technique J10). Factures détaillées (fourniture, placement, raccordement sous-station, adaptation tuyauteries/robinetteries). Preuves de paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: J10. Résidentiels ET non résidentiels. Raccordement à réseau existant exclusivement. Installation par entreprise BCE avec accès réglementé. Calorifugeage obligatoire selon PEB. Cumulable avec toutes autres primes.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "1.000€ par raccordement",
    "bruxelles_cat2": "1.250€ par raccordement",
    "bruxelles_cat3": "1.500€ par raccordement"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/raccordement_chaleur.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME K : Sanitaires
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_appareil_sanitaire").update!(
  titre: "K1 - Appareils et installation sanitaires - Bruxelles",
  ordre_affichage: 44,
  icon_name: "droplet-half",
  unite: "€/appareil",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 200, "condition": "200€ par appareil sanitaire (max 5 par logement)"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 340, "condition": "340€ par appareil sanitaire (max 5 par logement)"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 540, "condition": "540€ par appareil sanitaire (max 5 par logement)"}
  }'),
  condition: "Logements ou bâtiments affectés au logement construits depuis au moins 10 ans. Propriétaire occupant (inscription registre population 5 ans si prime >30.000€) ou propriétaire non occupant avec contrat AIS 9 ans minimum. Copropriété forcée: bâtiment affecté logement à 80% minimum. Maximum 5 appareils par logement.",
  conseil: "Installation d'appareils sanitaires et raccordement: lavabo, lave-mains, douche, bain, évier, WC, bidet. Bonus réemploi disponible: +70€/appareil (max 5) si appareils de réemploi mentionnés expressément sur facture.",
  document: "Attestation entrepreneur (informations générales + volet technique K1). Factures détaillées (description précise appareils, accessoires, circuits arrivée/évacuation). Si bonus réemploi: mention expresse achat magasin revente. Preuves paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: K1. EXCLUSIVEMENT résidentiel. Propriétaire occupant ou AIS. Copropriété forcée acceptée si 80% logement. Bonus réemploi +70€/appareil toutes catégories. Maximum 5 appareils/logement. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre appareils × 200€ (+70€ réemploi)",
    "bruxelles_cat2": "Nombre appareils × 340€ (+70€ réemploi)",
    "bruxelles_cat3": "Nombre appareils × 540€ (+70€ réemploi)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/sanitaire_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME L : Électricité & gaz
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_mise_normes_electricite_gaz").update!(
  titre: "L1 - Conformité de l'installation électrique - Bruxelles",
  ordre_affichage: 45,
  icon_name: "lightning",
  unite: "% des coûts éligibles HTVA",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 30, "condition": "30% des coûts éligibles HTVA (mise en conformité électrique)"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 50, "condition": "50% des coûts éligibles HTVA (mise en conformité électrique)"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 70, "condition": "70% des coûts éligibles HTVA (mise en conformité électrique)"}
  }'),
  condition: "Logements ou bâtiments affectés au logement construits depuis au moins 10 ans. Propriétaire occupant (inscription registre + engagement 5 ans si prime >30.000€) ou propriétaire non occupant avec contrat AIS 9 ans. Copropriété forcée: bâtiment affecté logement à 80%. Rapport contrôle organisme agréé obligatoire. Exclusion installations internet.",
  conseil: "Mise en conformité installation électrique espace habitable: tableau principal/divisionnaires, prises, interrupteurs, points lumineux (hors appareils éclairage), rénovation plafonnages/murs liés aux travaux électriques. Rapport contrôle totalité installation requis.",
  document: "Attestation entrepreneur (informations générales). Rapport contrôle totalité installation par organisme contrôle agréé OBLIGATOIRE. Factures détaillées (tableaux électriques, prises, interrupteurs, points lumineux, travaux plafonnages/murs liés). Preuves paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: L1. EXCLUSIVEMENT résidentiel. Propriétaire occupant, AIS ou copropriété forcée (80% logement). Plafond: 50.000€ logement individuel / 200.000€ bâtiment entier. Rapport organisme agréé OBLIGATOIRE. Installation par entreprise BCE électrotechnique.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Coût travaux × 30% (HTVA)",
    "bruxelles_cat2": "Coût travaux × 50% (HTVA)",
    "bruxelles_cat3": "Coût travaux × 70% (HTVA)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/electricite_gaz_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME M : Ventilation
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_c").update!(
  titre: "M1 - Ventilation mécanique contrôlée: Système C - Bruxelles",
  ordre_affichage: 46,
  icon_name: "wind",
  unite: "€/logement individuel",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 1550, "condition": "1.550€ par logement individuel (VMC simple flux centralisé)"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 1950, "condition": "1.950€ par logement individuel (VMC simple flux centralisé)"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 2230, "condition": "2.230€ par logement individuel (VMC simple flux centralisé)"}
  }'),
  condition: "Bâtiments résidentiels uniquement, construits depuis au moins 10 ans. VMC simple flux centralisé avec régulation débits permanents extraction. Système conforme PEB (annexe XIX NBN D50-001) et EPDB. Système complet: ouvertures alimentation locaux secs + évacuation locaux humides + transferts. Extraction centralisée. Interdiction chauffage électrique et climatisation électrique. Débits permanents obligatoires.",
  conseil: "Si vous avez rénové votre logement qui devient plus étanche, un système de ventilation avec évacuation mécanique de l'air devient essentiel pour assurer le confort intérieur et évacuer l'humidité.",
  document: "Attestation entrepreneur (informations générales + volet technique M1). Factures détaillées (marque, modèle ventilation, type régulation, ensemble système C, percements gaines). Mesures débits sortie/entrée bouches + réglage installation obligatoires. Preuves paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: M1. EXCLUSIVEMENT résidentiel. Bonus plusieurs travaux (Z10): +10% (cat I&II), +20% (cat III) si ≥3 primes combinées. Système EPDB ou calcul débits requis. Mesures et réglage installateur obligatoires. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "1.550€ par logement (+10% si Z10)",
    "bruxelles_cat2": "1.950€ par logement (+10% si Z10)",
    "bruxelles_cat3": "2.230€ par logement (+20% si Z10)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/ventilation_c_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_d").update!(
  titre: "M2 - Ventilation mécanique contrôlée: Système D - Bruxelles",
  ordre_affichage: 47,
  icon_name: "arrow-repeat",
  unite: "€/logement ou % coûts",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 3000, "condition": "Résidentiel: 3.000€/logement - Non résidentiel: 25% échangeur+régulation"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 3750, "condition": "Résidentiel: 3.750€/logement - Non résidentiel: 25% échangeur+régulation"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 4300, "condition": "Résidentiel: 4.300€/logement - Non résidentiel: 25% échangeur+régulation"}
  }'),
  condition: "Bâtiments résidentiels et non résidentiels construits depuis au moins 10 ans. VMC double flux avec récupération chaleur et régulation débits permanents. Système conforme PEB (annexe XIX NBN D50-001 résidentiel / annexe XX NBN EN 13779 non résidentiel) et EPDB. Échangeur rendement minimum 80%. Système complet centralisé. Débits permanents résidentiel / régulation adaptée non résidentiel.",
  conseil: "Système double-flux très économe en énergie qui transfère la chaleur de l'air sortant à l'air entrant, assurant qualité d'air et confort respiratoire optimaux lors de la rénovation.",
  document: "Attestation entrepreneur (informations générales + volet technique M2). Factures détaillées (marque, modèle ventilation, type régulation, échangeur thermique, ensemble système D, percements). Mesures débits + réglage obligatoires. Non résidentiel: surcoût échangeur ou forfait 30%. Preuves paiement.",
  échéances: "12 mois maximum après la date de facture de solde",
  specifique: "Bruxelles - Renolution - Ref: M2. Résidentiel ET non résidentiel. Bonus plusieurs travaux (Z10): +10% (cat I&II), +20% (cat III) si ≥3 primes. Échangeur 80% minimum. Système EPDB ou calcul débits. Régulation avancée non résidentiel (CO2, COV, présence, etc.). Installation par entreprise BCE.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Résidentiel: 3.000€ - Non résidentiel: 25%",
    "bruxelles_cat2": "Résidentiel: 3.750€ - Non résidentiel: 25%",
    "bruxelles_cat3": "Résidentiel: 4.300€ - Non résidentiel: 25%"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/vmc_double_flux_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME Z : Bonus
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z1").update!(
  titre: "Bonus Z1 – Matériau d'isolation durable - Bruxelles",
  ordre_affichage: 48,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_par_m2": 10, "condition": "Isolation avec matériaux naturels composés d\'au moins 85% de composants renouvelables"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_par_m2": 10, "condition": "Isolation avec matériaux naturels composés d\'au moins 85% de composants renouvelables"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_par_m2": 10, "condition": "Isolation avec matériaux naturels composés d\'au moins 85% de composants renouvelables"}
  }'),
  condition: "Matériaux naturels : cellulose, liège, fibres végétales (chanvre, bois, lin, paille, coton) ou animales (plumes, laine, duvet)",
  conseil: "Privilégier des matériaux certifiés écologiques avec au moins 85% de composants renouvelables",
  document: "Facture + certificat du fournisseur attestant de la composition du matériau",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z1.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z2").update!(
  titre: "Bonus Z2 – Matériau de couverture durable - Bruxelles",
  ordre_affichage: 49,
  icon_name: "umbrella",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bardeaux de bois, tuiles céramiques, ardoises naturelles (toitures en pente) ou EPDM (toitures plates)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bardeaux de bois, tuiles céramiques, ardoises naturelles (toitures en pente) ou EPDM (toitures plates)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bardeaux de bois, tuiles céramiques, ardoises naturelles (toitures en pente) ou EPDM (toitures plates)"}
  }'),
  condition: "Matériaux de couverture durables selon le type de toiture (pente ou plate)",
  conseil: "Choisissez des matériaux adaptés au type de toiture pour optimiser la durabilité",
  document: "Facture + fiche technique du matériau + attestation de pose conforme",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface de couverture en m²",
    "bruxelles_cat2": "Surface de couverture en m²",
    "bruxelles_cat3": "Surface de couverture en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z2.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z3").update!(
  titre: "Bonus Z3 – Matériau de bardage durable - Bruxelles",
  ordre_affichage: 50,
  icon_name: "building",
  unite: "€/m²",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bois local (rayon 300km), pierre naturelle locale ou brique de terre cuite"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bois local (rayon 300km), pierre naturelle locale ou brique de terre cuite"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_par_m2": 20, "condition": "Bois local (rayon 300km), pierre naturelle locale ou brique de terre cuite"}
  }'),
  condition: "Pose d’un bardage extérieur en matériaux labellisés écologiques ou issus du réemploi",
  conseil: "Privilégiez des matériaux durables certifiés (FSC, PEFC, etc.) ou réemployés localement",
  document: "Facture + attestation ou fiche technique prouvant la durabilité ou le label du matériau",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution - Bonus Z3",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Majoration automatique si matériau certifié",
    "bruxelles_cat2": "Majoration automatique si matériau certifié",
    "bruxelles_cat3": "Majoration automatique si matériau certifié"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z3.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z4").update!(
  titre: "Bonus Z4 – Matériau de fenêtres durables - Bruxelles",
  ordre_affichage: 51,
  icon_name: "door-open",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_par_m2": 100, "condition": "Châssis bois local, alu recyclé ou PVC recyclé"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_par_m2": 100, "condition": "Châssis bois local, alu recyclé ou PVC recyclé"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_par_m2": 100, "condition": "Châssis bois local, alu recyclé ou PVC recyclé"}
    }'),
    condition: "Matériaux de châssis durables (bois local, métaux recyclés)",
    conseil: "Privilégiez des châssis avec certification environnementale",
  document: "Facture + certificat d'origine du matériau + fiche technique",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface de châssis en m²",
    "bruxelles_cat2": "Surface de châssis en m²",
    "bruxelles_cat3": "Surface de châssis en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z4.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z5").update!(
  titre: "Bonus Z5 – Portes et fenêtres acoustiques - Bruxelles",
  ordre_affichage: 51,
  icon_name: "volume-x",
  unite: "€/m² (max 50m²)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2_et_limite", "montant_par_m2": 35, "plafond_m2": 50, "condition": "Fenêtres ou portes avec isolation acoustique ≥ 30 dB"},
    "bruxelles_cat2": {"type": "montant_m2_et_limite", "montant_par_m2": 35, "plafond_m2": 50, "condition": "Fenêtres ou portes avec isolation acoustique ≥ 30 dB"},
    "bruxelles_cat3": {"type": "montant_m2_et_limite", "montant_par_m2": 35, "plafond_m2": 50, "condition": "Fenêtres ou portes avec isolation acoustique ≥ 30 dB"}
    }'),
    condition: "Isolation acoustique certifiée pour chaque vitrage ou bâti",
    conseil: "Utilisez des vitrages multi-couches avec intercalaire acoustique",
    document: "Facture détaillant le type et la performance acoustique + certificat",
  échéances: "12 mois à partir de la date de facture de solde",
    specifique: "Bruxelles - Renolution",
    placeholder: JSON.parse('{
      "bruxelles_cat1": "Surface en m² – max 50",
      "bruxelles_cat2": "Surface en m² – max 50",
      "bruxelles_cat3": "Surface en m² – max 50"
    }'),
    statut_compatible: ["residentiel"],
  image: "images/bonus_z5.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z6").update!(
  titre: "Bonus Z6 – Réemploi d'équipements sanitaires - Bruxelles",
  ordre_affichage: 53,
  icon_name: "recycle",
  unite: "€/appareil (max 5)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_par_unite": 70, "condition": "Réemploi ou remise en état d équipements sanitaires (max 5 appareils)"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_par_unite": 70, "condition": "Réemploi ou remise en état d équipements sanitaires (max 5 appareils)"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_par_unite": 70, "condition": "Réemploi ou remise en état d équipements sanitaires (max 5 appareils)"}
  }'),
  condition: "Lavabos, baignoires ou WC remis en état ou repris d'un autre projet",
  conseil: "Vérifiez la conformité sanitaire avant réemploi. Maximum 5 appareils",
  document: "Facture ou bon de cession + certificat de remise en état",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre d appareils réemployés (max 5)",
    "bruxelles_cat2": "Nombre d appareils réemployés (max 5)",
    "bruxelles_cat3": "Nombre d appareils réemployés (max 5)"
    }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z6.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z7").update!(
  titre: "Bonus Z7 – Capacité tampon de citerne d'eau de pluie - Bruxelles",
  ordre_affichage: 54,
  icon_name: "droplet-percent",
  unite: "€/citerne",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 100, "condition": "Capacité de stockage ≥ 3 000 L"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 150, "condition": "Capacité de stockage ≥ 3 000 L"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 200, "condition": "Capacité de stockage ≥ 3 000 L"}
  }'),
  condition: "Citerne enterrée ou aérienne avec capacité tampon minimale de 3 000 litres",
  conseil: "Vérifiez l'espace disponible et la stabilité du terrain avant installation",
  document: "Facture + fiche technique citerne précisant capacité",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait pour citerne ≥ 3000L",
    "bruxelles_cat2": "Forfait pour citerne ≥ 3000L",
    "bruxelles_cat3": "Forfait pour citerne ≥ 3000L"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z7.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z9").update!(
  titre: "Bonus Z9 – Sortie mazout et charbon - Bruxelles",
  ordre_affichage: 54,
  icon_name: "fire",
  unite: "€/forfait",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 300, "condition": "Désinstallation et évacuation de cuve mazout/charbon"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 350, "condition": "Désinstallation et évacuation de cuve mazout/charbon"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 500, "condition": "Désinstallation et évacuation de cuve mazout/charbon"}
  }'),
  condition: "Enlèvement complet et dépollution du site de stockage de mazout ou charbon",
  conseil: "Engagez un spécialiste agréé pour assurer la conformité environnementale",
  document: "Rapport d'enlèvement + facture du prestataire",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait nettoyage cuve",
    "bruxelles_cat2": "Forfait nettoyage cuve",
    "bruxelles_cat3": "Forfait nettoyage cuve"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z9.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z10").update!(
  titre: "Bonus Z10 – Plusieurs travaux combinés - Bruxelles",
  ordre_affichage: 55,
  icon_name: "layers",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 20, "condition": "Au moins 3 types de travaux soumis"}
  }'),
  condition: "Regroupement de trois travaux ou plus dans la même demande",
  conseil: "Réunissez vos travaux pour maximiser la prime globale",
  document: "Factures pour chaque type de travaux + récapitulatif",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z10.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ #{Prime.where(region: 'bruxelles').count} primes Bruxelles RENOLUTION créées avec succès"
