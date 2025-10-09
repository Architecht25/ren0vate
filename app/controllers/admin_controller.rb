class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def dashboard
    @local_storage_data = {} # Placeholder pour les données JS
    @primes = Prime.all
    @categories = Category.all
    @documents = Document.all
    @notifications = Notification.all
    @properties = Property.all
    @projects = Project.all
    @requests = Request.all
    @simulations = Simulation.all
    @users = User.all
    @backup_status = BackupStatusService.call
    @admin_stats = AdminStatsService.call
    @system_info = SystemInfoService.collect_system_info
  end

  def geocode_properties
    properties_to_geocode = Property.where(latitude: nil, longitude: nil)

    geocoded_count = 0
    properties_to_geocode.each do |property|
      if property.geocode
        property.update(geocoded_at: Time.current)
        geocoded_count += 1
      end

      # Petite pause pour éviter de surcharger l'API de géocodage
      sleep(0.1)
    end

    render json: {
      success: true,
      geocoded: geocoded_count,
      total: properties_to_geocode.count,
      message: "#{geocoded_count} propriétés géocodées sur #{properties_to_geocode.count}"
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: 422
  end

  def generate_notifications
    results = SmartNotificationGeneratorService.generate_all

    render json: {
      success: true,
      total_generated: results.values.sum,
      profile_completion: results[:profile_completion],
      property_setup: results[:property_setup],
      simulation_encouragement: results[:simulation_encouragement],
      geocoding_issues: results[:geocoding_issues],
      admin_insights: results[:admin_insights],
      engagement: results[:engagement],
      message: "#{results.values.sum} notifications générées avec succès"
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: 422
  end

  private

  def ensure_admin
    unless current_user&.admin?
      flash[:alert] = "Accès non autorisé. Vous devez être administrateur."
      redirect_to root_path
    end
  end
end
