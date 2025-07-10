# Seeds pour enrichir le dashboard avec des données réalistes
puts "Enrichissement des données pour le dashboard..."

# Récupérer l'utilisateur de test
user = User.find_by(email: 'test@example.com')
if user.nil?
  puts "Utilisateur de test non trouvé. Exécutez d'abord le seed test_dashboard.rb"
  exit
end

# Créer des notifications de test
puts "Création des notifications..."
notifications_data = [
  {
    message: "Nouvelle prime disponible : Une nouvelle prime pour l'isolation des murs est disponible en Wallonie",
    type: "info"
  },
  {
    message: "Demande approuvée : Votre demande de prime pour l'isolation de la toiture a été approuvée",
    type: "success"
  },
  {
    message: "Document manquant : Il manque le certificat PEB pour votre propriété rue de la Paix",
    type: "warning"
  },
  {
    message: "Simulation terminée : La simulation pour votre appartement à Liège est terminée",
    type: "info"
  }
]

notifications_data.each do |notification_data|
  user.notifications.create!(
    message: notification_data[:message],
    type: notification_data[:type],
    read: false,
    created_at: rand(1..7).days.ago
  )
end

# Créer des simulations de test
puts "Création des simulations..."
properties = user.properties.limit(3)
properties.each_with_index do |property, index|
  simulation = user.simulations.find_or_create_by(
    property: property,
    titre: "Simulation #{property.commune}",
    region: property.region,
    source: "dashboard_test"
  ) do |sim|
    sim.created_at = rand(1..30).days.ago
    sim.updated_at = sim.created_at
  end
end

# Créer des projets de test
puts "Création des projets..."
projects_data = [
  {
    nom: "Isolation toiture - Bruxelles",
    description: "Isolation de la toiture de la maison rue de la Paix",
    statut: "en_cours"
  },
  {
    nom: "Changement chaudière - Liège",
    description: "Remplacement de la chaudière au gaz par une pompe à chaleur",
    statut: "planifie"
  },
  {
    nom: "Panneaux solaires - Gand",
    description: "Installation de panneaux photovoltaïques",
    statut: "termine"
  }
]

projects_data.each_with_index do |project_data, index|
  property = properties[index]
  next unless property
  
  project = Project.find_or_create_by(
    nom: project_data[:nom],
    property: property
  ) do |proj|
    proj.description = project_data[:description]
    proj.statut = project_data[:statut]
    proj.created_at = rand(1..60).days.ago
  end
end

# Créer des demandes de test
puts "Création des demandes..."
projects = Project.joins(:property).where(property: { user_id: user.id }).limit(2)
projects.each_with_index do |project, index|
  simulation = user.simulations.where(property: project.property).first
  next unless simulation
  
  request = user.requests.find_or_create_by(
    property: project.property,
    project: project,
    simulation: simulation
  ) do |req|
    req.status = index.even? ? 'pending' : 'in_progress'
    req.created_at = rand(1..14).days.ago
  end
end

puts "Données créées avec succès !"
puts "- Notifications: #{user.notifications.count}"
puts "- Simulations: #{user.simulations.count}"
puts "- Projets: #{Project.joins(:property).where(property: { user_id: user.id }).count}"
puts "- Demandes: #{user.requests.count}"
puts ""
puts "Le dashboard est maintenant enrichi avec des données réalistes."
puts "Accédez au dashboard : http://localhost:3000/dashboard"
