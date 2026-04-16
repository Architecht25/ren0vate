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

    # Suivi chantier visuel — photos groupées par phase
    @phases_avancement = @project.phases_avancement || {}
    @photos_by_phase = @photos.group_by do |photo|
      photo.phase_chantier.presence || infer_phase_from_type(photo.type_document)
    end
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

  # POST /projects/:id/upload_facture_pro
  # Entrepreneur uploade une facture/devis depuis sa vue pro — partagé automatiquement avec le client
  def upload_facture_pro
    unless @membership&.role == 'entrepreneur'
      redirect_back fallback_location: root_path, alert: "Seul un entrepreneur peut utiliser cette action." and return
    end
    unless params[:facture_pdf].present?
      redirect_back fallback_location: pro_view_project_path(@project), alert: "Veuillez joindre un fichier." and return
    end

    type_facture = params[:type_facture].presence_in(%w[devis facture acompte solde]) || 'devis'

    document = Document.new(
      user: current_user,
      project: @project,
      property: @project.property,
      type_document: 'facture',
      status: 'pending'
    )
    document.file.attach(params[:facture_pdf])

    unless document.save
      redirect_back fallback_location: pro_view_project_path(@project),
                    alert: "Erreur lors de l'envoi : #{document.errors.full_messages.join(', ')}" and return
    end

    montant = params[:montant_ttc].presence&.to_f

    facture = Facture.new(
      document: document,
      project: @project,
      property: @project.property,
      type_facture: type_facture,
      statut_paiement: 'non_paye',
      type_intervenant: 'entrepreneur',
      nom_entreprise: current_user.full_name,
      montant: montant || 0
    )
    facture.save

    redirect_to pro_view_project_path(@project),
                notice: "#{type_facture == 'devis' ? 'Devis' : 'Facture'} envoyé#{type_facture == 'devis' ? '' : 'e'} au client ✓"
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

  # Déduit la phase chantier depuis le type_document existant (rétrocompatibilité)
  def infer_phase_from_type(type_document)
    case type_document
    when 'photo_avant'   then 'phase_preparation'
    when 'photo_pendant' then 'phase_installation'
    when 'photo_apres'   then 'phase_reception'
    when 'photo_chassis' then 'phase_finition'
    else 'phase_installation'
    end
  end
end
