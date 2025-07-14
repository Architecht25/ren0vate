# Prime PEB spéciale pour certificat énergétique après travaux
Prime.find_or_initialize_by(slug: "certificat_peb_apres_travaux").update!(
  titre: "Certificat PEB après travaux",
  ordre_affichage: 13,
  icon_name: "award",
  unite: "label_final",
  type_de_valeur: "conditionnel",
  eligible_categories: ["1", "2", "3", "4"],
  valeurs_par_categorie: JSON.parse('{
    "4": {
      "maison": {
        "A": { "sans_ventilation": 6000, "avec_ventilation": 7000 },
        "B": { "sans_ventilation": 4500, "avec_ventilation": 5250 },
        "C": { "sans_ventilation": 3000, "avec_ventilation": 3500 }
      },
      "appartement": {
        "A": { "sans_ventilation": 4500, "avec_ventilation": 5250 },
        "B": { "sans_ventilation": 3000, "avec_ventilation": 3500 }
      }
    },
    "3": {
      "maison": {
        "A": { "sans_ventilation": 5000, "avec_ventilation": 6000 },
        "B": { "sans_ventilation": 3750, "avec_ventilation": 4500 },
        "C": { "sans_ventilation": 2500, "avec_ventilation": 3000 }
      },
      "appartement": {
        "A": { "sans_ventilation": 3750, "avec_ventilation": 4500 },
        "B": { "sans_ventilation": 2500, "avec_ventilation": 3000 }
      }
    },
    "2": {
      "maison": {
        "A": { "sans_ventilation": 4000, "avec_ventilation": 5000 },
        "B": { "sans_ventilation": 3000, "avec_ventilation": 3750 },
        "C": { "sans_ventilation": 2000, "avec_ventilation": 2500 }
      },
      "appartement": {
        "A": { "sans_ventilation": 3000, "avec_ventilation": 3750 },
        "B": { "sans_ventilation": 2000, "avec_ventilation": 2500 }
      }
    },
    "1": {
      "maison": {
        "A": { "sans_ventilation": 3000, "avec_ventilation": 4000 },
        "B": { "sans_ventilation": 2000, "avec_ventilation": 3000 },
        "C": { "sans_ventilation": 1000, "avec_ventilation": 2000 }
      },
      "appartement": {
        "A": { "sans_ventilation": 2250, "avec_ventilation": 3000 },
        "B": { "sans_ventilation": 1500, "avec_ventilation": 2000 }
      }
    }
  }'),
  condition: "La rénovation doit faire passer le logement d'un label E/F (ou D pour appartement) à A, B ou C. Le montant dépend de la ventilation installée et du type de logement.",
  conseil: "Faites réaliser un certificat PEB avant et après travaux. Vérifiez que l'amélioration correspond bien à un saut d'au moins deux lettres pour activer la prime maximale.",
  document: "Certificat PEB initial et final",
  specifique: "Normes de ventilation: installation d'un système D(double flux) et/ou placer les invisivents dans toutes les pièces sèches",
  placeholder: JSON.parse('{"1": "Label final (ex : B)", "2": "Label final (ex : B)", "3": "Label final (ex : B)", "4": "Label final (ex : B)"}'),
  image: "images/certificat.png",
  region: "flandre",
  category_id: Category.find_by(code: "categorie_4").id
)
