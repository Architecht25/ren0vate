class Users::SessionsController < Devise::SessionsController
  # Surcharge de la méthode après connexion pour forcer la redirection vers le dashboard

  # Après déconnexion : forcer le navigateur à vider SON cache HTTP pour ce domaine.
  # Clear-Site-Data: "cache" est le standard W3C — empêche qu'un autre utilisateur
  # voit des pages en cache appartenant à la session précédente.
  def respond_to_on_destroy
    response.headers['Clear-Site-Data'] = '"cache"'
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
