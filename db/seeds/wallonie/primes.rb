puts "🏴󠁢󠁥󠁷󠁡󠁬󠁿 Création des primes Wallonie..."

# Mode sécurisé : ne supprime que si explicitement demandé
if ENV['FORCE_PRIME_RESET'] == 'true'
  puts "🗑️  Nettoyage des primes Wallonie existantes (#{Rails.env})..."
  Prime.where(region: "wallonie").delete_all
else
  puts "🔒 Mode sécurisé : conservation des primes existantes (utilisez FORCE_PRIME_RESET=true pour réinitialiser)"
end

# === AUDIT ===

Prime.find_or_initialize_by(slug: "wallonie_realisation_audit_logement").update!(
  titre: "Réalisation d'un audit logement - Wallonie",
  ordre_affichage: 1,
  icon_name: "search",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 456, "condition": "Audit énergétique complet"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 304, "condition": "Audit énergétique complet"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 228, "condition": "Audit énergétique complet"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 152, "condition": "Audit énergétique complet"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 76, "condition": "Audit énergétique complet"}
  }'),
  condition: "Réalisé par auditeur agréé. Rapport dans les 6 mois.",
  conseil: "Étape préalable recommandée avant travaux.",
  document: "Rapport d'audit + facture auditeur agréé",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === TOITURE ===

Prime.find_or_initialize_by(slug: "wallonie_toiture_remplacement_couverture").update!(
  titre: "Toiture - Remplacement de la couverture - Wallonie",
  ordre_affichage: 2,
  icon_name: "hammer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 24, "condition": "Remplacement complet"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 16, "condition": "Remplacement complet"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 12, "condition": "Remplacement complet"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 8, "condition": "Remplacement complet"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 4, "condition": "Remplacement complet"}
  }'),
  condition: "Remplacement complet de la couverture. Isolation intégrée recommandée.",
  conseil: "Coordonner avec isolation thermique. Prévoir évacuation gravats.",
  document: "Devis détaillé + factures + photos avant/après",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/remplacement_toiture_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_appropriation_charpente").update!(
  titre: "Toiture - Appropriation de la charpente - Wallonie",
  ordre_affichage: 3,
  icon_name: "tools",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 600, "condition": "Renforcement charpente"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 400, "condition": "Renforcement charpente"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 300, "condition": "Renforcement charpente"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 200, "condition": "Renforcement charpente"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 100, "condition": "Renforcement charpente"}
  }'),
  condition: "Renforcement ou appropriation de la charpente existante.",
  conseil: "Expertise structure recommandée avant travaux.",
  document: "Rapport expertise + factures + attestation conformité",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/charpente_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_evacuation_eaux_pluviales").update!(
  titre: "Toiture - Évacuation des eaux pluviales - Wallonie",
  ordre_affichage: 4,
  icon_name: "tint",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 240, "condition": "Remplacement système"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 160, "condition": "Remplacement système"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 120, "condition": "Remplacement système"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 80, "condition": "Remplacement système"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 40, "condition": "Remplacement système"}
  }'),
  condition: "Remplacement du dispositif de collecte et d'évacuation des eaux pluviales.",
  conseil: "Dimensionnement selon surface toiture. Raccordement aux égouts.",
  document: "Factures + plan évacuation + photos installation",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/gouttiere_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_isolation_thermique").update!(
  titre: "Toiture - Isolation thermique du toit ou des combles - Wallonie",
  ordre_affichage: 5,
  icon_name: "house",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 120, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 80, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 60, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 40, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 20, "condition": "R ≥ 5,00 m²K/W"}
  }'),
  condition: "• Travaux réalisés par entrepreneur BCE enregistré\n• Isolation thermique du toit/combles en contact avec extérieur, espace non chauffé à l'abri du gel ou non à l'abri du gel, ou sol\n• Coefficient de résistance thermique R ≥ 5,00 m²K/W\n• Isolant placé en plusieurs couches : somme des résistances ≥ 5,00 m²K/W\n• Seuls matériaux de la demande comptabilisés (couche existante exclue)\n• Valeurs lambda (λ) certifiées par ATG, ETA, marquage CE ou base EPBD (www.epbd.be)\n• À défaut : valeurs Annexe B1 Arrêté 15/05/2014 ou norme NBN B 62-002\n• Paroi isolée existante au jour de visite auditeur",
  conseil: "Si audit mentionne 'travaux liés' sur même paroi, demande unique obligatoire. Travaux salubrité liés possibles : remplacement couverture, appropriation charpente, remplacement dispositifs collecte/évacuation eaux pluviales (hors stockage). Vérifier continuité isolation et étanchéité air.",
  document: "• Copie ensemble des factures (montants détaillés des éléments, liste travaux éligibles sur https://energie.wallonie.be)\n• Annexe technique 1 administration complétée, datée et signée par entrepreneur\n• Photos explicites avant, pendant et après travaux\n• Certificats matériaux isolants (ATG, ETA, marquage CE ou EPBD)\n• Attestation entrepreneur BCE",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_toiture_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_isolation_biosource").update!(
  titre: "Toiture - Isolation thermique BIOSOURCÉE - Wallonie",
  ordre_affichage: 6,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 156, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 104, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 78, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 52, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 26, "condition": "R ≥ 4,5 + biosourcé"}
  }'),
  condition: "Matériau biosourcé certifié. R ≥ 4,5 m²K/W.",
  conseil: "Prime majorée pour matériaux écologiques. Certification obligatoire.",
  document: "Factures + certificat biosourcé + attestation performance",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)
