class ComplementRequestMailer < ApplicationMailer
  def new_request(complement_request)
    @complement_request = complement_request
    @request_progress = @complement_request.request_progress
    @request = @request_progress.request
    @client = @request.user
    @deadline = @complement_request.deadline

    mail(
      to: @client.email,
      subject: "Complément d'information requis - Dossier #{@request.title}"
    )
  end

  def response_received(complement_request)
    @complement_request = complement_request
    @request_progress = @complement_request.request_progress
    @request = @request_progress.request
    @client = @request.user

    # Mail aux admins/gestionnaires
    admin_emails = User.admin.pluck(:email)

    mail(
      to: admin_emails,
      cc: @client.email,
      subject: "Réponse reçue - Complément #{@complement_request.id}"
    )
  end

  def deadline_expired(complement_request)
    @complement_request = complement_request
    @request_progress = @complement_request.request_progress
    @request = @request_progress.request
    @client = @request.user

    mail(
      to: @client.email,
      subject: "Délai dépassé - Complément d'information requis"
    )
  end

  def response_rejected(complement_request)
    @complement_request = complement_request
    @request_progress = @complement_request.request_progress
    @request = @request_progress.request
    @client = @request.user

    mail(
      to: @client.email,
      subject: "Complément d'information insuffisant - Action requise"
    )
  end

  def reminder(complement_request)
    @complement_request = complement_request
    @request_progress = @complement_request.request_progress
    @request = @request_progress.request
    @client = @request.user
    @days_remaining = @complement_request.days_remaining

    mail(
      to: @client.email,
      subject: "Rappel - Complément requis (#{@days_remaining} jours restants)"
    )
  end
end
