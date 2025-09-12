#!/usr/bin/env ruby

puts "🔍 TEST MINIMAL - ÉTAPE PAR ÉTAPE"
puts "=" * 40

# Test 1: Le serveur répond-il ?
puts "\n1. Test serveur..."
require 'net/http'
begin
  response = Net::HTTP.get_response(URI('http://localhost:3000'))
  puts "   ✅ Serveur OK (#{response.code})"
rescue => e
  puts "   ❌ Serveur KO: #{e.message}"
  exit 1
end

# Test 2: L'environnement Rails
require_relative '../config/environment'
puts "\n2. Test Rails..."
puts "   ✅ Rails chargé: #{Rails.version}"
puts "   ✅ Environnement: #{Rails.env}"

# Test 3: Y a-t-il des documents ?
puts "\n3. Test documents..."
doc_count = Document.count
puts "   Documents total: #{doc_count}"

if doc_count == 0
  puts "   ❌ AUCUN DOCUMENT ! C'est peut-être le problème."
  puts "   👉 Uploadez d'abord un PDF via l'interface web"
  exit 0
end

# Test 4: Y a-t-il un PDF ?
pdf_doc = Document.joins(:file_attachment, :file_blob)
                  .where(active_storage_blobs: { content_type: 'application/pdf' })
                  .first

if pdf_doc.nil?
  puts "   ❌ AUCUN PDF trouvé !"
  puts "   👉 Uploadez un PDF via l'interface web"
  exit 0
else
  puts "   ✅ PDF trouvé: ID #{pdf_doc.id}"
end

# Test 5: Les boutons sont-ils présents dans la vue ?
puts "\n4. Test des boutons..."
view_file = Rails.root.join('app/views/documents/_type_filtered_documents.html.erb')
if File.exist?(view_file)
  content = File.read(view_file)
  has_stimulus = content.include?('data-controller="document-preview"')
  has_preview_btn = content.include?('data-action="click->document-preview#showRemotePreview"')
  has_download_btn = content.include?('data-action="click->document-preview#downloadFile"')

  puts "   Stimulus controller: #{has_stimulus ? '✅' : '❌'}"
  puts "   Bouton preview: #{has_preview_btn ? '✅' : '❌'}"
  puts "   Bouton download: #{has_download_btn ? '✅' : '❌'}"
else
  puts "   ❌ Fichier vue non trouvé"
end

# Test 6: Le JavaScript est-il présent ?
puts "\n5. Test JavaScript..."
js_file = Rails.root.join('app/javascript/controllers/document_preview_controller.js')
if File.exist?(js_file)
  content = File.read(js_file)
  has_preview_method = content.include?('showRemotePreview')
  has_download_method = content.include?('downloadFile')

  puts "   Fichier JS: ✅"
  puts "   Méthode preview: #{has_preview_method ? '✅' : '❌'}"
  puts "   Méthode download: #{has_download_method ? '✅' : '❌'}"
else
  puts "   ❌ Fichier JS non trouvé"
end

# Test 7: L'API répond-elle ?
puts "\n6. Test API..."
if pdf_doc
  begin
    uri = URI("http://localhost:3000/fr/documents/#{pdf_doc.id}/preview")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'

    response = http.request(request)
    puts "   API Status: #{response.code}"

    if response.code == '200'
      puts "   ✅ API fonctionne !"
      require 'json'
      data = JSON.parse(response.body)
      puts "   Type: #{data['type']}"
      puts "   URL: #{data['url'] ? data['url'][0..50] + '...' : 'nil'}"
    else
      puts "   ❌ API erreur: #{response.body[0..100]}"
    end
  rescue => e
    puts "   ❌ Erreur API: #{e.message}"
  end
end

puts "\n" + "=" * 40
puts "🎯 DIAGNOSTIC TERMINÉ"
puts "Si tout est ✅ mais ça ne marche pas,"
puts "le problème est dans le navigateur (JavaScript/CSP)"
puts "Ouvrez F12 dans le navigateur et regardez les erreurs"
puts "=" * 40
