class RequestProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_request_progress, only: [:show, :edit, :update, :destroy]
  before_action :set_request, only: [:index, :new, :create]

  def index
    @request_progresses = @request ?
      @request.request_progresses.includes(:prime) :
      RequestProgress.includes(:request, :prime).all

    # Filtres
    @request_progresses = @request_progresses.where(status_administratif: params[:status]) if params[:status].present?
    @request_progresses = @request_progresses.joins(:prime).where(primes: { region: params[:region] }) if params[:region].present?

    # Pagination simple
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @per_page = 20
    @offset = (@page - 1) * @per_page
    @total_count = @request_progresses.count
    @request_progresses = @request_progresses.limit(@per_page).offset(@offset)

    # Statistiques pour le dashboard
    all_progresses = @request ?
      @request.request_progresses :
      RequestProgress.all

    @stats = {
      total: all_progresses.count,
      en_attente: all_progresses.en_attente.count,
      finalises: all_progresses.finalises.count,
      accordees: all_progresses.where(status_administratif: 'accorde').count,
      montant_total_demande: all_progresses.sum(:montant_demande) || 0,
      montant_total_accorde: all_progresses.sum(:montant_accorde) || 0
    }
  end

  def show
    @request = @request_progress.request
    @prime = @request_progress.prime
  end

  def new
    @request_progress = @request.request_progresses.build
    @primes = Prime.where(region: @request.region)
  end

  def create
    @request_progress = @request.request_progresses.build(request_progress_params)
    @primes = Prime.where(region: @request.region)

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

    if params[:document_type] == 'suivi_pdf' && params[:document_suivi_pdf].present?
      @request_progress.document_suivi_pdf.attach(params[:document_suivi_pdf])
      @request_progress.update(document_recu: true, date_derniere_maj: Date.current)
    elsif params[:document_type] == 'suivi_photo' && params[:document_suivi_photo].present?
      @request_progress.document_suivi_photo.attach(params[:document_suivi_photo])
      @request_progress.update(document_recu: true, date_derniere_maj: Date.current)
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
    @request_progress = RequestProgress.find(params[:id])
  end

  def set_request
    @request = Request.find(params[:request_id]) if params[:request_id]
  end

  def request_progress_params
    params.require(:request_progress).permit(
      :prime_id, :step, :pourcentage, :status_administratif,
      :montant_demande, :montant_accorde, :date_soumission,
      :date_derniere_maj, :commentaires_admin, :document_recu,
      :numero_dossier, :document_suivi_pdf, :document_suivi_photo
    )
  end
end
