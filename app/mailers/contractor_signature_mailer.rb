class ContractorSignatureMailer < ApplicationMailer
  def signature_request(contractor_signature)
    @contractor_signature = contractor_signature
    @request = @contractor_signature.request
    @project = @request.project
    @property = @request.property
    @signature_url = @contractor_signature.signature_url

    mail(
      to: @contractor_signature.contractor_email,
      subject: "Demande de signature - Projet #{@project&.nom || 'Travaux de rénovation'}"
    )
  end

  def signature_completed(contractor_signature)
    @contractor_signature = contractor_signature
    @request = @contractor_signature.request
    @client = @request.user

    mail(
      to: @client.email,
      subject: "Signature entrepreneur reçue - #{@contractor_signature.contractor_name}"
    )
  end

  def signature_rejected(contractor_signature)
    @contractor_signature = contractor_signature
    @request = @contractor_signature.request
    @client = @request.user

    mail(
      to: @client.email,
      subject: "Signature entrepreneur refusée - #{@contractor_signature.contractor_name}"
    )
  end

  def signature_expired(contractor_signature)
    @contractor_signature = contractor_signature
    @request = @contractor_signature.request
    @client = @request.user

    mail(
      to: @client.email,
      subject: "Demande de signature expirée - #{@contractor_signature.contractor_name}"
    )
  end

  def reminder(contractor_signature)
    @contractor_signature = contractor_signature
    @request = @contractor_signature.request
    @project = @request.project
    @signature_url = @contractor_signature.signature_url
    @days_remaining = @contractor_signature.days_until_expiry

    mail(
      to: @contractor_signature.contractor_email,
      subject: "Rappel - Signature requise (expire dans #{@days_remaining} jours)"
    )
  end
end
