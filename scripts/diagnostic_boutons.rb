#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔍 Diagnostic approfondi des boutons de prévisualisation"
puts "=" * 60

# Trouve un document PDF
document = Document.joins(:file_attachment).joins('JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id').where(active_storage_blobs: { content_type: 'application/pdf' }).last

if document&.file&.attached?
  puts "\n📄 Document trouvé:"
  puts "   ID: #{document.id}"
  puts "   Nom: #{document.file.filename}"
  puts "   Service: #{document.file.service_name}"
  puts "   URL de base: #{document.file.url[0..80]}..."
  
  puts "\n🔗 Test des routes:"
  
  # Test 1: Route preview
  puts "\n1. Route preview: /fr/documents/#{document.id}/preview"
  begin
    require 'net/http'
    require 'json'
    
    uri = URI("http://localhost:3000/fr/documents/#{document.id}/preview")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    
    puts "   Tentative de connexion à #{uri}..."
    response = http.request(request)
    puts "   Status: #{response.code} #{response.message}"
    
    if response.code == "200"
      data = JSON.parse(response.body)
      puts "   ✅ Réponse JSON valide:"
      puts "      - Type: #{data['type']}"
      puts "      - URL: #{data['url'][0..60]}..." if data['url']
      puts "      - Nom: #{data['filename']}" if data['filename']
    else
      puts "   ❌ Erreur: #{response.body[0..100]}..."
    end
  rescue => e
    puts "   ❌ Erreur de connexion: #{e.message}"
    puts "   💡 Le serveur Rails n'est probablement pas démarré"
  end
  
  # Test 2: Route download
  puts "\n2. Route download: /fr/documents/#{document.id}/download"
  begin
    uri = URI("http://localhost:3000/fr/documents/#{document.id}/download")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    puts "   Status: #{response.code} #{response.message}"
    
    if response.code == "302"
      puts "   ✅ Redirection vers: #{response['Location'][0..60]}..."
    else
      puts "   ❌ Réponse inattendue: #{response.body[0..100]}..."
    end
  rescue => e
    puts "   ❌ Erreur: #{e.message}"
  end
  
  # Test 3: Vérification du controller
  puts "\n3. Test direct du controller:"
  begin
    require 'app/controllers/documents_controller'
    controller = DocumentsController.new
    
    # Simulation d'une requête
    puts "   Controller class: #{controller.class}"
    puts "   Méthodes disponibles: #{controller.class.instance_methods(false).select { |m| m.to_s.include?('preview') || m.to_s.include?('download') }}"
  rescue => e
    puts "   ❌ Erreur controller: #{e.message}"
  end
  
  # Test 4: Vérification du JavaScript
  puts "\n4. Vérification du controller Stimulus:"
  stimulus_file = Rails.root.join('app/javascript/controllers/document_preview_controller.js')
  if File.exist?(stimulus_file)
    content = File.read(stimulus_file)
    puts "   ✅ Fichier Stimulus trouvé"
    puts "   Méthodes définies:"
    content.scan(/(\w+)\s*\([^)]*\)\s*{/).each do |method|
      puts "     - #{method[0]}"
    end
  else
    puts "   ❌ Fichier Stimulus manquant: #{stimulus_file}"
  end
  
else
  puts "\n❌ Aucun document PDF trouvé"
  puts "Créez un document en uploadant un PDF via l'interface web"
end

puts "\n" + "=" * 60
puts "🚀 Pour tester manuellement:"
puts "1. Démarrez le serveur: rails server"
puts "2. Allez sur: http://localhost:3000/fr/documents"
puts "3. Trouvez un PDF et testez les boutons"
puts "4. Ouvrez la console du navigateur (F12) pour voir les erreurs JS"
puts "=" * 60