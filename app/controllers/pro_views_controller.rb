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

    # Données permis & documents architecte
    if @membership.can_manage_permis? || @membership.can_view_metre?
      @metres        = @project.documents.where(type_document: 'metre').order(created_at: :desc)
    end
    if @membership.can_manage_permis?
      @permis_docs   = @project.documents.where(type_document: 'permis_urbanisme').order(created_at: :desc)
      @plans_docs    = @project.documents.where(type_document: 'plan').order(created_at: :desc)
      @permis_statut_config = {
        'non_requis' => { label: 'Non requis',  color: 'secondary', icon: 'bi-slash-circle'       },
        'en_cours'   => { label: 'En cours',    color: 'warning',   icon: 'bi-hourglass-split'    },
        'obtenu'     => { label: 'Obtenu',      color: 'success',   icon: 'bi-check-circle-fill'  },
        'refuse'     => { label: 'Refusé',      color: 'danger',    icon: 'bi-x-circle-fill'      },
        'a_deposer'  => { label: 'À déposer',   color: 'info',      icon: 'bi-send'               }
      }
    end

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
  def upload_facture_pro    unless @membership&.role == 'entrepreneur'
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

  # POST /projects/:id/upload_document_pro
  # Architecte uploade un plan, un métré ou un document permis depuis sa vue pro
  def upload_document_pro
    unless @membership&.can_manage_permis?
      redirect_back fallback_location: root_path, alert: "Action réservée à l'architecte." and return
    end

    allowed_types = %w[plan metre permis_urbanisme]
    type_doc = params[:type_document].presence_in(allowed_types)
    unless type_doc
      redirect_back fallback_location: pro_view_project_path(@project), alert: "Type de document invalide." and return
    end
    unless params[:document_file].present?
      redirect_back fallback_location: pro_view_project_path(@project), alert: "Veuillez joindre un fichier." and return
    end

    document = Document.new(
      user:          current_user,
      project:       @project,
      property:      @project.property,
      type_document: type_doc,
      status:        'approved',
      description:   params[:description].presence
    )
    document.file.attach(params[:document_file])

    if document.save
      labels = { 'plan' => 'Plan', 'metre' => 'Métré', 'permis_urbanisme' => 'Document permis' }
      redirect_to pro_view_project_path(@project), notice: "#{labels[type_doc]} ajouté ✓"
    else
      redirect_back fallback_location: pro_view_project_path(@project),
                    alert: "Erreur : #{document.errors.full_messages.join(', ')}"
    end
  end

  # PATCH /projects/:id/update_permis_pro
  # Architecte met à jour les infos du permis d'urbanisme
  def update_permis_pro
    unless @membership&.can_manage_permis?
      redirect_back fallback_location: root_path, alert: "Action réservée à l'architecte." and return
    end

    permis_attrs = params.require(:project).permit(
      :permis_urbanisme_statut,
      :permis_urbanisme_number,
      :permis_urbanisme_date,
      :permis_urbanisme_autorite,
      :permis_urbanisme_notes
    )

    # Suivi historique si le statut change
    if permis_attrs[:permis_urbanisme_statut].present? &&
       permis_attrs[:permis_urbanisme_statut] != @project.permis_urbanisme_statut
      historique = (@project.permis_urbanisme_historique || []).dup
      historique << {
        'statut'     => permis_attrs[:permis_urbanisme_statut],
        'changed_at' => Time.current.iso8601,
        'changed_by' => current_user.id
      }
      permis_attrs = permis_attrs.merge(permis_urbanisme_historique: historique)
    end

    if @project.update(permis_attrs)
      redirect_to pro_view_project_path(@project), notice: "Infos permis mises à jour ✓"
    else
      redirect_back fallback_location: pro_view_project_path(@project),
                    alert: "Erreur : #{@project.errors.full_messages.join(', ')}"
    end
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
