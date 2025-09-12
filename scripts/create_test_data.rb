puts "🏗️ Création des données test : biens, entreprises, chantiers et simulations..."

# Récupérer l'utilisateur robin (admin)
robin = User.find_by(email: 'robin@primes-services.be')
unless robin
  puts "❌ Utilisateur robin@primes-services.be non trouvé"
  exit
end

puts "👤 Utilisateur trouvé : #{robin.email}"

# === 1. BIEN EN FLANDRE ===
puts "\n🇳🇱 === CRÉATION BIEN FLANDRE ==="

flandre_property = robin.properties.find_or_create_by(
  rue: "Energiestraat",
  numero: "25"
) do |property|
  property.code_postal = "9000"
  property.commune = "Gent"
  property.region = "flandre"
  property.annee_construction = 1985

  # Champs spécifiques Flandre
  property.type_bien_flandre = "maison"
  property.usage_flandre = "residence_principale"
  property.chauffage_post_renovation_flandre = "pac"
  property.ean_flandre = "541449100001234567"
  property.parcelle_flandre = "44123/02C"
  property.certificat_peb_flandre = "D"
end
puts "✅ Propriété Flandre créée : #{flandre_property.full_address}"

# === 2. ENTREPRISE À BRUXELLES ===
puts "\n🏢 === CRÉATION ENTREPRISE BRUXELLES ==="

bruxelles_enterprise = robin.properties.find_or_create_by(
  rue: "Avenue des Entrepreneurs",
  numero: "42"
) do |property|
  property.code_postal = "1080"
  property.commune = "Molenbeek-Saint-Jean"
  property.region = "bruxelles"
  property.annee_construction = 1995

  # Marquer comme entreprise
  property.type = "entreprise"

  # Champs spécifiques entreprise Bruxelles
  property.type_bien_bruxelles = "immeuble_mixte"
  property.certificat_peb_bruxelles = "C"

  # Champs entreprise (noter que ces champs semblent exister d'après le schéma)
  property.nombre_salaries = 15
  property.date_creation = Date.new(2015, 3, 15)
  property.code_nace_1 = "6201"  # Programmation informatique
  property.comptes_annuels_conformes = true
  property.regle_minimis = false
  property.pourcentage_financement_public = 25.0

  # Champ d'adresse d'exploitation (même adresse)
  property.meme_adresse_exploitation = true
end
puts "✅ Entreprise Bruxelles créée : InnoTech Solutions (type: #{bruxelles_enterprise.type}) - #{bruxelles_enterprise.full_address}"

# === 3. BIENS SUPPLÉMENTAIRES POUR COMPLÉTER ===
puts "\n🏠 === CRÉATION BIENS SUPPLÉMENTAIRES ==="

# Bien Wallonie pour faire 4 au total
wallonie_property = robin.properties.find_or_create_by(
  rue: "Rue de l'Innovation",
  numero: "18"
) do |property|
  property.code_postal = "5000"
  property.commune = "Namur"
  property.region = "wallonie"
  property.annee_construction = 2005

  # Champs spécifiques Wallonie
  property.type_propriete_wallonie = "maison_individuelle"
  property.certificat_peb_wallonie = "B"
  property.surface_habitable_wallonie = 180
  property.mode_chauffage_wallonie = "pompe_chaleur"
end
puts "✅ Propriété Wallonie créée : #{wallonie_property.full_address}"

# Deuxième bien Bruxelles
bruxelles_property = robin.properties.find_or_create_by(
  rue: "Place de l'Innovation",
  numero: "7"
) do |property|
  property.code_postal = "1000"
  property.commune = "Bruxelles"
  property.region = "bruxelles"
  property.annee_construction = 1980

  # Champs spécifiques Bruxelles
  property.type_bien_bruxelles = "appartement"
  property.certificat_peb_bruxelles = "E"
end
puts "✅ Propriété Bruxelles créée : #{bruxelles_property.full_address}"

# === 4. CRÉATION DES PROJETS/CHANTIERS ===
puts "\n🔨 === CRÉATION DES PROJETS/CHANTIERS ==="

