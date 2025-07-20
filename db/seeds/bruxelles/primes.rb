# Primes RENOLUTION pour la région de Bruxelles-Capitale (2024)
# Système à 3 catégories avec montants dégressifs selon les revenus

puts "🏢 Création des primes Bruxelles RENOLUTION..."

# Nettoyage des primes Bruxelles existantes
Prime.where(region: "bruxelles").delete_all

# =====================================================
# PRIME A : Services et études préalables
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_maison").update!(
  titre: "Audit énergétique (maison) - Bruxelles",
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
  condition: "Audit énergétique pour maison individuelle selon normes Renolution",
  conseil: "Étape préalable recommandée avant travaux de rénovation énergétique",
  document: "Rapport d'audit + facture auditeur agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_batiment").update!(
  titre: "Audit énergétique (bâtiment complet) - Bruxelles",
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
  condition: "Audit énergétique pour bâtiment complet selon normes Renolution",
  conseil: "Nécessaire pour les bâtiments collectifs et copropriétés",
  document: "Rapport d'audit + facture auditeur agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_batiment_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_materiaux").update!(
  titre: "Étude matériaux - Bruxelles",
  ordre_affichage: 3,
  icon_name: "tools",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 200, "condition": "Étude préalable des matériaux"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 200, "condition": "Étude préalable des matériaux"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 200, "condition": "Étude préalable des matériaux"}
  }'),
  condition: "Étude préalable des matériaux selon normes Renolution",
  conseil: "Recommandée pour identifier les matériaux existants et optimiser le choix",
  document: "Rapport d'étude + facture expert agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/etude_materiaux_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME B : Installations de chantier
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_protection_echafaudages").update!(
  titre: "Protection/échafaudages - Bruxelles",
  ordre_affichage: 4,
  icon_name: "ladder",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 40, "condition": "Protection et échafaudages résidentiels"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "Protection et échafaudages résidentiels"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 20, "condition": "Protection et échafaudages résidentiels"}
  }'),
  condition: "Installation de protection et échafaudages pour travaux résidentiels",
  conseil: "Indispensable pour la sécurité lors de travaux en hauteur",
  document: "Facture détaillée + métré des surfaces",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/echafaudage_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME C : Gros-œuvre & gestion de l'eau
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_recuperation_eau_pluie").update!(
  titre: "Récupération eau de pluie - Bruxelles",
  ordre_affichage: 5,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 1100, "condition": "Installation récupération eau de pluie"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 750, "condition": "Installation récupération eau de pluie"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 500, "condition": "Installation récupération eau de pluie"}
  }'),
  condition: "Installation complète de récupération d'eau de pluie",
  conseil: "Permet de réduire la consommation d'eau potable et gérer les eaux pluviales",
  document: "Facture installation + plan technique",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/eau_pluie_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_demolition_permeabilisation").update!(
  titre: "Démolition perméabilisation - Bruxelles",
  ordre_affichage: 6,
  icon_name: "water",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 80, "condition": "Démolition pour perméabilisation du sol"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 75, "condition": "Démolition pour perméabilisation du sol"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 60, "condition": "Démolition pour perméabilisation du sol"}
  }'),
  condition: "Démolition d'éléments pour améliorer la perméabilisation du sol",
  conseil: "Améliore la gestion des eaux de pluie et réduit le ruissellement",
  document: "Facture détaillée + plan des surfaces démolies + preuve perméabilisation",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/demolition_permeabilisation_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME E : Toiture
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_toiture_etancheite").update!(
  titre: "Isolation toiture (isolation/étanchéité) - Bruxelles",
  ordre_affichage: 7,
  icon_name: "house-up",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 80, "condition": "Isolation et étanchéité de toiture"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 70, "condition": "Isolation et étanchéité de toiture"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 60, "condition": "Isolation et étanchéité de toiture"}
  }'),
  condition: "Isolation thermique et étanchéité de toiture selon normes",
  conseil: "Combine isolation et étanchéité pour une performance optimale",
  document: "Facture détaillée + certificat de performance + plan d'exécution",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_toiture_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_toiture").update!(
  titre: "Isolation thermique toiture - Bruxelles",
  ordre_affichage: 8,
  icon_name: "thermometer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 55, "condition": "Isolation thermique de toiture"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 45, "condition": "Isolation thermique de toiture"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 35, "condition": "Isolation thermique de toiture"}
  }'),
  condition: "Isolation thermique de toiture selon normes de performance",
  conseil: "Améliore significativement l'efficacité énergétique du bâtiment",
  document: "Facture + certificat de résistance thermique + attestation pose",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_thermique_toiture_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_toiture_vegetale").update!(
  titre: "Toiture végétale - Bruxelles",
  ordre_affichage: 9,
  icon_name: "tree",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 40, "condition": "Installation de toiture végétale"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "Installation de toiture végétale"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 20, "condition": "Installation de toiture végétale"}
  }'),
  condition: "Installation de toiture végétale extensive ou intensive",
  conseil: "Améliore l'isolation, la gestion des eaux pluviales et la biodiversité",
  document: "Facture + plan d'exécution + garantie étanchéité + plan plantation",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/toiture_vegetale_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME F : Façades
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_interieure_facade").update!(
  titre: "Isolation intérieure façade - Bruxelles",
  ordre_affichage: 10,
  icon_name: "house",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 45, "condition": "Isolation intérieure des façades"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 40, "condition": "Isolation intérieure des façades"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 35, "condition": "Isolation intérieure des façades"}
  }'),
  condition: "Isolation intérieure des murs de façade selon normes de performance",
  conseil: "Solution pratique quand l'isolation extérieure n'est pas possible",
  document: "Facture + certificat de résistance thermique + plan de pose",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_interieure_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_exterieure_facade").update!(
  titre: "Isolation extérieure façade - Bruxelles",
  ordre_affichage: 11,
  icon_name: "house-door",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 90, "condition": "Isolation extérieure des façades"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 70, "condition": "Isolation extérieure des façades"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 50, "condition": "Isolation extérieure des façades"}
  }'),
  condition: "Isolation extérieure des murs de façade avec finition",
  conseil: "Solution optimale pour performance thermique et suppression ponts thermiques",
  document: "Facture + certificat + plan architectural + autorisation urbanisme si requis",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_exterieure_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_coulisse").update!(
  titre: "Isolation en coulisse - Bruxelles",
  ordre_affichage: 12,
  icon_name: "layers",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 30, "condition": "Isolation en coulisse des murs"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 25, "condition": "Isolation en coulisse des murs"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 20, "condition": "Isolation en coulisse des murs"}
  }'),
  condition: "Isolation par injection ou insufflation dans coulisse existante",
  conseil: "Solution économique pour murs creux sans démolition",
  document: "Facture + rapport d'inspection coulisse + certificat matériau",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_coulisse_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_embellissement_facade_avant").update!(
  titre: "Embellissement façade avant - Bruxelles",
  ordre_affichage: 13,
  icon_name: "brush",
  unite: "€/m² (+750€/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"}
  }'),
  condition: "Embellissement de façade avant visible depuis l'espace public",
  conseil: "Améliore l'esthétique urbaine, bonus forfaitaire par logement",
  document: "Facture + photos avant/après + plan façade + autorisation si requis",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m² + nb logements",
    "bruxelles_cat2": "Surface en m² + nb logements",
    "bruxelles_cat3": "Surface en m² + nb logements"
  }'),
  image: "images/embellissement_facade_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_facades_arriere_laterales").update!(
  titre: "Façades arrière/latérales - Bruxelles",
  ordre_affichage: 14,
  icon_name: "house-gear",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 40, "condition": "Rénovation façades arrière et latérales"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "Rénovation façades arrière et latérales"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 20, "condition": "Rénovation façades arrière et latérales"}
  }'),
  condition: "Rénovation des façades arrière et latérales non visibles depuis l'espace public",
  conseil: "Permet d'améliorer l'esthétique et l'étanchéité de toutes les façades",
  document: "Facture détaillée + photos avant/après + plan des façades",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/facades_arriere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME G : Portes & fenêtres
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_bois").update!(
  titre: "Remplacement fenêtres (bois) - Bruxelles",
  ordre_affichage: 15,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 140, "condition": "Remplacement fenêtres en bois performantes"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 120, "condition": "Remplacement fenêtres en bois performantes"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 100, "condition": "Remplacement fenêtres en bois performantes"}
  }'),
  condition: "Remplacement par fenêtres bois haute performance énergétique",
  conseil: "Matériau écologique avec excellentes performances thermiques",
  document: "Facture + certificat de performance + attestation pose + métrés",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/fenetres_bois_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_pvc_alu").update!(
  titre: "Remplacement fenêtres (PVC/alu) - Bruxelles",
  ordre_affichage: 16,
  icon_name: "window-desktop",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 55, "condition": "Remplacement fenêtres PVC ou aluminium"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "condition": "Remplacement fenêtres PVC ou aluminium"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 40, "condition": "Remplacement fenêtres PVC ou aluminium"}
  }'),
  condition: "Remplacement par fenêtres PVC ou aluminium haute performance",
  conseil: "Solution durable avec bon rapport qualité-prix",
  document: "Facture + certificat de performance + attestation pose + métrés",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/fenetres_pvc_alu_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_fenetres").update!(
  titre: "Réparation fenêtres - Bruxelles",
  ordre_affichage: 17,
  icon_name: "tools",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 260, "condition": "Réparation fenêtres existantes"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 220, "condition": "Réparation fenêtres existantes"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 130, "condition": "Réparation fenêtres existantes"}
  }'),
  condition: "Réparation de fenêtres existantes pour améliorer leurs performances",
  conseil: "Alternative économique au remplacement pour fenêtres de qualité",
  document: "Facture détaillée + rapport d'état avant/après + garantie travaux",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/reparation_fenetres_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_portes").update!(
  titre: "Réparation portes - Bruxelles",
  ordre_affichage: 18,
  icon_name: "door-closed",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 180, "condition": "Réparation portes existantes"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 150, "condition": "Réparation portes existantes"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "condition": "Réparation portes existantes"}
  }'),
  condition: "Réparation de portes existantes pour améliorer isolation et sécurité",
  conseil: "Permet de conserver le patrimoine architectural tout en améliorant les performances",
  document: "Facture détaillée + rapport d'état avant/après + garantie travaux",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/reparation_portes_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME H : Sols & planchers
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_sols").update!(
  titre: "Isolation thermique sols - Bruxelles",
  ordre_affichage: 19,
  icon_name: "square",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 45, "condition": "Isolation thermique sols et planchers"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 40, "condition": "Isolation thermique sols et planchers"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 35, "condition": "Isolation thermique sols et planchers"}
  }'),
  condition: "Isolation thermique des sols et planchers selon normes de performance",
  conseil: "Réduit les pertes de chaleur par le sol et améliore le confort",
  document: "Facture + certificat de résistance thermique + plan de pose",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_sols_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_acoustique_sols").update!(
  titre: "Isolation acoustique sols - Bruxelles",
  ordre_affichage: 20,
  icon_name: "volume-mute",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 90, "condition": "Isolation acoustique sols et planchers"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 60, "condition": "Isolation acoustique sols et planchers"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 30, "condition": "Isolation acoustique sols et planchers"}
  }'),
  condition: "Isolation acoustique des sols et planchers pour réduire les nuisances sonores",
  conseil: "Améliore significativement le confort acoustique entre logements",
  document: "Facture + certificat de performance acoustique + mesures avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_acoustique_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME I : Aménagement intérieur
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_escaliers").update!(
  titre: "Escaliers - Bruxelles",
  ordre_affichage: 21,
  icon_name: "ladder",
  unite: "€/marche",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 80, "condition": "Rénovation ou installation d\'escaliers"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 50, "condition": "Rénovation ou installation d\'escaliers"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 30, "condition": "Rénovation ou installation d\'escaliers"}
  }'),
  condition: "Rénovation ou installation d'escaliers intérieurs ou extérieurs",
  conseil: "Améliore la sécurité et l'accessibilité du logement",
  document: "Facture détaillée + plan d'exécution + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de marches",
    "bruxelles_cat2": "Nombre de marches",
    "bruxelles_cat3": "Nombre de marches"
  }'),
  image: "images/escaliers_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_emplacement_velo").update!(
  titre: "Emplacement vélo - Bruxelles",
  ordre_affichage: 22,
  icon_name: "bicycle",
  unite: "€/vélo (max 2/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacement vélo (max 2 par logement)"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacement vélo (max 2 par logement)"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacement vélo (max 2 par logement)"}
  }'),
  condition: "Aménagement d'emplacement sécurisé pour vélos",
  conseil: "Encourage la mobilité douce et répond aux obligations urbanistiques",
  document: "Facture + plan d'aménagement + photos de réalisation",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de vélos (max 2/logement)",
    "bruxelles_cat2": "Nombre de vélos (max 2/logement)",
    "bruxelles_cat3": "Nombre de vélos (max 2/logement)"
  }'),
  image: "images/emplacement_velo_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_amenagement_pmr").update!(
  titre: "Aménagement PMR - Bruxelles",
  ordre_affichage: 23,
  icon_name: "universal-access",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 7500, "condition": "Aménagement pour personne à mobilité réduite"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 7500, "condition": "Aménagement pour personne à mobilité réduite"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 7500, "condition": "Aménagement pour personne à mobilité réduite"}
  }'),
  condition: "Aménagement pour personne à mobilité réduite selon normes d'accessibilité",
  conseil: "Améliore l'accessibilité et maintien à domicile, montant forfaitaire élevé",
  document: "Facture + plan d'aménagement + certificat de conformité accessibilité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/amenagement_pmr_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME J : Chauffage & chauffe-eau
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_chaudiere_100kw").update!(
  titre: "Chaudière ≤ 100 kW - Bruxelles",
  ordre_affichage: 24,
  icon_name: "fire",
  unite: "€/chaudière",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 1200, "condition": "Installation chaudière jusqu\'à 100 kW"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 800, "condition": "Installation chaudière jusqu\'à 100 kW"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 700, "condition": "Installation chaudière jusqu\'à 100 kW"}
  }'),
  condition: "Installation de chaudière haute performance jusqu'à 100 kW",
  conseil: "Améliore l'efficacité énergétique du chauffage, choisir label énergétique élevé",
  document: "Facture + fiche technique + certificat d'installation + test étanchéité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par chaudière",
    "bruxelles_cat2": "Forfaitaire - par chaudière",
    "bruxelles_cat3": "Forfaitaire - par chaudière"
  }'),
  image: "images/chaudiere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_controle_chaudiere").update!(
  titre: "Contrôle chaudière - Bruxelles",
  ordre_affichage: 25,
  icon_name: "gear",
  unite: "€/contrôle (max 2/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 100, "limite": 2, "condition": "Contrôle et entretien chaudière (max 2 par logement)"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 100, "limite": 2, "condition": "Contrôle et entretien chaudière (max 2 par logement)"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 100, "limite": 2, "condition": "Contrôle et entretien chaudière (max 2 par logement)"}
  }'),
  condition: "Contrôle périodique et entretien de chaudière par professionnel agréé",
  conseil: "Obligatoire pour la sécurité et l'efficacité, maximum 2 contrôles par logement",
  document: "Facture + rapport de contrôle + certificat de conformité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de contrôles (max 2/logement)",
    "bruxelles_cat2": "Nombre de contrôles (max 2/logement)",
    "bruxelles_cat3": "Nombre de contrôles (max 2/logement)"
  }'),
  image: "images/controle_chaudiere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME K : Sanitaires
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_appareil_sanitaire").update!(
  titre: "Appareil sanitaire - Bruxelles",
  ordre_affichage: 26,
  icon_name: "droplet-half",
  unite: "€/unité",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 540, "condition": "Installation d\'appareils sanitaires"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 340, "condition": "Installation d\'appareils sanitaires"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 200, "condition": "Installation d\'appareils sanitaires"}
  }'),
  condition: "Installation d'appareils sanitaires performants (WC, lavabo, douche, etc.)",
  conseil: "Améliore le confort et l'hygiène, choisir équipements économes en eau",
  document: "Facture détaillée + fiches techniques + certificat d'installation",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre d\'appareils",
    "bruxelles_cat2": "Nombre d\'appareils",
    "bruxelles_cat3": "Nombre d\'appareils"
  }'),
  image: "images/sanitaire_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME L : Électricité & gaz
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_mise_normes_electricite_gaz").update!(
  titre: "Mise aux normes électricité/gaz - Bruxelles",
  ordre_affichage: 27,
  icon_name: "lightning",
  unite: "% du coût",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 70, "condition": "Mise aux normes installations électriques et gaz"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 50, "condition": "Mise aux normes installations électriques et gaz"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 30, "condition": "Mise aux normes installations électriques et gaz"}
  }'),
  condition: "Mise aux normes des installations électriques et gaz selon réglementation",
  conseil: "Obligatoire pour la sécurité, intervention par professionnel agréé requise",
  document: "Facture + certificat de conformité + rapport de contrôle + PV réception",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Coût total des travaux",
    "bruxelles_cat2": "Coût total des travaux",
    "bruxelles_cat3": "Coût total des travaux"
  }'),
  image: "images/electricite_gaz_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

