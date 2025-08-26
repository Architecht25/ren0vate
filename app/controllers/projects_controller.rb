class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    @projects = current_user.projects.includes(:property).order(created_at: :desc)
  end

  def show
    @documents = @project.documents.order(created_at: :desc) if @project.documents.respond_to?(:order)
  end

  def new
    @project = current_user.projects.build
    @project.project_type = params[:project_type] if params[:project_type].present?
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user

    if @project.save
      message = @project.investment? ? 'Investissement créé avec succès.' : 'Chantier créé avec succès.'
      redirect_to @project, notice: message
    else
      Rails.logger.error "Project validation errors: #{@project.errors.full_messages}"
      flash.now[:alert] = "Erreurs de validation : #{@project.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      message = @project.investment? ? 'Investissement mis à jour avec succès.' : 'Chantier mis à jour avec succès.'
      redirect_to @project, notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_name = @project.nom
    project_type = @project.investment? ? "l'investissement" : "le chantier"

    begin
      @project.destroy
      redirect_to projects_path, notice: "#{project_type.capitalize} '#{project_name}' a été supprimé avec succès."
    rescue => e
      redirect_to @project, alert: "Erreur lors de la suppression #{project_type.gsub('l\'', 'd\'un ')} : #{e.message}"
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :nom, :description, :date_début, :date_fin, :statut, :property_id, :project_type,
      :bce_number, :invoice_date, :work_completion_date,
      # Champs spécifiques Flandre
      :type_travaux, :reconstruction_demolition, :tva_reduit_6_pourcent,
      # Checkboxes pour types de travaux Flandre
      :type_travaux_isolation, :type_travaux_chauffage, :type_travaux_ventilation,
      :type_travaux_fenetres, :type_travaux_toiture, :type_travaux_autre
    )
  end
end
