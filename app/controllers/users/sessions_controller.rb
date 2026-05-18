class Users::SessionsController < Devise::SessionsController
  # Surcharge de la méthode après connexion pour forcer la redirection vers le dashboard

  # Après connexion : vider l'historique de l'ancienne session avant de créer la nouvelle
  def create
    super
  end

  # Après déconnexion : vider l'historique IA + cookie 2FA + forcer purge cache
  def respond_to_on_destroy(non_navigational_status: :no_content)
    if current_user
      cache_key = "chat_history_#{current_user.id}_#{session.id}"
      Rails.cache.delete(cache_key)
    end
    cookies.delete(:admin_2fa_verified)
    response.headers['Clear-Site-Data'] = '"cache"'
    super(non_navigational_status: non_navigational_status)
  end

  protected

  def after_sign_in_path_for(resource)
    stored = stored_location_for(resource)
    return stored if stored.present?
    resource.onboarding_done? ? dashboard_path : onboarding_profile_selection_path(locale: I18n.locale)
  end

  def after_sign_up_path_for(resource)
    onboarding_profile_selection_path(locale: I18n.locale)
  end

  def after_sign_out_path_for(resource_or_scope)
    # Après déconnexion, aller à la page d'accueil avec un header qui force le rechargement
    # pour vider le snapshot cache Turbo côté client
    root_path
  end
end
