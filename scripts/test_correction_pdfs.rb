#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔧 CORRECTION DES URLs CLOUDINARY POUR LES PDFs EXISTANTS"
puts "=" * 60

# Trouve tous les PDFs Cloudinary
pdf_documents = Document.joins(:file_attachment, :file_blob)
                       .where(active_storage_blobs: { content_type: 'application/pdf' })
                       .where(active_storage_blobs: { service_name: 'cloudinary' })

puts "\n📊 Documents PDF trouvés: #{pdf_documents.count}"

pdf_documents.each do |doc|
  puts "\n📄 Document ID: #{doc.id}"
  puts "   Nom: #{doc.file.filename}"
  puts "   Clé Cloudinary: #{doc.file.key}"

  begin
    # URL actuelle (probablement avec resource_type: image)
    current_url = doc.file.url
    puts "   ❌ URL actuelle (image): #{current_url[0..80]}..."

    # URL corrigée avec resource_type: raw
    corrected_url = CloudinaryPdfService.generate_pdf_url(doc.file.key)
    if corrected_url
      puts "   ✅ URL corrigée (raw): #{corrected_url[0..80]}..."

      # Test si l'URL corrigée est accessible
      require 'net/http'
      require 'uri'

      begin
        uri = URI(corrected_url)
        response = Net::HTTP.get_response(uri)
        puts "   🌐 Test d'accès URL corrigée: #{response.code} #{response.message}"

        if response.code == '200'
          puts "   ✅ PDF accessible avec resource_type: raw !"
        else
          puts "   ❌ PDF non accessible avec resource_type: raw"
        end
      rescue => e
        puts "   ⚠️  Erreur test URL: #{e.message}"
      end

    else
      puts "   ❌ Impossible de générer l'URL corrigée"
    end

  rescue => e
    puts "   ❌ Erreur: #{e.message}"
  end

  puts "   " + "-" * 50
end

puts "\n🎯 SOLUTION RECOMMANDÉE:"
puts "Si les URLs avec resource_type: raw fonctionnent,"
puts "alors le problème est confirmé et la solution est:"
puts "1. Utiliser CloudinaryPdfService.generate_pdf_url pour les PDFs"
puts "2. S'assurer que les nouveaux PDFs utilisent resource_type: raw"
puts "3. Peut-être re-uploader les PDFs existants si nécessaire"

puts "\n" + "=" * 60
