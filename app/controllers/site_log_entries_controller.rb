# V2 — Lot 4 : journal de chantier (cahier des charges §5.D).
class SiteLogEntriesController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_entry, only: %i[destroy]

  def index
    authorize @project, :show?
    @site_log_entries = policy_scope(SiteLogEntry).where(project: @project).chronological.includes(:author, :lot)
  end

  def new
    @entry = @project.site_log_entries.build
    authorize @entry, :create?
  end

  def create
    @entry = @project.site_log_entries.build(entry_params)
    authorize @entry, :create?
    @entry.author = current_user

    if @entry.save
      AuditEvent.record!(action: "site_log_entry.created", auditable: @entry, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_site_log_entries_path(@project), notice: "Observation ajoutée au journal."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @entry, :destroy?
    project = @entry.project
    @entry.destroy!
    redirect_to project_site_log_entries_path(project), notice: "Observation supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_entry
    @entry = SiteLogEntry.find(params[:id])
  end

  def entry_params
    params.require(:site_log_entry).permit(:body, :lot_id, :observed_at, :latitude, :longitude, photos: [])
  end
end
