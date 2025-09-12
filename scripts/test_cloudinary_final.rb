#!/usr/bin/env ruby

# Test final pour comprendre le problème Cloudinary PDF
puts "🔍 DIAGNOSTIC FINAL CLOUDINARY PDF"
puts "=" * 50

# Trouver le dernier document PDF plus simplement
last_pdf = Document.where("file_name LIKE '%.pdf'").order(:created_at).last

if last_pdf.nil?
  puts "❌ Aucun PDF trouvé dans la base"

  # Lister tous les documents avec fichiers
  docs_with_files = Document.joins(:file_attachment).limit(5)
  puts "\n📋 Documents disponibles:"
  docs_with_files.each do |doc|
    puts "   - Document ##{doc.id}: #{doc.file_name} (#{doc.file.content_type})"
  end

  # Prendre le premier document trouvé
  last_pdf = docs_with_files.first
  puts "\n📎 Utilisation du document ##{last_pdf&.id} pour le test"
end

if last_pdf.nil?
  puts "❌ Aucun document avec fichier trouvé"
  exit 1
end

puts "📄 PDF trouvé: Document ##{last_pdf.id}"
puts "   Nom: #{last_pdf.file_name}"
puts "   Clé: #{last_pdf.file.key}"
puts "   Service: #{last_pdf.file.service_name}"
puts "   Content-Type: #{last_pdf.file.content_type}"

# Générer l'URL Active Storage
blob_url = Rails.application.routes.url_helpers.rails_blob_url(
  last_pdf.file,
  disposition: "inline",
  host: "localhost:3000"
)
puts "\n📎 URL Active Storage:"
puts "   #{blob_url}"

# Faire une requête HTTP pour voir ce qui se passe
require 'net/http'
require 'uri'

begin
  uri = URI(blob_url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri)

  puts "\n🌐 Test requête HTTP..."
  response = http.request(request)

  puts "   Status: #{response.code} #{response.message}"
  puts "   Content-Type: #{response['content-type']}"
  puts "   Content-Length: #{response['content-length']}"
  puts "   Location: #{response['location']}" if response['location']

  # Si c'est une redirection, suivre
  if response.code.start_with?('3') && response['location']
    cloudinary_url = response['location']
    puts "\n☁️ URL Cloudinary finale:"
    puts "   #{cloudinary_url}"

    # Tester l'URL Cloudinary directement
    cloudinary_uri = URI(cloudinary_url)
    cloudinary_http = Net::HTTP.new(cloudinary_uri.host, cloudinary_uri.port)
    cloudinary_http.use_ssl = true if cloudinary_uri.scheme == 'https'
    cloudinary_request = Net::HTTP::Get.new(cloudinary_uri)

    puts "\n🔗 Test URL Cloudinary directe..."
    cloudinary_response = cloudinary_http.request(cloudinary_request)

    puts "   Status: #{cloudinary_response.code} #{cloudinary_response.message}"
    puts "   Content-Type: #{cloudinary_response['content-type']}"
    puts "   Content-Length: #{cloudinary_response['content-length']}"
    puts "   Content-Disposition: #{cloudinary_response['content-disposition']}"

    # Analyser le contenu
    if cloudinary_response.code == '200'
      content = cloudinary_response.body[0..100]
      if content.start_with?('%PDF')
        puts "   ✅ CONTENU PDF VALIDE!"
      else
        puts "   ❌ Contenu non-PDF:"
        puts "   Début: #{content.inspect}"
      end
    else
      puts "   ❌ Erreur Cloudinary: #{cloudinary_response.body[0..200]}"
    end
  end

rescue => e
  puts "❌ Erreur test: #{e.message}"
  puts "   #{e.backtrace.first}"
end

puts "\n" + "=" * 50
puts "🏁 FIN DU DIAGNOSTIC"
