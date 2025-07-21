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
  document: "Rapport d\'audit + facture auditeur agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  document: "Rapport d\'audit + facture auditeur agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_batiment_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  document: "Rapport d\'étude + facture expert agréé",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/etude_materiaux_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_totem").update!(
  titre: "Étude TOTEM - Bruxelles",
  ordre_affichage: 4,
  icon_name: "activity",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 200, "condition": "Étude via la plateforme TOTEM réalisée avant travaux"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 200, "condition": "Étude via la plateforme TOTEM réalisée avant travaux"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 200, "condition": "Étude via la plateforme TOTEM réalisée avant travaux"}
  }'),
  condition: "L\'étude doit être menée via la plateforme TOTEM (Tool to Optimise the Total Environmental impact of Materials)",
  conseil: "L\'étude permet d'objectiver l'impact environnemental des matériaux avant chantier",
  document: "Rapport d\'étude TOTEM + facture du prestataire",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait - 1 si réalisée, 0 sinon",
    "bruxelles_cat2": "Forfait - 1 si réalisée, 0 sinon",
    "bruxelles_cat3": "Forfait - 1 si réalisée, 0 sinon"
  }'),
  image: "images/etude_totem.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME B : Installations de chantier
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_protection_echafaudages").update!(
  titre: "Protection/échafaudages - Bruxelles",
  ordre_affichage: 5,
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME C : Gros-œuvre & gestion de l'eau
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_recuperation_eau_pluie").update!(
  titre: "Récupération eau de pluie - Bruxelles",
  ordre_affichage: 6,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 1100, "condition": "Installation récupération eau de pluie"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 750, "condition": "Installation récupération eau de pluie"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 500, "condition": "Installation récupération eau de pluie"}
  }'),
  condition: "Installation complète de récupération d\'eau de pluie",
  conseil: "Permet de réduire la consommation d\'eau potable et gérer les eaux pluviales",
  document: "Facture installation + plan technique",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par logement",
    "bruxelles_cat2": "Forfaitaire - par logement",
    "bruxelles_cat3": "Forfaitaire - par logement"
  }'),
  image: "images/eau_pluie_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_demolition_permeabilisation").update!(
  titre: "Démolition perméabilisation - Bruxelles",
  ordre_affichage: 7,
  icon_name: "water",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 80, "condition": "Démolition pour perméabilisation du sol"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 75, "condition": "Démolition pour perméabilisation du sol"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 60, "condition": "Démolition pour perméabilisation du sol"}
  }'),
  condition: "Démolition d\'éléments pour améliorer la perméabilisation du sol",
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME E : Toiture
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_toiture_etancheite").update!(
  titre: "Isolation toiture (isolation/étanchéité) - Bruxelles",
  ordre_affichage: 8,
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
  document: "Facture détaillée + certificat de performance + plan d\'exécution",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_toiture_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_toiture").update!(
  titre: "Isolation thermique toiture - Bruxelles",
  ordre_affichage: 9,
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
  conseil: "Améliore significativement l\'efficacité énergétique du bâtiment",
  document: "Facture + certificat de résistance thermique + attestation pose",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_thermique_toiture_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_toiture_vegetale").update!(
  titre: "Toiture végétale - Bruxelles",
  ordre_affichage: 10,
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
  conseil: "Améliore l\'isolation, la gestion des eaux pluviales et la biodiversité",
  document: "Facture + plan d\'exécution + garantie étanchéité + plan plantation",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/toiture_vegetale_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME F : Façades
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_isolation_interieure_facade").update!(
  titre: "Isolation intérieure façade - Bruxelles",
  ordre_affichage: 11,
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
  conseil: "Solution pratique quand l\'isolation extérieure n'est pas possible",
  document: "Facture + certificat de résistance thermique + plan de pose",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_interieure_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_exterieure_facade").update!(
  titre: "Isolation extérieure façade - Bruxelles",
  ordre_affichage: 12,
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_coulisse").update!(
  titre: "Isolation en coulisse - Bruxelles",
  ordre_affichage: 13,
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
  document: "Facture + rapport d\'inspection coulisse + certificat matériau",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/isolation_coulisse_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_embellissement_facade_avant").update!(
  titre: "Embellissement façade avant - Bruxelles",
  ordre_affichage: 14,
  icon_name: "brush",
  unite: "€/m² (+750€/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 50, "bonus_fixe": 750, "condition": "Embellissement façade avant + bonus logement"}
  }'),
  condition: "Embellissement de façade avant visible depuis l\'espace public",
  conseil: "Améliore l\'esthétique urbaine, bonus forfaitaire par logement",
  document: "Facture + photos avant/après + plan façade + autorisation si requis",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m² + nb logements",
    "bruxelles_cat2": "Surface en m² + nb logements",
    "bruxelles_cat3": "Surface en m² + nb logements"
  }'),
  image: "images/embellissement_facade_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  condition: "Rénovation des façades arrière et latérales non visibles depuis l\'espace public",
  conseil: "Permet d\'améliorer l\'esthétique et l'étanchéité de toutes les façades",
  document: "Facture détaillée + photos avant/après + plan des façades",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/facades_arriere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  document: "Facture détaillée + rapport d\'état avant/après + garantie travaux",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/reparation_fenetres_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  document: "Facture détaillée + rapport d\'état avant/après + garantie travaux",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m²",
    "bruxelles_cat2": "Surface en m²",
    "bruxelles_cat3": "Surface en m²"
  }'),
  image: "images/reparation_portes_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  condition: "Rénovation ou installation d\'escaliers intérieurs ou extérieurs",
  conseil: "Améliore la sécurité et l'accessibilité du logement",
  document: "Facture détaillée + plan d\'exécution + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de marches",
    "bruxelles_cat2": "Nombre de marches",
    "bruxelles_cat3": "Nombre de marches"
  }'),
  image: "images/escaliers_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  condition: "Installation de chaudière haute performance jusqu\'à 100 kW",
  conseil: "Améliore l\'efficacité énergétique du chauffage, choisir label énergétique élevé",
  document: "Facture + fiche technique + certificat d'installation + test étanchéité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - par chaudière",
    "bruxelles_cat2": "Forfaitaire - par chaudière",
    "bruxelles_cat3": "Forfaitaire - par chaudière"
  }'),
  image: "images/chaudiere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  conseil: "Obligatoire pour la sécurité et l\'efficacité, maximum 2 contrôles par logement",
  document: "Facture + rapport de contrôle + certificat de conformité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de contrôles (max 2/logement)",
    "bruxelles_cat2": "Nombre de contrôles (max 2/logement)",
    "bruxelles_cat3": "Nombre de contrôles (max 2/logement)"
  }'),
  image: "images/controle_chaudiere_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  condition: "Installation d\'appareils sanitaires performants (WC, lavabo, douche, etc.)",
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
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
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_suivi_professionnel").update!(
  titre: "Suivi architecte / ingénieur stabilité / expert façade - Bruxelles",
  ordre_affichage: 30,
  icon_name: "briefcase",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "Montant basé sur les honoraires liés à la mission de suivi"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "Montant basé sur les honoraires liés à la mission de suivi"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "Montant basé sur les honoraires liés à la mission de suivi"
    }
  }'),
  condition: "Uniquement si un professionnel reconnu assure le suivi technique des travaux de rénovation",
  conseil: "Faites appel à un architecte, ingénieur ou expert façade pour bénéficier d\'un accompagnement technique reconnu et de la prime",
  document: "Contrat ou convention + facture du professionnel",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage des honoraires - ex : 8%",
    "bruxelles_cat2": "Pourcentage des honoraires - ex : 2%",
    "bruxelles_cat3": "Pourcentage des honoraires - ex : 2%"
  }'),
  image: "images/suivi_professionnel.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_structure_portante").update!(
  titre: "Structures portantes - Bruxelles",
  ordre_affichage: 31,
  icon_name: "columns",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 70,
      "condition": "Sur base du montant facturé pour les travaux liés aux structures portantes"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "Sur base du montant facturé pour les travaux liés aux structures portantes"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "Sur base du montant facturé pour les travaux liés aux structures portantes"
    }
  }'),
  condition: "Travaux touchant aux murs porteurs, planchers portants, structures métalliques ou en béton, nécessaires pour stabiliser ou modifier le bâtiment",
  conseil: "Faites réaliser une étude préalable par un professionnel pour vérifier l'impact structurel",
  document: "Devis + facture + preuve de l'intervention structurelle (ex : plans, photos, rapports)",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage du montant total - ex : 70%",
    "bruxelles_cat2": "Pourcentage du montant total - ex : 50%",
    "bruxelles_cat3": "Pourcentage du montant total - ex : 30%"
  }'),
  image: "images/structure_portante.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_gestion_egouts").update!(
  titre: "Gestion des égouts - Bruxelles",
  ordre_affichage: 32,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "grille_variable",
      "grille": {
        "mètre de tuyauterie": 45,
        "chambre de visite": 210,
        "avaloir": 70,
        "raccordement égout": 440
      },
      "condition": "Montants maximaux pour les différents éléments du système de canalisation"
    },
    "bruxelles_cat2": {
      "type": "grille_variable",
      "grille": {
        "mètre de tuyauterie": 35,
        "chambre de visite": 160,
        "avaloir": 50,
        "raccordement égout": 330
      },
      "condition": "Montants maximaux pour les différents éléments du système de canalisation"
    },
    "bruxelles_cat3": {
      "type": "grille_variable",
      "grille": {
        "mètre de tuyauterie": 25,
        "chambre de visite": 120,
        "avaloir": 25,
        "raccordement égout": 165
      },
      "condition": "Montants maximaux pour les différents éléments du système de canalisation"
    }
  }'),
  condition: "Prime octroyée pour la réfection, la séparation ou le raccordement conforme à l'égouttage public",
  conseil: "Vérifiez auprès de Vivaqua si un séparateur ou une mise aux normes est exigée",
  document: "Factures détaillées + plan de l'égouttage + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Indiquer le nombre de mètres, chambres, avaloirs, etc.",
    "bruxelles_cat2": "Indiquer le nombre de mètres, chambres, avaloirs, etc.",
    "bruxelles_cat3": "Indiquer le nombre de mètres, chambres, avaloirs, etc."
  }'),
  image: "images/gestion_egouts.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_traitement_humidite_sol").update!(
  titre: "Traitement de l'humidité du sol - Bruxelles",
  ordre_affichage: 33,
  icon_name: "waves",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 80,
      "condition": "Traitement contre les remontées capillaires, humidité ascensionnelle ou infiltration par le sol"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "Traitement contre les remontées capillaires, humidité ascensionnelle ou infiltration par le sol"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "Traitement contre les remontées capillaires, humidité ascensionnelle ou infiltration par le sol"
    }
  }'),
  condition: "Travaux de traitement de l'humidité d'origine souterraine, justifiés par un diagnostic ou des signes visibles",
  conseil: "Un diagnostic préalable par un professionnel est vivement recommandé avant d'engager les travaux",
  document: "Rapport ou photos + facture détaillée des travaux",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage du montant total - ex : 80%",
    "bruxelles_cat2": "Pourcentage du montant total - ex : 50%",
    "bruxelles_cat3": "Pourcentage du montant total - ex : 30%"
  }'),
  image: "images/humidite_sol.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_traitement_fongique_insectes").update!(
  titre: "Traitement champignons / moisissures / insectes xylophages - Bruxelles",
  ordre_affichage: 34,
  icon_name: "bug",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 80,
      "condition": "Traitement ciblé contre les moisissures, champignons (ex. mérule) ou insectes xylophages (ex. capricornes, vrillettes)"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "Traitement ciblé contre les moisissures, champignons (ex. mérule) ou insectes xylophages (ex. capricornes, vrillettes)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "Traitement ciblé contre les moisissures, champignons (ex. mérule) ou insectes xylophages (ex. capricornes, vrillettes)"
    }
  }'),
  condition: "Traitement chimique ou thermique appliqué aux zones contaminées ou menacées, à l'intérieur du bâtiment",
  conseil: "Un diagnostic professionnel est conseillé pour confirmer la présence de pathologies biologiques",
  document: "Rapport ou photos + facture descriptive précisant les zones et techniques utilisées",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage du montant total - ex : 80%",
    "bruxelles_cat2": "Pourcentage du montant total - ex : 50%",
    "bruxelles_cat3": "Pourcentage du montant total - ex : 30%"
  }'),
  image: "images/traitement_fongique.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_structure_toiture").update!(
  titre: "Structure de la toiture - Bruxelles",
  ordre_affichage: 35,
  icon_name: "layers",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "Travaux de réparation ou remplacement de la structure porteuse de la toiture"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 40,
      "condition": "Travaux de réparation ou remplacement de la structure porteuse de la toiture"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "Travaux de réparation ou remplacement de la structure porteuse de la toiture"
    }
  }'),
  condition: "Intervention sur les éléments porteurs de la toiture, comme les chevrons, poutres ou fermes, en lien avec une rénovation ou consolidation",
  conseil: "Vérifiez si une intervention sur la structure est requise avant d'isoler ou réétanchéifier la toiture",
  document: "Facture détaillée + photos ou plans de la structure rénovée",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage du montant total - ex : 50%",
    "bruxelles_cat2": "Pourcentage du montant total - ex : 40%",
    "bruxelles_cat3": "Pourcentage du montant total - ex : 30%"
  }'),
  image: "images/structure_toiture.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_couverture_etancheite_toiture").update!(
  titre: "Couverture et étanchéité de la toiture - Bruxelles",
  ordre_affichage: 36,
  icon_name: "droplet",
  unite: "€/m² (max 100m²)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 50,
      "plafond_m2": 100,
      "condition": "Travaux d\'étanchéité ou remplacement complet de la couverture de toiture"
    },
    "bruxelles_cat2": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 40,
      "plafond_m2": 100,
      "condition": "Travaux d\'étanchéité ou remplacement complet de la couverture de toiture"
    },
    "bruxelles_cat3": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 30,
      "plafond_m2": 100,
      "condition": "Travaux d\'étanchéité ou remplacement complet de la couverture de toiture"
    }
  }'),
  condition: "Remplacement ou rénovation complète de la couverture et/ou de l'étanchéité d\'une toiture inclinée ou plate",
  conseil: "Cette prime peut être combinée avec les primes isolation ou structure de toiture",
  document: "Facture avec surface précisée + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface (en m²) – max 100 m²",
    "bruxelles_cat2": "Surface (en m²) – max 100 m²",
    "bruxelles_cat3": "Surface (en m²) – max 100 m²"
  }'),
  image: "images/couverture_toiture.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_accessoires_toiture").update!(
  titre: "Accessoires de toiture - Bruxelles",
  ordre_affichage: 37,
  icon_name: "wind",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "Accessoires liés à la toiture : coupoles, lanterneaux, costières, abergements, etc."
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 40,
      "condition": "Accessoires liés à la toiture : coupoles, lanterneaux, costières, abergements, etc."
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "Accessoires liés à la toiture : coupoles, lanterneaux, costières, abergements, etc."
    }
  }'),
  condition: "Éléments complémentaires à la toiture permettant l'éclairage naturel, la ventilation ou l'accès, mais hors couverture ou isolation",
  conseil: "Peut être combiné avec les primes toiture, mais doit figurer comme ligne distincte dans la facture",
  document: "Facture détaillée précisant la nature et la localisation des accessoires",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage du montant total - ex : 50%",
    "bruxelles_cat2": "Pourcentage du montant total - ex : 40%",
    "bruxelles_cat3": "Pourcentage du montant total - ex : 30%"
  }'),
  image: "images/accessoires_toiture.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bardage_facade").update!(
  titre: "Bardage de façade - Bruxelles",
  ordre_affichage: 38,
  icon_name: "wall",
  unite: "€/m² (max 100m²)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 80,
      "plafond_m2": 100,
      "condition": "Pose d\'un bardage extérieur neuf (bois, métal, fibre-ciment...) en complément ou non d\'une isolation"
    },
    "bruxelles_cat2": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 60,
      "plafond_m2": 100,
      "condition": "Pose d\'un bardage extérieur neuf (bois, métal, fibre-ciment...) en complément ou non d\'une isolation"
    },
    "bruxelles_cat3": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 40,
      "plafond_m2": 100,
      "condition": "Pose d\'un bardage extérieur neuf (bois, métal, fibre-ciment...) en complément ou non d\'une isolation"
    }
  }'),
  condition: "Travaux de recouvrement extérieur des façades à l'aide d\'un bardage neuf, ventilé et durable",
  conseil: "Le bardage peut améliorer l'aspect esthétique et protéger la façade tout en renforçant l\'isolation",
  document: "Facture mentionnant le type de matériau + surface + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m² – max 100 m²",
    "bruxelles_cat2": "Surface en m² – max 100 m²",
    "bruxelles_cat3": "Surface en m² – max 100 m²"
  }'),
  image: "images/bardage_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_enduit_facade").update!(
  titre: "Enduit de façade - Bruxelles",
  ordre_affichage: 39,
  icon_name: "paintbrush",
  unite: "€/m² (max 100m²)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 70,
      "plafond_m2": 100,
      "condition": "Application d\'un enduit neuf sur la façade, en complément ou non d\'une isolation extérieure"
    },
    "bruxelles_cat2": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 50,
      "plafond_m2": 100,
      "condition": "Application d\'un enduit neuf sur la façade, en complément ou non d\'une isolation extérieure"
    },
    "bruxelles_cat3": {
      "type": "montant_m2_et_limite",
      "montant_par_m2": 30,
      "plafond_m2": 100,
      "condition": "Application d\'un enduit neuf sur la façade, en complément ou non d\'une isolation extérieure"
    }
  }'),
  condition: "Travaux de finition extérieure par enduit minéral ou organique, en une ou plusieurs couches, appliqué manuellement ou mécaniquement",
  conseil: "Un bon enduit protège contre les intempéries et valorise esthétiquement le bâtiment",
  document: "Facture mentionnant surface, type d'enduit, technique d'application + photos avant/après",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m² – max 100 m²",
    "bruxelles_cat2": "Surface en m² – max 100 m²",
    "bruxelles_cat3": "Surface en m² – max 100 m²"
  }'),
  image: "images/enduit_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_pac_chauffage").update!(
  titre: "Pompe à chaleur chauffage - Bruxelles",
  ordre_affichage: 40,
  icon_name: "flame",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 6000,
      "condition": "Installation d\'une pompe à chaleur pour chauffage central en remplacement d\'un ancien système"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 4500,
      "condition": "Installation d\'une pompe à chaleur pour chauffage central en remplacement d\'un ancien système"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 3000,
      "condition": "Installation d\'une pompe à chaleur pour chauffage central en remplacement d\'un ancien système"
    }
  }'),
  condition: "La pompe à chaleur doit être dimensionnée pour couvrir les besoins en chauffage du logement, avec un COP conforme aux normes PEB",
  conseil: "Vérifie que ton logement est bien isolé avant d'installer une PAC. Combine-la avec des émetteurs basse température",
  document: "Facture avec marque, modèle, COP + attestation de remplacement de système précédent",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant forfaitaire par logement",
    "bruxelles_cat2": "Montant forfaitaire par logement",
    "bruxelles_cat3": "Montant forfaitaire par logement"
  }'),
  image: "images/pac_chauffage.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_radiateurs_basse_temperature").update!(
  titre: "Radiateurs basse température - Bruxelles",
  ordre_affichage: 41,
  icon_name: "thermometer",
  unite: "€/unité (max 10)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 200,
      "plafond_unites": 10,
      "condition": "Remplacement ou installation de radiateurs basse température compatibles avec une pompe à chaleur"
    },
    "bruxelles_cat2": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 125,
      "plafond_unites": 10,
      "condition": "Remplacement ou installation de radiateurs basse température compatibles avec une pompe à chaleur"
    },
    "bruxelles_cat3": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 75,
      "plafond_unites": 10,
      "condition": "Remplacement ou installation de radiateurs basse température compatibles avec une pompe à chaleur"
    }
  }'),
  condition: "Les radiateurs doivent être certifiés basse température et compatibles avec un système de chauffage performant",
  conseil: "Combine cette prime avec celle pour pompe à chaleur ou chaudière à condensation",
  document: "Facture précisant le type et le nombre de radiateurs + preuve de compatibilité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre d\'unités – max 10",
    "bruxelles_cat2": "Nombre d\'unités – max 10",
    "bruxelles_cat3": "Nombre d\'unités – max 10"
  }'),
  image: "images/radiateurs_bt.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_regulation_thermique").update!(
  titre: "Régulation thermique - Bruxelles",
  ordre_affichage: 42,
  icon_name: "sliders",
  unite: "€/unité (max 10)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 70,
      "plafond_unites": 10,
      "condition": "Installation de dispositifs de régulation thermique par pièce (thermostats, vannes thermostatiques, etc.)"
    },
    "bruxelles_cat2": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 40,
      "plafond_unites": 10,
      "condition": "Installation de dispositifs de régulation thermique par pièce (thermostats, vannes thermostatiques, etc.)"
    },
    "bruxelles_cat3": {
      "type": "montant_unite_et_limite",
      "montant_par_unite": 15,
      "plafond_unites": 10,
      "condition": "Installation de dispositifs de régulation thermique par pièce (thermostats, vannes thermostatiques, etc.)"
    }
  }'),
  condition: "Dispositifs de régulation indépendants par pièce : vannes thermostatiques, thermostats d'ambiance, etc.",
  conseil: "Une bonne régulation thermique permet de réduire la consommation d'énergie tout en améliorant le confort",
  document: "Facture précisant le nombre d\'unités, type de dispositifs et emplacement",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de pièces équipées – max 10",
    "bruxelles_cat2": "Nombre de pièces équipées – max 10",
    "bruxelles_cat3": "Nombre de pièces équipées – max 10"
  }'),
  image: "images/regulation_thermique.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_chauffe_eau_solaire").update!(
  titre: "Chauffe-eau solaire thermique - Bruxelles",
  ordre_affichage: 43,
  icon_name: "sun",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 2500,
      "condition": "Installation d\'un chauffe-eau solaire thermique conforme aux normes PEB"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 3000,
      "condition": "Installation d\'un chauffe-eau solaire thermique conforme aux normes PEB"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 3500,
      "condition": "Installation d\'un chauffe-eau solaire thermique conforme aux normes PEB"
    }
  }'),
  condition: "Installation d\'un système solaire thermique dédié à la production d\'eau chaude sanitaire",
  conseil: "Vérifiez l'orientation et l'inclinaison des capteurs pour optimiser le rendement",
  document: "Facture + attestation du prestataire précisant capacité et certification",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait par logement",
    "bruxelles_cat2": "Forfait par logement",
    "bruxelles_cat3": "Forfait par logement"
  }'),
  image: "images/chauffe_eau_solaire.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_raccordement_reseau_chaleur").update!(
  titre: "Raccordement réseau de chaleur - Bruxelles",
  ordre_affichage: 44,
  icon_name: "heat-wave",
  unite: "€/logement",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "montant_fixe",
      "montant": 1000,
      "condition": "Raccordement de l\'installation de chauffage au réseau de chaleur urbain"
    },
    "bruxelles_cat2": {
      "type": "montant_fixe",
      "montant": 1250,
      "condition": "Raccordement de l\'installation de chauffage au réseau de chaleur urbain"
    },
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 1500,
      "condition": "Raccordement de l\'installation de chauffage au réseau de chaleur urbain"
    }
  }'),
  condition: "Installation conforme via un fournisseur agrée de réseau de chaleur",
  conseil: "Vérifier la disponibilité et l'admissibilité auprès du gestionnaire de réseau local",
  document: "Facture + attestation de raccordement du gestionnaire du réseau",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait par logement",
    "bruxelles_cat2": "Forfait par logement",
    "bruxelles_cat3": "Forfait par logement"
  }'),
  image: "images/raccordement_chaleur.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z1").update!(
  titre: "Bonus Z1 – Matériau d\'isolation durable - Bruxelles",
  ordre_affichage: 45,
  icon_name: "leaf",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux d\'isolation biosourcés ou recyclés"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux d\'isolation biosourcés ou recyclés"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux d\'isolation biosourcés ou recyclés"}
  }'),
  condition: "Matériaux d\'isolation durables (laine de bois, cellulose, fibres de coton, etc.)",
  conseil: "Privilégier des matériaux certifiés écologiques pour maximiser l'impact environnemental",
  document: "Facture + certificat du fournisseur attestant de la durabilité du matériau",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage d\'augmentation automatique",
    "bruxelles_cat2": "Pourcentage d\'augmentation automatique",
    "bruxelles_cat3": "Pourcentage d\'augmentation automatique"
  }'),
  image: "images/bonus_z1.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z2").update!(
  titre: "Bonus Z2 – Matériau de couverture durable - Bruxelles",
  ordre_affichage: 46,
  icon_name: "umbrella",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux de couverture recyclables ou durables"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux de couverture recyclables ou durables"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 10, "condition": "Utilisation de matériaux de couverture recyclables ou durables"}
  }'),
  condition: "Matériaux de couverture certifiés durables (tuiles recyclables, zinc naturel, etc.)",
  conseil: "Choisissez des matériaux à faible empreinte carbone pour renforcer la performance environnementale",
  document: "Facture + certificat du fournisseur attestant la durabilité du matériau",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
  }'),
  image: "images/bonus_z2.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)


