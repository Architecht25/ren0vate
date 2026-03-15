class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def dashboard
    @local_storage_data = {} # Placeholder pour les données JS

    # ✅ Les données admin doivent montrer TOUTES les données du système
    # Mais seulement si l'utilisateur est admin (déjà vérifié par before_action :ensure_admin)
    @primes = Prime.all
    @categories = Category.all
    @documents = Document.all
    @notifications = Notification.all
    @properties = Property.all
    @projects = Project.all
    @requests = Request.all
    @request_progresses = RequestProgress.all
    @simulations = Simulation.all
    @users = User.all
    @backup_status = BackupStatusService.call
    @admin_stats = AdminStatsService.call
    @system_info = SystemInfoService.collect_system_info

    # Données de sécurité centralisées (évite les N+1 dans les partials)
    @security_stats = {
      admin_count:       User.admin.count,
      moderator_count:   User.moderator.count,
      user_count:        User.user.count,
      confirmed_count:   User.where.not(confirmed_at: nil).count,
      unconfirmed_count: User.where(confirmed_at: nil).count,
      total_users:       @users.size,
      csp_enforced:      Rails.env.production?,
      ssl_active:        Rails.application.config.force_ssl,
      hsts_active:       Rails.env.production?,
    }

    # Analytics des pages visitées hors connexion
    @page_visits_stats = calculate_page_visits_stats
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

  # Calcul des statistiques des visites de pages
  def calculate_page_visits_stats
    return {} unless PageVisit.table_exists?  # Au cas où la migration n'a pas encore été exécutée

    {
      total_visits: PageVisit.count,
      anonymous_visits: PageVisit.anonymous.count,
      authenticated_visits: PageVisit.authenticated.count,
      today_visits: PageVisit.today.count,
      week_visits: PageVisit.this_week.count,
      month_visits: PageVisit.this_month.count,
      popular_pages: PageVisit.popular_pages(10),
      visits_by_region: PageVisit.visits_by_region,
      simulation_activity: PageVisit.simulation_activity,
      daily_visits: PageVisit.daily_visits(7),
      anonymous_vs_auth: PageVisit.anonymous_vs_authenticated
    }
  rescue => e
    Rails.logger.error "Erreur calcul page_visits_stats: #{e.message}"
    {}
  end
end
