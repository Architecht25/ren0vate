# =====================================================
# PRIME J : Chauffage & chauffe-eau
# =====================================================

puts "🔥 Création des primes J - Chauffage & chauffe-eau..."

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
      "condition": "Installation chauffe-eau alimenté par pompe à chaleur"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 1500,
      "condition": "Installation chauffe-eau alimenté par pompe à chaleur"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 1600,
      "condition": "Installation chauffe-eau alimenté par pompe à chaleur"
    }
  }'),
  condition: "Système de production d'eau chaude sanitaire basé sur une pompe à chaleur dédiée",
  conseil: "Vérifie la compatibilité avec le système de chauffage existant et l'isolation du ballon",
  document: "Attestation entrepreneur (informations générales + volet technique J9). Factures détaillées (marque, modèle, n° série, puissance installation). Preuves de paiement. Compteurs électriques de passage si requis.",
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

puts "✅ Primes J (Chauffage & chauffe-eau) créées avec succès"