# === MURS ===

Prime.find_or_initialize_by(slug: "wallonie_assechement_murs_infiltration").update!(
  titre: "Assèchement des murs - infiltration - Wallonie",
  ordre_affichage: 7,
  icon_name: "droplet",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 14.4, "condition": "Traitement infiltration"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Traitement infiltration"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 7.2, "condition": "Traitement infiltration"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4.8, "condition": "Traitement infiltration"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2.4, "condition": "Traitement infiltration"}
  }'),
  condition: "Traitement des infiltrations d'eau dans les murs.",
  conseil: "Diagnostic humidité préalable obligatoire.",
  document: "Rapport diagnostic + factures + garantie travaux",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/assechement_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_assechement_murs_humidite").update!(
  titre: "Assèchement des murs - humidité ascensionnelle - Wallonie",
  ordre_affichage: 8,
  icon_name: "arrow-up",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 19.2, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 12.8, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 6.4, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 3.2, "condition": "Traitement humidité ascensionnelle"}
  }'),
  condition: "Traitement de l'humidité ascensionnelle dans les murs.",
  conseil: "Barrière étanche obligatoire. Ventilation renforcée.",
  document: "Rapport diagnostic + factures + garantie décennale",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/humidite_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_renforcement_murs").update!(
  titre: "Renforcement des murs instables ou démolition/reconstruction - Wallonie",
  ordre_affichage: 9,
  icon_name: "hammer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 19.2, "condition": "Renforcement structure"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 12.8, "condition": "Renforcement structure"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Renforcement structure"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 6.4, "condition": "Renforcement structure"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 3.2, "condition": "Renforcement structure"}
  }'),
  condition: "Renforcement ou reconstruction de murs instables.",
  conseil: "Expertise structure obligatoire avant travaux.",
  document: "Rapport structural + factures + attestation conformité",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/renforcement_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_elimination_merule").update!(
  titre: "Élimination de la mérule - Wallonie",
  ordre_affichage: 10,
  icon_name: "bug",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Traitement complet mérule"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Traitement complet mérule"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Traitement complet mérule"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Traitement complet mérule"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Traitement complet mérule"}
  }'),
  condition: "Élimination complète de la mérule par entreprise agréée.",
  conseil: "Traitement obligatoire par professionnel certifié.",
  document: "Diagnostic + factures + garantie traitement",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/merule_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_elimination_radon").update!(
  titre: "Élimination du radon - Wallonie",
  ordre_affichage: 11,
  icon_name: "radiation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Système anti-radon"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Système anti-radon"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Système anti-radon"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Système anti-radon"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Système anti-radon"}
  }'),
  condition: "Installation système de ventilation anti-radon.",
  conseil: "Mesure préalable concentration radon obligatoire.",
  document: "Mesures radon + factures + attestation efficacité",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/radon_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_murs").update!(
  titre: "Isolation thermique des murs - Wallonie",
  ordre_affichage: 12,
  icon_name: "brick-wall",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 52.8, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 35.2, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 26.4, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 17.6, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8.8, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Murs contact extérieur/espace non chauffé/sol. R ≥ 4,00 m²K/W (3,50 si demande avant 30/06/2024). Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "ITE privilégiée pour ponts thermiques. Possible assèchement/renforcement murs si nécessaire.",
  document: "Factures détaillées + Annexe technique 2 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/isolation_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_murs_biosource").update!(
  titre: "Isolation thermique des murs BIOSOURCÉE - Wallonie",
  ordre_affichage: 13,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 72, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Matériau biosourcé certifié. Murs contact extérieur/espace non chauffé/sol. R ≥ 4,00 m²K/W (3,50 si demande avant 30/06/2024). Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Prime majorée pour matériaux écologiques. Possible assèchement/renforcement murs si nécessaire.",
  document: "Factures détaillées + Certificat biosourcé + Annexe technique 2 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/isolation_murs_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_travaux_salubrite_murs").update!(
  titre: "Travaux de salubrité liés à l'isolation des murs - Wallonie",
  ordre_affichage: 13.5,
  icon_name: "droplet-slash",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 45, "condition": "Assèchement/renforcement murs"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 30, "condition": "Assèchement/renforcement murs"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 22.5, "condition": "Assèchement/renforcement murs"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 15, "condition": "Assèchement/renforcement murs"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 7.5, "condition": "Assèchement/renforcement murs"}
  }'),
  condition: "Travaux liés obligatoires sur même paroi que isolation. Assèchement (infiltrations, humidité ascensionnelle) ou renforcement/reconstruction murs instables. Même demande de prime que isolation.",
  conseil: "Obligatoire si mentionné dans rapport d'audit. Coordonner avec isolation murs.",
  document: "Factures détaillées + Photos avant/pendant/après + Rapport expertise si renforcement + Même demande que isolation murs",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/salubrite_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === SOLS ===

