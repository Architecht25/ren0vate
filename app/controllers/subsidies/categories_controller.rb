class CategoriesController < ApplicationController
  def index
    @categories = Category.all
  end

  def show
    @category = Category.find(params[:id])
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to @category, notice: 'Catégorie créée avec succès.'
    else
      render :new
    end
  end

  def edit
    @category = Category.find(params[:id])
  end

  def update
    @category = Category.find(params[:id])
    if @category.update(category_params)
      redirect_to @category, notice: 'Catégorie mise à jour avec succès.'
    else
      render :edit
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    redirect_to categories_path, notice: 'Catégorie supprimée avec succès.'
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

  private

  def category_params
    params.require(:category).permit(
      :code, :description, :seuil_seul, :seuil_seul_avec_charge, :couple_sans_charge,
      :increment_par_personne, :autre_bien_interdit, :location_sociale_autorisee,
      :eligible_pour_verbouwlening, :notes
    )
  end
end
