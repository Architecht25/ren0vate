# =====================================================
# PRIME F : Façades
# =====================================================

puts "🏠 Création des primes F - Façades..."

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
  conseil: "Combinez avec l'étude acoustique (A2) pour maximiser votre confort intérieur",
  document: "Attestation entrepreneur (générale + volet technique F6), factures détaillées (type/marque/modèle isolant, surface isolée, épaisseur), preuves paiement (extrait bancaire si ≥3000€), documents revenus si cat II/III, titre propriété, extrait cadastral. Demande sur IRISbox dans 12 mois après facture solde. Référentiel technique fiches 11-12 Code bonnes pratiques.",
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

puts "✅ Primes F (Façades) créées avec succès"
