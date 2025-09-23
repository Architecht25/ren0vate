#!/usr/bin/env ruby
# Script pour vérifier la persistance et l'accessibilité des documents Wallonie en production
# Usage: rails runner scripts/verify_wallonie_production.rb

puts "🔍 Vérification de la persistance en production - Documents Wallonie"
puts "=" * 80

# Variables de configuration
EXPECTED_ATTESTATIONS = 7
EXPECTED_FORMULAIRES = 2
CLOUDINARY_DOMAIN = "res.cloudinary.com"
CLOUDINARY_CLOUD_NAME = "dtdelexhd"

puts "📊 ÉTAPE 1: Vérification de la configuration"
puts "=" * 50

# Vérifier l'environnement
puts "Environnement: #{Rails.env}"
puts "Base de données: #{ActiveRecord::Base.connection.current_database}"

# Vérifier la configuration Cloudinary
if defined?(Cloudinary)
  puts "✅ Cloudinary configuré"
  puts "   Cloud name: #{Cloudinary.config.cloud_name}"
  puts "   API Key présente: #{Cloudinary.config.api_key.present? ? 'Oui' : 'Non'}"
  puts "   API Secret présente: #{Cloudinary.config.api_secret.present? ? 'Oui' : 'Non'}"
else
  puts "❌ Cloudinary non configuré"
end

# Vérifier Active Storage
puts "Active Storage service: #{Rails.application.config.active_storage.service}"

puts
puts "📊 ÉTAPE 2: Vérification des documents en base"
puts "=" * 50

# Récupérer les documents Wallonie
attestations = PrimeDocumentTemplate.joins(:prime)
                                   .where(primes: { region: 'wallonie' }, type_document: 'attestation_entrepreneur')
                                   .includes(:prime)

formulaires = PrimeDocumentTemplate.joins(:prime)
                                  .where(primes: { region: 'wallonie' }, type_document: 'formulaire_demande')
                                  .includes(:prime)

puts "Documents trouvés:"
puts "- Attestations: #{attestations.count} (attendu: #{EXPECTED_ATTESTATIONS})"
puts "- Formulaires: #{formulaires.count} (attendu: #{EXPECTED_FORMULAIRES})"

# Vérifier le nombre de documents
if attestations.count == EXPECTED_ATTESTATIONS && formulaires.count == EXPECTED_FORMULAIRES
  puts "✅ Nombre de documents correct"
else
  puts "❌ Nombre de documents incorrect"
  puts "   Action requise: Exécuter le script de mise à jour en production"
end

puts
puts "📊 ÉTAPE 3: Vérification des URLs Cloudinary"
puts "=" * 50

all_documents = attestations + formulaires
cloudinary_urls = []
invalid_urls = []

all_documents.each do |doc|
  if doc.file_url.present?
    if doc.file_url.include?(CLOUDINARY_DOMAIN) && doc.file_url.include?(CLOUDINARY_CLOUD_NAME)
      cloudinary_urls << doc
      puts "✅ #{doc.title}: URL Cloudinary valide"
    else
      invalid_urls << doc
      puts "❌ #{doc.title}: URL non-Cloudinary (#{doc.file_url})"
    end
  else
    invalid_urls << doc
    puts "❌ #{doc.title}: Aucune URL définie"
  end
end

puts
puts "Résumé URLs:"
puts "- URLs Cloudinary valides: #{cloudinary_urls.count}"
puts "- URLs invalides/manquantes: #{invalid_urls.count}"

puts
puts "📊 ÉTAPE 4: Test d'accessibilité des PDFs"
puts "=" * 50

require 'net/http'
require 'uri'

def test_url_accessibility(url, title)
  begin
    uri = URI(url)

    # Timeout plus court pour éviter de bloquer
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Head.new(uri)
    response = http.request(request)

    case response.code.to_i
    when 200
      puts "✅ #{title}: Accessible (#{response.code})"
      return true
    when 301, 302
      puts "⚠️  #{title}: Redirection (#{response.code}) vers #{response['location']}"
      return true
    when 403
      puts "❌ #{title}: Accès interdit (#{response.code})"
      return false
    when 404
      puts "❌ #{title}: Fichier non trouvé (#{response.code})"
      return false
    else
      puts "⚠️  #{title}: Statut inattendu (#{response.code})"
      return false
    end
  rescue => e
    puts "❌ #{title}: Erreur de connexion (#{e.class}: #{e.message})"
    return false
  end
end

accessible_count = 0
inaccessible_count = 0

cloudinary_urls.each do |doc|
  if test_url_accessibility(doc.file_url, doc.title)
    accessible_count += 1
  else
    inaccessible_count += 1
  end
end

puts
puts "Résumé accessibilité:"
puts "- PDFs accessibles: #{accessible_count}"
puts "- PDFs inaccessibles: #{inaccessible_count}"

puts
puts "📊 ÉTAPE 5: Test de la méthode download_url"
puts "=" * 50

download_url_errors = []

