require "test_helper"

class RequestProgressDeadlineJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Bien Flandre", rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent",
      region: "flandre", skip_onboarding_validation: true
    )
    @request = Request.create!(user: @user, property: @property, region: "flandre", status: "draft")
  end

  test "notifie l'utilisateur quand le délai de réponse Flandre devient urgent" do
    # Flandre : délai de réponse de 5 mois. On soumet une date_soumission telle
    # qu'il reste 10 jours avant l'échéance (statut :urgent).
    date_soumission = (Date.current + 10.days) - 5.months
    request_progress = RequestProgress.create!(
      request: @request, step: 1, pourcentage: 0, status_administratif: "soumis",
      date_soumission: date_soumission, form_type: "regional_flandre"
    )

    assert_difference "Notification.count", 1 do
      RequestProgressDeadlineJob.perform_now
    end

    notification = Notification.last
    assert_equal "deadline_proche", notification.type
    assert_equal @user, notification.user
    assert_includes notification.message, "suivi ##{request_progress.id}"
  end

  test "ne notifie pas deux fois dans les 24h pour le même suivi" do
    date_soumission = (Date.current + 10.days) - 5.months
    RequestProgress.create!(
      request: @request, step: 1, pourcentage: 0, status_administratif: "soumis",
      date_soumission: date_soumission, form_type: "regional_flandre"
    )

    RequestProgressDeadlineJob.perform_now
    assert_no_difference "Notification.count" do
      RequestProgressDeadlineJob.perform_now
    end
  end

  test "fait expirer un complément dépassé et notifie via mailer" do
    request_progress = RequestProgress.create!(
      request: @request, step: 1, pourcentage: 0, status_administratif: "incomplet",
      date_soumission: 2.months.ago, form_type: "regional_flandre"
    )
    complement = request_progress.complement_requests.create!(
      admin_message: "Merci de fournir la facture manquante",
      complement_type: "missing_documents",
      deadline: 3.days.ago,
      status: "pending"
    )

    RequestProgressDeadlineJob.perform_now

    assert_equal 1, queue_adapter.enqueued_jobs.size
    assert_equal "ActionMailer::MailDeliveryJob", queue_adapter.enqueued_jobs.first[:job].to_s
    assert_equal "expired", complement.reload.status

    # Le mailer se rend bien sans erreur (vues présentes) et envoie au client concerné.
    mail = ComplementRequestMailer.deadline_expired(complement).deliver_now
    assert_equal [@user.email], mail.to
  end
end
