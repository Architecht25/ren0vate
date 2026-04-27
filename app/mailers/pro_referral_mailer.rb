class ProReferralMailer < ApplicationMailer
  # Email envoyé par un architecte à son client via /pro/inviter-client
  def invite_client(pro, client_email, referral_url)
    @pro          = pro
    @referral_url = referral_url
    @pro_name     = pro.full_name.presence || pro.email

    mail(
      to:      client_email,
      subject: "#{@pro_name} vous invite à gérer votre rénovation sur Ren0vate"
    )
  end
end
