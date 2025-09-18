namespace :factures do
  desc "Vérifier les alertes automatiques pour les factures"
  task check_alerts: :environment do
    puts "🔍 Début de vérification des alertes factures..."

    begin
      resultats = FactureAlertService.verifier_alertes_automatiques

      puts "✅ Vérification terminée!"
      puts "📊 Résultats:"
      puts "   • Délais critiques: #{resultats[:delais_critiques].count}"
      puts "   • Dépassements budget: #{resultats[:depassements_budget].count}"
      puts "   • Extractions faibles: #{resultats[:extractions_faibles].count}"
      puts "   • Factures orphelines: #{resultats[:factures_orphelines].count}"
      puts "   • Notifications créées: #{resultats[:notifications_creees]}"

    rescue => e
      puts "❌ Erreur lors de la vérification: #{e.message}"
      puts e.backtrace.first(5) if Rails.env.development?
    end
  end

  desc "Statistiques des factures"
  task stats: :environment do
    puts "📈 Statistiques des factures:"
    puts "   • Total factures: #{Facture.count}"
    puts "   • Factures validées: #{Facture.where(valide_manuellement: true).count}"
    puts "   • Extractions complètes: #{Facture.where(extraction_complete: true).count}"
    puts "   • Factures de solde: #{Facture.where(facture_solde: true).count}"
    puts "   • Délais critiques (< 30j): #{Facture.where('jours_avant_expiration <= ? AND jours_avant_expiration >= 0', 30).count}"
    puts "   • Délais expirés: #{Facture.where('jours_avant_expiration < 0').count}"

    confiance_moyenne = Facture.average(:confiance_ocr)
    puts "   • Confiance OCR moyenne: #{confiance_moyenne&.round(1) || 'N/A'}%"
  end

  desc "Nettoyer les anciennes notifications d'alertes"
  task clean_old_alerts: :environment do
    puts "🧹 Nettoyage des anciennes notifications d'alertes..."

    # Supprimer les notifications de plus de 30 jours
    old_notifications = Notification.where(
      type_notification: 'facture_alerte'
    ).where('created_at < ?', 30.days.ago)

    count = old_notifications.count
    old_notifications.destroy_all

    puts "✅ #{count} anciennes notifications supprimées"
  end

  desc "Recalculer les délais de toutes les factures"
  task recalculate_delays: :environment do
    puts "🔄 Recalcul des délais pour toutes les factures..."

    factures_solde = Facture.where(facture_solde: true)

    factures_solde.find_each do |facture|
      if facture.date_facture.present?
        facture.update_columns(
          date_limite_prime: facture.date_facture + 12.months,
          jours_avant_expiration: ((facture.date_facture + 12.months) - Date.current).to_i
        )
      end
    end

    puts "✅ #{factures_solde.count} factures de solde mises à jour"
  end

  desc "Rapport détaillé des projets avec problèmes"
  task detailed_report: :environment do
    puts "📋 Rapport détaillé des projets avec problèmes de factures:"
    puts "=" * 60

    Project.joins(:factures).group(:id).each do |project|
      validation_service = FactureValidationService.new(project)
      analyse = validation_service.analyser_factures

      # Afficher seulement les projets avec des problèmes
      problemes = []

      if analyse[:comparaison_devis][:status] == 'depassement_important'
        problemes << "Dépassement: #{analyse[:comparaison_devis][:pourcentage_ecart]}%"
      end

      if analyse[:alertes_delais][:status] == 'critique'
        problemes << "Délai critique: #{analyse[:alertes_delais][:jours_restants]} jours"
      end

      if analyse[:anomalies].any?
        problemes << "#{analyse[:anomalies].count} anomalie(s)"
      end

      if problemes.any?
        puts "\n🏗️  Projet: #{project.nom}"
        puts "   User: #{project.user.email}"
        puts "   Problèmes: #{problemes.join(', ')}"
        puts "   Factures: #{project.factures.count}"
        puts "   URL: /projects/#{project.id}/factures_dashboard"
      end
    end

    puts "\n✅ Rapport terminé"
  end
end