Prime.find_or_initialize_by(slug: "wallonie_remplacement_supports_circulation").update!(
  titre: "Remplacement des supports des aires de circulation - Wallonie",
  ordre_affichage: 14,
  icon_name: "layer-group",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 12, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 8, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 6, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2, "condition": "Travaux salubrité liés isolation sols"}
  }'),
  condition: "Travaux liés obligatoires sur même paroi que isolation sols. Remplacement supports (gîtage, hourdis), aires circulation, sous-couches, plinthes induit par travaux. Même demande de prime que isolation.",
  conseil: "Obligatoire si mentionné dans rapport d'audit. Coordonner avec isolation sols. Diagnostic structure préalable recommandé.",
  document: "Factures détaillées + Photos avant/pendant/après + Même demande que isolation sols + Plans techniques",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/plancher_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_sols").update!(
  titre: "Isolation thermique des sols - Wallonie",
  ordre_affichage: 15,
  icon_name: "layer-group",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 18, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 6, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Sol contact extérieur/espace non chauffé à l'abri du gel ou non/sol. R ≥ 3,50 m²K/W. Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Isolation par dessous privilégiée si cave accessible. Coordonner avec remplacement supports si nécessaire.",
  document: "Factures détaillées + Annexe technique 3 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_sols_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_sols_biosource").update!(
  titre: "Isolation thermique des sols BIOSOURCÉE - Wallonie",
  ordre_affichage: 16,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 32, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 16, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Matériau biosourcé certifié. Sol contact extérieur/espace non chauffé à l'abri du gel ou non/sol. R ≥ 3,50 m²K/W. Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Prime majorée pour matériaux écologiques. Coordonner avec remplacement supports si nécessaire.",
  document: "Factures détaillées + Certificat biosourcé + Annexe technique 3 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_sols_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_finition_planchers").update!(
  titre: "Isolation finition planchers - Wallonie",
  ordre_affichage: 17,
  icon_name: "grip-lines",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 12, "condition": "Finition isolante"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 8, "condition": "Finition isolante"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 6, "condition": "Finition isolante"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4, "condition": "Finition isolante"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2, "condition": "Finition isolante"}
  }'),
  condition: "Isolation et finition des planchers.",
  conseil: "Complémentaire à l'isolation principale.",
  document: "Factures + photos finition",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/finition_plancher_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === MENUISERIES ===

