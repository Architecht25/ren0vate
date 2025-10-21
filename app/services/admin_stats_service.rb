class AdminStatsService
  def self.call
    new.call
  end

  def call
    {
      overview: overview_stats,
      users: user_stats,
      properties: property_stats,
      projects: project_stats,
      simulations: simulation_stats,
      primes: prime_stats,
      documents: document_stats,
      request_progresses: request_progress_stats,
      activity: activity_stats,
      geographic: geographic_stats,
      growth: growth_stats
    }
  end

  private

  def overview_stats
    {
      total_users: User.count,
      total_properties: Property.count,
      total_projects: Project.count,
      total_simulations: Simulation.count,
      total_primes: Prime.count,
      total_documents: Document.count,
      total_request_progresses: RequestProgress.count
    }
  end

  def user_stats
    {
      total: User.count,
      confirmed: User.where.not(confirmed_at: nil).count,
      unconfirmed: User.where(confirmed_at: nil).count,
      with_phone: User.where.not(phone: nil).count,
      with_city: User.where.not(city: nil).count,
      admins: User.admin.count,
      users: User.user.count,
      recent_signups: User.where('created_at > ?', 1.week.ago).count,
      active_last_week: User.where('updated_at > ?', 1.week.ago).count,
      completion_rate: calculate_user_completion_rate
    }
  end

  def property_stats
    total = Property.count
    return { total: 0 } if total.zero?

    {
      total: total,
      geocoded: Property.where.not(latitude: nil, longitude: nil).count,
      with_projects: Property.joins(:projects).distinct.count,
      with_simulations: Property.joins(:simulations).distinct.count,
      geocoding_rate: Property.where.not(latitude: nil).count.to_f / total * 100,
      usage_rate: Property.joins(:projects).distinct.count.to_f / total * 100,
      recent_additions: Property.where('created_at > ?', 1.week.ago).count,
      by_region: property_distribution_by_region
    }
  end

  def project_stats
    total = Project.count
    return { total: 0 } if total.zero?

    {
      total: total,
      active: Project.where(statut: 'en_cours').count,
      completed: Project.where(statut: 'termine').count,
      recent: Project.where('created_at > ?', 1.week.ago).count,
      avg_per_property: (total.to_f / Property.count).round(2),
      completion_rate: calculate_project_completion_rate,
      by_type: project_distribution_by_type
    }
  end

  def simulation_stats
    total = Simulation.count
    return { total: 0 } if total.zero?

    {
      total: total,
      this_week: Simulation.where('created_at > ?', 1.week.ago).count,
      this_month: Simulation.where('created_at > ?', 1.month.ago).count,
      avg_per_user: (total.to_f / User.count).round(2),
      success_rate: calculate_simulation_success_rate,
      recent_trend: calculate_simulation_trend
    }
  end

  def prime_stats
    {
      total: Prime.count,
      by_region: Prime.group(:region).count,
      by_category: Prime.joins(:category).group('categories.description').count,
      most_popular: most_popular_primes,
      coverage_by_region: calculate_prime_coverage
    }
  end

  def document_stats
    total = Document.count
    return { total: 0 } if total.zero?

    {
      total: total,
      this_week: Document.where('created_at > ?', 1.week.ago).count,
      this_month: Document.where('created_at > ?', 1.month.ago).count,
      avg_per_user: (total.to_f / User.count).round(2),
      by_type: document_distribution_by_type
    }
  end

  def request_progress_stats
    total = RequestProgress.count
    return { total: 0 } if total.zero?

    {
      total: total,
      en_attente: RequestProgress.en_attente.count,
      finalises: RequestProgress.finalises.count,
      accordes: RequestProgress.where(status_administratif: 'accorde').count,
      refuses: RequestProgress.where(status_administratif: 'refuse').count,
      this_week: RequestProgress.where('created_at > ?', 1.week.ago).count,
      this_month: RequestProgress.where('created_at > ?', 1.month.ago).count,
      avg_per_user: (total.to_f / User.count).round(2),
      by_region: request_progress_distribution_by_region,
      by_status: RequestProgress.group(:status_administratif).count,
      success_rate: calculate_request_progress_success_rate
    }
  end

  def activity_stats
    {
      daily_signups: daily_activity('users'),
      daily_properties: daily_activity('properties'),
      daily_simulations: daily_activity('simulations'),
      peak_hours: calculate_peak_activity_hours,
      weekly_growth: calculate_weekly_growth
    }
  end

  def geographic_stats
    {
      top_cities: top_cities_by_users,
      postal_code_distribution: postal_code_distribution,
      region_activity: region_activity_stats,
      geocoding_quality: geocoding_quality_stats
    }
  end

  def growth_stats
    {
      user_growth_7d: growth_rate('users', 7.days),
      user_growth_30d: growth_rate('users', 30.days),
      property_growth_7d: growth_rate('properties', 7.days),
      property_growth_30d: growth_rate('properties', 30.days),
      simulation_growth_7d: growth_rate('simulations', 7.days),
      simulation_growth_30d: growth_rate('simulations', 30.days)
    }
  end

  # Méthodes d'aide privées

  def calculate_user_completion_rate
    return 0 if User.count.zero?

    complete_users = User.where.not(phone: nil, city: nil).count
    (complete_users.to_f / User.count * 100).round(1)
  end

  def property_distribution_by_region
    # Approximation basée sur les codes postaux (utiliser code_postal pour Property)
    {
      'Bruxelles' => Property.where('code_postal LIKE ?', '1%').count,
      'Flandre' => Property.where('code_postal SIMILAR TO ?', '[2-3][0-9]{3}').count,
      'Wallonie' => Property.where('code_postal SIMILAR TO ?', '[4-7][0-9]{3}').count
    }
  rescue
    { 'Non déterminé' => Property.count }
  end

  def project_distribution_by_type
    # Utiliser project_type au lieu de type_projet
    Project.group(:project_type).count
  rescue
    { 'Non spécifié' => Project.count }
  end

  def calculate_project_completion_rate
    total = Project.count
    return 0 if total.zero?

    completed = Project.where(statut: 'termine').count
    (completed.to_f / total * 100).round(1)
  rescue
    0
  end

  def calculate_simulation_success_rate
    # Suppose qu'une simulation est réussie si elle a des résultats
    return 0 if Simulation.count.zero?

    # Utiliser total_simule au lieu de prime_totale
    successful = Simulation.where.not(total_simule: nil).count
    (successful.to_f / Simulation.count * 100).round(1)
  rescue
    100 # Par défaut, supposons que toutes sont réussies
  end

  def calculate_simulation_trend
    current_week = Simulation.where('created_at > ?', 1.week.ago).count
    previous_week = Simulation.where('created_at BETWEEN ? AND ?', 2.weeks.ago, 1.week.ago).count

    return 0 if previous_week.zero?

    ((current_week - previous_week).to_f / previous_week * 100).round(1)
  end

  def most_popular_primes
    # Les 5 primes les plus populaires (si vous trackez l'utilisation)
    Prime.limit(5).pluck(:titre, :id).map { |titre, id| { name: titre, id: id } }
  end

  def calculate_prime_coverage
    Prime.group(:region).count.transform_values { |count| "#{count} primes" }
  end

  def document_distribution_by_type
    # Utiliser type_document qui existe dans la table
    Document.group(:type_document).count
  rescue
    { 'Documents' => Document.count }
  end

  def daily_activity(model_name)
    model = model_name.classify.constantize
    (0..6).map do |days_ago|
      date = days_ago.days.ago.beginning_of_day
      count = model.where(created_at: date..date.end_of_day).count
      { date: date.strftime('%d/%m'), count: count }
    end.reverse
  end

  def calculate_peak_activity_hours
    # Analyse des heures de création des utilisateurs
    hours_data = User.group("EXTRACT(hour FROM created_at)").count
    peak_hour = hours_data.max_by { |hour, count| count }&.first || 12
    "#{peak_hour}h - #{(peak_hour + 1) % 24}h"
  end

  def calculate_weekly_growth
    current_users = User.where('created_at > ?', 1.week.ago).count
    previous_users = User.where('created_at BETWEEN ? AND ?', 2.weeks.ago, 1.week.ago).count

    return '+∞%' if previous_users.zero? && current_users > 0
    return '0%' if previous_users.zero?

    growth = ((current_users - previous_users).to_f / previous_users * 100).round(1)
    growth > 0 ? "+#{growth}%" : "#{growth}%"
  end

  def top_cities_by_users
    User.where.not(city: nil)
        .group(:city)
        .order('count_id DESC')
        .limit(5)
        .count('id')
  end

  def postal_code_distribution
    Property.where.not(code_postal: nil)
            .group(:code_postal)
            .order('count_id DESC')
            .limit(10)
            .count('id')
  end

  def region_activity_stats
    {
      'Bruxelles' => {
        users: User.where('postal_code LIKE ?', '1%').count,
        properties: Property.where('code_postal LIKE ?', '1%').count
      },
      'Flandre' => {
        users: User.where('postal_code SIMILAR TO ?', '[2-3][0-9]{3}').count,
        properties: Property.where('code_postal SIMILAR TO ?', '[2-3][0-9]{3}').count
      },
      'Wallonie' => {
        users: User.where('postal_code SIMILAR TO ?', '[4-7][0-9]{3}').count,
        properties: Property.where('code_postal SIMILAR TO ?', '[4-7][0-9]{3}').count
      }
    }
  rescue
    { 'Données non disponibles' => { users: 0, properties: 0 } }
  end

  def geocoding_quality_stats
    total = Property.count
    return { quality: 0, total: 0 } if total.zero?

    geocoded = Property.where.not(latitude: nil, longitude: nil).count
    quality = (geocoded.to_f / total * 100).round(1)

    {
      quality: quality,
      total: total,
      geocoded: geocoded,
      pending: total - geocoded
    }
  end

  def growth_rate(model_name, period)
    model = model_name.classify.constantize
    current_period = model.where('created_at > ?', period.ago).count
    previous_start = (period.to_i * 2).seconds.ago
    previous_end = period.ago
    previous_period = model.where('created_at BETWEEN ? AND ?', previous_start, previous_end).count

    return '+∞%' if previous_period.zero? && current_period > 0
    return '0%' if previous_period.zero?

    growth = ((current_period - previous_period).to_f / previous_period * 100).round(1)
    growth > 0 ? "+#{growth}%" : "#{growth}%"
  end

  def request_progress_distribution_by_region
    # Utiliser la région de la demande associée
    RequestProgress.joins(:request).group('requests.region').count
  rescue
    { 'Non déterminé' => RequestProgress.count }
  end

  def calculate_request_progress_success_rate
    total = RequestProgress.count
    return 0 if total.zero?

    # Taux de succès = nombre de demandes accordées / total des demandes finalisées
    finalises = RequestProgress.finalises.count
    return 0 if finalises.zero?

    accordes = RequestProgress.where(status_administratif: 'accorde').count
    (accordes.to_f / finalises * 100).round(1)
  rescue
    0
  end
end
