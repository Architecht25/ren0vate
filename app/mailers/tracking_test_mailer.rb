class TrackingTestMailer < ApplicationMailer
  # ApplicationMailer utilise déjà default from: 'noreply@ren0vate.be'

  def test_notification_to_user(request_progress, test_email)
    @request_progress = request_progress
    @property = request_progress.request.property
    @prime = request_progress.prime
    @email_tracking = request_progress.email_suivi

    mail(
      to: test_email,
      subject: "🧪 Test notification - Demande #{@prime.titre}",
      reply_to: @email_tracking
    )
  end

  def simulate_admin_response(request_progress, from_email)
    @request_progress = request_progress
    @property = request_progress.request.property
    @prime = request_progress.prime

    # Cet email sera envoyé vers l'adresse de tracking pour tester la réception
    mail(
      to: request_progress.email_suivi,
      from: from_email,
      subject: "RE: Demande de prime #{@prime.titre} - Statut: En cours d'examen",
      body: build_test_admin_body
    )
  end

  private

  def build_test_admin_body
    <<~BODY
      Bonjour,

      Nous accusons réception de votre demande de prime pour #{@prime.titre}.

      Informations de votre dossier :
      - Numéro de dossier : TEST-#{@request_progress.id}-#{Date.current.strftime('%Y%m%d')}
      - Statut : En cours d'examen
      - Montant demandé : #{@request_progress.montant_demande} €

      Votre dossier est actuellement en cours d'examen par nos services.
      Nous vous tiendrons informé de l'évolution de votre demande.

      Cette estimation des délais :
      - Région : #{@request_progress.region.capitalize}
      - Délai prévu : #{@request_progress.delai_reponse_mois} mois
      - Date limite prévue : #{@request_progress.date_limite_reponse}

      Cordialement,
      Service des Primes (TEST)
      Administration #{@request_progress.region.capitalize}
    BODY
  end
end
