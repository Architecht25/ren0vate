namespace :bce do
  desc "Import des entreprises de Bruxelles uniquement (~144k entreprises)"
  task import_brussels: :environment do
    puts "🇧🇪 Début de l'import des entreprises de Bruxelles"
    puts "📊 Cible estimée: ~144,000 entreprises (personnes morales, siège social Bruxelles)"
    puts ""

    # Vérification des fichiers
    required_files = %w[address.csv enterprise.csv denomination.csv activity.csv]
    missing_files = required_files.reject do |file|
      File.exist?(Rails.root.join('db', 'bce_data', file))
    end

    if missing_files.any?
      puts "❌ Fichiers manquants: #{missing_files.join(', ')}"
      puts "📂 Placez les fichiers BCE dans db/bce_data/"
      exit 1
    end

    # Confirmation
    print "Continuer avec l'import? (y/N): "
    response = $stdin.gets.chomp.downcase
    unless response == 'y' || response == 'yes'
      puts "❌ Import annulé"
      exit 0
    end

    # Statistiques avant import
    before_count = BceEnterprise.count
    puts "📊 Entreprises déjà en base: #{before_count}"
    puts ""

    # Import
    service = Entreprises::BrusselsBceImportService.new
    result = service.import_brussels_enterprises

    # Statistiques finales
    after_count = BceEnterprise.count
    puts ""
    puts "=" * 60
    puts "📊 RÉSULTATS IMPORT BRUXELLES"
    puts "=" * 60
    puts "✅ Entreprises importées: #{result[:imported]}"
    puts "⏭️  Entreprises ignorées: #{result[:skipped]}"
    puts "❌ Erreurs: #{result[:errors].size}"
    puts "⏱️  Durée: #{result[:duration].round(2)} secondes"
    puts "📈 Total en base: #{before_count} → #{after_count} (+#{after_count - before_count})"
    puts ""

    if result[:errors].any?
      puts "❌ ERREURS DÉTAILLÉES:"
      result[:errors].first(10).each do |error|
        puts "   #{error[:entity_number]}: #{error[:error]}"
      end
      puts "   ... et #{result[:errors].size - 10} autres erreurs" if result[:errors].size > 10
    end

    puts ""
    puts "🎉 Import terminé!"
    puts "💡 Vous pouvez maintenant tester la recherche dans votre application"
  end

  desc "Statistiques des entreprises de Bruxelles"
  task brussels_stats: :environment do
    puts "📊 STATISTIQUES ENTREPRISES BRUXELLES"
    puts "=" * 50

    total = BceEnterprise.joins(:bce_addresses)
                        .where(bce_addresses: {
                          type_of_address: 'REGO',
                          zipcode: %w[1000 1020 1030 1040 1050 1060 1070 1080 1081 1082 1083 1090 1120 1130 1140 1150 1160 1170 1180 1190 1200 1210]
                        }).distinct.count

    puts "Total entreprises Bruxelles: #{total}"
    puts ""

    # Par commune
    puts "📍 RÉPARTITION PAR COMMUNE:"
    communes = {
      '1000' => 'Bruxelles-Ville', '1020' => 'Laeken', '1030' => 'Schaerbeek',
      '1040' => 'Etterbeek', '1050' => 'Ixelles', '1060' => 'Saint-Gilles',
      '1070' => 'Anderlecht', '1080' => 'Molenbeek-Saint-Jean', '1081' => 'Koekelberg',
      '1082' => 'Berchem-Sainte-Agathe', '1083' => 'Ganshoren', '1090' => 'Jette',
      '1120' => 'Neder-Over-Heembeek', '1130' => 'Haren', '1140' => 'Evere',
      '1150' => 'Woluwe-Saint-Pierre', '1160' => 'Auderghem', '1170' => 'Watermael-Boitsfort',
      '1180' => 'Uccle', '1190' => 'Forest', '1200' => 'Woluwe-Saint-Lambert',
      '1210' => 'Saint-Josse-ten-Noode'
    }

    communes.each do |code, name|
      count = BceEnterprise.joins(:bce_addresses)
                          .where(bce_addresses: {
                            type_of_address: 'REGO',
                            zipcode: code
                          }).distinct.count
      puts sprintf("   %s %-25s: %6d entreprises", code, name, count) if count > 0
    end

    puts ""
    puts "💡 Utilisez 'rails bce:import_brussels' pour importer les données"
  end

  desc "Nettoyer les données BCE"
  task clean: :environment do
    print "⚠️  Supprimer toutes les données BCE? (y/N): "
    response = $stdin.gets.chomp.downcase
    unless response == 'y' || response == 'yes'
      puts "❌ Nettoyage annulé"
      exit 0
    end

    puts "🗑️  Suppression des données BCE..."

    count_activities = BceActivity.count
    count_addresses = BceAddress.count
    count_denominations = BceDenomination.count
    count_enterprises = BceEnterprise.count

    BceActivity.delete_all
    BceAddress.delete_all
    BceDenomination.delete_all
    BceEnterprise.delete_all

    puts "✅ Supprimé:"
    puts "   #{count_enterprises} entreprises"
    puts "   #{count_denominations} dénominations"
    puts "   #{count_addresses} adresses"
    puts "   #{count_activities} activités"
    puts ""
    puts "🎯 Base de données BCE nettoyée"
  end
end
