namespace :tracking do
  desc "Test direct de la TrackingMailbox"

  task :test_direct_mailbox => :environment do
    puts "🧪 Test direct de la TrackingMailbox"

    # Trouver un RequestProgress pour le test
    request_progress = RequestProgress.last
    puts "📧 RequestProgress utilisé: ##{request_progress.id} - #{request_progress.email_suivi}"

    # Créer un email de test simple
    test_email_content = <<~EMAIL
      From: robin@primes-services.be
      To: #{request_progress.email_suivi}
      Subject: Test de mise à jour - Dossier #{request_progress.id}
      Content-Type: text/plain; charset=UTF-8

      Bonjour,

      Ceci est un test de mise à jour pour votre dossier.

      Numéro de dossier: TEST-#{request_progress.id}-#{Date.current.strftime('%Y%m%d')}
      Statut: En cours d'examen

      Cordialement,
      Service des Primes
    EMAIL

    begin
      # Créer un objet Mail
      mail = Mail.new(test_email_content)
      puts "📬 Email créé: #{mail.subject}"
      puts "📬 De: #{mail.from.first}"
      puts "📬 Vers: #{mail.to.first}"

      # Créer un InboundEmail pour Action Mailbox
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(test_email_content)

      if inbound_email && inbound_email.persisted?
        puts "📥 InboundEmail créé: ##{inbound_email.id}"
      else
        puts "❌ Échec de création d'InboundEmail"
        next
      end

      # État avant traitement
      puts "\n📊 État AVANT traitement:"
      puts "  - Document reçu: #{request_progress.document_recu}"
      puts "  - Email traité: #{request_progress.email_processed_at}"
      puts "  - Statut: #{request_progress.status_administratif}"

      # Traiter directement avec TrackingMailbox
      mailbox = TrackingMailbox.new(inbound_email)
      mailbox.process

      # Recharger et vérifier
      request_progress.reload
      puts "\n📊 État APRÈS traitement:"
      puts "  - Document reçu: #{request_progress.document_recu}"
      puts "  - Email traité: #{request_progress.email_processed_at}"
      puts "  - Statut: #{request_progress.status_administratif}"
      puts "  - Dernière MAJ: #{request_progress.date_derniere_maj}"

      puts "\n✅ Test direct réussi!"

    rescue => e
      puts "\n❌ Erreur lors du test direct:"
      puts "  #{e.class}: #{e.message}"
      puts "  #{e.backtrace.first(3).join("\n  ")}"
    end
  end

  task :test_complete_flow => :environment do
    puts "🧪 Test du flux complet avec bon domaine"

    # Nettoyer les anciens emails
    FileUtils.rm_rf(Rails.root.join('tmp/mails/*'))

    # Étape 1: Créer ou trouver un RequestProgress avec une bonne adresse
    rp = RequestProgress.last
    puts "📧 Utilisation de RequestProgress ##{rp.id}: #{rp.email_suivi}"

    # Étape 2: Envoyer la notification test
    service = TrackingEmailTestService.new(rp)
    result1 = service.send_test_notification_to_user('robin@primes-services.be')
    puts "📤 #{result1[:message]}"

    # Étape 3: Simuler une réponse admin
    result2 = service.simulate_admin_email_response('robin@primes-services.be')
    puts "📤 #{result2[:message]}"

    # Étape 4: Traiter directement (sans passer par les fichiers)
    puts "\n🔄 Traitement direct de l'email de simulation..."
    Rake::Task["tracking:test_direct_mailbox"].invoke

    puts "\n🎉 Test complet terminé!"
  end
end
