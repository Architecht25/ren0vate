# Script simplifié pour recréer seulement l'utilisateur et les propriétés
puts "Nettoyage des données existantes..."

# Nettoyer seulement les propriétés et l'utilisateur de test
Property.destroy_all
User.where(email: 'test@example.com').destroy_all

puts "Création de l'utilisateur de test..."

# Créer l'utilisateur de test
user = User.create!(
  email: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Test',
  last_name: 'User'
)

puts "Utilisateur créé: #{user.email} (ID: #{user.id})"

# Créer les propriétés
puts "Création des propriétés..."

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
puts "- #{property1.name} (ID: #{property1.id}, Complétude: #{property1.completion_percentage}%)"
puts "- #{property2.name} (ID: #{property2.id}, Complétude: #{property2.completion_percentage}%)"
puts "- #{property3.name} (ID: #{property3.id}, Complétude: #{property3.completion_percentage}%)"

puts "\nURLs valides:"
puts "Dashboard général: http://localhost:3000/dashboard"
puts "Liste des biens: http://localhost:3000/properties"
puts ""
user.properties.each do |property|
  puts "#{property.name}:"
  puts "  - Vue détaillée: http://localhost:3000/properties/#{property.id}"
  puts "  - Dashboard: http://localhost:3000/properties/#{property.id}/dashboard"
end

puts "\nDonnées de test créées avec succès!"
puts "Connectez-vous avec: test@example.com / password123"
