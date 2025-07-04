class Api::LocalstorageController < ApplicationController
  skip_before_action :verify_authenticity_token

  def save
    localstorage_data = params[:localstorage]

    # Exemple de traitement des données
    localstorage_data.each do |key, value|
      case key
      when "region"
        # Enregistrer la région dans la base de données
        current_user.update(region: value)
      when "eligibiliteRenovate"
        # Enregistrer les données d'éligibilité
        Eligibility.create(user: current_user, data: value)
      else
        # Autres cas
        Rails.logger.info("Clé inconnue : #{key}, valeur : #{value}")
      end
    end

    render json: { message: "Données enregistrées avec succès" }, status: :ok
  end
end
