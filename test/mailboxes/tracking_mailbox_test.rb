require "test_helper"
require "action_mailbox/test_helper"

class TrackingMailboxTest < ActiveSupport::TestCase
  include ActionMailbox::TestHelper
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Bien Flandre", rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent",
      region: "flandre", skip_onboarding_validation: true
    )
    @request = Request.create!(user: @user, property: @property, region: "flandre", status: "draft")
    @request_progress = RequestProgress.create!(
      request: @request, step: 1, pourcentage: 0, status_administratif: "soumis",
      date_soumission: Date.current, form_type: "regional_flandre"
    )
  end

  test "un email détecté incomplet crée une ComplementRequest" do
    receive_inbound_email_from_mail(
      to: @request_progress.email_suivi,
      from: "admin@mijnverbouwpremie.be",
      subject: "Votre dossier est incomplet",
      body: "Votre dossier est incomplet, merci de fournir les documents manquants."
    )

    @request_progress.reload
    assert_equal "incomplet", @request_progress.status_administratif
    assert_equal 1, @request_progress.complement_requests.count
    assert @request_progress.has_pending_complements?
  end

  test "un email détecté accordé persiste le montant accordé" do
    receive_inbound_email_from_mail(
      to: @request_progress.email_suivi,
      from: "admin@mijnverbouwpremie.be",
      subject: "Votre demande est accordée",
      body: "Votre demande a été accordée pour un montant de 3500€."
    )

    @request_progress.reload
    assert_equal "accorde", @request_progress.status_administratif
    assert_equal 3500.0, @request_progress.montant_accorde
  end

  test "un deuxième email incomplet ne crée pas de doublon de complément" do
    receive_inbound_email_from_mail(
      to: @request_progress.email_suivi, from: "admin@mijnverbouwpremie.be",
      subject: "Dossier incomplet", body: "Votre dossier est incomplet."
    )
    receive_inbound_email_from_mail(
      to: @request_progress.email_suivi, from: "admin@mijnverbouwpremie.be",
      subject: "Rappel dossier incomplet", body: "Votre dossier est toujours incomplet."
    )

    @request_progress.reload
    assert_equal 1, @request_progress.complement_requests.count
  end
end
