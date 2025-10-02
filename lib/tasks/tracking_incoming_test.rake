namespace :tracking do
  desc "Simuler la réception d'un email d'une administration vers une adresse de tracking"
  task :simulate_incoming_email, [:tracking_email, :from_email, :subject, :body] => :environment do |t, args|
    tracking_email = args[:tracking_email] || 'wallonie-94-general-1758549730@tracking.ren0vate.be'
    from_email = args[:from_email] || 'admin.primes@wallonie.be'
    subject = args[:subject] || 'Réponse administrative - Demande de prime énergie'
    body = args[:body] || 'Bonjour, votre dossier a été étudié. Documents complémentaires requis.'

    puts "🔄 Simulation d'un email entrant"
    puts "📧 De: #{from_email}"
    puts "📧 Vers: #{tracking_email}"
    puts "📧 Sujet: #{subject}"
    puts ""

    # Créer un email factice pour Action Mailbox
    raw_email = <<~EMAIL
      From: #{from_email}
      To: #{tracking_email}
      Subject: #{subject}
      Date: #{Time.current.rfc2822}
      Message-ID: <#{SecureRandom.uuid}@wallonie.be>
      Content-Type: text/plain; charset=UTF-8

      #{body}

      ---
      Administration Wallonne
      Service des Primes Énergie
      Cet email a été généré automatiquement.
    EMAIL

    begin
      # Traiter l'email avec Action Mailbox
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)

      puts "✅ Email créé avec ID: #{inbound_email.id}"
      puts "📥 Message ID: #{inbound_email.message_id}"

      # Forcer le routage vers TrackingMailbox
      inbound_email.route

      puts "🔀 Email routé vers TrackingMailbox"

      # Vérifier le traitement
      if tracking_email.include?('@tracking.ren0vate.be')
        # Extraire les infos de l'adresse de tracking
        parts = tracking_email.split('@')[0].split('-')
        if parts.length >= 3
          region = parts[0]
          request_id = parts[1] if parts[1] != 'general'
          type_suivi = parts[2] if parts[1] == 'general'

          puts ""
          puts "🔍 Recherche du RequestProgress correspondant..."
          puts "   Région: #{region}"
          puts "   Request ID: #{request_id || 'général'}"
          puts "   Type suivi: #{type_suivi || 'N/A'}"

          # Chercher le RequestProgress
          if request_id && request_id != 'general'
            request_progress = RequestProgress.joins(:request).where(
              email_suivi: tracking_email
            ).first
          else
            request_progress = RequestProgress.where(email_suivi: tracking_email).first
          end

          if request_progress
            puts "✅ RequestProgress trouvé (ID: #{request_progress.id})"
            puts "📊 Statut avant: #{request_progress.status_administratif}"
            puts "📊 Email processé: #{request_progress.email_processed_at || 'Jamais'}"

            # Mettre à jour si nécessaire
            if request_progress.email_processed_at.nil?
              request_progress.update!(
                email_processed_at: Time.current,
                status_administratif: 'en_cours'
              )
              puts "✅ RequestProgress mis à jour!"
              puts "📊 Nouveau statut: #{request_progress.reload.status_administratif}"
            else
              puts "ℹ️  RequestProgress déjà traité précédemment"
            end
          else
            puts "❌ Aucun RequestProgress trouvé pour #{tracking_email}"
          end
        else
          puts "❌ Format d'adresse de tracking invalide"
        end
      else
        puts "❌ Adresse ne correspond pas au domaine tracking"
      end

      puts ""
      puts "📈 Résumé:"
      puts "   InboundEmail créé: ✅"
      puts "   Routage effectué: ✅"
      puts "   Traitement: #{request_progress ? '✅' : '❌'}"

    rescue => e
      puts "❌ Erreur lors du traitement: #{e.message}"
      puts e.backtrace.first(3)
    end
  end

  desc "Test rapide d'email entrant avec la dernière adresse de tracking"
  task :test_incoming => :environment do
    last_tracking = RequestProgress.where.not(email_suivi: nil).order(:updated_at).last

    if last_tracking
      puts "🎯 Test avec la dernière adresse de tracking générée:"
      puts "   #{last_tracking.email_suivi}"
      puts ""

      Rake::Task['tracking:simulate_incoming_email'].invoke(
        last_tracking.email_suivi,
        'robin@primes-services.be',
        '✅ Réponse de test - Votre dossier avance!',
        'Bonjour, ceci est un email de test envoyé par Robin pour tester la réception côté administration. Votre dossier est en cours de traitement.'
      )
    else
      puts "❌ Aucune adresse de tracking trouvée. Créez d'abord un test d'envoi."
    end
  end
end
