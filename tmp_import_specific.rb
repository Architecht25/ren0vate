#!/usr/bin/env ruby

puts "🔄 Import de l'entreprise 0833.618.097 (PRIMES-SERVICES)..."

begin
  service = Entreprises::FastBceImportService.new
  result = service.import_specific_enterprise("0833.618.097")

  # Vérifier si l'import a réussi
  enterprise = BceEnterprise.find_by_number("0833.618.097")

  if enterprise
    denomination = enterprise.bce_denominations.first&.denomination || "Sans dénomination"
    puts "✅ Import réussi : #{denomination}"
    puts "📍 Adresse : #{enterprise.bce_addresses.first&.street_fr || 'N/A'}"
    puts "🏢 Statut : #{enterprise.status}"
    puts "📊 Nombre d'activités : #{enterprise.bce_activities.count}"
    puts "📧 Nombre de dénominations : #{enterprise.bce_denominations.count}"
  else
    puts "❌ Échec de l'import - Entreprise non trouvée après import"
  end

rescue StandardError => e
  puts "❌ Erreur lors de l'import : #{e.message}"
  puts "🔍 Backtrace : #{e.backtrace.first(3).join("\n")}"
end

puts "🔢 Total entreprises BCE en base : #{BceEnterprise.count}"