Prime.find_or_initialize_by(slug: "wallonie_menuiseries_vitrages").update!(
  titre: "Remplacement des menuiseries/vitrages extérieurs - Wallonie",
  ordre_affichage: 18,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 156, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 104, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 78, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 52, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 26, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"}
  }'),
  condition: "Entrepreneur BCE enregistré + accès profession. Contact extérieur/espace non chauffé. Ug vitrage ≤ 1,10 W/m²K (NBN EN 673). Éléments transparents/translucides ≤ 1,10 W/m²K. Vitrages norme NBN S23-002. Uw menuiseries ≤ 1,50 W/m²K (annexe B1 arrêté 15/05/2014).",
  conseil: "Mesurer surface vitrage précisément. Pose étanche obligatoire. Coordination portes/fenêtres.",
  document: "Factures détaillées + Annexe technique 4 complétée/signée + Bordereau menuiseries (surfaces + coefficients transmission thermique) + Fiches techniques + Photos",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/menuiseries_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === INSTALLATIONS ===

Prime.find_or_initialize_by(slug: "wallonie_installation_electrique").update!(
  titre: "Appropriation de l'installation électrique - Wallonie",
  ordre_affichage: 19,
  icon_name: "bolt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1920, "condition": "Mise aux normes"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1280, "condition": "Mise aux normes"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 960, "condition": "Mise aux normes"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 640, "condition": "Mise aux normes"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 320, "condition": "Mise aux normes"}
  }'),
  condition: "Mise aux normes de l'installation électrique.",
  conseil: "Contrôle électricien agréé obligatoire.",
  document: "Certificat conformité + factures + rapport contrôle",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/electricite_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_installation_gaz").update!(
  titre: "Appropriation de l'installation de gaz - Wallonie",
  ordre_affichage: 20,
  icon_name: "fire",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Mise aux normes gaz"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Mise aux normes gaz"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Mise aux normes gaz"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Mise aux normes gaz"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Mise aux normes gaz"}
  }'),
  condition: "Mise aux normes de l'installation de gaz.",
  conseil: "Contrôle organisme agréé obligatoire.",
  document: "Certificat conformité + factures + rapport contrôle",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/gaz_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === CHAUFFAGE ===

Prime.find_or_initialize_by(slug: "wallonie_pac_eau_chaude").update!(
  titre: "Pompe à chaleur - eau chaude sanitaire (boiler thermodynamique) - Wallonie",
  ordre_affichage: 21,
  icon_name: "tint",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1680, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1120, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 840, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 560, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 280, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"}
  }'),
  condition: "PAC reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession. Prévention légionellose. Groupe sécurité classique.",
  conseil: "Vérifier éligibilité sur energie.wallonie.be. Local non chauffé recommandé. Évacuation condensats.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos source chaleur + Offre-type complétée/signée (dès 01/01/2026) + Si hors liste: étiquette énergétique règlement 812/2013 ou fiche Ecodesign 814/2013",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/cet_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_pac_chauffage").update!(
  titre: "Pompe à chaleur - chauffage ou combinée air/eau ou air/sol - Wallonie",
  ordre_affichage: 22,
  icon_name: "thermometer-half",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 3600, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2400, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1800, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1200, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 600, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"}
  }'),
  condition: "PAC reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession. EXCLUSION: PAC AIR/AIR non éligibles (rejet énergie thermique sur air).",
  conseil: "Dimensionnement par thermicien. Isolation préalable recommandée. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos source chaleur + Offre-type complétée/signée (dès 01/01/2026) + Si hors liste: fiche EcoDesign règlement 813/2013 ou rapport test NBN EN 14511/15879-1",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/pac_air_eau_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chaudiere_biomasse").update!(
  titre: "Chaudière biomasse - Wallonie",
  ordre_affichage: 23,
  icon_name: "fire",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 4320, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2880, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 2160, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1440, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 720, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"}
  }'),
  condition: "Chaudière reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be + rapport test fabricant). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession.",
  conseil: "Stockage combustible adéquat. Conduit ramonage. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos démonstrant effectivité + Si hors liste: rapport test NBN EN 303-5",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chaudiere_biomasse_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffe_eau_solaire").update!(
  titre: "Chauffe-eau solaire - Wallonie",
  ordre_affichage: 24,
  icon_name: "solar-panel",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 2520, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1680, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1260, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 840, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 420, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"}
  }'),
  condition: "Installateur certifié rescert.be (art. 3, § 2, 2° arrêté 27/06/2013). Capteurs Solar Keymark NBN EN 12975 + surface optique ≥ 2m² (solarkeymark.dk). Fraction solaire ≥ 60%. Orientation sud-est-ouest. Système comptage: débitmètre + 2 thermomètres + compteur énergie thermique + compteur eau sanitaire. Calorifugeage annexe C4 arrêté 15/05/2014. Permis urbanisme si nécessaire.",
  conseil: "Orientation optimale 45° sud. Vérifier règles urbanisme pour capteurs sol.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos capteurs solaires + Offre-type complétée/signée + Certificats Solar Keymark",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ces_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_poele_biomasse").update!(
  titre: "Poêle biomasse local - Wallonie",
  ordre_affichage: 25,
  icon_name: "fire-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 960, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 640, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 480, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 320, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"}
  }'),
  condition: "Poêle repris liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be + rapport test fabricant). OBLIGATOIRE: foyer fermé. EXCLUSION: feux ouverts et appareils mixtes (ouvert/fermé). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession.",
  conseil: "Installation conduit conforme. Ventilation suffisante. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos démonstrant effectivité + Si hors liste: rapport test NBN EN 14785/13240/13229/12809/15250/12815/16510 selon type poêle",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/poele_biomasse_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === VENTILATION ===
