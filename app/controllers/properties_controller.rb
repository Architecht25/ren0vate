class PropertiesController < ApplicationController
  def index
    @properties = Property.all
  end

  def show
    @property = Property.find(params[:id])
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(property_params)
    if @property.save
      redirect_to @property
    else
      # Si la création échoue, garder le paramètre region pour ré-afficher le bon formulaire
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @property = Property.find(params[:id])
  end

  def update
    @property = Property.find(params[:id])
    if @property.update(property_params)
      redirect_to @property
    else
      render :edit
    end
  end

  def destroy
    @property = Property.find(params[:id])
    @property.destroy
    redirect_to properties_path
  end

  private

  def property_params
    params.require(:property).permit(
      :name, :location, :price,
      :rue, :numero, :code_postal, :commune, :region,
      :type_propriete, :type, :occupation,
      :autre_bien, :peb,
      :annee_construction, :date_raccordement_electrique,
      :numero_ean, :numero_cadastre
    )
  end
end
