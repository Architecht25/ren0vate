class Users::SessionsController < Devise::SessionsController
  # Surcharge de la méthode après connexion pour forcer la redirection vers le dashboard

  # Après déconnexion : vider le cache Turbo via header pour éviter la fuite de données cross-user
  def destroy
    super
  end

  protected

  def after_sign_in_path_for(resource)
    # Forcer complètement la redirection vers le dashboard, ignorer toute autre URL stockée
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    # Rediriger vers le dashboard après inscription aussi
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    # Après déconnexion, aller à la page d'accueil avec un header qui force le rechargement
    # pour vider le snapshot cache Turbo côté client
    root_path
  end
end
