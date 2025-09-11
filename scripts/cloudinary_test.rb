#!/usr/bin/env ruby

puts "=== Test de configuration Cloudinary ==="

# Vérification des variables d'environnement
cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
api_key = ENV['CLOUDINARY_API_KEY']
api_secret = ENV['CLOUDINARY_API_SECRET']

puts "\n1. Variables d'environnement:"
puts "   CLOUDINARY_CLOUD_NAME: #{cloud_name.present? ? 'OK' : 'MANQUANTE'}"
puts "   CLOUDINARY_API_KEY: #{api_key.present? ? 'OK' : 'MANQUANTE'}"
puts "   CLOUDINARY_API_SECRET: #{api_secret.present? ? 'OK' : 'MANQUANTE'}"

if cloud_name.blank? || api_key.blank? || api_secret.blank?
  puts "\n❌ ERREUR: Configuration Cloudinary incomplète!"
  puts "Vérifiez vos variables d'environnement Heroku:"
  puts "heroku config:get CLOUDINARY_CLOUD_NAME"
  puts "heroku config:get CLOUDINARY_API_KEY"
  puts "heroku config:get CLOUDINARY_API_SECRET"
  exit 1
end

# Test de connexion à Cloudinary
puts "\n2. Test de connexion Cloudinary:"
begin
  require 'cloudinary'
  
  # Configuration
  Cloudinary.config do |config|
    config.cloud_name = cloud_name
    config.api_key = api_key
    config.api_secret = api_secret
    config.secure = true
  end
  
  # Test simple
  result = Cloudinary::Api.ping
  puts "   ✅ Connexion Cloudinary: OK"
  puts "   Cloud: #{cloud_name}"
  
rescue => e
  puts "   ❌ Erreur de connexion Cloudinary: #{e.message}"
  exit 1
end

# Test Active Storage
puts "\n3. Configuration Active Storage:"
puts "   Service en cours: #{Rails.application.config.active_storage.service}"

if Rails.application.config.active_storage.service == :cloudinary
  puts "   ✅ Active Storage configuré pour Cloudinary"
else
  puts "   ⚠️  Active Storage utilise: #{Rails.application.config.active_storage.service}"
end

# Test des documents
puts "\n4. Test des documents PDFs:"
pdf_count = Document.joins(:file_attachment).where(active_storage_blobs: { content_type: 'application/pdf' }).count
puts "   Nombre de PDFs en base: #{pdf_count}"

if pdf_count > 0
  latest_pdf = Document.joins(:file_attachment).where(active_storage_blobs: { content_type: 'application/pdf' }).last
  puts "   Dernier PDF (ID: #{latest_pdf.id}):"
  puts "     - Nom: #{latest_pdf.file.filename}"
  puts "     - Service: #{latest_pdf.file.service_name}"
  puts "     - Key: #{latest_pdf.file.key}"
  puts "     - URL: #{Rails.application.routes.url_helpers.rails_blob_url(latest_pdf.file)}"
  
  # Test d'accès au fichier
  begin
    latest_pdf.file.download(limit: 1024)
    puts "     - ✅ Fichier accessible"
  rescue => e
    puts "     - ❌ Erreur d'accès: #{e.message}"
  end
end

puts "\n=== Fin du test ==="