properties = [flandre_property, bruxelles_enterprise, wallonie_property, bruxelles_property]
project_types = [
  { name: "Isolation toiture", description: "Isolation thermique complète de la toiture", project_type: "renovation", finalite: "residentielle" },
  { name: "Transformation bureaux", description: "Rénovation énergétique des bureaux", project_type: "investment", finalite: "economique" },
  { name: "Pompe à chaleur", description: "Installation pompe à chaleur air-eau", project_type: "renovation", finalite: "residentielle" },
  { name: "Rénovation énergétique", description: "Rénovation globale du bien", project_type: "renovation", finalite: "residentielle" }
]

projects = []
properties.each_with_index do |property, index|
  project_data = project_types[index]

  project = Project.find_or_create_by(
    nom: "#{project_data[:name]} - #{property.commune}",
    property: property,
    user: robin
  ) do |proj|
    proj.description = project_data[:description]
    proj.project_type = project_data[:project_type]
    proj.finalite = project_data[:finalite]
    proj.statut = "en_cours"
    proj.date_début = Date.current + rand(30).days
    proj.date_fin = Date.current + rand(60..180).days

    # Ajouter des professionnels
    proj.entrepreneur_principal_nom = "Jean Dupont"
    proj.entrepreneur_principal_entreprise = "Entreprise Dupont & Fils"
    proj.entrepreneur_principal_numero_tva = "BE0123456789"
    proj.entrepreneur_principal_telephone = "+32 123 45 67 89"
    proj.entrepreneur_principal_email = "jean@dupont-fils.be"

    if project_data[:project_type] == "investment"
      proj.architecte_nom = "Martin"
      proj.architecte_prenom = "Sophie"
      proj.architecte_entreprise = "Cabinet Martin Architectes"
      proj.architecte_email = "sophie@martin-architectes.be"
    end
  end

  if project.persisted?
    projects << project
    puts "✅ Projet créé : #{project.nom}"
  else
    puts "❌ Erreur création projet #{project_data[:name]} : #{project.errors.full_messages.join(', ')}"
  end
end

# === 5. CRÉATION DES SIMULATIONS ===
puts "\n📊 === CRÉATION DES SIMULATIONS ==="

projects.each_with_index do |project, index|
  property = project.property

  # Déterminer la catégorie selon la région
  case property.region
  when "wallonie"
    category = "wallonie_r3"  # Catégorie moyenne
  when "flandre"
    category = "3"  # Catégorie Flandre
  when "bruxelles"
    category = "bruxelles_cat2"  # Catégorie moyenne Bruxelles
  end

  simulation = robin.simulations.find_or_create_by(
    titre: "Simulation #{project.nom}",
    property: property,
    project: project
  ) do |sim|
    sim.region = property.region
    sim.categorie = category
    sim.category = category
    sim.category_description = "Simulation pour #{property.region}"
    sim.eligible = true
    sim.total_simule = rand(2000..8000)
    sim.parameters = {
      surface_isolation: rand(50..150),
      type_travaux: project.description
    }.to_json
    sim.source = "script_test"

    # Pour les entreprises, ajouter l'éligibilité investissement
    if property.type == "entreprise"
      sim.eligible_investment = true
      sim.eligible_renolution = true
    end
  end

  # Ajouter quelques primes à la simulation
  primes_region = Prime.where(region: property.region).limit(3)
  primes_region.each do |prime|
    simulation.simulation_prime_cards.find_or_create_by(prime: prime) do |card|
      card.montant_simule = rand(500..2500)
      card.calcul_details = "Calcul automatique pour test"
    end
  end

  puts "✅ Simulation créée : #{simulation.titre} (#{simulation.total_simule}€)"
end

puts "\n🎉 === RÉCAPITULATIF ==="
puts "📊 Statistiques créées :"
puts "  🏠 Propriétés : #{robin.properties.count} total"
puts "  🔨 Projets : #{robin.projects.count} total"
puts "  📈 Simulations : #{robin.simulations.count} total"

puts "\n📍 Répartition par région :"
robin.properties.group(:region).count.each do |region, count|
  puts "  #{region&.humanize || 'Non définie'} : #{count} bien(s)"
end

puts "\n🎯 Types de projets :"
if robin.projects.any?
  robin.projects.group(:project_type).count.each do |type, count|
    puts "  #{type.humanize} : #{count} projet(s)"
  end
else
  puts "  Aucun projet créé"
end

puts "\n✅ Script terminé avec succès !"
