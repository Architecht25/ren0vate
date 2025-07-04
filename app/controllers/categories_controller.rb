class CategoriesController < ApplicationController
  def index
    @categories = Category.all
  end

  def show
    @category = Category.find(params[:id])
  end

   def calcul
    profil = {
      revenu_annuel: params[:revenu_annuel].to_f,
      statut: params[:statut],
      personnes_a_charge: params[:personnes_a_charge].to_i,
      autre_bien: params[:autre_bien] == "true",
      woonmaatschappij: params[:woonmaatschappij] == "true"
    }

    categorie = Categorie.calculer_depuis(profil)
    render json: categorie
  end
end
