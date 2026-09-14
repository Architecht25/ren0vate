class FinancingSourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_project_access!
  before_action :set_source, only: %i[edit update destroy]
  before_action :reject_auto_synced!, only: %i[edit update destroy]

  # GET /projects/:project_id/financing_sources/new
  def new
    @source = @project.financing_sources.build(source_type: params[:source_type])
  end

  # POST /projects/:project_id/financing_sources
  # Reçoit aussi bien la soumission du formulaire "+ Ajouter" que le bouton
  # "Ajouter comme source de financement" des simulateurs loans_hub.
  def create
    @source = @project.financing_sources.build(source_params)

    if @source.save
      redirect_to project_path(@project, tab: "preparation"), notice: "Source de financement ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/financing_sources/:id/edit
  def edit
  end

  # PATCH /projects/:project_id/financing_sources/:id
  def update
    if @source.update(source_params)
      redirect_to project_path(@project, tab: "preparation"), notice: "Source de financement mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:project_id/financing_sources/:id
  def destroy
    @source.destroy
    redirect_to project_path(@project, tab: "preparation"), notice: "Source de financement supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_source
    @source = @project.financing_sources.find(params[:id])
  end

  def authorize_project_access!
    is_owner = @project.user_id == current_user.id
    is_member = @project.project_members.active.where(user: current_user).exists?
    redirect_to root_path, alert: "Accès non autorisé." unless is_owner || is_member
  end

  # Les lignes "prime" et "pret_taux_zero" (Wallonie) auto-synchronisées ne se modifient
  # qu'en agissant sur la Simulation ou le PretWallonieDossier source, pas ici.
  def reject_auto_synced!
    return unless @source.auto_synced?

    redirect_to project_path(@project, tab: "preparation"),
                alert: "Cette source est liée à une simulation ou un dossier de prêt — modifiez-la depuis là."
  end

  # Les 4 types sont saisissables manuellement — y compris "prime", pour une aide déjà
  # obtenue ou en cours qui n'est pas passée par le simulateur (ex. prime communale
  # ponctuelle). Les lignes "prime"/"pret_taux_zero" issues de Simulation/PretWallonieDossier
  # restent, elles, non éditables ici (voir reject_auto_synced! — auto_synced? les distingue
  # via simulation_id/pret_wallonie_dossier_id, jamais renseignés sur une ligne manuelle).
  MANUAL_SOURCE_TYPES = %w[fonds_propres emprunt_bancaire pret_taux_zero prime].freeze

  def source_params
    permitted = params.require(:financing_source).permit(
      :label, :source_type, :amount, :rate, :duration_months, :notes, :status
    )
    permitted[:source_type] = "fonds_propres" unless permitted[:source_type].in?(MANUAL_SOURCE_TYPES)
    permitted
  end
end
