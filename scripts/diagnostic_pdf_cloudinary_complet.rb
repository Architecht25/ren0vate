#!/usr/bin/env ruby

# Script de diagnostic complet pour les PDF Cloudinary
# Ce script trace le cycle de vie complet des documents PDF

puts "🔍 DIAGNOSTIC COMPLET CLOUDINARY PDF"
puts "=" * 60

# 1. Vérification de la configuration
puts "\n1. 📋 Configuration Cloudinary"
puts "-" * 30

config_ok = true
%w[CLOUDINARY_CLOUD_NAME CLOUDINARY_API_KEY CLOUDINARY_API_SECRET].each do |var|
  value = ENV[var]
  if value.present?
    puts "   ✅ #{var}: #{value[0..5]}..."
  else
    puts "   ❌ #{var}: NON DÉFINI"
    config_ok = false
  end
end

puts "   🌍 Environnement: #{Rails.env}"
puts "   🔒 Secure mode: #{Rails.env.production?}"

unless config_ok
  puts "\n❌ Configuration Cloudinary incomplète !"
  exit 1
end

# 2. Test du service Active Storage
puts "\n2. 📦 Service Active Storage"
puts "-" * 30

storage_service = Rails.application.config.active_storage.service
puts "   Service configuré: #{storage_service}"

# 3. Recherche de documents test
puts "\n3. 📄 Documents PDF disponibles"
puts "-" * 30

pdf_documents = Document.joins(:file_attachment)
                       .where(active_storage_blobs: { content_type: 'application/pdf' })
                       .limit(3)

if pdf_documents.empty?
  puts "   ⚠️  Aucun PDF trouvé en base"

  # Chercher n'importe quel document avec fichier
  any_document = Document.joins(:file_attachment).first
  if any_document
    puts "   📎 Document test disponible: #{any_document.file_name} (#{any_document.file.content_type})"
    pdf_documents = [any_document]
  else
    puts "   ❌ Aucun document avec fichier trouvé"
    puts "\n💡 Uploadez un PDF via l'interface pour tester"
    exit 0
  end
else
  puts "   ✅ #{pdf_documents.count} PDF(s) trouvé(s)"
end

# 4. Test détaillé pour chaque document
pdf_documents.each_with_index do |doc, index|
  puts "\n#{4 + index}. 🔬 Test Document ##{doc.id}"
  puts "-" * 40

  puts "   📁 Informations de base:"
  puts "      Nom: #{doc.file_name}"
  puts "      Type: #{doc.file.content_type}"
  puts "      Taille: #{doc.file_size_human}"
  puts "      Service: #{doc.file.service_name}"
  puts "      Clé: #{doc.file.key}"

  puts "\n   🔗 Test des URLs:"

  # Test URL Cloudinary
  begin
    cloudinary_url = doc.cloudinary_url
    if cloudinary_url
      puts "      ✅ URL Cloudinary: #{cloudinary_url[0..80]}..."

      # Test de l'accessibilité de l'URL
      begin
        require 'net/http'
        uri = URI(cloudinary_url)
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.head(uri.path + (uri.query ? "?#{uri.query}" : ""))
        end
        puts "      ✅ Status HTTP: #{response.code} #{response.message}"
        puts "      📏 Content-Length: #{response['content-length']} bytes"
        puts "      📋 Content-Type: #{response['content-type']}"
      rescue => e
        puts "      ❌ Erreur HTTP: #{e.message}"
      end
    else
      puts "      ❌ URL Cloudinary: NON GÉNÉRÉE"
    end
  rescue => e
    puts "      ❌ Erreur Cloudinary URL: #{e.message}"
  end

  # Test URL de preview
  if doc.is_pdf?
    begin
      preview_url = doc.cloudinary_preview_url
      if preview_url
        puts "      ✅ URL Preview: #{preview_url[0..80]}..."
      else
        puts "      ⚠️  URL Preview: Non disponible (normal pour les non-PDF)"
      end
    rescue => e
      puts "      ❌ Erreur Preview URL: #{e.message}"
    end
  end

  # Test Rails blob URL (fallback)
  begin
    blob_url = Rails.application.routes.url_helpers.rails_blob_url(doc.file)
    puts "      ✅ Rails Blob URL: #{blob_url[0..80]}..."
  rescue => e
    puts "      ❌ Erreur Rails Blob: #{e.message}"
  end

  puts "\n   📊 Routes de test:"
  puts "      Preview: #{Rails.application.routes.url_helpers.preview_document_url(doc)}"
  puts "      Download: #{Rails.application.routes.url_helpers.download_document_url(doc)}"
  puts "      View: #{Rails.application.routes.url_helpers.view_document_url(doc)}"

  # Test de téléchargement local
  puts "\n   💾 Test de téléchargement:"
  begin
    file_data = doc.file.download(limit: 2048) # Limiter à 2KB pour le test
    puts "      ✅ Téléchargement OK (#{file_data.bytesize} bytes)"

    if doc.is_pdf?
      is_valid_pdf = file_data.start_with?('%PDF')
      puts "      #{is_valid_pdf ? '✅' : '❌'} Format PDF valide: #{is_valid_pdf}"
    end
  rescue => e
    puts "      ❌ Erreur téléchargement: #{e.message}"
  end
end

# 5. Test des services
puts "\n#{4 + pdf_documents.count + 1}. 🛠️  Services disponibles"
puts "-" * 30

services_to_test = %w[CloudinaryPdfService]
services_to_test.each do |service_name|
  begin
    service_class = service_name.constantize
    puts "   ✅ #{service_name}: Disponible"

    # Test des méthodes publiques
    if service_class.respond_to?(:generate_pdf_url)
      puts "      ✅ generate_pdf_url: Disponible"
    end
    if service_class.respond_to?(:generate_preview_url)
      puts "      ✅ generate_preview_url: Disponible"
    end
  rescue NameError
    puts "   ❌ #{service_name}: NON TROUVÉ"
  rescue => e
    puts "   ⚠️  #{service_name}: Erreur - #{e.message}"
  end
end

# 6. Instructions de test
puts "\n#{4 + pdf_documents.count + 2}. 🎯 Instructions de test"
puts "-" * 30

puts "   1. Démarrez votre serveur Rails:"
puts "      bin/rails server"
puts
puts "   2. Allez sur la page des documents:"
puts "      http://localhost:3000/fr/documents"
puts
puts "   3. Uploadez un nouveau PDF et testez:"
puts "      - Le bouton 'Prévisualiser'"
puts "      - Le bouton 'Télécharger'"
puts
puts "   4. Vérifiez les logs Rails pour les messages:"
puts "      - 🔗 URL PDF générée avec resource_type: raw"
puts "      - 📄 PDF détecté - utilisation CloudinaryPdfService"
puts "      - ☁️ Redirection vers Cloudinary"

puts "\n" + "=" * 60
puts "✅ Diagnostic terminé. Vérifiez les logs Rails lors des tests !"
puts "=" * 60
