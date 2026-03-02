class PrimesController < ApplicationController
  def index
    @primes_by_region = {
      flandre: Prime.where(region: 'flandre').order(:ordre_affichage, :titre),
      wallonie: Prime.where(region: 'wallonie').order(:ordre_affichage, :titre),
      bruxelles: Prime.where(region: 'bruxelles').order(:ordre_affichage, :titre)
    }

    # Pour la compatibilité avec l'ancien code
    @primes = Prime.all.order(:ordre_affichage, :titre)
  end

  def show
    @prime = Prime.find(params[:id])
  end

  def new
    @prime = Prime.new
  end

  def create
    @prime = Prime.new(prime_params)
    if @prime.save
      redirect_to @prime, notice: 'Prime créée avec succès.'
    else
      render :new
    end
  end

  def edit
    @prime = Prime.find(params[:id])
  end

  def update
    @prime = Prime.find(params[:id])

    # Traitement spécial pour les champs JSON et arrays
    processed_params = prime_params.dup

    # Convertir eligible_categories string en array
    if processed_params[:eligible_categories].present?
      processed_params[:eligible_categories] = processed_params[:eligible_categories].split(',').map(&:strip)
    end

    # Convertir les champs JSON string en hash
    [:valeurs_par_categorie, :placeholder].each do |field|
      if processed_params[field].present?
        begin
          processed_params[field] = JSON.parse(processed_params[field])
        rescue JSON::ParserError
          @prime.errors.add(field, "Format JSON invalide")
          render :edit and return
        end
      end
    end

    if @prime.update(processed_params)
      redirect_to @prime, notice: 'Prime mise à jour avec succès.'
    else
      render :edit
    end
  end

  def destroy
    @prime = Prime.find(params[:id])
    @prime.destroy
    redirect_to primes_path, notice: 'Prime supprimée avec succès.'
  end

  private

  def prime_params
    params.require(:prime).permit(
      :titre, :slug, :region, :ordre_affichage, :icon_name, :unite, :type_de_valeur,
      :condition, :conseil, :document, :specifique, :image, :category_id,
      :valeurs_par_categorie, :placeholder, eligible_categories: []
    )
  end
end
