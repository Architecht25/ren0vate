#!/usr/bin/env ruby

# Test de simulation du controller requests#create
require 'bundler/setup'
require_relative 'config/environment'

puts "Test de simulation du controller pour brouillon..."

user = User.first
if user.nil?
  puts "ERREUR: Aucun utilisateur trouvé"
  exit 1
end

# Simulation des paramètres comme s'ils venaient du formulaire
request_params = {
  title: 'Mon brouillon test',
  description: '',  # Vide intentionnellement
  region: 'flandre',
  nom: '',          # Vide intentionnellement
  prenom: '',       # Vide intentionnellement
  email: '',        # Vide intentionnellement
}

commit_param = "Sauvegarder en brouillon"

puts "Paramètres reçus:"
puts "  commit: '#{commit_param}'"
puts "  request_params: #{request_params}"

# Simulation de la logique du controller
request = Request.new(request_params)
request.user = user

# Logique pour les brouillons (comme dans le controller)
if commit_param == "Sauvegarder en brouillon"
  request.status = 'draft'
  request.title = request.title.present? ? request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
  request.description = request.description.present? ? request.description : "Brouillon en cours de rédaction"
  request.region = request.region.present? ? request.region : nil
else
  request.status = 'draft' if request.status.blank?
end

puts "\nAprès traitement des paramètres:"
puts "  Status: #{request.status}"
puts "  Title: #{request.title}"
puts "  Description: '#{request.description}'"
puts "  Valid?: #{request.valid?}"

if request.valid?
  puts "  Erreurs: Aucune"
else
  puts "  Erreurs: #{request.errors.full_messages.join(', ')}"
end

puts "\nTentative de sauvegarde..."
if request.save
  puts "✅ SUCCÈS: Brouillon sauvegardé avec ID: #{request.id}"

  # Test de redirection (simulation)
  if commit_param == "Sauvegarder en brouillon"
    request.update(status: 'draft')
    puts "✅ Redirection vers requests_path avec message: 'Brouillon sauvegardé avec succès.'"
  end
else
  puts "❌ ÉCHEC: #{request.errors.full_messages.join(', ')}"
end
