class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, except: [:stop_impersonating]
  before_action :find_user, only: [:show, :details, :edit, :update, :destroy, :properties, :documents, :projects, :impersonate]

  def index
    @users = User.includes(:properties, :projects, :simulations, :requests, :documents, :notifications)
                 .order(created_at: :desc)
    @stats = {
      total_users: @users.count,
      confirmed_users: @users.where.not(confirmed_at: nil).count,
      recent_signups: @users.where(created_at: 1.week.ago..Time.current).count,
      admin_count: @users.admin.count,
      moderator_count: @users.moderator.count
    }
  end

  def show
    @user_stats = calculate_user_stats(@user)
  rescue => e
    Rails.logger.error "Erreur lors du chargement de l'utilisateur #{params[:id]}: #{e.message}"
    redirect_to admin_dashboard_path, alert: "Utilisateur non trouvé"
  end

  def details
    # Endpoint AJAX pour charger les détails complets d'un utilisateur
    begin
      @user_stats = calculate_user_stats(@user)

      html_content = render_to_string(
        partial: 'admin/users/user_details_content',
        locals: { user: @user, stats: @user_stats }
      )

      render json: { html: html_content, status: 'success' }
    rescue => e
      Rails.logger.error "Erreur lors du chargement des détails utilisateur #{@user.id}: #{e.message}"
      handle_ajax_error("Erreur lors du chargement des données")
    end
  end

  def edit
  end

  def update
    previous_role = @user.role
    if @user.update(user_params)
      if previous_role != @user.role
        AdminAuditLog.log(admin: current_user, action: "role_change", target_user: @user, request: request,
                          metadata: { from: previous_role, to: @user.role })
      else
        AdminAuditLog.log(admin: current_user, action: "user_update", target_user: @user, request: request)
      end
      redirect_to admin_user_path(@user), notice: 'Utilisateur mis à jour avec succès'
    else
      render :edit
    end
  end

  def destroy
    if @user.admin? && User.admin.count == 1
      redirect_to admin_users_path, alert: 'Impossible de supprimer le dernier administrateur'
      return
    end

    AdminAuditLog.log(admin: current_user, action: "user_destroy", target_user: @user, request: request,
                      metadata: { email: @user.email })
    @user.destroy
    redirect_to admin_users_path, notice: 'Utilisateur supprimé avec succès'
  end

  def toggle_primes_services
    @user.update!(primes_services_client: !@user.primes_services_client)
    redirect_back fallback_location: admin_dashboard_path, notice: "Segment mis à jour pour #{@user.email}."
  end

  def impersonate
    if @user.admin?
      redirect_to admin_user_path(@user), alert: "Impossible d'emprunter l'identité d'un administrateur."
      return
    end

    AdminAuditLog.log(admin: current_user, action: "impersonate", target_user: @user, request: request)
    session[:impersonating_admin_id] = current_user.id
    sign_in(:user, @user, bypass: true)
    redirect_to root_path, notice: "Vous naviguez en tant que #{@user.email}. Déconnectez-vous pour revenir à votre compte admin."
  end

  def stop_impersonating
    admin_id = session.delete(:impersonating_admin_id)
    unless admin_id
      redirect_to root_path, alert: "Aucune session d'impersonation active."
      return
    end

    admin = User.find_by(id: admin_id)
    unless admin&.admin?
      redirect_to root_path, alert: "Session invalide."
      return
    end

    AdminAuditLog.log(admin: admin, action: "stop_impersonating", target_user: current_user, request: request)
    sign_in(:user, admin, bypass: true)
    redirect_to admin_users_path, notice: "Vous êtes revenu sur votre compte administrateur."
  end

  # Action pour voir tous les documents d'un utilisateur
  def documents
    @documents = @user.documents.includes(:property, :project, file_attachment: :blob)
                     .order(created_at: :desc)

    # Filtrer par propriété si demandé
    if params[:property_filter].present?
      @documents = @documents.where(property_id: params[:property_filter])
    end

    render :documents
  end

  # Action pour voir toutes les propriétés d'un utilisateur
  def properties
    @properties = @user.properties.includes(:projects, :simulations, :documents)
                      .order(created_at: :desc)
    render :properties
  end

  # Action pour voir tous les projets d'un utilisateur
  def projects
    @projects = @user.projects.includes(:property, :documents)
                    .order(created_at: :desc)

    # Filtrer par propriété si demandé
    if params[:property_filter].present?
      @projects = @projects.where(property_id: params[:property_filter])
    end

    render :projects
  end

  private

  def find_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_dashboard_path, alert: "Utilisateur non trouvé (ID: #{params[:id]})"
  end

  def ensure_admin
    unless current_user&.admin?
      flash[:alert] = "Accès non autorisé. Vous devez être administrateur."
      redirect_to root_path
    end
  end

  def calculate_user_stats(user)
    {
      properties_count: user.properties.count,
      projects_count: user.projects.count,
      simulations_count: user.simulations.count,
      requests_count: user.requests.count,
      documents_count: user.documents.count,
      notifications_count: user.notifications.count,
      last_sign_in: "Non disponible", # Pas de tracking des connexions pour l'instant
      created_at: user.created_at.strftime("%d/%m/%Y à %H:%M"),
      confirmed_at: user.confirmed_at&.strftime("%d/%m/%Y à %H:%M") || "Non confirmé",
      profile_completion: calculate_profile_completion(user),
      total_document_size: "Non calculé", # file_size n'existe pas dans le modèle Document
      recent_activity: user.notifications.where(created_at: 1.week.ago..Time.current).count
    }
  end

  def calculate_profile_completion(user)
    fields = [:first_name, :last_name, :region, :phone]
    completed = fields.count { |field| user.send(field).present? }
    (completed.to_f / fields.count * 100).round
  end

  # Méthode helper pour gérer les erreurs AJAX
  def handle_ajax_error(error_message)
    render json: {
      html: "<div class='alert alert-danger'><i class='bi bi-exclamation-triangle me-2'></i>#{error_message}</div>",
      status: 'error'
    }
  end

  def user_params
    # :role est intentionnel ici — admin seulement (double vérification ensure_admin)
    params.require(:user).permit(:email, :first_name, :last_name, :phone, :region, :role, :preferred_locale, :primes_services_client) # rubocop:disable Rails/MassAssignment
  end
end
