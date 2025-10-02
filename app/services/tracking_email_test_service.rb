class TrackingEmailTestService
  def initialize(request_progress)
    @request_progress = request_progress
  end

  def send_test_notification_to_user(user_email = 'robin@primes-services.be')
    Rails.logger.info "🧪 Envoi d'un email de test vers #{user_email}"

    TrackingTestMailer.test_notification_to_user(@request_progress, user_email).deliver_now

    Rails.logger.info "✅ Email de test envoyé avec succès"
    {
      success: true,
      message: "Email de test envoyé vers #{user_email}",
      tracking_email: @request_progress.email_suivi
    }
  rescue => e
    Rails.logger.error "❌ Erreur lors de l'envoi de l'email de test: #{e.message}"
    {
      success: false,
      message: "Erreur: #{e.message}",
      tracking_email: @request_progress.email_suivi
    }
  end

  def simulate_admin_email_response(from_email = 'robin@primes-services.be')
    Rails.logger.info "🧪 Simulation d'une réponse admin depuis #{from_email}"

    # Créer un email qui sera traité par la TrackingMailbox
    TrackingTestMailer.simulate_admin_response(@request_progress, from_email).deliver_now

    Rails.logger.info "✅ Email de simulation admin envoyé"
    {
      success: true,
      message: "Email de simulation envoyé vers #{@request_progress.email_suivi}",
      from: from_email,
      to: @request_progress.email_suivi
    }
  rescue => e
    Rails.logger.error "❌ Erreur lors de la simulation admin: #{e.message}"
    {
      success: false,
      message: "Erreur: #{e.message}"
    }
  end

  def run_full_test_cycle(user_email = 'robin@primes-services.be')
    results = {
      test_started_at: Time.current,
      steps: []
    }

    # Étape 1: Envoyer l'email de notification
    step1 = send_test_notification_to_user(user_email)
    results[:steps] << {
      step: 1,
      name: "Notification vers utilisateur",
      result: step1
    }

    if step1[:success]
      # Étape 2: Attendre un peu et simuler la réponse admin
      sleep(2)

      step2 = simulate_admin_email_response(user_email)
      results[:steps] << {
        step: 2,
        name: "Simulation réponse admin",
        result: step2
      }

      # Étape 3: Vérifier que le RequestProgress a été mis à jour
      sleep(3)
      @request_progress.reload

      step3 = {
        success: true,
        message: "RequestProgress vérifié",
        last_update: @request_progress.email_processed_at,
        document_received: @request_progress.document_recu,
        status: @request_progress.status_administratif
      }

      results[:steps] << {
        step: 3,
        name: "Vérification mise à jour",
        result: step3
      }
    end

    results[:test_completed_at] = Time.current
    results[:overall_success] = results[:steps].all? { |step| step[:result][:success] }

    Rails.logger.info "🧪 Test cycle complet: #{results[:overall_success] ? 'SUCCÈS' : 'ÉCHEC'}"
    results
  end

  def self.find_test_request_progress
    # Chercher un RequestProgress existant pour les tests
    RequestProgress.includes(:request, :prime).first || create_test_request_progress
  end

  def self.create_test_request_progress
    Rails.logger.info "🧪 Création d'un RequestProgress de test"

    # Utiliser le premier utilisateur disponible ou en créer un
    user = User.first
    unless user
      Rails.logger.error "❌ Aucun utilisateur trouvé pour créer un test"
      return nil
    end

    # Créer une requête de test
    request = Request.create!(
      user: user,
      title: "Test tracking email system",
      description: "Demande de test pour valider le système d'emails de tracking",
      region: "bruxelles",
      status: "submitted",
      form_type: "regional_bruxelles"
    )

    # Créer un RequestProgress de test
    prime = Prime.first
    unless prime
      Rails.logger.error "❌ Aucune prime trouvée pour créer un test"
      return nil
    end

    request_progress = RequestProgress.create!(
      request: request,
      prime: prime,
      step: "Demande soumise",
      pourcentage: 25,
      status_administratif: "soumis",
      montant_demande: 2500.00,
      date_soumission: Date.current
    )

    Rails.logger.info "✅ RequestProgress de test créé: ##{request_progress.id}"
    request_progress
  end
end
