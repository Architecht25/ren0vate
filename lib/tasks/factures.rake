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

  # ---------------------------------------------------------------------------
  # Backfill OCR : traite tous les documents de type "facture" déjà uploadés
  # qui n'ont pas encore d'enregistrement Facture associé.
  #
  # Usage :
  #   rails factures:backfill_ocr
  #   rails factures:backfill_ocr DRY_RUN=true     # aperçu sans écrire
  #   rails factures:backfill_ocr USER_ID=42        # limiter à un utilisateur
  # ---------------------------------------------------------------------------
  desc "Backfill OCR : extrait les données des factures uploadées sans enregistrement Facture"
  task backfill_ocr: :environment do
    dry_run = ENV['DRY_RUN'].present?
    user_id = ENV['USER_ID'].present? ? ENV['USER_ID'].to_i : nil

    puts dry_run ? "🔍 [DRY RUN] Aucune donnée ne sera écrite." : "🚀 Backfill OCR factures — démarrage..."
    puts "   Filtré sur user_id=#{user_id}" if user_id

    # Documents de type facture, liés à un projet, sans Facture existante
    scope = Document
      .where(type_document: 'facture')
      .where.not(project_id: nil)
      .left_outer_joins(:facture)
      .where(factures: { id: nil })
      .includes(:project)

    scope = scope.where(user_id: user_id) if user_id

    total   = scope.count
    traites = 0
    erreurs = 0
    ignores = 0

    puts "   #{total} document(s) éligible(s) trouvé(s).\n\n"

    scope.find_each do |document|
      project = document.project

      unless document.file.attached?
        puts "  ⚠️  Document ##{document.id} — pas de fichier attaché, ignoré."
        ignores += 1
        next
      end

      print "  📄 Document ##{document.id} (projet ##{project.id} — #{project.try(:nom) || 'sans nom'}) ... "

      begin
        # Télécharger le fichier depuis ActiveStorage en mémoire
        file_data = document.file.download
        file_io = StringIO.new(file_data)
        filename = document.file.filename.to_s
        content_type = document.file.content_type
        file_size = document.file.byte_size

        # Décorer le StringIO pour que OcrService / FactureOcrService puisse l'utiliser
        file_io.define_singleton_method(:original_filename) { filename }
        file_io.define_singleton_method(:content_type) { content_type }
        file_io.define_singleton_method(:size) { file_size }
        file_io.define_singleton_method(:path) { nil }

        service = FactureOcrService.new(file_io)
        result  = service.extraire_donnees_facture

        unless result[:success] && result[:donnees_facture]
          puts "❌ OCR échoué : #{result[:error]}"
          erreurs += 1
          next
        end

        donnees = result[:donnees_facture]
        puts "✅ montant=#{donnees[:montant]} | date=#{donnees[:date_facture]} | type=#{donnees[:type_facture]} | confiance=#{result[:confiance_extraction]}%"

        unless dry_run
          arch_nom = project.architecte_entreprise&.downcase&.strip
          type_intervenant = if donnees[:nom_entreprise].present? && arch_nom.present? &&
                                donnees[:nom_entreprise].downcase.include?(arch_nom.split.first || '')
                               'architecte'
                             else
                               'entrepreneur'
                             end

          Facture.create!(
            document:              document,
            project:               project,
            property:              document.property || project.property,
            montant:               donnees[:montant] || 0,
            numero_facture:        donnees[:numero_facture],
            date_facture:          donnees[:date_facture],
            type_facture:          donnees[:type_facture] || 'facture',
            statut_paiement:       'non_paye',
            nom_entreprise:        donnees[:nom_entreprise],
            numero_bce_entreprise: donnees[:numero_bce],
            montant_ht:            donnees[:montant_ht],
            montant_tva:           donnees[:montant_tva],
            taux_tva:              donnees[:taux_tva],
            confiance_ocr:         result[:confiance_extraction],
            extraction_complete:   result[:extraction_complete],
            texte_ocr_brut:        result[:texte_brut],
            donnees_extraites:     donnees,
            type_intervenant:      type_intervenant,
            valide_manuellement:   false
          )
        end

        traites += 1

      rescue => e
        puts "❌ Erreur : #{e.message}"
        Rails.logger.error "backfill_ocr document ##{document.id}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
        erreurs += 1
      end
    end

    puts "\n#{'─' * 60}"
    puts "  Total éligibles : #{total}"
    puts "  Traités         : #{traites}"
    puts "  Ignorés         : #{ignores} (pas de fichier)"
    puts "  Erreurs         : #{erreurs}"
    puts dry_run ? "\n  [DRY RUN] Relancez sans DRY_RUN=true pour appliquer." : "\n  ✅ Backfill terminé."
  end
end

