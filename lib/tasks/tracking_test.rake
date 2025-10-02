namespace :tracking do
  desc "Test du système d'emails de tracking"

  task :test_send_notification, [:email] => :environment do |t, args|
    email = args[:email] || 'robin@primes-services.be'

    puts "🧪 Démarrage du test d'envoi de notification vers #{email}"

    request_progress = TrackingEmailTestService.find_test_request_progress

    if request_progress
      service = TrackingEmailTestService.new(request_progress)
      result = service.send_test_notification_to_user(email)

      puts "📧 Adresse de tracking générée: #{result[:tracking_email]}"
      puts result[:success] ? "✅ #{result[:message]}" : "❌ #{result[:message]}"

      puts "\n📝 Instructions pour la suite:"
      puts "1. Vérifiez votre boîte email (#{email})"
      puts "2. Répondez à l'email reçu ou envoyez un nouveau message vers:"
      puts "   #{result[:tracking_email]}"
      puts "3. L'application traitera automatiquement votre réponse"

    else
      puts "❌ Impossible de trouver ou créer un RequestProgress pour le test"
    end
  end

  task :test_simulate_admin, [:email] => :environment do |t, args|
    email = args[:email] || 'robin@primes-services.be'

    puts "🧪 Simulation d'une réponse d'administration depuis #{email}"

    request_progress = TrackingEmailTestService.find_test_request_progress

    if request_progress
      service = TrackingEmailTestService.new(request_progress)
      result = service.simulate_admin_email_response(email)

      puts result[:success] ? "✅ #{result[:message]}" : "❌ #{result[:message]}"

      if result[:success]
        puts "📧 Email envoyé de #{result[:from]} vers #{result[:to]}"
        puts "⏳ Attendre quelques secondes pour le traitement..."

        sleep(3)
        request_progress.reload

        puts "\n📊 État du RequestProgress après traitement:"
        puts "- Dernière MAJ: #{request_progress.date_derniere_maj}"
        puts "- Email traité: #{request_progress.email_processed_at}"
        puts "- Document reçu: #{request_progress.document_recu}"
        puts "- Statut: #{request_progress.status_administratif}"
      end
    else
      puts "❌ Impossible de trouver ou créer un RequestProgress pour le test"
    end
  end

  task :test_full_cycle, [:email] => :environment do |t, args|
    email = args[:email] || 'robin@primes-services.be'

    puts "🧪 Démarrage du test complet du cycle d'emails"
    puts "👤 Email utilisateur: #{email}"

    request_progress = TrackingEmailTestService.find_test_request_progress

    if request_progress
      service = TrackingEmailTestService.new(request_progress)
      results = service.run_full_test_cycle(email)

      puts "\n📊 Résultats du test complet:"
      puts "⏰ Début: #{results[:test_started_at]}"
      puts "⏰ Fin: #{results[:test_completed_at]}"
      puts "🎯 Succès global: #{results[:overall_success] ? '✅ OUI' : '❌ NON'}"

      puts "\n📝 Détail des étapes:"
      results[:steps].each do |step_info|
        status = step_info[:result][:success] ? '✅' : '❌'
        puts "#{step_info[:step]}. #{step_info[:name]}: #{status} #{step_info[:result][:message]}"
      end

      puts "\n🔗 Adresse de tracking: #{request_progress.email_suivi}"

    else
      puts "❌ Impossible de trouver ou créer un RequestProgress pour le test"
    end
  end

  task :show_tracking_emails => :environment do
    puts "📧 Adresses de tracking actives:"

    RequestProgress.includes(:request, :prime).each do |rp|
      puts "ID: #{rp.id} | #{rp.email_suivi} | Prime: #{rp.prime.titre} | Statut: #{rp.status_administratif}"
    end
  end

  task :test_mailbox_routing => :environment do
    puts "🧪 Test du routage des mailboxes"

    test_emails = [
      "test@tracking.ren0vate.be",
      "bruxelles-123-456-789@tracking.ren0vate.be",
      "invalid@example.com"
    ]

    test_emails.each do |email|
      matches_tracking = email.match(/@tracking\.ren0vate\.be$/i)
      puts "#{email}: #{matches_tracking ? '✅ Routé vers TrackingMailbox' : '❌ Non routé'}"
    end
  end
end
