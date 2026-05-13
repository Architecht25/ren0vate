class AdminController < ApplicationController
  include ActionView::Helpers::NumberHelper

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

    # --- Nouvelles données dashboard ---

    # Onglet Activité : feed des 7 derniers jours
    @recent_activity = build_recent_activity

    # Onglet Projets & Chantiers
    @projects_recent = Project.includes(:user, :property, :reserves).order(created_at: :desc).limit(20)
    @reserves_stats = {
      ouvertes:   Reserve.where(statut: 'ouverte').count,
      en_cours:   Reserve.where(statut: 'en_cours').count,
      levees:     Reserve.where(statut: 'levee').count,
    }
    @project_members_pending = ProjectMember.includes(:user, :project).where(status: 'pending').order(created_at: :desc).limit(10)

    # Onglet Finances
    @factures_recent = Facture.includes(:project, document: :property).order(created_at: :desc).limit(30)
    @factures_expiration_critique = Facture.expiration_critique.includes(:project).order(jours_avant_expiration: :asc).limit(10)
    @factures_expiration_proche   = Facture.expiration_proche.where('jours_avant_expiration > 30').includes(:project).order(jours_avant_expiration: :asc).limit(10)
    @finance_stats = {
      total_devis:           Facture.devis.count,
      total_factures:        Facture.factures.count,
      non_payees:            Facture.non_payees.count,
      ocr_confiance_moyenne: Facture.where.not(confiance_ocr: nil).average(:confiance_ocr)&.round(1) || 0,
      validees_manuellement: Facture.extraction_validee.count,
    }

    # Onglet Finances : abonnements Stripe
    @subscriptions_active = Subscription.active.includes(:user)
    @subscriptions_by_tier = Subscription::TIERS.each_with_object({}) do |tier, h|
      subs = Subscription.active.by_tier(tier)
      price = Subscription.new(tier: tier).monthly_price
      h[tier] = { count: subs.count, mrr: subs.count * price }
    end
    @mrr_total = @subscriptions_by_tier.values.sum { |v| v[:mrr] }
    @saas_metrics = SaasMetricsService.call

    # Onglet Support
    @support_tickets_recent = SupportTicket.includes(:user, :support_messages).order(created_at: :desc).limit(20)
    @support_stats = {
      open:      SupportTicket.open_tickets.count,
      overdue:   SupportTicket.overdue.count,
      in_progress: SupportTicket.where(status: 'in_progress').count,
      resolved_this_week: SupportTicket.where(status: 'resolved').where('updated_at >= ?', 7.days.ago).count,
    }
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

  # Feed d'activité récente cross-entités (7 derniers jours)
  def build_recent_activity
    since = 7.days.ago
    events = []

    User.where('created_at >= ?', since).order(created_at: :desc).limit(20).each do |u|
      events << { type: :user, icon: 'person-plus', color: '#667eea', label: "Nouvel utilisateur : #{u.email}", at: u.created_at, link: admin_user_path(u) }
    end
    Project.where('created_at >= ?', since).includes(:user, :property).order(created_at: :desc).limit(20).each do |p|
      events << { type: :project, icon: 'hammer', color: '#ea580c', label: "Projet créé : #{p.nom || 'Sans nom'} (#{p.user&.email})", at: p.created_at }
    end
    Simulation.where('created_at >= ?', since).includes(:user).order(created_at: :desc).limit(20).each do |s|
      events << { type: :simulation, icon: 'calculator', color: '#43e97b', label: "Simulation : #{s.titre || s.region} — #{number_to_currency(s.total_simule, unit: '€', format: '%n %u')} (#{s.user&.email})", at: s.created_at }
    end
    Document.where('created_at >= ?', since).order(created_at: :desc).limit(20).each do |d|
      events << { type: :document, icon: 'file-earmark-arrow-up', color: '#fd9644', label: "Document uploadé : #{d.type_document&.humanize}", at: d.created_at }
    end
    SupportTicket.where('created_at >= ?', since).includes(:user).order(created_at: :desc).limit(20).each do |t|
      events << { type: :ticket, icon: 'headset', color: '#0ea5e9', label: "Ticket support : #{t.subject} (#{t.user&.email})", at: t.created_at, link: admin_support_ticket_path(t) }
    end
    RequestProgress.where('created_at >= ?', since).order(created_at: :desc).limit(20).each do |rp|
      events << { type: :prime, icon: 'clipboard-check', color: '#8b5cf6', label: "Suivi prime : #{rp.status_administratif&.humanize}", at: rp.created_at }
    end

    events.sort_by { |e| e[:at] }.reverse
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