Prime.find_or_initialize_by(slug: "wallonie_vmc_simple").update!(
  titre: "Ventilation - VMC simple flux toutes les pièces humides - Wallonie",
  ordre_affichage: 26,
  icon_name: "wind",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1680, "condition": "Hygroréglable"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1120, "condition": "Hygroréglable"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 840, "condition": "Hygroréglable"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 560, "condition": "Hygroréglable"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 280, "condition": "Hygroréglable"}
  }'),
  condition: "Installation d'un système centralisé de ventilation mécanique simple flux qui assure la ventilation de l'ensemble des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'une fonctionnalité à la demande selon l'arrêté ministériel du 16 octobre 2015. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système centralisé avec fonctionnalité à la demande obligatoire. Bouches hygroréglables dans toutes les pièces humides. Respect strict des annexes C4, C2 et C3.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure attestant des débits de ventilation effectivement mis en œuvre et de leur conformité PEB + attestation capacité ouvertures de ventilation naturelle + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vsf_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_double").update!(
  titre: "Ventilation - VMC double flux avec récupération de chaleur - Wallonie",
  ordre_affichage: 27,
  icon_name: "fan",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 4080, "condition": "Efficacité ≥ 85%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2720, "condition": "Efficacité ≥ 85%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 2040, "condition": "Efficacité ≥ 85%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1360, "condition": "Efficacité ≥ 85%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 680, "condition": "Efficacité ≥ 78%"}
  }'),
  condition: "Installation d'un système centralisé de ventilation mécanique double flux qui assure la ventilation de l'ensemble des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'un dispositif de récupération de chaleur d'une efficacité minimale de 78% selon la NBN EN 308, complétée par l'annexe G. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système centralisé avec récupération de chaleur d'efficacité minimale 78% selon NBN EN 308. Réseau étanche obligatoire. Vérifier présence du récupérateur sur base EPBD (www.epbd.be).",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure attestant des débits de ventilation + rapport de test du récupérateur selon NBN EN 308 si non présent sur base EPBD + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vdf_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_simple_partielle").update!(
  titre: "Ventilation - VMC simple flux (partielle, pièces humides uniquement) - Wallonie",
  ordre_affichage: 28,
  icon_name: "wind",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 480, "condition": "Hygroréglable partiel"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 320, "condition": "Hygroréglable partiel"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 240, "condition": "Hygroréglable partiel"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 160, "condition": "Hygroréglable partiel"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 80, "condition": "Hygroréglable partiel"}
  }'),
  condition: "Installation d'un système de ventilation mécanique simple flux qui assure la ventilation d'une partie des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'une régulation du débit par détection : toilettes (présence, CO2 ou couplage éclairage), cuisine (CO2 ou humidité), autres espaces humides (humidité). Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système partiel avec régulation obligatoire par détection selon le type d'espace. Toilettes : détection présence/CO2/couplage éclairage. Cuisine : détection CO2/humidité. SDD/SDB/buanderie : détection humidité.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure des débits de ventilation PEB + fiche technique de l'appareil si dessert un seul espace + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vsf_partielle_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_double_partielle").update!(
  titre: "Ventilation - VMC double flux (partielle, pièces humides uniquement) - Wallonie",
  ordre_affichage: 29,
  icon_name: "fan",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 960, "condition": "Efficacité ≥ 75%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 640, "condition": "Efficacité ≥ 75%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 480, "condition": "Efficacité ≥ 75%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 320, "condition": "Efficacité ≥ 75%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Efficacité ≥ 50%"}
  }'),
  condition: "Installation d'un système de ventilation mécanique double flux qui assure la ventilation d'une partie des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit comporter, pour chaque groupe de ventilation, un dispositif de récupération de chaleur d'une efficacité minimale de 50% selon l'annexe G. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système partiel avec récupération de chaleur d'efficacité minimale 50% par groupe de ventilation. Vérifier présence du récupérateur sur base EPBD (www.epbd.be) pour éviter rapport de test supplémentaire.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure des débits de ventilation PEB + rapport de test du rendement du récupérateur selon NBN EN 308 si non présent sur base EPBD + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vdf_partielle_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === AMÉLIORATIONS CHAUFFAGE ===
Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_conduites").update!(
  titre: "Amélioration chauffage - Isolation des conduites de chauffage et accessoires - Wallonie",
  ordre_affichage: 30,
  icon_name: "pipe",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"}
  }'),
  condition: "Conduites chauffage et accessoires situées dans espace non chauffé (à l'abri du gel ou non). Calorifugeage conforme annexe C4 Arrêté 15/05/2014 (performance énergétique bâtiments).",
  conseil: "Matériau isolant adapté aux hautes températures. Inclut accessoires système chauffage.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Rapport calorifugeage tuyaux eau chaude annexe C4 rédigé par installateur + Photos avant/après",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/isolation_conduites_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_ballon_500").update!(
  titre: "Amélioration chauffage - Isolation ballon ≤500l - Wallonie",
  ordre_affichage: 31,
  icon_name: "thermometer-quarter",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"}
  }'),
  condition: "Isolation ballon stockage chauffage ≤500 litres. Matériau isolant coefficient résistance thermique R ≥ 1,50 m²K/W.",
  conseil: "Matériau isolant résistant à la température. Vérifier coefficient R isolant.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos ballon + Caractéristiques volume + Certificat coefficient R isolant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ballon_chauffage_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_ballon_sup").update!(
  titre: "Amélioration chauffage - Isolation ballon >500l - Wallonie",
  ordre_affichage: 32,
  icon_name: "thermometer-half",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"}
  }'),
  condition: "Isolation ballon stockage chauffage >500 litres. Matériau isolant coefficient résistance thermique R ≥ 1,50 m²K/W.",
  conseil: "Isolation renforcée pour gros volumes. Vérifier coefficient R isolant.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos ballon + Caractéristiques volume + Certificat coefficient R isolant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ballon_chauffage_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_circ_3logt").update!(
  titre: "Amélioration chauffage - Circulateur (max 3 logements) - Wallonie",
  ordre_affichage: 33,
  icon_name: "cog",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 84, "condition": "Max 3 logements"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 56, "condition": "Max 3 logements"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 42, "condition": "Max 3 logements"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 28, "condition": "Max 3 logements"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 14, "condition": "Max 3 logements"}
  }'),
  condition: "Installation de circulateurs à vitesse variable pour maximum 3 logements. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Circulateurs à vitesse variable classe A++ obligatoires. Modulation automatique selon les besoins du circuit de chauffage.",
  document: "Factures détaillées + fiche technique avec classe énergétique + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/circulateur_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_circ_4logt").update!(
  titre: "Amélioration chauffage - Circulateur (min 4 logements) - Wallonie",
  ordre_affichage: 34,
  icon_name: "cogs",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 456, "condition": "Min 4 logements"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 304, "condition": "Min 4 logements"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 228, "condition": "Min 4 logements"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 152, "condition": "Min 4 logements"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 76, "condition": "Min 4 logements"}
  }'),
  condition: "Installation de circulateurs à vitesse variable pour minimum 4 logements en habitat collectif. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation collective. Circulateurs à vitesse variable classe A++ avec régulation automatique selon les besoins du circuit de chauffage.",
  document: "Factures détaillées + fiche technique avec classe énergétique + annexe technique 6 complétée + attestation nombre de logements + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/circulateur_collectif_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_ballon_500").update!(
  titre: "Amélioration chauffage - Remplacement ballon ≤500l - Wallonie",
  ordre_affichage: 35,
  icon_name: "exchange-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 240, "condition": "Remplacement ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 160, "condition": "Remplacement ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 120, "condition": "Remplacement ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 80, "condition": "Remplacement ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 40, "condition": "Remplacement ≤500l"}
  }'),
  condition: "Remplacement d'un ballon de stockage de chauffage ≤500 litres par un modèle haute performance énergétique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Ballon de stockage haute performance énergétique obligatoire avec isolation renforcée. Respect des normes européennes en vigueur.",
  document: "Factures détaillées + attestation de dépose de l'ancien ballon + fiche technique du nouveau ballon avec performances énergétiques + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/remplacement_ballon_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_ballon_sup").update!(
  titre: "Amélioration chauffage - Remplacement ballon >500l - Wallonie",
  ordre_affichage: 36,
  icon_name: "exchange-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 408, "condition": "Remplacement >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 272, "condition": "Remplacement >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 204, "condition": "Remplacement >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 136, "condition": "Remplacement >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 68, "condition": "Remplacement >500l"}
  }'),
  condition: "Remplacement d'un ballon de stockage de chauffage >500 litres par un modèle haute performance énergétique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Ballon de stockage haute performance pour gros volumes avec isolation thermique renforcée. Respect des normes européennes en vigueur.",
  document: "Factures détaillées + attestation de dépose de l'ancien ballon + fiche technique du nouveau ballon avec performances énergétiques + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/remplacement_ballon_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_vannes_base").update!(
  titre: "Amélioration chauffage - minimum 5 vannes thermostatiques - Wallonie",
  ordre_affichage: 37,
  icon_name: "sliders-h",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Min 5 vannes"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Min 5 vannes"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Min 5 vannes"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Min 5 vannes"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Min 5 vannes"}
  }'),
  condition: "Installation de minimum 5 vannes thermostatiques de régulation avec régulation de température ambiante. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Vannes thermostatiques programmables recommandées pour une régulation optimale de la température ambiante. Installation sur radiateurs existants.",
  document: "Factures détaillées + photos avant/après installation + plan de situation des radiateurs équipés + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vannes_thermostatiques_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_vannes_sup").update!(
  titre: "Amélioration chauffage - supplémentaire aux 5 vannes thermostatiques de base - Wallonie",
  ordre_affichage: 38,
  icon_name: "plus-square",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_par_unite", "montant_unitaire": 24, "condition": "Vannes supplémentaires"},
    "wallonie_r2": {"type": "montant_par_unite", "montant_unitaire": 16, "condition": "Vannes supplémentaires"},
    "wallonie_r3": {"type": "montant_par_unite", "montant_unitaire": 12, "condition": "Vannes supplémentaires"},
    "wallonie_r4": {"type": "montant_par_unite", "montant_unitaire": 8, "condition": "Vannes supplémentaires"},
    "wallonie_r5": {"type": "montant_par_unite", "montant_unitaire": 4, "condition": "Vannes supplémentaires"}
  }'),
  condition: "Vannes thermostatiques de régulation supplémentaires au-delà des 5 de base. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Prime accordée pour chaque vanne supplémentaire au-delà du minimum requis de 5 vannes. Régulation de température ambiante obligatoire.",
  document: "Factures détaillées + décompte exact du nombre total de vannes installées + photos + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Nombre de vannes",
    "wallonie_r2": "Nombre de vannes",
    "wallonie_r3": "Nombre de vannes",
    "wallonie_r4": "Nombre de vannes",
    "wallonie_r5": "Nombre de vannes"
  }'),
  image: "images/vannes_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_thermostat").update!(
  titre: "Amélioration chauffage - Thermostat d'ambiance - Wallonie",
  ordre_affichage: 40,
  icon_name: "thermometer-three-quarters",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 96, "condition": "Thermostat programmable"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 64, "condition": "Thermostat programmable"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 48, "condition": "Thermostat programmable"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 32, "condition": "Thermostat programmable"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 16, "condition": "Thermostat programmable"}
  }'),
  condition: "Installation d'un thermostat d'ambiance programmable avec fonction d'arrêt automatique du producteur de chaleur et des circulateurs. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Thermostat programmable obligatoire avec capacité d'arrêt automatique des systèmes de production et circulation. Installation par professionnel certifié recommandée.",
  document: "Factures détaillées + fiche technique du thermostat + attestation de fonctionnalité d'arrêt automatique + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)
