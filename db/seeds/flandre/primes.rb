Prime.where(region: "flandre").delete_all

Prime.find_or_initialize_by(slug: "isolation_toiture").update!(
  titre: "Isolation de la toiture",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5750, "condition": "isolation et rénovation"}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 4025, "condition": "isolation et rénovation"}, "2": {"type": "montant_m2_et_limite", "montant_m2": 16, "surface_max": 100, "plafond_pourcentage": 25, "condition": "isolation seule"}, "1": {"type": "montant_m2_et_limite", "montant_m2": 8, "surface_max": 100, "plafond_pourcentage": 20, "condition": "isolation seule"}}'),
  condition: "R ≥ 4.5 m²K/W pour toiture inclinée, plate et grenier",
  conseil: "Utiliser un isolant certifié (laine minérale, PIR, etc.) et vérifier l'étanchéité.",
  document: "Facture détaillée + devis ou métré + attestation de l entrepreneur",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "Surface en m²", "2": "Surface en m²", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/isolation_toiture.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "isolation_murs_cat12").update!(
  titre: "Isolation des murs extérieurs (cat. 1-2)",
  unite: "m²",
  type_de_valeur: "surface_et_type",
  categorie_limite: ["1", "2"],
  eligible_categories: ["1", "2"],
  valeurs_par_categorie: JSON.parse('{"2": {"type": "montant_variable_m2_et_limite", "montants_m2": {"mur_creux": 7.5, "interieur": 15, "exterieur": 22.5}, "surface_max": 100, "plafond_pourcentage": 25, "condition": "isolation seule"}, "1": {"type": "montant_variable_m2_et_limite", "montants_m2": {"mur_creux": 5, "interieur": 10, "exterieur": 15}, "surface_max": 100, "plafond_pourcentage": 20, "condition": "isolation seule"}}'),
  condition: "R ≥ 3.0 m²K/W (selon méthode, mur creux: 5 cm de creux et R≥ 2, intérieur:2.0 ou extérieur:3.0)",
  conseil: "Vérifiez les ponts thermiques, choisissez la méthode adaptée (spouwmuur, intérieur, extérieur).",
  document: "Facture + devis ou métré + attestation de l entrepreneur. Si isolation par l'intérieur, alors attestation de l'entrepreneur, il faut un architecte ou un entrepreneur avec numéro BIM.",
  specifique: "Si isolation par murs creux/en coulisse - attestation STS et numéro STS présent dans la facture",
  placeholder: JSON.parse('{"1": "Surface en m²", "2": "Surface en m²"}'),
  image: "images/isolation_murs_ext.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "isolation_murs_cat34").update!(
  titre: "Isolation des murs extérieurs (cat. 3-4)",
  unite: "€",
  type_de_valeur: "montant_facture",
  categorie_limite: ["3", "4"],
  eligible_categories: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5000, "condition": "isolation et rénovation"}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 3500, "condition": "isolation et rénovation"}}'),
  condition: "R ≥ 3.0 m²K/W (selon méthode, mur creux: 5 cm de creux et R≥ 2, intérieur:2.0 ou extérieur:3.0)",
  conseil: "Vérifiez les ponts thermiques, choisissez la méthode adaptée (spouwmuur, intérieur, extérieur).",
  document: "Facture + devis ou métré + attestation de l entrepreneur. si isolation par l'intérieur, alors attestation de l'entrepreneur, il faut un architecte ou un entrepreneur avec numéro BIM.",
  specifique: "Si isolation par murs creux/en coulisse - attestation STS et numéro STS présent dans la facture",
  placeholder: JSON.parse('{"3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/isolation_murs_ext.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "isolation_sol").update!(
  titre: "Isolation du sol / plancher bas et sol cave",
  unite: "m²",
  type_de_valeur: "surface",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 1500, "condition": "isolation et rénovation"}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 1050, "condition": "isolation et rénovation"}, "2": {"type": "montant_m2_et_limite", "montant_m2": 9, "surface_max": 75, "plafond_pourcentage": 25, "condition": "isolation seule"}, "1": {"type": "montant_m2_et_limite", "montant_m2": 6, "surface_max": 75, "plafond_pourcentage": 20, "condition": "isolation seule"}}'),
  condition: "R ≥ 2.0 m²K/W + Isolation thermique du plancher bas sur vide sanitaire ou terre-plein",
  conseil: "Privilégier les isolants à forte résistance thermique. Traiter également les ponts thermiques si possible.",
  document: "Facture détaillée + devis ou métré + attestation de l entrepreneur",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "Surface en m²", "2": "Surface en m²", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/isolation_sol.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "ramen_deuren").update!(
  titre: "Remplacement des châssis et portes extérieures",
  unite: "m²",
  type_de_valeur: "surface",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5250, "condition": "remplacement du vitrage et des menuiseries extérieures, ventilation obligatoire"}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 3675, "condition": "remplacement du vitrage et des menuiseries extérieures – ventilation obligatoire"}, "2": {"type": "montant_m2_et_limite", "montant_m2": 64, "surface_max": 20, "plafond_pourcentage": 25, "condition": "remplacement du vitrage uniquement – ventilation obligatoire"}, "1": {"type": "montant_m2_et_limite", "montant_m2": 30, "surface_max": 20, "plafond_pourcentage": 20, "condition": "remplacement du vitrage uniquement – ventilation obligatoire"}}'),
  condition: "Vitrage HR++ (U ≤ 1.0 W/m²K) + ventilation conforme (type invisivent dans toutes les pièces sèches ou VMC double flux (système D))",
  conseil: "Veillez à intégrer un système de ventilation efficace lors du remplacement des menuiseries.",
  document: "Facture + bordereau de commande + attestation de l'entrepreneur + preuve du respect des normes de ventilation",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "Surface en m²", "2": "Surface en m²", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/remplacement_chassis.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "voorbereiding_isolatie").update!(
  titre: "Travaux préparatoires pour l isolation",
  unite: "€",
  type_de_valeur: "facture",
  eligible_categories: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{
    "4": {
      "type": "pourcentage_et_plafond",
      "pourcentage": 50,
      "plafond": 2000,
      "condition": "Travaux préparatoires pour une isolation, uniquement si la prime isolation est demandée"
    },
    "3": {
      "type": "pourcentage_et_plafond",
      "pourcentage": 35,
      "plafond": 1400,
      "condition": "Travaux préparatoires pour une isolation, uniquement si la prime isolation est demandée"
    },
    "2": {
      "type": "prime_conditionnelle",
      "valeur": 0,
      "condition": "Prime complémentaire uniquement si la prime isolation est demandée"
    },
    "1": {
      "type": "prime_conditionnelle",
      "valeur": 0,
      "condition": "Prime complémentaire uniquement si la prime isolation est demandée"
    }
  }'),
  condition: "Les travaux doivent précéder une isolation effective et être facturés séparément",
  conseil: "Pensez à intégrer ces travaux dans le devis global mais à les distinguer clairement",
  document: "Facture détaillée + devis ou métré + preuve (photos!) des travaux réalisés en amont d une isolation",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "", "2": "", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/preparation_isolation.webp",
  region: "flandre",
  categorie_limite: nil,
  categorie_visible: nil
)



