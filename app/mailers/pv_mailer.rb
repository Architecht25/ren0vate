class PvMailer < ApplicationMailer
  # Email envoyé à une partie pour signer le PV
  def signature_request(pv, role)
    @pv      = pv
    @project = pv.project
    @role    = role

    @nom     = pv.nom_pour_role(role)
    @token   = case role
               when :owner        then pv.token_owner
               when :architect    then pv.token_architect
               when :entrepreneur then pv.token_entrepreneur
               end

    @sign_url = pv_signature_url(@token)
    @role_label = case role
                  when :owner        then "Maître d'ouvrage"
                  when :architect    then "Architecte"
                  when :entrepreneur then "Entrepreneur"
                  end

    to_email = case role
               when :owner        then pv.email_owner
               when :architect    then pv.email_architect
               when :entrepreneur then pv.email_entrepreneur
               end

    mail(
      to:      to_email,
      subject: "PV de réception à signer — #{@project.nom} — Ren0vate"
    )
  end
end
