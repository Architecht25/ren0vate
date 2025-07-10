# Script ultra-simplifié - création uniquement
puts "Création des données de test..."

# Créer l'utilisateur de test (ou le récupérer s'il existe)
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Test'
  u.last_name = 'User'
end

puts "Utilisateur: #{user.email} (ID: #{user.id})"

# Créer les propriétés si elles n'existent pas
if user.properties.empty?
  property1 = user.properties.create!(
    rue: 'Rue de la Paix',
    numero: '123',
    code_postal: '1000',
    commune: 'Bruxelles',
    region: 'bruxelles',
    type: 'maison',
    occupation: 'locataire',
    annee_construction: 1990,
    date_raccordement_electrique: 2010,
    numero_ean: '541234567890123456',
    autre_bien: 'non',
    peb: 'ef'
  )

  property2 = user.properties.create!(
    rue: 'Avenue des Tilleuls',
    numero: '45',
    code_postal: '4000',
    commune: 'Liège',
    region: 'wallonie',
    type: 'appartement',
    occupation: 'proprietaire',
    annee_construction: 2005,
    date_raccordement_electrique: 2015,
    numero_ean: '541234567890123457',
    autre_bien: 'oui',
    peb: 'autre'
  )

  property3 = user.properties.create!(
    rue: 'Boulevard de la Liberté',
    numero: '78',
    code_postal: '9000',
    commune: 'Gand',
    region: 'flandre',
    type: 'maison',
    occupation: 'proprietaire',
    annee_construction: 1985,
    date_raccordement_electrique: 2008,
    numero_ean: '541234567890123458',
    autre_bien: 'non',
    peb: 'ef'
  )

  puts "Propriétés créées:"
  puts "- #{property1.name} (ID: #{property1.id})"
  puts "- #{property2.name} (ID: #{property2.id})"
  puts "- #{property3.name} (ID: #{property3.id})"
else
  puts "Propriétés existantes:"
  user.properties.each do |property|
    puts "- #{property.name} (ID: #{property.id})"
  end
end

puts "\nURLs valides:"
user.properties.each do |property|
  puts "#{property.name}:"
  puts "  - Vue détaillée: http://localhost:3000/properties/#{property.id}"
  puts "  - Dashboard: http://localhost:3000/properties/#{property.id}/dashboard"
end

puts "\nConnexion: test@example.com / password123"
