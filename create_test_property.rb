require './config/environment'

# Créer un utilisateur admin pour tester
admin = User.where(email: 'admin@ren0vate.be').first_or_create! do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'admin'
end

# Créer une propriété de test avec votre adresse
property = Property.create!(
  user: admin,
  rue: 'clos charles bailly',
  numero: '16',
  code_postal: '1310',
  commune: 'la hulpe',
  region: 'Wallonie',
  type_propriete_wallonie: 'maison_unifamiliale',
  valeur_achat: 350000,
  certificat_peb_wallonie: 'B'
)

puts 'Propriété créée: ' + property.full_address
puts 'Géocodage en cours...'

if property.geocode
  property.update(geocoded_at: Time.current)
  puts 'Géocodage réussi!'
  puts 'Latitude: ' + property.latitude.to_s
  puts 'Longitude: ' + property.longitude.to_s
  puts 'ID: ' + property.id.to_s
else
  puts 'Échec du géocodage'
end

puts "\nStatistiques après création:"
puts 'Total properties: ' + Property.count.to_s
puts 'Geocoded: ' + Property.where.not(latitude: nil).count.to_s
puts 'Not geocoded: ' + Property.where(latitude: nil).count.to_s