Prime.find_or_initialize_by(slug: "voorbereiding_sanitair_elec").update!(
  titre: "Travaux préparatoires sanitaires et électricité",
  unite: "€",
  type_de_valeur: "facture",
  eligible_categories: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 3000}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 2100}}'),
  condition: "Doit concerner les réseaux intérieurs à remplacer avant travaux principaux (chauffage, électricité, sanitaire)",
  conseil: "Séparez ces interventions dans le devis pour les rendre éligibles. Attention nous parlons bien des typaux par exemple et non les appareils eux-mêmes.",
  document: "Facture + devis ou métré + justificatif des travaux concernés (photos!) et l'attestation de conformité si applicable",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "", "2": "", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/electricité.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "warmtepomp").update!(
  titre: "Pompe à chaleur",
  unite: "type_de_pompe",
  type_de_valeur: "forfait",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "forfait_et_plafond_facture", "forfaits": {"geothermique": 8000, "air_eau": 6000, "air_air": 600, "hybride": 4000}, "plafond_pourcentage": 50}, "3": {"type": "forfait_et_plafond_facture", "forfaits": {"geothermique": 6000, "air_eau": 4500, "air_air": 450, "hybride": 3000}, "plafond_pourcentage": 35}, "2": {"type": "forfait_et_plafond_facture", "forfaits": {"geothermique": 4000, "air_eau": 2250, "air_air": 300, "hybride": 1500}, "plafond_pourcentage": 25}, "1": {"type": "forfait_et_plafond_facture", "forfaits": {"geothermique": 4000, "air_eau": 2250, "air_air": 300, "hybride": 1500}, "plafond_pourcentage": 20}}'),
  condition: "Uniquement pour bâtiments de plus de 5 ans avec permis d environnement",
  conseil: "Vérifiez si le type de pompe est bien éligible et installé par un professionnel agréé + l'installation doit être conforme aux normes PEB, bâtiment de +5 ans.",
  document: "Facture détaillée + devis ou métré + attestation de conformité de l installateur - numéro RESERT obligatoire pour toutes les pompes à chaleur + label européen. si Air/eau, fonction réversible soit non active.",
  specifique: "Pour une PAC air/eau, si elle n'a pas le refroidissement actif, il faut une attestation de l'entrepreneur. Si elle en dispose, il faut respecter 3 conditions 1/panneaux solaires installés ET enregistrés auprès de Fluvius 2/la PAC = moyen de chauffage principal 3/ factures émises au moins depuis 2023 ",
  placeholder: JSON.parse('{"1": "Choisissez le type de pompe", "2": "Choisissez le type de pompe", "3": "Choisissez le type de pompe", "4": "Choisissez le type de pompe"}'),
  image: "images/pac_géothermique.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "warmtepompboiler").update!(
  titre: "Chauffe-eau thermodynamique",
  unite: "forfait",
  type_de_valeur: "montant",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "forfait_et_plafond_facture", "forfait": 1200, "plafond_pourcentage": 50}, "3": {"type": "forfait_et_plafond_facture", "forfait": 1050, "plafond_pourcentage": 35}, "2": {"type": "forfait_et_plafond_facture", "forfait": 900, "plafond_pourcentage": 25}, "1": {"type": "forfait_et_plafond_facture", "forfait": 900, "plafond_pourcentage": 20}}'),
  condition: "Système à pompe à chaleur pour eau chaude sanitaire. Non combiné avec boiler électrique classique",
  conseil: "L’installation doit être effectuée par un professionnel agréé et être bien dimensionnée selon les besoins du foyer + bâtiment de plus de 5 ans et respect des normes PEB.",
  document: "Facture + devis ou métré + label euorpéen + attestation de conformité de l'entrepreneur",
  specifique: " XX ",
  placeholder: JSON.parse('{"1": "Montant total de la facture", "2": "Montant total de la facture", "3": "Montant total de la facture", "4": "Montant total de la facture"}'),
  image: "images/pac_hybride.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "renovation_toiture").update!(
  titre: "Travaux de rénovation associés - Toiture",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["3", "4"],
  categorie_visible: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5750}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 4025}}'),
  condition: "Travaux de rénovation associés à l isolation de toiture + Factures admissibles liées à la structure, couverture, accessoires toiture, étanchéité, corniche, descente d'eau pluviale.",
  conseil: "Peuvent inclure dépose de l'ancienne couverture, renforcement charpente, etc.",
  document: "Facture détaillée mentionnant les postes concernés + devis ou métré.",
  specifique: " XX ",
  placeholder: JSON.parse('{"3": "Montant total des travaux toiture hors isolation", "4": "Montant total des travaux toiture hors isolation"}'),
  image: "images/renovation_toiture.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "renovation_murs").update!(
  titre: "Travaux de rénovation associés - Murs",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["3", "4"],
  categorie_visible: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5750}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 4025}}'),
  condition: "Travaux de rénovation associés à l isolation des murs + Travaux admissibles hors isolation, ex. bardage, crépi, traitement humidité",
  conseil: "Inclut travaux préparatoires ou de remise en état après isolation",
  document: "Facture détaillée avec ventilation des coûts + devis ou métré.",
  specifique: " XX ",
  placeholder: JSON.parse('{"3": "Montant total des travaux murs hors isolation", "4": "Montant total des travaux murs hors isolation"}'),
  image: "images/renovation_murs.webp",
  region: "flandre",
)


Prime.find_or_initialize_by(slug: "renovation_sol").update!(
  titre: "Travaux de rénovation associés - Sol",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["3", "4"],
  categorie_visible: ["3", "4"],
  valeurs_par_categorie: JSON.parse('{"4": {"type": "pourcentage_et_plafond", "pourcentage": 50, "plafond": 5750}, "3": {"type": "pourcentage_et_plafond", "pourcentage": 35, "plafond": 4025}}'),
  condition: "Travaux de rénovation associés à l isolation du sol + Travaux admissibles incluant chape, ragréage, reprise du revêtement, étanchéite.",
  conseil: "Documentez bien les postes techniques hors isolant",
  document: "Facture séparant les postes d isolation et de rénovation + devis ou métré.",
  specifique: " XX ",
  placeholder: JSON.parse('{"3": "Montant total des travaux sols hors isolation", "4": "Montant total des travaux sols hors isolation"}'),
  image: "images/renovation_sol.webp",
  region: "flandre",
)