# =====================================================
# PRIME M : Ventilation
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_c").update!(
  titre: "Ventilation système C - Bruxelles",
  ordre_affichage: 28,
  icon_name: "wind",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 2230, "condition": "Installation ventilation mécanique système C"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 1950, "condition": "Installation ventilation mécanique système C"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 1550, "condition": "Installation ventilation mécanique système C"}
  }'),
  condition: "Installation de ventilation mécanique système C (extraction mécanique)",
  conseil: "Améliore la qualité de l'air intérieur et évacue l'humidité",
  document: "Facture + plan de ventilation + certificat de performance + test débit",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/ventilation_c_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_d").update!(
  titre: "Ventilation système D (VMC double flux) - Bruxelles",
  ordre_affichage: 29,
  icon_name: "arrow-repeat",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 4300, "condition": "Installation VMC double flux (système D)"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 3750, "condition": "Installation VMC double flux (système D)"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 3000, "condition": "Installation VMC double flux (système D)"}
  }'),
  condition: "Installation VMC double flux avec récupération de chaleur",
  conseil: "Solution haut de gamme pour qualité d'air optimale et économies d'énergie",
  document: "Facture + plan ventilation + certificat performance + mesure rendement récupération",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/vmc_double_flux_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1")&.id
)

puts "✅ #{Prime.where(region: 'bruxelles').count} primes Bruxelles RENOLUTION créées avec succès"
