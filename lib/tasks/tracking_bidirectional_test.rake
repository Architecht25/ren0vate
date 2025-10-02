namespace :tracking do
  desc "Test complet du cycle bidirectionnel d'emails"
  task :test_bidirectional_cycle, [:user_email] => :environment do |t, args|
    user_email = args[:user_email] || 'robin@primes-services.be'

    puts "🔄 Test du cycle bidirectionnel complet"
    puts "=" * 50

    # Étape 1: Générer et envoyer une notification vers l'utilisateur
    puts "\n📤 ÉTAPE 1: Envoi notification vers l'utilisateur"
    rp = RequestProgress.where.not(email_suivi: nil).last
    if rp
      # Remettre à zéro pour un test propre
      rp.update_column(:email_processed_at, nil)

      result = rp.test_full_email_cycle(user_email)
      tracking_email = rp.reload.email_suivi

      puts "✅ Notification envoyée vers #{user_email}"
      puts "📧 Adresse de tracking générée: #{tracking_email}"
    else
      puts "❌ Aucun RequestProgress trouvé"
      exit 1
    end

    puts "\n⏳ Pause de 2 secondes..."
    sleep 2

    # Étape 2: Simuler une réponse de l'administration
    puts "\n📥 ÉTAPE 2: Simulation de réponse administrative"

    Rake::Task['tracking:simulate_incoming_email'].invoke(
      tracking_email,
      'admin.primes@wallonie.be',
      '✅ Votre dossier a été traité - Accord de prime',
      "Bonjour,

Nous avons le plaisir de vous informer que votre demande de prime a été approuvée.

Détails:
- Montant accordé: 2.150,00 €
- Date de décision: #{Date.current.strftime('%d/%m/%Y')}
- Numéro de dossier: WAL-2025-#{rp.id.to_s.rjust(6, '0')}

Les documents de validation suivront par courrier postal.

Cordialement,
Service des Primes Énergie
Administration Wallonne"
    )

    puts "\n📊 ÉTAT FINAL DU REQUESTPROGRESS"
    puts "=" * 40
    rp.reload
    puts "ID: #{rp.id}"
    puts "Email de suivi: #{rp.email_suivi}"
    puts "Statut: #{rp.status_administratif}"
    puts "Email traité le: #{rp.email_processed_at&.strftime('%d/%m/%Y à %H:%M') || 'Jamais'}"
    puts "Montant accordé: #{rp.montant_accorde || 'Non défini'}"
    puts "Documents reçus: #{rp.document_recu? ? 'Oui' : 'Non'}"

    if rp.commentaires_admin.present?
      puts "\nDerniers commentaires admin:"
      puts "-" * 30
      puts rp.commentaires_admin
    end

    puts "\n🎉 CYCLE BIDIRECTIONNEL COMPLÉTÉ AVEC SUCCÈS!"
    puts "📧 Vérifiez Mailcatcher à http://127.0.0.1:1080 pour voir tous les emails"
  end

  desc "Test rapide bidirectionnel avec paramètres par défaut"
  task :test_quick_bidirectional => :environment do
    Rake::Task['tracking:test_bidirectional_cycle'].invoke('robin@primes-services.be')
  end
end
