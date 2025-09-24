#!/usr/bin/env ruby
# Script pour tester le système de tracking email en développement

require_relative '../config/environment'

class EmailTrackingTestHelper
  def self.create_test_request_progress
    # Créer un utilisateur de test si nécessaire
    user = User.find_by(email: 'test@example.com') || User.create!(
      email: 'test@example.com',
      password: 'password123',
      prenom: 'Test',
      nom: 'User',
      confirmed_at: Time.current
    )

    # Créer une propriété de test
    property = user.properties.first || user.properties.create!(
      name: 'Propriété de test tracking',
      address: '123 Rue de Test, 1000 Bruxelles',
      region: 'bruxelles',
      type_bien: 'maison',
      surface_habitable: 120,
      construction_year: 1980
    )

    # Créer une demande de test
    prime = Prime.first || Prime.create!(
      titre: 'Prime de test',
      region: 'bruxelles',
      montant_max: 5000,
      category_id: 1
    )

    request = Request.create!(
      property: property,
      region: 'bruxelles',
      status: 'submitted'
    )

    # Créer le RequestProgress avec email de tracking
    request_progress = RequestProgress.create!(
      request: request,
      prime: prime,
      step: 'Demande soumise',
      pourcentage: 50,
      status_administratif: 'soumis',
      montant_demande: 3000,
      date_soumission: Date.current
    )

    puts "✅ RequestProgress créé avec l'email de tracking: #{request_progress.email_suivi}"
    puts "🆔 RequestProgress ID: #{request_progress.id}"

    request_progress
  end

  def self.simulate_incoming_email(request_progress, with_attachment: false)
    email_content = build_test_email_content(request_progress)

    # Créer l'email via ActionMailbox::InboundEmail
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(email_content)

    puts "📧 Email simulé créé avec ID: #{inbound_email.id}"
    puts "📨 Routage vers: #{request_progress.email_suivi}"

    # Traiter l'email
    inbound_email.route

    puts "✅ Email traité!"
    puts "📊 Statut extraction: #{request_progress.reload.document_extraction_status}"

    inbound_email
  end

  private

  def self.build_test_email_content(request_progress)
    <<~EMAIL
      From: administration@bruxelles.be
      To: #{request_progress.email_suivi}
      Subject: Votre demande de prime - Dossier en cours d'examen
      Date: #{Time.current.strftime('%a, %d %b %Y %H:%M:%S %z')}
      Message-ID: <test-#{SecureRandom.hex(8)}@bruxelles.be>

      Bonjour,

      Nous accusons réception de votre demande de prime.

      Votre dossier est actuellement en cours d'examen par nos services.
      Numéro de dossier: BXL-2024-#{rand(1000..9999)}

      Nous vous recontacterons dès que nous aurons des nouvelles à vous communiquer.

      Cordialement,
      Service des Primes - Région de Bruxelles-Capitale
    EMAIL
  end
end

# Script principal
if __FILE__ == $0
  puts "🚀 Démarrage du test du système de tracking email"
  puts "=" * 50

  begin
    # Créer un RequestProgress de test
    request_progress = EmailTrackingTestHelper.create_test_request_progress

    puts "\n📧 Simulation d'un email entrant..."

    # Simuler la réception d'un email
    inbound_email = EmailTrackingTestHelper.simulate_incoming_email(request_progress)

    puts "\n📊 Résultats après traitement:"
    puts "- Statut administratif: #{request_progress.reload.status_administratif}"
    puts "- Email traité le: #{request_progress.email_processed_at}"
    puts "- Statut d'extraction: #{request_progress.document_extraction_status}"
    puts "- Document reçu: #{request_progress.document_recu? ? 'Oui' : 'Non'}"

    if request_progress.commentaires_admin.present?
      puts "\n📝 Commentaires mis à jour:"
      puts request_progress.commentaires_admin.last(200) + "..."
    end

    puts "\n✅ Test terminé avec succès!"

  rescue => e
    puts "❌ Erreur lors du test: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end
end
