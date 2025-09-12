#!/usr/bin/env ruby

puts '🔄 TEST SERVICE PUBLIQUE PERSONNALISÉ'
puts '=' * 45

require_relative '../app/services/cloudinary_public_service'

# Testons avec un blob PDF existant
blob = ActiveStorage::Blob.where(content_type: 'application/pdf').last
if blob
  puts "📄 PDF: #{blob.filename} (ID: #{blob.id})"
  puts "   Key: #{blob.key}"

  # Créons une instance du service public
  public_service = CloudinaryPublicService.new(
    cloud_name: ENV['CLOUDINARY_CLOUD_NAME'],
    api_key: ENV['CLOUDINARY_API_KEY'],
    api_secret: ENV['CLOUDINARY_API_SECRET'],
    folder: Rails.env
  )

  begin
    public_url = public_service.url(blob.key, filename: blob.filename)
    puts "   📡 URL publique: #{public_url}"
    puts ""
    puts "🧪 TESTEZ CETTE URL DANS VOTRE NAVIGATEUR:"
    puts "   #{public_url}"

    if public_url.include?('_a=')
      puts "   ❌ URL encore signée"
    else
      puts "   ✅ URL publique sans signature!"
    end
  rescue => e
    puts "   ❌ Erreur: #{e.message}"
  end
else
  puts '❌ Aucun PDF trouvé'
end