Prime.find_or_initialize_by(slug: "bruxelles_bonus_z4").update!(
  titre: "Bonus Z4 – Portes et fenêtres durables - Bruxelles",
  ordre_affichage: 47,
  icon_name: "door-open",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Pose de portes/fenêtres fabriquées à partir de matériaux durables ou recyclés"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Pose de portes/fenêtres fabriquées à partir de matériaux durables ou recyclés"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 10, "condition": "Pose de portes/fenêtres fabriquées à partir de matériaux durables ou recyclés"}
    }'),
    condition: "Portes et fenêtres avec labels environnementaux (bois certifié, alu recyclé, etc.)",
    conseil: "Privilégiez des fenêtres avec certification NF Environnement ou équivalent",
  document: "Facture + certificat ou label du fabricant",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
  }'),
  image: "images/bonus_z4.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
  )

  Prime.find_or_initialize_by(slug: "bruxelles_bonus_z5").update!(
    titre: "Bonus Z5 – Portes et fenêtres acoustiques - Bruxelles",
    ordre_affichage: 48,
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
      specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface en m² – max 50",
    "bruxelles_cat2": "Surface en m² – max 50",
    "bruxelles_cat3": "Surface en m² – max 50"
    }'),
  image: "images/bonus_z5.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
  )

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z6").update!(
  titre: "Bonus Z6 – Réemploi d\'équipements sanitaires - Bruxelles",
  ordre_affichage: 49,
  icon_name: "recycle",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Réemploi ou remise en état d\'équipements sanitaires existants"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Réemploi ou remise en état d\'équipements sanitaires existants"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 10, "condition": "Réemploi ou remise en état d\'équipements sanitaires existants"}
    }'),
    condition: "Lavabos, baignoires ou WC remis en état ou repris d\'un autre projet",
    conseil: "Vérifiez la conformité sanitaire avant réemploi",
    document: "Facture ou bon de cession + certificat de remise en état",
    specifique: "Bruxelles - Renolution",
    placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
    }'),
  image: "images/bonus_z6.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z7").update!(
  titre: "Bonus Z7 – Capacité tampon de citerne d\'eau de pluie - Bruxelles",
  ordre_affichage: 50,
  icon_name: "droplet-percent",
  unite: "€/citerne",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 300, "condition": "Capacité de stockage ≥ 3 000 L"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 300, "condition": "Capacité de stockage ≥ 3 000 L"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 300, "condition": "Capacité de stockage ≥ 3 000 L"}
  }'),
  condition: "Citerne enterrée ou aérienne avec capacité tampon minimale de 3 000 litres",
  conseil: "Vérifiez l\'espace disponible et la stabilité du terrain avant installation",
  document: "Facture + fiche technique citerne précisant capacité",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait pour citerne ≥ 3000L",
    "bruxelles_cat2": "Forfait pour citerne ≥ 3000L",
    "bruxelles_cat3": "Forfait pour citerne ≥ 3000L"
  }'),
  image: "images/bonus_z7.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z9").update!(
  titre: "Bonus Z9 – Sortie mazout et charbon - Bruxelles",
  ordre_affichage: 51,
  icon_name: "fire",
  unite: "€/forfait",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 400, "condition": "Désinstallation et évacuation de cuve mazout/charbon"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 400, "condition": "Désinstallation et évacuation de cuve mazout/charbon"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 400, "condition": "Désinstallation et évacuation de cuve mazout/charbon"}
  }'),
  condition: "Enlèvement complet et dépollution du site de stockage de mazout ou charbon",
  conseil: "Engagez un spécialiste agréé pour assurer la conformité environnementale",
  document: "Rapport d'enlèvement + facture du prestataire",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait nettoyage cuve",
    "bruxelles_cat2": "Forfait nettoyage cuve",
    "bruxelles_cat3": "Forfait nettoyage cuve"
  }'),
  image: "images/bonus_z9.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z10").update!(
  titre: "Bonus Z10 – Plusieurs travaux combinés - Bruxelles",
  ordre_affichage: 52,
  icon_name: "layers",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 20, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"}
  }'),
  condition: "Regroupement de trois travaux ou plus dans la même demande",
  conseil: "Réunissez vos travaux pour maximiser la prime globale",
  document: "Factures pour chaque type de travaux + récapitulatif",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
  }'),
  image: "images/bonus_z10.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ #{Prime.where(region: 'bruxelles').count} primes Bruxelles RENOLUTION créées avec succès"
