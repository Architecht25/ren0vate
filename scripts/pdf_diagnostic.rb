#!/usr/bin/env ruby

# Script de diagnostic pour les PDFs
# Usage: bin/rails runner scripts/pdf_diagnostic.rb

puts "=== Diagnostic des PDFs ==="
puts

# Vérifier la configuration Cloudinary
puts "1. Configuration Cloudinary:"
puts "   Cloud Name: #{ENV['CLOUDINARY_CLOUD_NAME'] ? 'OK' : 'MANQUANT'}"
puts "   API Key: #{ENV['CLOUDINARY_API_KEY'] ? 'OK' : 'MANQUANT'}"
puts "   API Secret: #{ENV['CLOUDINARY_API_SECRET'] ? 'OK' : 'MANQUANT'}"
puts

# Trouver des documents PDF
pdf_documents = Document.joins(:file_attachment)
                       .joins("JOIN active_storage_blobs ON active_storage_attachments.blob_id = active_storage_blobs.id")
                       .where("active_storage_blobs.content_type = ?", 'application/pdf')
                       .limit(5)

puts "2. Documents PDF trouvés: #{pdf_documents.count}"
puts

if pdf_documents.any?
  pdf_documents.each_with_index do |doc, index|
    puts "   PDF #{index + 1}:"
    puts "     ID: #{doc.id}"
    puts "     Nom: #{doc.file.filename}"
    puts "     Taille: #{ActionController::Base.helpers.number_to_human_size(doc.file.byte_size)}"
    puts "     Service: #{doc.file.service_name}"
    puts "     Key: #{doc.file.key}"
    puts "     Content Type: #{doc.file.content_type}"

    # Test des URLs
    begin
      blob_url = Rails.application.routes.url_helpers.rails_blob_url(doc.file, host: 'localhost:3000')
      puts "     Blob URL: #{blob_url}"
    rescue => e
      puts "     Blob URL: ERREUR - #{e.message}"
    end

    # Test Cloudinary si disponible
    if doc.file.service_name.to_s == 'cloudinary'
      begin
        cloudinary_url = doc.cloudinary_url
        puts "     Cloudinary URL: #{cloudinary_url ? 'OK' : 'ERREUR'}"
      rescue => e
        puts "     Cloudinary URL: ERREUR - #{e.message}"
      end

      begin
        preview_url = doc.cloudinary_preview_url
        puts "     Preview URL: #{preview_url ? 'OK' : 'Non disponible'}"
      rescue => e
        puts "     Preview URL: ERREUR - #{e.message}"
      end
    end

    puts
  end
else
  puts "   Aucun PDF trouvé dans la base de données."
  puts "   Créez un document PDF pour tester la fonctionnalité."
end

puts "3. Tests de service:"

# Test du service CloudinaryPdfService
if defined?(CloudinaryPdfService)
  puts "   CloudinaryPdfService: Disponible"
else
  puts "   CloudinaryPdfService: NON CHARGÉ"
end

# Test de la configuration Active Storage
case Rails.application.config.active_storage.service
when :cloudinary
  puts "   Service Active Storage: Cloudinary (Production)"
when :local
  puts "   Service Active Storage: Local (Développement)"
else
  puts "   Service Active Storage: #{Rails.application.config.active_storage.service}"
end

puts
puts "=== Fin du diagnostic ==="
