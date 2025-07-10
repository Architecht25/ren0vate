class PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :dashboard, :edit, :update, :destroy]

  def index
    @properties = current_user.properties
  end

  def show
    # Données pour le dashboard du bien
    @completion_stats = {
      admin: @property.admin_completion_percentage,
      chantier: @property.chantier_completion_percentage,
      primes: @property.primes_completion_percentage,
      overall: @property.completion_percentage
    }
    
    # Requests et simulations liées à ce bien
    @recent_requests = @property.requests.recent.limit(3) if @property.respond_to?(:requests)
    @recent_simulations = @property.simulations.recent.limit(3) if @property.respond_to?(:simulations)
    
    # Actions disponibles
    @actions_available = {
      can_request: @property.ready_for_request?,
      missing_fields: @property.missing_required_fields
    }
  end

  def new
    @property = current_user.properties.new
  end

  def create
    @property = current_user.properties.new(property_params)
    if @property.save
      redirect_to @property
    else
      # Si la création échoue, garder le paramètre region pour ré-afficher le bon formulaire
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property
    else
      render :edit
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_path
  end

  def dashboard
    # Données pour le dashboard du bien
    @completion_stats = {
      admin: @property.admin_completion_percentage,
      chantier: @property.chantier_completion_percentage,
      primes: @property.primes_completion_percentage,
      overall: @property.completion_percentage
    }
    
    # Requests et simulations liées à ce bien
    @recent_requests = @property.requests.recent.limit(3) if @property.respond_to?(:requests)
    @recent_simulations = @property.simulations.recent.limit(3) if @property.respond_to?(:simulations)
    
    # Actions disponibles
    @actions_available = {
      can_request: @property.ready_for_request?,
      missing_fields: @property.missing_required_fields
    }
    
    # Notifications liées à ce bien
    @property_notifications = current_user.notifications.where(property: @property).recent.limit(5) if current_user.respond_to?(:notifications)
  end

  private

  def set_property
    @property = current_user.properties.find(params[:id])
  end

  def property_params
    params.require(:property).permit(
      :name, :location, :price,
      :rue, :numero, :code_postal, :commune, :region,
      :type_propriete, :type, :occupation,
      :autre_bien, :peb, :audit_energetique,
      :annee_construction, :date_raccordement_electrique,
      :numero_ean, :numero_cadastre
    )
  end
end
