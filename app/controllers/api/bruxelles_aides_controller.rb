class Api::BruxellesAidesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:categories, :category_details]
  skip_before_action :verify_authenticity_token, only: [:categories, :category_details]

  def categories
    begin
      categories = Entreprises::BruxellesAidesDataService.get_all_categories

      # Simplifier la structure pour l'aperçu des catégories
      simplified_categories = categories.map do |key, category|
        {
          id: key,
          name: category[:name],
          icon: category[:icon],
          description: category[:description],
          color: category[:color],
          nombre_aides: category[:aides].length
        }
      end

      render json: {
        success: true,
        data: {
          categories: simplified_categories,
          total: simplified_categories.length
        }
      }
    rescue StandardError => e
      Rails.logger.error "❌ Erreur récupération catégories aides Bruxelles: #{e.message}"
      render json: {
        success: false,
        error: "Erreur lors de la récupération des catégories d'aides"
      }, status: 500
    end
  end

  def category_details
    begin
      category_key = params[:category_id]

      if category_key.blank?
        return render json: {
          success: false,
          error: "Identifiant de catégorie manquant"
        }, status: 400
      end

      category_data = Entreprises::BruxellesAidesDataService.get_category_details(category_key)

      if category_data.empty?
        return render json: {
          success: false,
          error: "Catégorie non trouvée"
        }, status: 404
      end

      render json: {
        success: true,
        data: {
          category: category_data,
          metadata: {
            total_aides: category_data[:aides]&.length || 0,
            last_updated: "2025-01-01" # À adapter selon vos besoins
          }
        }
      }
    rescue StandardError => e
      Rails.logger.error "❌ Erreur récupération détails catégorie #{params[:category_id]}: #{e.message}"
      render json: {
        success: false,
        error: "Erreur lors de la récupération des détails de la catégorie"
      }, status: 500
    end
  end
end
