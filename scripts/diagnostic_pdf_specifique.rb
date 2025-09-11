#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔍 DIAGNOSTIC SPÉCIFIQUE PDF vs AUTRES TYPES"
puts "=" * 50

# Trouve différents types de documents
pdf_doc = Document.joins(:file_attachment, :file_blob).where(active_storage_blobs: { content_type: 'application/pdf' }).first
image_doc = Document.joins(:file_attachment, :file_blob).where("active_storage_blobs.content_type LIKE 'image/%'").first
other_doc = Document.joins(:file_attachment, :file_blob).where.not(active_storage_blobs: { content_type: ['application/pdf'] }).where.not("active_storage_blobs.content_type LIKE 'image/%'").first

puts "\n📄 Documents trouvés:"
puts "   PDF: #{pdf_doc ? "ID #{pdf_doc.id} - #{pdf_doc.file.filename}" : "Aucun"}"
puts "   Image: #{image_doc ? "ID #{image_doc.id} - #{image_doc.file.filename}" : "Aucun"}"
puts "   Autre: #{other_doc ? "ID #{other_doc.id} - #{other_doc.file.filename}" : "Aucun"}"

def test_document_urls(doc, type_name)
  return unless doc&.file&.attached?
  
  puts "\n🔗 Test #{type_name} (ID: #{doc.id}):"
  puts "   Content-Type: #{doc.file.content_type}"
  puts "   Service: #{doc.file.service_name}"
  
  begin
    # URL de base
    base_url = doc.file.url
    puts "   ✅ URL de base: #{base_url[0..80]}..."
    
    # Test des routes Rails
    puts "   Routes Rails:"
    puts "     - View: /fr/documents/#{doc.id}/view"
    puts "     - Download: /fr/documents/#{doc.id}/download"  
    puts "     - Preview: /fr/documents/#{doc.id}/preview"
    
    # Test spécifique pour PDF
    if doc.file.content_type == 'application/pdf'
      puts "   🔍 Tests spécifiques PDF:"
      
      # Test URL avec disposition inline vs attachment
      begin
        inline_url = doc.file.url(disposition: :inline)
        puts "     ✅ URL inline: #{inline_url[0..60]}..."
      rescue => e
        puts "     ❌ Erreur URL inline: #{e.message}"
      end
      
      begin
        attachment_url = doc.file.url(disposition: :attachment)
        puts "     ✅ URL attachment: #{attachment_url[0..60]}..."
      rescue => e
        puts "     ❌ Erreur URL attachment: #{e.message}"
      end
      
      # Test Cloudinary spécifique pour PDF
      if base_url.include?('cloudinary.com')
        puts "     📊 Analyse URL Cloudinary:"
        puts "       - Contient 'image/upload': #{base_url.include?('image/upload')}"
        puts "       - Contient '.pdf': #{base_url.include?('.pdf')}"
        puts "       - Resource type détecté: #{base_url.match(/\/(image|video|raw|auto)\/upload/) ? $1 : 'non détecté'}"
      end
    end
    
  rescue => e
    puts "   ❌ Erreur: #{e.message}"
  end
end

# Test chaque type
test_document_urls(pdf_doc, "PDF")
test_document_urls(image_doc, "IMAGE") if image_doc
test_document_urls(other_doc, "AUTRE") if other_doc

puts "\n🔧 TESTS DES CONTROLLERS:"

# Test direct des méthodes du controller
controller = DocumentsController.new
puts "   Controller chargé: #{controller.class}"

# Simulation de paramètres
if pdf_doc
  puts "\n   Test simulation controller pour PDF #{pdf_doc.id}:"
  
  # Créer un contexte de requête fictif
  class FakeRequest
    def format
      Mime::Type.lookup('application/json')
    end
  end
  
  class FakeResponse
    attr_accessor :body, :status
    def initialize
      @body = nil
      @status = 200
    end
  end
  
  controller.instance_variable_set(:@document, pdf_doc)
  controller.request = FakeRequest.new
  controller.response = FakeResponse.new
  
  begin
    # Test de la logique de preview
    puts "     Test logique preview..."
    
    # Vérification des conditions
    puts "       - Document trouvé: #{controller.instance_variable_get(:@document) ? 'Oui' : 'Non'}"
    puts "       - Fichier attaché: #{pdf_doc.file.attached? ? 'Oui' : 'Non'}"
    puts "       - Content type: #{pdf_doc.file.content_type}"
    
  rescue => e
    puts "     ❌ Erreur simulation: #{e.message}"
  end
end

puts "\n" + "=" * 50
puts "🎯 PROCHAINES ÉTAPES DE DEBUG:"
puts "1. Tester manuellement les URLs générées"
puts "2. Vérifier les logs du serveur lors des clics"
puts "3. Examiner la console navigateur (F12) pour les erreurs JS"
puts "4. Comparer le comportement PDF vs Image"
puts "=" * 50