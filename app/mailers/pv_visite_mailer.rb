class PvVisiteMailer < ApplicationMailer
  def partage(pv_visite, role)
    @pv_visite = pv_visite
    @project   = pv_visite.project
    @role      = role

    @token = case role
             when :owner        then pv_visite.token_owner
             when :entrepreneur then pv_visite.token_entrepreneur
             end

    @role_label = case role
                  when :owner        then "Maître d'ouvrage"
                  when :entrepreneur then "Entrepreneur"
                  end

    @nom = case role
           when :owner
             @project.user.full_name
           when :entrepreneur
             @project.project_members.active.includes(:user).find_by(role: "entrepreneur")&.user&.full_name
           end

    @view_url   = pv_visite_link_url(@token)
    @auteur_nom = pv_visite.auteur.full_name

    to_email = case role
               when :owner        then @project.user.email
               when :entrepreneur then @project.project_members.active.includes(:user).find_by(role: "entrepreneur")&.user&.email
               end

    mail(
      to:      to_email,
      subject: "PV de visite de chantier — #{@project.nom} — Ren0vate"
    )
  end
end
