class ProViewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_membership

  def show
    @property = @project.property
    @quote    = @property&.quotes&.includes(:quote_items)&.order(created_at: :desc)&.first
    @members  = @project.project_members.includes(:user).active

    photo_types = %w[photo_avant photo_pendant photo_apres photo_chassis]
    @photos = @project.documents.where(type_document: photo_types).order(created_at: :desc)
    @factures = @project.factures.order(created_at: :desc) if @membership.role == 'entrepreneur'
  end

  # POST /projects/:id/invite
  def invite
    # Seul le propriétaire peut inviter
    unless @project.user_id == current_user.id
      redirect_to project_path(@project), alert: "Vous n'êtes pas autorisé à inviter des pros." and return
    end

    service = ProjectInvitationService.new
    member = service.invite(
      project:    @project,
      invited_by: current_user,
      email:      params[:email],
      role:       params[:role]
    )

    redirect_to project_path(@project),
                notice: "Invitation envoyée à #{member.invited_email} (#{member.role_label})."
  rescue ProjectInvitationService::InvitationError => e
    redirect_to project_path(@project), alert: e.message
  end

  # DELETE /projects/:id/members/:member_id
  def remove_member
    unless @project.user_id == current_user.id
      redirect_to project_path(@project), alert: "Non autorisé." and return
    end

    member = @project.project_members.find(params[:member_id])
    member.destroy
    redirect_to project_path(@project), notice: "#{member.role_label} retiré du projet."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def set_membership
    # Le propriétaire du projet a accès, ainsi que les membres actifs
    if @project.user_id == current_user.id
      @membership = @project.project_members.find_or_initialize_by(user: current_user, role: 'owner')
    else
      @membership = @project.project_members.active.find_by(user: current_user)
      unless @membership
        redirect_to root_path, alert: "Vous n'avez pas accès à ce projet." and return
      end
    end
  end
end
