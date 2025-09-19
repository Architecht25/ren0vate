# =====================================================
# PRIMES WALLONIE - AUDIT
# =====================================================
# Module pour les primes d'audit énergétique
# =====================================================

puts "🔍 Création des primes Audit Wallonie..."

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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Audit Wallonie créées avec succès"
