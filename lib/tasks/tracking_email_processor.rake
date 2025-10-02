namespace :tracking do
  desc "Traite manuellement les emails sauvegardés en développement"

  task :process_saved_emails => :environment do
    mail_dir = Rails.root.join('tmp/mails')

    puts "🔍 Recherche d'emails sauvegardés dans #{mail_dir}"

    Dir.glob("#{mail_dir}/*@tracking.*").each do |file_path|
      puts "\n📧 Traitement de l'email: #{File.basename(file_path)}"

      begin
        # Lire le contenu de l'email
        email_content = File.read(file_path)

        # Créer un objet Mail à partir du contenu
        mail = Mail.new(email_content)

        puts "  📬 De: #{mail.from.first if mail.from}"
        puts "  📬 Vers: #{mail.to.first if mail.to}"
        puts "  📬 Sujet: #{mail.subject}"

        # Traiter via la TrackingMailbox
        if mail.to && mail.to.first && mail.to.first.match(/@tracking\./i)
          puts "  🔄 Traitement via TrackingMailbox..."

          # Créer un InboundEmail pour Action Mailbox
          inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(email_content)

          # Traiter l'email
          TrackingMailbox.new(inbound_email).process

          puts "  ✅ Email traité avec succès"

          # Supprimer le fichier traité
          File.delete(file_path)
          puts "  🗑️  Fichier supprimé"

        else
          puts "  ⏭️  Email ignoré (pas une adresse de tracking)"
        end

      rescue => e
        puts "  ❌ Erreur lors du traitement: #{e.message}"
        puts "     #{e.backtrace.first}"
      end
    end

    puts "\n🏁 Traitement terminé"
  end

  task :send_and_process_test => :environment do
    puts "🧪 Test complet: Envoi + Traitement automatique"

    # Étape 1: Nettoyer les anciens emails
    FileUtils.rm_rf(Rails.root.join('tmp/mails/*'))

    # Étape 2: Envoyer les emails de test
    puts "\n📤 Envoi des emails de test..."
    result = Rake::Task["tracking:test_full_cycle"].invoke("robin@primes-services.be")

    # Étape 3: Traiter les emails sauvegardés
    puts "\n🔄 Traitement des emails sauvegardés..."
    Rake::Task["tracking:process_saved_emails"].invoke

    # Étape 4: Vérifier les résultats
    puts "\n📊 Vérification des résultats..."
    request_progress = RequestProgress.last

    if request_progress
      puts "✅ RequestProgress ##{request_progress.id}:"
      puts "  - Email traité à: #{request_progress.email_processed_at}"
      puts "  - Document reçu: #{request_progress.document_recu}"
      puts "  - Statut: #{request_progress.status_administratif}"
      puts "  - Dernière MAJ: #{request_progress.date_derniere_maj}"

      if request_progress.email_processed_at
        puts "\n🎉 Test complet RÉUSSI ! Le cycle d'emails fonctionne."
      else
        puts "\n⚠️  L'email n'a pas été traité automatiquement."
      end
    else
      puts "❌ Aucun RequestProgress trouvé"
    end
  end

  task :show_email_content, [:email_address] => :environment do |t, args|
    email_address = args[:email_address]

    if email_address.nil?
      puts "❌ Usage: rake tracking:show_email_content[email@example.com]"
      exit 1
    end

    file_path = Rails.root.join('tmp/mails', email_address)

    if File.exist?(file_path)
      puts "📧 Contenu de l'email pour #{email_address}:"
      puts "=" * 60
      puts File.read(file_path)
      puts "=" * 60
    else
      puts "❌ Aucun email trouvé pour #{email_address}"
      puts "📁 Emails disponibles:"
      Dir.glob(Rails.root.join('tmp/mails/*')).each do |file|
        puts "  - #{File.basename(file)}"
      end
    end
  end
end
