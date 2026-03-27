class NotificationMailer < ApplicationMailer
  def alert(notification)
    @notification = notification
    @user         = notification.user
    @title        = notification.title
    @message      = notification.message
    @action_url   = build_action_url(notification.action_url)
    @icon         = notification.type_icon
    @priority_color = priority_hex(notification.priority)

    mail(
      to:      @user.email,
      subject: "[Ren0vate] #{@title}"
    )
  end

  private

  def build_action_url(path)
    return nil if path.blank?
    # Si c'est déjà une URL absolue : retourner telle quelle
    return path if path.start_with?("http")
    # Sinon construire l'URL absolue
    root_url(locale: :fr).chomp("/") + path
  end

  def priority_hex(priority)
    case priority
    when "critique", "urgente" then "#dc3545"
    when "haute"               then "#fd7e14"
    when "normale"             then "#0d6efd"
    else                            "#6c757d"
    end
  end
end
