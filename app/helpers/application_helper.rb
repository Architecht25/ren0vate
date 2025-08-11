module ApplicationHelper
  # Détermine si l'utilisateur actuel est un administrateur
  def current_user_admin?
    return false unless user_signed_in?
    # Pour l'instant, basé sur l'email admin - à améliorer avec un vrai système de rôles
    current_user.email == 'robin@primes-services.be'
  end
end
