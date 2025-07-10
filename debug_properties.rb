puts "=== Vérification des propriétés existantes ==="

# Lister toutes les propriétés
all_properties = Property.all
puts "Nombre total de propriétés: #{all_properties.count}"

all_properties.each do |property|
  puts "- ID: #{property.id}, User ID: #{property.user_id}, Nom: #{property.name}"
end

# Lister les utilisateurs
puts "\n=== Utilisateurs ==="
User.all.each do |user|
  puts "- ID: #{user.id}, Email: #{user.email}, Propriétés: #{user.properties.count}"
end

# Vérifier l'utilisateur de test
user = User.find_by(email: 'test@example.com')
if user
  puts "\n=== Propriétés pour test@example.com ==="
  user.properties.each do |property|
    puts "- ID: #{property.id}, Nom: #{property.name}, Adresse: #{property.full_address}"
  end

  puts "\n=== URLs valides ==="
  user.properties.each do |property|
    puts "- Vue détaillée: http://localhost:3000/properties/#{property.id}"
    puts "- Dashboard: http://localhost:3000/properties/#{property.id}/dashboard"
  end
else
  puts "Utilisateur de test non trouvé"
end
