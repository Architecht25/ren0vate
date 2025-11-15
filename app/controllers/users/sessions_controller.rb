class Users::SessionsController < Devise::SessionsController
  # Surcharge de la méthode après connexion pour forcer la redirection vers le dashboard

  protected

  def after_sign_in_path_for(resource)
    # Forcer complètement la redirection vers le dashboard, ignorer toute autre URL stockée
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    # Rediriger vers le dashboard après inscription aussi
    dashboard_path
  end
end
