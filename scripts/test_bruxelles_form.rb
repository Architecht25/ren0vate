#!/usr/bin/env ruby

require_relative 'config/environment'

# Créer un utilisateur de test s'il n'existe pas
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.confirmed_at = Time.current
end

puts "User created/found: #{user.email}"

# Tenter de créer une propriété avec les paramètres minimaux requis
property_params = {
  region: 'bruxelles',
  rue: 'Test Street',
  numero: '123',
  code_postal: '1000',
  commune: 'Bruxelles',
  type_bien_bruxelles: 'maison',
  user: user
}

begin
  property = Property.new(property_params)

  puts "Property validation:"
  if property.valid?
    puts "✓ Property is valid"
    property.save!
    puts "✓ Property saved successfully with ID: #{property.id}"
  else
    puts "✗ Property validation errors:"
    property.errors.full_messages.each do |error|
      puts "  - #{error}"
    end
  end
rescue => e
  puts "✗ Error creating property: #{e.message}"
  puts e.backtrace.first(5)
end
