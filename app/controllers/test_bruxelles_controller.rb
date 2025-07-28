class TestBruxellesController < ApplicationController

  def test_action
    render plain: "Test méthode fonctionne parfaitement !"
  end

  def select_profile_bruxelles
    @user_type = params[:profile_type]

    # Logique de redirection selon le type d'utilisateur pour Bruxelles
    case @user_type
    when "entreprise"
      render plain: "Entreprise non éligible"
    when "prive", "asbl"
      render plain: "Profil #{@user_type} éligible !"
    else
      render plain: "Type de profil non reconnu: #{@user_type}"
    end
  end

end
