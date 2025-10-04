class ComplementRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_moderator, only: [:index], unless: -> { params[:request_progress_id].present? }
  before_action :set_request_progress, only: [:new, :create], if: -> { params[:request_progress_id].present? }
  before_action :set_complement_request, only: [:show, :edit, :update, :destroy, :respond, :approve, :reject]

  def index
    if params[:request_progress_id].present?
      # Vue spécifique à un dossier
      @request_progress = RequestProgress.find(params[:request_progress_id])
      @complement_requests = @request_progress.complement_requests.order(created_at: :desc)
      @active_requests = @complement_requests.active
      @completed_requests = @complement_requests.where(status: 'completed')
      @expired_requests = @complement_requests.where(status: 'expired')
    else
      # Vue globale pour les gestionnaires
      @complement_requests = ComplementRequest.joins(request_progress: { request: [:user, :property] })
                                            .includes(request_progress: { request: [:user, :property] })

      # Filtres
      if params[:status].present?
        @complement_requests = @complement_requests.where(status: params[:status])
      end

      if params[:complement_type].present?
        @complement_requests = @complement_requests.where(complement_type: params[:complement_type])
      end

      if params[:priority].present?
        @complement_requests = @complement_requests.where(priority: params[:priority])
      end

      # Tri par défaut : priorité et délais
      @complement_requests = @complement_requests.order(
        Arel.sql("CASE
          WHEN status = 'pending' AND deadline <= CURRENT_DATE + INTERVAL '3 days' THEN 1
          WHEN status = 'pending' THEN 2
          WHEN status = 'completed' THEN 3
          ELSE 4
        END"),
        deadline: :asc,
        created_at: :desc
      )

      # Limite pour performance
      @complement_requests = @complement_requests.limit(100)
    end
  end

  def show
    @response_form = @complement_request.status == 'pending' || @complement_request.status == 'in_progress'
  end

  def new
    @complement_request = @request_progress.complement_requests.build
    @complement_types = ComplementRequest.complement_types.keys.map { |key| [key.humanize, key] }
  end

  def create
    @complement_request = @request_progress.complement_requests.build(complement_request_params)

    if @complement_request.save
      redirect_to request_progress_complement_requests_path(@request_progress),
                  notice: 'Demande de complément créée et envoyée au client.'
    else
      @complement_types = ComplementRequest.complement_types.keys.map { |key| [key.humanize, key] }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @complement_request if @complement_request.completed?
  end

  def update
    if @complement_request.update(complement_request_params)
      redirect_to @complement_request, notice: 'Demande de complément mise à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    request_progress = @complement_request.request_progress
    @complement_request.destroy!
    redirect_to request_progress_complement_requests_path(request_progress),
                notice: 'Demande de complément supprimée.'
  end

  def respond
    # Action pour que le client réponde à la demande de complément
    @complement_request.mark_in_progress! if @complement_request.pending?

    if params[:client_response].present? || params[:response_documents].present?
      response_params = {
        client_response: params[:client_response]
      }

      if @complement_request.submit_response!(response_params[:client_response])
        # Attacher les documents de réponse
        if params[:response_documents].present?
          params[:response_documents].each do |file|
            @complement_request.response_documents.attach(file)
          end
        end

        redirect_to @complement_request,
                    notice: 'Votre réponse a été envoyée avec succès. Elle sera examinée dans les plus brefs délais.'
      else
        flash.now[:alert] = 'Erreur lors de l\'envoi de votre réponse.'
        render :show, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Veuillez fournir une réponse ou des documents.'
      render :show, status: :unprocessable_entity
    end
  end

  def approve
    # Action pour approuver la réponse du client (admin/gestionnaire)
    if current_user.can_access_admin?
      @complement_request.approve_response!
      redirect_to @complement_request,
                  notice: 'Réponse approuvée. Le traitement du dossier peut reprendre.'
    else
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  def reject
    # Action pour rejeter la réponse du client (admin/gestionnaire)
    if current_user.can_access_admin?
      rejection_reason = params[:rejection_reason]

      if rejection_reason.present?
        @complement_request.reject_response!(rejection_reason)
        redirect_to @complement_request,
                    notice: 'Réponse rejetée. Le client sera notifié.'
      else
        flash.now[:alert] = 'Veuillez préciser la raison du rejet.'
        render :show, status: :unprocessable_entity
      end
    else
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  # Actions AJAX
  def extend_deadline
    if current_user.can_access_admin?
      new_deadline = Date.parse(params[:new_deadline])

      if @complement_request.update(deadline: new_deadline)
        render json: {
          success: true,
          message: "Délai prolongé jusqu'au #{new_deadline.strftime('%d/%m/%Y')}",
          new_deadline: new_deadline,
          days_remaining: @complement_request.days_remaining
        }
      else
        render json: {
          success: false,
          message: 'Erreur lors de la prolongation du délai.'
        }
      end
    else
      render json: { success: false, message: 'Accès non autorisé.' }
    end
  end

  def send_reminder
    if @complement_request.pending? || @complement_request.in_progress?
      ComplementRequestMailer.reminder(@complement_request).deliver_now

      render json: {
        success: true,
        message: 'Rappel envoyé au client.',
        last_reminder: Time.current
      }
    else
      render json: {
        success: false,
        message: 'Impossible d\'envoyer un rappel pour ce statut.'
      }
    end
  end

  def analytics
    # Vue analytique pour les admins
    if current_user.can_access_admin?
      @analytics = {
        total_requests: ComplementRequest.count,
        by_status: ComplementRequest.group(:status).count,
        by_type: ComplementRequest.group(:complement_type).count,
        average_response_time: calculate_average_response_time,
        completion_rate: calculate_completion_rate,
        overdue_requests: ComplementRequest.overdue.count
      }
      render :analytics
    else
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  private

  def set_request_progress
    @request_progress = RequestProgress.find(params[:request_progress_id])

    # Vérifier l'accès utilisateur
    unless @request_progress.request.user == current_user || current_user.can_access_admin?
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  def set_complement_request
    @complement_request = ComplementRequest.find(params[:id])

    # Vérifier l'accès utilisateur
    unless @complement_request.request.user == current_user || current_user.can_access_admin?
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  def complement_request_params
    params.require(:complement_request).permit(
      :complement_type, :admin_message, :deadline, :priority,
      required_documents: [], complement_documents: []
    )
  end

  def calculate_average_response_time
    completed_requests = ComplementRequest.where(status: 'completed')
    return 0 if completed_requests.empty?

    total_days = completed_requests.sum do |request|
      (request.completed_at.to_date - request.created_at.to_date).to_i
    end

    (total_days.to_f / completed_requests.count).round(1)
  end

  def calculate_completion_rate
    total = ComplementRequest.count
    return 0 if total.zero?

    completed = ComplementRequest.where(status: 'completed').count
    (completed.to_f / total * 100).round
  end
end
