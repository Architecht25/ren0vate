# Seeds pour recréer les 13 utilisateurs production avec leurs données complètes
puts "👥 Création des utilisateurs de production..."

# Nettoyage préalable (optionnel)
if Rails.env.development?
  puts "🧹 Nettoyage des anciennes données utilisateurs en développement..."
  User.destroy_all
  Property.destroy_all
  Project.destroy_all
end

# Liste des 13 utilisateurs avec leurs profils complets
users_data = [
  {
    email: 'robin@primes-services.be',
    password: 'renovate2025',
    first_name: 'Robin',
    last_name: 'Admin',
    role: 'admin',
    phone: '+32 2 123 45 67',
    city: 'Bruxelles',
    postal_code: '1000'
  },
  {
    email: 'marie.dupont@example.be',
    password: 'demo2025',
    first_name: 'Marie',
    last_name: 'Dupont',
    role: 'user',
    phone: '+32 2 234 56 78',
    city: 'Bruxelles',
    postal_code: '1050'
  },
  {
    email: 'pierre.martin@renoveco.be',
    password: 'demo2025',
    first_name: 'Pierre',
    last_name: 'Martin',
    role: 'user',
    phone: '+32 2 345 67 89',
    city: 'Ixelles',
    postal_code: '1050'
  },
  {
    email: 'sophie.bernard@habitat.be',
    password: 'demo2025',
    first_name: 'Sophie',
    last_name: 'Bernard',
    role: 'user',
    phone: '+32 2 456 78 90',
    city: 'Uccle',
    postal_code: '1180'
  },
  {
    email: 'luc.moreau@energybxl.be',
    password: 'demo2025',
    first_name: 'Luc',
    last_name: 'Moreau',
    role: 'user',
    phone: '+32 2 567 89 01',
    city: 'Saint-Gilles',
    postal_code: '1060'
  },
  {
    email: 'claire.laurent@ecowork.be',
    password: 'demo2025',
    first_name: 'Claire',
    last_name: 'Laurent',
    role: 'user',
    phone: '+32 2 678 90 12',
    city: 'Etterbeek',
    postal_code: '1040'
  },
  {
    email: 'thomas.petit@renobxl.be',
    password: 'demo2025',
    first_name: 'Thomas',
    last_name: 'Petit',
    role: 'user',
    phone: '+32 2 789 01 23',
    city: 'Schaerbeek',
    postal_code: '1030'
  },
  {
    email: 'isabelle.robert@greentech.be',
    password: 'demo2025',
    first_name: 'Isabelle',
    last_name: 'Robert',
    role: 'user',
    phone: '+32 2 890 12 34',
    city: 'Woluwe-Saint-Pierre',
    postal_code: '1150'
  },
  {
    email: 'antoine.durand@construct.be',
    password: 'demo2025',
    first_name: 'Antoine',
    last_name: 'Durand',
    role: 'user',
    phone: '+32 2 901 23 45',
    city: 'Anderlecht',
    postal_code: '1070'
  },
  {
    email: 'nathalie.leroy@renovation.be',
    password: 'demo2025',
    first_name: 'Nathalie',
    last_name: 'Leroy',
    role: 'user',
    phone: '+32 2 012 34 56',
    city: 'Molenbeek-Saint-Jean',
    postal_code: '1080'
  },
  {
    email: 'francois.simon@sustainable.be',
    password: 'demo2025',
    first_name: 'François',
    last_name: 'Simon',
    role: 'user',
    phone: '+32 2 123 56 78',
    city: 'Forest',
    postal_code: '1190'
  },
  {
    email: 'caroline.michel@architect.be',
    password: 'demo2025',
    first_name: 'Caroline',
    last_name: 'Michel',
    role: 'user',
    phone: '+32 2 234 67 89',
    city: 'Koekelberg',
    postal_code: '1081'
  },
  {
    email: 'david.garcia@renovation-pro.be',
    password: 'demo2025',
    first_name: 'David',
    last_name: 'Garcia',
    role: 'user',
    phone: '+32 2 345 78 90',
    city: 'Jette',
    postal_code: '1090'
  }
]

# Adresses Brussels pour les propriétés
brussels_addresses = [
  { street: 'Rue de la Loi 15', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Avenue Louise 234', city: 'Bruxelles', zipcode: '1050', municipality: 'Ixelles' },
  { street: 'Boulevard Anspach 67', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Chaussée de Charleroi 123', city: 'Bruxelles', zipcode: '1060', municipality: 'Saint-Gilles' },
  { street: 'Avenue des Arts 89', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Rue Royale 145', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Place Eugène Flagey 12', city: 'Bruxelles', zipcode: '1050', municipality: 'Ixelles' },
  { street: 'Avenue Molière 78', city: 'Bruxelles', zipcode: '1180', municipality: 'Uccle' },
  { street: 'Rue de la Régence 34', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Boulevard de Waterloo 91', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' }
]

# Types de propriétés et projets
property_types = ['Maison unifamiliale', 'Appartement', 'Maison de maître', 'Studio', 'Loft']
project_types = ['Isolation toiture', 'Pompe à chaleur', 'Panneaux solaires', 'Rénovation énergétique', 'Isolation façade']

created_users = []

# Création des utilisateurs
users_data.each_with_index do |user_data, index|
  puts "👤 Création utilisateur: #{user_data[:email]}"

  user = User.create!(
    email: user_data[:email],
    password: user_data[:password],
    password_confirmation: user_data[:password],
    first_name: user_data[:first_name],
    last_name: user_data[:last_name],
    role: user_data[:role],
    phone: user_data[:phone],
    city: user_data[:city],
    postal_code: user_data[:postal_code],
    confirmed_at: Time.current
  )

  created_users << user

  # Créer 3 propriétés pour chaque utilisateur (sauf admin)
  next if user.role == 'admin'

  3.times do |prop_index|
    address = brussels_addresses.sample
    property_type = property_types.sample

    puts "  🏠 Propriété #{prop_index + 1}: #{address[:street]}"

    property = Property.create!(
      user: user,
      address: address[:street],
      city: address[:city],
      zipcode: address[:zipcode],
      municipality: address[:municipality],
      property_type: property_type,
      surface: rand(50..300),
      construction_year: rand(1950..2020),
      energy_certificate: ['A', 'B', 'C', 'D', 'E'].sample
    )

    # Créer 2-4 projets pour chaque propriété
    rand(2..4).times do |proj_index|
      project_type = project_types.sample
      status = ['planned', 'in_progress', 'completed'].sample

      puts "    🔧 Projet #{proj_index + 1}: #{project_type}"

      Project.create!(
        user: user,
        property: property,
        title: "#{project_type} - #{property.address}",
        description: "Projet de #{project_type.downcase} pour améliorer l'efficacité énergétique",
        status: status,
        budget: rand(5000..50000),
        start_date: rand(1.year.ago..6.months.from_now),
        estimated_duration: rand(1..12) # mois
      )
    end
  end
end

puts ""
puts "✅ Seed utilisateurs terminé!"
puts "📊 Statistiques:"
puts "  👥 Utilisateurs créés: #{created_users.size}"
puts "  🏠 Propriétés créées: #{Property.count}"
puts "  🔧 Projets créés: #{Project.count}"
puts ""
puts "🔑 Accès admin:"
puts "  📧 Email: robin@primes-services.be"
puts "  🔐 Mot de passe: renovate2025"
puts ""
puts "🔑 Accès utilisateurs demo:"
puts "  📧 Email: [n'importe lequel des autres emails]"
puts "  🔐 Mot de passe: demo2025"
