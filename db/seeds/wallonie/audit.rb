puts "� Création des standards d'audit énergétique Wallonie..."

# Ce fichier contient les spécificités de l'audit énergétique wallon
# Système de certification énergétique propre à la Wallonie

# === CERTIFICATS PEB WALLONIE ===
# Classes énergétiques selon le système wallon
# Consommation en kWh/m²/an

audit_wallonie_classes = {
  "A++" => {
    min: 0, max: 15,
    description: "Très haute performance énergétique",
    eligibilite_primes: "Toutes catégories",
    bonus_primes: 10
  },
  "A+" => {
    min: 16, max: 30,
    description: "Haute performance énergétique",
    eligibilite_primes: "Toutes catégories",
    bonus_primes: 5
  },
  "A" => {
    min: 31, max: 45,
    description: "Bonne performance énergétique",
    eligibilite_primes: "Toutes catégories",
    bonus_primes: 0
  },
  "B" => {
    min: 46, max: 85,
    description: "Performance correcte",
    eligibilite_primes: "Toutes catégories",
    bonus_primes: 0
  },
  "C" => {
    min: 86, max: 170,
    description: "Performance moyenne",
    eligibilite_primes: "Rénovation recommandée",
    bonus_primes: 0
  },
  "D" => {
    min: 171, max: 255,
    description: "Performance faible - Rénovation nécessaire",
    eligibilite_primes: "Rénovation prioritaire",
    bonus_primes: 0
  },
  "E" => {
    min: 256, max: 340,
    description: "Mauvaise performance - Rénovation urgente",
    eligibilite_primes: "Rénovation lourde",
    bonus_primes: 0
  },
  "F" => {
    min: 341, max: 425,
    description: "Très mauvaise performance",
    eligibilite_primes: "Rénovation lourde obligatoire",
    bonus_primes: 0
  },
  "G" => {
    min: 426, max: 999,
    description: "Performance très faible",
    eligibilite_primes: "Rénovation complète nécessaire",
    bonus_primes: 0
  }
}

# === AUDIT ÉNERGÉTIQUE ===
audit_wallonie_types = {
  "audit_simple" => {
    prix_moyen: 500,
    duree: "2-3 heures",
    description: "Audit de base avec recommandations",
    obligatoire_pour: "Primes > 3000€"
  },
  "audit_complet" => {
    prix_moyen: 800,
    duree: "4-6 heures",
    description: "Audit détaillé avec calculs thermiques",
    obligatoire_pour: "Rénovations lourdes"
  },
  "audit_pre_travaux" => {
    prix_moyen: 300,
    duree: "1-2 heures",
    description: "État avant travaux",
    obligatoire_pour: "Toutes demandes de primes"
  },
  "audit_post_travaux" => {
    prix_moyen: 400,
    duree: "2-3 heures",
    description: "Contrôle après travaux",
    obligatoire_pour: "Validation des primes"
  }
}

# === RÈGLES DE SCORING PEB WALLONIE ===
regles_wallonie = {
  seuils_peb: [
    { score_min: 90, lettre: "A" },
    { score_min: 75, lettre: "B" },
    { score_min: 60, lettre: "C" },
    { score_min: 45, lettre: "D" },
    { score_min: 30, lettre: "E" },
    { score_min: 15, lettre: "F" },
    { score_min: 0,  lettre: "G" }
  ],
  points: {
    isolation: {
      toiture: { oui: 20, partiellement: 10, non: 0 },
      murs: { oui_ext: 15, oui_int: 10, non: 0 },
      sol: { oui: 10, non: 0 }
    },
    chassis: {
      vitrage: { triple: 15, double: 10, simple: 0 }
    },
    chauffage: {
      type: { pac: 20, gaz: 10, mazout: 5, electrique: 0 },
      ecs: { solaire: 5, chaudiere: 3, boiler: 1 }
    },
    renouvelables: {
      pv: 10,
      solaire: 5,
      batterie: 5
    }
  }
}

# Fonction pour calculer le bonus d'ancienneté du chauffage
def bonus_annee_chauffage(annee)
  return 0 if annee.nil? || annee >= 2018
  return 3 if annee >= 2005
  return 5 if annee >= 1995
  7
end

puts "📊 Classes d'audit énergétique Wallonie :"
audit_wallonie_classes.each do |classe, info|
  puts "  #{classe}: #{info[:min]}-#{info[:max]} kWh/m²/an - #{info[:description]}"
end

puts "\n🔍 Types d'audit disponibles :"
audit_wallonie_types.each do |type, info|
  puts "  #{type}: #{info[:prix_moyen]}€ (#{info[:duree]}) - #{info[:description]}"
end

puts "\n📋 Règles de scoring PEB Wallonie :"
puts "  Seuils de notation :"
regles_wallonie[:seuils_peb].each do |seuil|
  puts "    #{seuil[:lettre]}: #{seuil[:score_min]}+ points"
end

puts "\n  Points par critère :"
puts "    Isolation toiture: #{regles_wallonie[:points][:isolation][:toiture]}"
puts "    Isolation murs: #{regles_wallonie[:points][:isolation][:murs]}"
puts "    Vitrage: #{regles_wallonie[:points][:chassis][:vitrage]}"
puts "    Chauffage: #{regles_wallonie[:points][:chauffage][:type]}"
puts "    Renouvelables: #{regles_wallonie[:points][:renouvelables]}"

puts "\n✅ Standards d'audit énergétique Wallonie configurés"
