class ContractorSignaturesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :sign, :reject]
  before_action :ensure_admin_or_moderator, only: [:index], unless: -> { params[:request_id].present? }
  before_action :set_request, only: [:new, :create], if: -> { params[:request_id].present? }
  before_action :set_contractor_signature, only: [:show, :edit, :update, :destroy, :sign, :reject, :resend]
  before_action :verify_signature_token, only: [:show, :sign, :reject]

  def index
    if params[:request_id].present?
      # Vue spécifique à une demande
      @request = Request.find(params[:request_id])
      @contractor_signatures = @request.contractor_signatures.includes(:user)
      @pending_signatures = @contractor_signatures.pending_signature
      @completed_signatures = @contractor_signatures.completed
    else
      # Vue globale pour les gestionnaires
      @contractor_signatures = ContractorSignature.joins(request: [:user, :property])
                                                 .includes(request: [:user, :property])

      # Filtres
      if params[:status].present?
        @contractor_signatures = @contractor_signatures.where(status: params[:status])
      end

      if params[:region].present?
        @contractor_signatures = @contractor_signatures.joins(request: :property)
                                                      .where(requests: { properties: { region: params[:region] } })
      end

      if params[:work_type].present?
        @contractor_signatures = @contractor_signatures.where(work_type: params[:work_type])
      end

      # Tri par défaut : les demandes en attente en premier
      @contractor_signatures = @contractor_signatures.order(
        Arel.sql("CASE
          WHEN status = 'pending' THEN 1
          WHEN status = 'signed' THEN 2
          WHEN status = 'rejected' THEN 3
          ELSE 4
        END"),
        created_at: :desc
      )

      # Limite pour performance
      @contractor_signatures = @contractor_signatures.limit(100)

      # Variables pour les statistiques dans la vue globale
      @pending_signatures = ContractorSignature.pending_signature
      @completed_signatures = ContractorSignature.completed
    end
  end

  def show
    # Page publique pour l'entrepreneur (via token)
    if params[:token].present?
      @contractor_signature.mark_as_viewed! if @contractor_signature.sent?
      render 'public_signature', layout: 'contractor'
    else
      # Page privée pour le client
      redirect_to request_contractor_signatures_path(@contractor_signature.request)
    end
  end

  def new
    @contractor_signature = @request.contractor_signatures.build
    @work_types = ContractorSignature.work_types.keys.map { |key| [key.humanize, key] }
  end

  def create
    @contractor_signature = @request.contractor_signatures.build(contractor_signature_params)
    @contractor_signature.user = current_user

    if @contractor_signature.save
      if params[:send_immediately] == '1'
        if @contractor_signature.send_signature_request!
          redirect_to request_contractor_signatures_path(@request),
                      notice: 'Demande de signature créée et envoyée avec succès.'
        else
          redirect_to request_contractor_signatures_path(@request),
                      alert: 'Demande créée mais erreur lors de l\'envoi de l\'email.'
        end
      else
        redirect_to request_contractor_signatures_path(@request),
                    notice: 'Demande de signature créée. Vous pouvez l\'envoyer manuellement.'
      end
    else
      @work_types = ContractorSignature.work_types.keys.map { |key| [key.humanize, key] }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to request_contractor_signatures_path(@contractor_signature.request) if @contractor_signature.completed?
  end

  def update
    if @contractor_signature.update(contractor_signature_params)
      redirect_to request_contractor_signatures_path(@contractor_signature.request),
                  notice: 'Demande de signature mise à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    request = @contractor_signature.request
    @contractor_signature.destroy!
    redirect_to request_contractor_signatures_path(request),
                notice: 'Demande de signature supprimée.'
  end

  def resend
    if @contractor_signature.send_signature_request!
      redirect_to request_contractor_signatures_path(@contractor_signature.request),
                  notice: 'Email de rappel envoyé avec succès.'
    else
      redirect_to request_contractor_signatures_path(@contractor_signature.request),
                  alert: 'Erreur lors de l\'envoi de l\'email.'
    end
  end

  def sign
    # Action publique pour l'entrepreneur
    signature_data = {
      signed_by: params[:signature_name],
      signed_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    }

    if @contractor_signature.mark_as_signed!(signature_data)
      # Upload des annexes signées si présentes
      if params[:signed_annexes].present?
        params[:signed_annexes].each do |file|
          @contractor_signature.signed_annexes.attach(file)
        end
      end

      render 'signature_success', layout: 'contractor'
    else
      flash.now[:alert] = 'Erreur lors de la signature. Veuillez réessayer.'
      render 'public_signature', layout: 'contractor', status: :unprocessable_entity
    end
  end

  def reject
    # Action publique pour l'entrepreneur
    rejection_reason = params[:rejection_reason]

    if rejection_reason.present? && @contractor_signature.mark_as_rejected!(rejection_reason)
      render 'signature_rejected', layout: 'contractor'
    else
      flash.now[:alert] = 'Veuillez préciser la raison du refus.'
      render 'public_signature', layout: 'contractor', status: :unprocessable_entity
    end
  end

  # Actions AJAX
  def send_batch
    request = Request.find(params[:request_id])
    signatures = request.contractor_signatures.where(id: params[:signature_ids])

    success_count = 0
    signatures.each do |signature|
      success_count += 1 if signature.send_signature_request!
    end

    render json: {
      success: true,
      message: "#{success_count}/#{signatures.count} emails envoyés avec succès.",
      sent_count: success_count,
      total_count: signatures.count
    }
  end

  def check_status
    render json: {
      status: @contractor_signature.status,
      progress: @contractor_signature.request.contractor_signatures_progress,
      last_activity: @contractor_signature.updated_at,
      expires_in: @contractor_signature.days_until_expiry
    }
  end

  private

  def set_request
    @request = current_user.requests.find(params[:request_id])
  end

  def set_contractor_signature
    if params[:token].present?
      @contractor_signature = ContractorSignature.find_by!(signature_token: params[:token])
    else
      @contractor_signature = ContractorSignature.find(params[:id])
      # Vérifier que l'utilisateur a accès à cette signature
      unless @contractor_signature.request.user == current_user
        redirect_to root_path, alert: 'Accès non autorisé.'
      end
    end
  end

  def verify_signature_token
    return if @contractor_signature&.signature_token == params[:token]

    render 'invalid_token', layout: 'contractor', status: :not_found
  end

  def contractor_signature_params
    params.require(:contractor_signature).permit(
      :contractor_name, :contractor_email, :contractor_phone, :contractor_company,
      :contractor_registration_number, :work_description, :work_type, :estimated_amount,
      technical_certificates: [], signed_annexes: []
    )
  end
end