all_documents.each do |doc|
  begin
    download_url = doc.download_url
    if download_url.present?
      puts "✅ #{doc.title}: download_url généré"
      puts "   URL: #{download_url}"
    else
      download_url_errors << doc
      puts "❌ #{doc.title}: download_url vide"
    end
  rescue => e
    download_url_errors << doc
    puts "❌ #{doc.title}: Erreur download_url (#{e.class}: #{e.message})"
  end
end

puts
puts "Erreurs download_url: #{download_url_errors.count}"

puts
puts "📊 ÉTAPE 6: Vérification de la sécurité CSP"
puts "=" * 50

# Vérifier que Cloudinary est autorisé dans la CSP
csp_file = Rails.root.join('config', 'initializers', 'content_security_policy.rb')

if File.exist?(csp_file)
  csp_content = File.read(csp_file)

  if csp_content.include?('res.cloudinary.com')
    puts "✅ Cloudinary autorisé dans la Content Security Policy"
  else
    puts "❌ Cloudinary non autorisé dans la CSP - PDFs pourraient être bloqués"
    puts "   Action requise: Ajouter 'https://res.cloudinary.com' à la CSP"
  end
else
  puts "⚠️  Fichier CSP non trouvé"
end

puts
puts "📊 ÉTAPE 7: Test d'intégration avec le contrôleur"
puts "=" * 50

# Tester que les documents sont bien exposés via les routes
begin
  # Simuler une requête vers un document
  if attestations.first
    doc = attestations.first
    puts "Test du document ID #{doc.id}:"

    # Vérifier que l'objet a toutes les méthodes nécessaires
    puts "- title: #{doc.title.present? ? 'OK' : 'MANQUANT'}"
    puts "- file_available?: #{doc.file_available? ? 'OK' : 'ÉCHEC'}"
    puts "- download_url: #{doc.download_url.present? ? 'OK' : 'MANQUANT'}"
    puts "- prime associée: #{doc.prime.present? ? 'OK' : 'MANQUANT'}"
  end
rescue => e
  puts "❌ Erreur lors du test d'intégration: #{e.class}: #{e.message}"
end

puts
puts "📊 RAPPORT FINAL"
puts "=" * 50

# Calculer le score de conformité
total_checks = 5
passed_checks = 0

# Check 1: Nombre de documents
if attestations.count == EXPECTED_ATTESTATIONS && formulaires.count == EXPECTED_FORMULAIRES
  passed_checks += 1
end

# Check 2: URLs Cloudinary
if invalid_urls.empty?
  passed_checks += 1
end

# Check 3: Accessibilité des PDFs
if inaccessible_count == 0 && accessible_count > 0
  passed_checks += 1
end

# Check 4: download_url
if download_url_errors.empty?
  passed_checks += 1
end

# Check 5: CSP
if File.exist?(csp_file) && File.read(csp_file).include?('res.cloudinary.com')
  passed_checks += 1
end

score = (passed_checks.to_f / total_checks * 100).round

puts "Score de conformité: #{score}% (#{passed_checks}/#{total_checks})"
puts

if score == 100
  puts "🎉 EXCELLENT! Tous les tests passent."
  puts "   ✅ La configuration est prête pour la production"
  puts "   ✅ Les PDFs seront accessibles aux utilisateurs"
  puts "   ✅ Aucune action requise"
elsif score >= 80
  puts "⚠️  BIEN. La plupart des tests passent."
  puts "   ✅ La configuration de base fonctionne"
  puts "   ⚠️  Quelques améliorations recommandées"
elsif score >= 60
  puts "⚠️  MOYEN. Quelques problèmes détectés."
  puts "   ⚠️  La configuration fonctionne partiellement"
  puts "   ❌ Actions correctives recommandées"
else
  puts "❌ PROBLÈMES CRITIQUES détectés."
  puts "   ❌ La configuration ne fonctionnera pas correctement en production"
  puts "   ❌ Actions correctives OBLIGATOIRES"
end

puts
puts "🔧 ACTIONS RECOMMANDÉES POUR LA PRODUCTION:"
puts "=" * 50

if attestations.count != EXPECTED_ATTESTATIONS || formulaires.count != EXPECTED_FORMULAIRES
  puts "1. Exécuter le script de mise à jour en production:"
  puts "   heroku run rails runner scripts/update_wallonie_documents.rb -a votre-app"
  puts
end

if invalid_urls.any?
  puts "2. Vérifier les URLs Cloudinary manquantes ou incorrectes"
  puts
end

if inaccessible_count > 0
  puts "3. Vérifier l'accessibilité des fichiers sur Cloudinary:"
  puts "   - Fichiers téléchargés correctement?"
  puts "   - Permissions publiques configurées?"
  puts
end

begin
  csp_content = File.read(csp_file)
  if !csp_content.include?('res.cloudinary.com')
    puts "4. Mettre à jour la Content Security Policy"
    puts
  end
rescue
  # Fichier CSP non trouvé ou erreur de lecture
end

puts "5. Tester manuellement depuis l'interface utilisateur en production"
puts "6. Surveiller les logs d'erreurs après déploiement"

puts
puts "🏁 Vérification terminée"
