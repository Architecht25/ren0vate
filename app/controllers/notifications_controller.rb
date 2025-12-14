class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, only: [:new_admin, :create_admin, :generate_automatic, :edit, :update, :destroy]
  before_action :set_notification, only: [:show, :edit, :update, :destroy, :mark_as_read]

  def index
    @notifications = current_user.notifications
                                .active
                                .includes(:property, :project, :simulation)
                                .by_priority

    # Filtrage par type si spécifié
    @notifications = @notifications.where(type: params[:type]) if params[:type].present?

    # Filtrage par catégorie si spécifié
    @notifications = @notifications.where(category: params[:category]) if params[:category].present?

    # Filtrage lu/non lu
    case params[:status]
    when 'unread'
      @notifications = @notifications.unread
    when 'read'
      @notifications = @notifications.read_notifications
    end

    # Stats pour l'interface
    @stats = {
      total: current_user.notifications.active.count,
      unread: current_user.unread_notifications_count,
      by_priority: current_user.notifications.active.group(:priority).count,
      by_category: current_user.notifications.active.group(:category).count
    }
  end

  def show
    # Marquer automatiquement comme lu quand on consulte
    @notification.mark_as_read! unless @notification.read?

    # Préparer les données pour la vue
    @related_items = get_related_items(@notification)
  end

  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.json { render json: { status: 'success', read: true } }
      format.html { redirect_back(fallback_location: notifications_path) }
    end
  end

  def mark_all_as_read
    current_user.mark_all_notifications_as_read!

    respond_to do |format|
      format.json { render json: { status: 'success', count: current_user.unread_notifications_count } }
      format.html { redirect_to notifications_path, notice: 'Toutes les notifications ont été marquées comme lues.' }
    end
  end

  def new
    @notification = current_user.notifications.build
  end

  def create
    @notification = current_user.notifications.build(notification_params)

    if @notification.save
      redirect_to notifications_path, notice: 'Notification créée avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @notification.destroy

    respond_to do |format|
      format.json { render json: { status: 'success' } }
      format.html { redirect_to notifications_path, notice: 'Notification supprimée.' }
    end
  end

  # Actions admin (à protéger avec un before_action pour les admins)
  def new_admin
    @notification = Notification.new
    @users = User.all
  end

  def create_admin
    case params[:notification][:target_type]
    when 'all_users'
      target_users = User.all
    when 'specific_users'
      target_users = User.where(id: params[:notification][:user_ids])
    when 'by_region'
      region = params[:notification][:target_region]
      target_users = User.where("LOWER(region) = ?", region.downcase) if region.present?
      target_users ||= User.none
    when 'bruxelles_entreprise'
      # Cibler uniquement les entreprises à Bruxelles
      target_users = User.joins(:properties).where(
        "LOWER(properties.region) = ? AND properties.type_bien_bruxelles = ?",
        'bruxelles', 'entreprise'
      ).distinct
    else
      target_users = User.all
    end

    expires_days = params[:notification][:expires_days]
    expires_at = if expires_days.present? && expires_days.to_i > 0
                   expires_days.to_i.days.from_now
                 else
                   nil  # Pas d'expiration si le champ est vide ou zéro
                 end

    Notification.create_admin_notification(
      type: params[:notification][:type],
      title: params[:notification][:title],
      message: params[:notification][:message],
      category: params[:notification][:category] || 'systeme',
      priority: params[:notification][:priority] || 'normale',
      target_users: target_users,
      expires_at: expires_at
    )

    redirect_to notifications_path, notice: "Notification envoyée à #{target_users.count} utilisateurs."
  end

  def generate_automatic
    service = NotificationService.new
    count = service.generate_all_automatic_notifications

    respond_to do |format|
      format.json { render json: { success: true, count: count } }
      format.html { redirect_to '/admin/dashboard', notice: "#{count} notifications automatiques générées." }
    end
  end

  private

  def ensure_admin
    # Pour l'instant, basé sur l'email - à améliorer avec un vrai système de rôles
    unless current_user.email == 'robin@primes-services.be'
      redirect_to notifications_path, alert: 'Accès non autorisé.'
    end
  end

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_params
    params.require(:notification).permit(:title, :message, :type, :category, :priority, :action_url, :expires_at, :property_id, :project_id, :simulation_id)
  end

  def get_related_items(notification)
    items = {}

    if notification.property
      items[:property] = notification.property
      items[:property_documents] = notification.property.documents.recent.limit(3)
    end

    if notification.project
      items[:project] = notification.project
      items[:project_documents] = notification.project.documents.recent.limit(3)
    end

    if notification.simulation
      items[:simulation] = notification.simulation
    end

    items
  end
end
