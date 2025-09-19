# ===================================
# AIDES AUX ENTREPRISES - BRUXELLES-CAPITALE
# ===================================
# Ce fichier charge toutes les aides disponibles pour les entreprises
# en Région de Bruxelles-Capitale, organisées par catégorie.
# Source officielle: economie-emploi.brussels
# ===================================

puts "🏢 Initialisation des aides aux entreprises Bruxelles..."

# Mode sécurisé : ne supprime que si pas en production
if Rails.env.development? || ENV['FORCE_AIDE_RESET'] == 'true'
  puts "🗑️  Nettoyage des aides entreprises Bruxelles existantes (#{Rails.env})..."
  EntrepriseAide.where(region: "bruxelles").delete_all
else
  puts "🔒 Mode production : conservation des aides existantes"
end

# Chargement des catégories d'aides
puts "📁 Chargement par catégories..."

# CATÉGORIE 1: TRANSITION ÉCONOMIQUE + MOBILITÉ (5 aides)
# - transition_consultance, investissements_transition_economique
# - mobilite_velo_cargo, mobilite_utilitaire_electrique, mobilite_utilitaire_retrofit
load Rails.root.join('db/seeds/entreprises/bruxelles/aides/transition_economique_mobilite.rb')

# CATÉGORIE 2: INVESTISSEMENTS (5 aides)
# - prime_materiel_travaux, prime_immobilier, prime_conformite_normes
# - prime_securisation, prime_accessibilite
load Rails.root.join('db/seeds/entreprises/bruxelles/aides/investissements.rb')

# CATÉGORIE 3: RECRUTEMENT ET FORMATION (2 aides)
# - prime_formation, prime_recrutement
load Rails.root.join('db/seeds/entreprises/bruxelles/aides/recrutement_formation.rb')

# CATÉGORIE 4: EXPERTISES OU SERVICES EXTERNES (2 aides)
# - prime_consultance, prime_digitalisation
load Rails.root.join('db/seeds/entreprises/bruxelles/aides/expertises_services_externes.rb')

puts "✅ Toutes les aides entreprises Bruxelles chargées avec succès (14 aides au total)"
puts "📊 Répartition: 5 Transition/Mobilité + 5 Investissements + 2 RH/Formation + 2 Expertises"