# === ECS (EAU CHAUDE SANITAIRE) ===


Prime.find_or_initialize_by(slug: "wallonie_ecs_ballon_500").update!(
  titre: "ECS - Remplacement ballon ≤500l - Wallonie",
  ordre_affichage: 41,
  icon_name: "water-tank",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 288, "condition": "Ballon ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 192, "condition": "Ballon ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 144, "condition": "Ballon ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 96, "condition": "Ballon ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 48, "condition": "Ballon ≤500l"}
  }'),
  condition: "Remplacement d'un réservoir de stockage pour l'eau chaude sanitaire ≤500l. Le réservoir ne doit PAS être équipé d'une résistance électrique. Le système doit permettre de prévenir le risque de légionellose et être muni d'un groupe de sécurité classique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation sans résistance électrique obligatoire. Système anti-légionellose et groupe de sécurité requis pour la conformité sanitaire.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du réservoir + attestation absence résistance électrique + certificat système anti-légionellose + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_ballon_sup").update!(
  titre: "ECS - Remplacement ballon >500l - Wallonie",
  ordre_affichage: 42,
  icon_name: "water-tank-large",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 432, "condition": "Ballon >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 288, "condition": "Ballon >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 216, "condition": "Ballon >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 144, "condition": "Ballon >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 72, "condition": "Ballon >500l"}
  }'),
  condition: "Remplacement d'un réservoir de stockage pour l'eau chaude sanitaire >500l. Le réservoir ne doit PAS être équipé d'une résistance électrique. Le système doit permettre de prévenir le risque de légionellose et être muni d'un groupe de sécurité classique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation sans résistance électrique obligatoire pour gros volumes. Système anti-légionellose et groupe de sécurité renforcés requis.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du réservoir + attestation absence résistance électrique + certificat système anti-légionellose + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_conduites_coll").update!(
  titre: "ECS - Isolation conduites boucle circulation (collective) - Wallonie",
  ordre_affichage: 43,
  icon_name: "pipe-isolation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Isolation conduites collective"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Isolation conduites collective"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Isolation conduites collective"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Isolation conduites collective"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Isolation conduites collective"}
  }'),
  condition: "Isolation des conduites d'une boucle de circulation d'eau chaude sanitaire et ses accessoires en installation collective. Le calorifugeage des conduites de la boucle de circulation d'eau chaude sanitaire et de ses accessoires doit répondre aux exigences de l'annexe C4 de l'Arrêté du Gouvernement wallon du 15 mai 2014. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Travaux exclusivement pour installation collective. Respect obligatoire des exigences annexe C4 pour le calorifugeage.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + rapport relatif au calorifugeage des tuyaux d'eau chaude selon l'annexe C4 rédigé par l'installateur + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_echangeur").update!(
  titre: "ECS - Isolation échangeur plaques externe - Wallonie",
  ordre_affichage: 44,
  icon_name: "heat-exchanger",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Échangeur plaques externe"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Échangeur plaques externe"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Échangeur plaques externe"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Échangeur plaques externe"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Échangeur plaques externe"}
  }'),
  condition: "Isolation d'un échangeur à plaques externe pour l'eau chaude sanitaire au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Matériau isolant haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire. Installation par professionnel qualifié recommandée.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_isol_ballon_500").update!(
  titre: "ECS - Isolation ballon ≤500l - Wallonie",
  ordre_affichage: 45,
  icon_name: "water-tank-insulation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Isolation ballon ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Isolation ballon ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Isolation ballon ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Isolation ballon ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Isolation ballon ≤500l"}
  }'),
  condition: "Isolation d'un ballon de stockage pour l'eau chaude sanitaire ≤500l au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Isolation thermique haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire. Amélioration significative de l'efficacité énergétique.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_isol_ballon_sup").update!(
  titre: "ECS - Isolation ballon >500l - Wallonie",
  ordre_affichage: 46,
  icon_name: "water-tank-insulation-large",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Isolation ballon >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Isolation ballon >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Isolation ballon >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Isolation ballon >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Isolation ballon >500l"}
  }'),
  condition: "Isolation d'un ballon de stockage pour l'eau chaude sanitaire >500l au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Isolation thermique haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire pour gros volumes. Économies d'énergie importantes.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
  échéances: "12 mois à partir de la date de facture de solde",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

puts "✅ #{Prime.where(region: 'wallonie').count} primes Wallonie créées avec succès"
