class RequestProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_request_progress, only: [:show, :edit, :update, :destroy]
  before_action :set_request, only: [:index, :new, :create]

  def index
    # ✅ CORRECTION SÉCURITÉ: Filtrer les request_progresses par utilisateur connecté
    if @request
      # Si on filtre par une request spécifique, vérifier qu'elle appartient à l'utilisateur
      unless @request.user == current_user
        redirect_to root_path, alert: "Accès non autorisé"
        return
      end
      @request_progresses = @request.request_progresses.includes(:prime)
    else
      # Récupérer uniquement les request_progresses liées aux requests de l'utilisateur
      base_progresses = RequestProgress.joins(:request)
                                      .where(requests: { user_id: current_user.id })
                                      .includes(:request, :prime)

      # Filtrer par property_id si fourni
      if params[:property_id].present?
        @property = current_user.properties.find(params[:property_id])
        @request_progresses = base_progresses.joins(:request)
                                           .where(requests: { property_id: @property.id })
      else
        @request_progresses = base_progresses
      end
    end

    # Filtres
    @request_progresses = @request_progresses.where(status_administratif: params[:status]) if params[:status].present?

    # Filtre par région - doit gérer les formulaires ET les primes
    if params[:region].present?
      region = params[:region].downcase
      @request_progresses = @request_progresses.where(
        "form_type LIKE ? OR EXISTS (SELECT 1 FROM primes WHERE primes.id = request_progresses.prime_id AND primes.region = ?)",
        "%#{region}%", region
      )
    end

    # Pagination simple
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @per_page = 20
    @offset = (@page - 1) * @per_page
    @total_count = @request_progresses.count
    @request_progresses = @request_progresses.limit(@per_page).offset(@offset)

    # Statistiques pour le dashboard - uniquement pour les données de l'utilisateur
    user_request_progresses = if @request
      @request.request_progresses
    else
      RequestProgress.joins(:request).where(requests: { user_id: current_user.id })
    end

    @stats = {
      total: user_request_progresses.count,
      en_attente: user_request_progresses.en_attente.count,
      finalises: user_request_progresses.finalises.count,
      accordees: user_request_progresses.where(status_administratif: 'accorde').count,
      montant_total_demande: user_request_progresses.sum(:montant_demande) || 0,
      montant_total_accorde: user_request_progresses.sum(:montant_accorde) || 0,
      delais_depasses: user_request_progresses.select { |p| p.statut_delai == :depasse }.count,
      delais_urgents: user_request_progresses.select { |p| p.statut_delai == :urgent }.count
    }
  end

  def show
    @request = @request_progress.request
    @prime = @request_progress.prime
  end

  def new
    if @request
      @request_progress = @request.request_progresses.build
      @primes = Prime.where(region: @request.region)
      @available_forms = get_available_forms_for_region(@request.region)
    else
      @request_progress = RequestProgress.new
      @primes = Prime.all
      @available_forms = get_available_forms_for_property(nil)
      @user_requests = current_user.requests.includes(:property).order(created_at: :desc)
    end
  end

  def create
    if @request
      @request_progress = @request.request_progresses.build(request_progress_params)
      @primes = Prime.where(region: @request.region)
      @available_forms = get_available_forms_for_region(@request.region)
    else
      @request_progress = RequestProgress.new(request_progress_params)
      @primes = Prime.all
      @available_forms = get_available_forms_for_property(nil)
      @user_requests = current_user.requests.includes(:property).order(created_at: :desc)

      # Vérifier que la request appartient bien à l'utilisateur
      if @request_progress.request_id.present?
        selected_request = current_user.requests.find_by(id: @request_progress.request_id)
        unless selected_request
          flash[:alert] = "Demande non trouvée ou non autorisée"
          render :new, status: :unprocessable_entity
          return
        end
      end
    end

    # Convertir les chaînes vides en nil pour respecter la contrainte d'unicité
    @request_progress.numero_dossier = nil if @request_progress.numero_dossier.blank?

    if @request_progress.save
      redirect_to @request_progress, notice: t('request_progress.created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @request = @request_progress.request
    @primes = Prime.where(region: @request.region)
    @available_forms = get_available_forms_for_region(@request.region)
  end

  def update
    # Convertir les chaînes vides en nil pour respecter la contrainte d'unicité
    params[:request_progress][:numero_dossier] = nil if params[:request_progress][:numero_dossier].blank?

    if @request_progress.update(request_progress_params)
      redirect_to @request_progress, notice: t('request_progress.updated_successfully')
    else
      @request = @request_progress.request
      @primes = Prime.where(region: @request.region)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @request = @request_progress.request
    @request_progress.destroy
    redirect_to request_request_progresses_path(@request), notice: t('request_progress.deleted_successfully')
  end

  # Action pour upload de documents
  def upload_document
    @request_progress = RequestProgress.find(params[:id])
    document_uploaded = false

    if params[:document_type] == 'suivi_pdf' && params[:document_suivi_pdf].present?
      @request_progress.document_suivi_pdf.attach(params[:document_suivi_pdf])
      @request_progress.update(document_recu: true, date_derniere_maj: Date.current)
      document_uploaded = true
    elsif params[:document_type] == 'suivi_photo' && params[:document_suivi_photo].present?
      @request_progress.document_suivi_photo.attach(params[:document_suivi_photo])
      @request_progress.update(document_recu: true, date_derniere_maj: Date.current)
      document_uploaded = true
    end

    # Envoyer une notification par email à l'administrateur
    if document_uploaded
      begin
        AdminMailer.tracking_document_uploaded(current_user, @request_progress).deliver_later
      rescue => e
        Rails.logger.error "Erreur lors de l'envoi de notification admin: #{e.message}"
      end
    end

    redirect_to @request_progress, notice: t('request_progress.document_uploaded')
  end

  # Action pour mettre à jour le statut via email
  def update_status_by_email
    @request_progress = RequestProgress.find_by(email_suivi: params[:email_suivi])

    if @request_progress && params[:status].present?
      @request_progress.update(
        status_administratif: params[:status],
        commentaires_admin: params[:commentaire],
        date_derniere_maj: Date.current
      )

      render json: { success: true, message: 'Statut mis à jour' }
    else
      render json: { success: false, message: 'Suivi non trouvé' }, status: :not_found
    end
  end

  private

  def set_request_progress
    @request_progress = RequestProgress.includes(request: :property).find(params[:id])

    # ✅ SÉCURITÉ: Vérifier que la request_progress appartient à l'utilisateur connecté
    unless @request_progress.request.user == current_user
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end
  end

  def set_request
    if params[:request_id]
      @request = Request.find(params[:request_id])

      # ✅ SÉCURITÉ: Vérifier que la request appartient à l'utilisateur connecté
      unless @request.user == current_user
        redirect_to root_path, alert: "Accès non autorisé"
        return
      end
    end
  end

  def request_progress_params
    params.require(:request_progress).permit(
      :request_id, :prime_id, :step, :pourcentage, :status_administratif,
      :montant_demande, :montant_accorde, :date_soumission,
      :date_derniere_maj, :commentaires_admin, :document_recu,
      :numero_dossier, :document_suivi_pdf, :document_suivi_photo,
      :form_type, :form_name
    )
  end

  def get_available_forms_for_region(region)
    forms = get_available_forms_for_property(nil) # Récupérer tous les formulaires
    # Normaliser la région en minuscules pour la comparaison
    normalized_region = region&.downcase
    forms.select { |form| form[:region] == normalized_region }
  end

  def get_available_forms_for_property(property)
    forms = []

    # Si property est nil, retourner tous les formulaires pour toutes les régions
    if property.nil?
      # Formulaires Bruxelles
      forms += [
        { id: :monuments_bruxelles, name: 'Monuments & Sites classés', region: 'bruxelles', category: 'Patrimoine' },
        { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', region: 'bruxelles', category: 'Patrimoine' },
        { id: :communal_bruxelles, name: 'Primes communales', region: 'bruxelles', category: 'Communal' }
      ]

      # Formulaires Wallonie
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', region: 'wallonie', category: 'Rénovation' },
        { id: :audit_wallonie, name: 'Audit énergétique', region: 'wallonie', category: 'Audit' },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', region: 'wallonie', category: 'Patrimoine' },
        { id: :communal_wallonie, name: 'Primes communales', region: 'wallonie', category: 'Communal' }
      ]

      # Formulaires Flandre
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', region: 'flandre', category: 'Rénovation' },
        { id: :monuments_flandre, name: 'Monuments & Sites', region: 'flandre', category: 'Patrimoine' },
        { id: :communal_flandre, name: 'Primes communales', region: 'flandre', category: 'Communal' }
      ]

      return forms
    end

    # Logique spécifique à la propriété (si nécessaire)
    case property.region&.downcase
    when 'bruxelles'
      forms += [
        { id: :monuments_bruxelles, name: 'Monuments & Sites classés', region: 'bruxelles', category: 'Patrimoine', eligible: true },
        { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', region: 'bruxelles', category: 'Patrimoine', eligible: true },
        { id: :communal_bruxelles, name: 'Primes communales', region: 'bruxelles', category: 'Communal', eligible: true }
      ]
    when 'wallonie'
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', region: 'wallonie', category: 'Rénovation', eligible: true },
        { id: :audit_wallonie, name: 'Audit énergétique', region: 'wallonie', category: 'Audit', eligible: true },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', region: 'wallonie', category: 'Patrimoine', eligible: true },
        { id: :communal_wallonie, name: 'Primes communales', region: 'wallonie', category: 'Communal', eligible: true }
      ]
    when 'flandre'
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', region: 'flandre', category: 'Rénovation', eligible: true },
        { id: :monuments_flandre, name: 'Monuments & Sites', region: 'flandre', category: 'Patrimoine', eligible: true },
        { id: :communal_flandre, name: 'Primes communales', region: 'flandre', category: 'Communal', eligible: true }
      ]
    end

    forms
  end
end
