#!/usr/bin/env ruby

# Test des fonctionnalités de prévisualisation avec Cloudinary
puts "🔍 Test des fonctionnalités de prévisualisation de documents avec Cloudinary"
puts "=" * 70

# Chargement de l'environnement Rails
require_relative '../config/environment'

# Test 1: Vérification de la configuration Active Storage
puts "\n1. Configuration Active Storage :"
puts "   Service utilisé : #{Rails.application.config.active_storage.service}"

# Test 2: Récupération d'un document existant
document = Document.joins(:file_attachment).last
if document&.file&.attached?
  puts "\n2. Document de test trouvé :"
  puts "   ID: #{document.id}"
  puts "   Nom: #{document.file.filename}"
  puts "   Type: #{document.file.content_type}"
  puts "   Service: #{document.file.service_name}"
  puts "   Taille: #{document.file.byte_size} bytes"

  # Test 3: URL de prévisualisation
  puts "\n3. Test des URLs :"
  begin
    url = document.file.url
    puts "   ✅ URL Active Storage: #{url[0..80]}..."

    # Test si c'est une URL Cloudinary
    if url.include?('cloudinary.com')
      puts "   ✅ Utilise bien Cloudinary !"
    else
      puts "   ⚠️  N'utilise pas Cloudinary"
    end
  rescue => e
    puts "   ❌ Erreur URL: #{e.message}"
  end

  # Test 4: URL spécifique pour PDF preview
  if document.file.content_type == 'application/pdf'
    puts "\n4. Test PDF preview :"
    begin
      # Test de l'URL avec nos méthodes personnalisées
      if document.respond_to?(:cloudinary_pdf_url)
        cloudinary_url = document.cloudinary_pdf_url
        puts "   URL PDF Cloudinary: #{cloudinary_url[0..80]}..." if cloudinary_url
      end

      # Test via le controller
      puts "   Route preview: /fr/documents/#{document.id}/preview"

    rescue => e
      puts "   ❌ Erreur PDF: #{e.message}"
    end
  end

else
  puts "\n❌ Aucun document avec fichier attaché trouvé"
  puts "   Vous pouvez en uploader un via l'interface web pour tester"
end

puts "\n5. Routes disponibles pour les documents :"
routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('documents') }
routes.each do |route|
  puts "   #{route.verb.ljust(6)} #{route.path.spec}"
end

puts "\n" + "=" * 70
puts "🎯 Pour tester :"
puts "1. Allez sur http://localhost:3000/fr/documents"
puts "2. Uploadez un PDF"
puts "3. Cliquez sur les boutons de prévisualisation et téléchargement"
puts "4. Vérifiez que les URLs pointent vers Cloudinary"
puts "=" * 70
