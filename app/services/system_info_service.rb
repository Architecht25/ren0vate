class SystemInfoService
  def self.collect_system_info
    {
      environment: collect_environment_info,
      performance: collect_performance_info,
      infrastructure: collect_infrastructure_info,
      services: collect_services_status,
      security: collect_security_info,
      maintenance: collect_maintenance_info
    }
  end

  private

  def self.collect_environment_info
    {
      rails_env: Rails.env,
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION,
      ruby_platform: RUBY_PLATFORM,
      current_time: Time.current,
      timezone: Time.zone.name,
      uptime: calculate_uptime
    }
  end

  def self.collect_performance_info
    memory_usage = get_memory_usage
    {
      memory_usage: memory_usage,
      database_pool: get_database_pool_info,
      active_connections: ActiveRecord::Base.connection_pool.connections.count,
      cache_stats: get_cache_stats
    }
  end

  def self.collect_infrastructure_info
    {
      database_adapter: ActiveRecord::Base.connection.adapter_name,
      database_version: get_database_version,
      critical_gems: get_critical_gems_info,
      heroku_info: get_heroku_info,
      storage_info: get_storage_info
    }
  end

  def self.collect_services_status
    {
      database: check_database_status,
      email: check_email_service,
      storage: check_storage_service,
      external_apis: check_external_apis
    }
  end

  def self.collect_security_info
    {
      active_sessions: count_active_sessions,
      csp_status: get_csp_status,
      ssl_info: get_ssl_info,
      recent_failed_logins: count_recent_failed_logins
    }
  end

  def self.collect_maintenance_info
    {
      last_migration: get_last_migration,
      deployment_info: get_deployment_info,
      log_size: get_log_sizes,
      cleanup_status: get_cleanup_status
    }
  end

  # Méthodes utilitaires
  def self.calculate_uptime
    if Rails.env.production?
      # En production sur Heroku, l'uptime est géré par la plateforme
      "Géré par Heroku"
    else
      # En développement, on donne une estimation simple
      "Session de développement active"
    end
  end

  def self.get_memory_usage
    if defined?(GC.stat)
      gc_stats = GC.stat
      {
        heap_allocated_pages: gc_stats[:heap_allocated_pages],
        heap_live_slots: gc_stats[:heap_live_slots],
        total_allocated_objects: gc_stats[:total_allocated_objects]
      }
    else
      { status: "GC stats non disponibles" }
    end
  end

  def self.get_database_pool_info
    pool = ActiveRecord::Base.connection_pool
    {
      size: pool.size,
      checked_out: pool.connections.count(&:in_use?),
      available: pool.size - pool.connections.count(&:in_use?)
    }
  end

  def self.get_cache_stats
    if Rails.cache.respond_to?(:stats)
      Rails.cache.stats
    else
      { status: "Cache stats non disponibles" }
    end
  end

  def self.get_database_version
    begin
      case ActiveRecord::Base.connection.adapter_name.downcase
      when 'postgresql'
        ActiveRecord::Base.connection.execute("SELECT version()").first['version']
      when 'sqlite'
        ActiveRecord::Base.connection.execute("SELECT sqlite_version()").first['sqlite_version()']
      else
        "Version non détectable"
      end
    rescue => e
      "Erreur: #{e.message}"
    end
  end

  def self.get_critical_gems_info
    critical_gems = %w[rails devise pg bootsnap puma]
    gems_info = {}

    critical_gems.each do |gem_name|
      begin
        gem_spec = Gem.loaded_specs[gem_name]
        gems_info[gem_name] = gem_spec ? gem_spec.version.to_s : "Non installé"
      rescue
        gems_info[gem_name] = "Erreur"
      end
    end

    gems_info
  end

  def self.get_heroku_info
    if ENV['DYNO']
      {
        dyno_name: ENV['DYNO'],
        heroku_app: ENV['HEROKU_APP_NAME'],
        release_version: ENV['HEROKU_RELEASE_VERSION'],
        slug_commit: ENV['HEROKU_SLUG_COMMIT']
      }
    else
      { status: "Non déployé sur Heroku" }
    end
  end

  def self.get_storage_info
    begin
      # Informations de base sur le stockage
      if Rails.env.production?
        { status: "Cloudinary configuré" }
      else
        { status: "Stockage local (développement)" }
      end
    rescue => e
      { error: e.message }
    end
  end

  def self.check_database_status
    begin
      start_time = Time.current
      ActiveRecord::Base.connection.execute("SELECT 1")
      response_time = ((Time.current - start_time) * 1000).round(2)
      {
        status: "✅ Opérationnel",
        response_time: "#{response_time}ms",
        connection_count: ActiveRecord::Base.connection_pool.connections.count
      }
    rescue => e
      {
        status: "❌ Erreur",
        error: e.message
      }
    end
  end

  def self.check_email_service
    begin
      # Test basique de configuration email
      if ActionMailer::Base.delivery_method == :smtp
        {
          status: "✅ SMTP configuré",
          delivery_method: ActionMailer::Base.delivery_method.to_s
        }
      else
        {
          status: "⚠️ Configuration basique",
          delivery_method: ActionMailer::Base.delivery_method.to_s
        }
      end
    rescue => e
      {
        status: "❌ Erreur",
        error: e.message
      }
    end
  end

  def self.check_storage_service
    begin
      if defined?(Cloudinary)
        {
          status: "✅ Cloudinary configuré",
          service: "Cloudinary"
        }
      else
        {
          status: "📁 Stockage local",
          service: "Local"
        }
      end
    rescue => e
      {
        status: "❌ Erreur",
        error: e.message
      }
    end
  end

  def self.check_external_apis
    apis = {}

    # Test API de géocodage si configurée
    if defined?(Geocoder)
      apis[:geocoding] = { status: "✅ Configuré", service: "Geocoder" }
    else
      apis[:geocoding] = { status: "❌ Non configuré" }
    end

    apis
  end

  def self.count_active_sessions
    begin
      # Compte les utilisateurs connectés dans les 30 dernières minutes
      if defined?(User)
        User.where('current_sign_in_at > ?', 30.minutes.ago).count
      else
        0
      end
    rescue
      0
    end
  end

  def self.get_csp_status
    if Rails.application.config.force_ssl
      { status: "✅ SSL forcé", csp: "Configuré" }
    else
      { status: "⚠️ SSL non forcé", csp: "Basique" }
    end
  end

  def self.get_ssl_info
    if Rails.env.production?
      { status: "✅ Production SSL", environment: "Production" }
    else
      { status: "🔧 Développement", environment: "Local" }
    end
  end

  def self.count_recent_failed_logins
    begin
      if defined?(User)
        # Approximation basée sur les tentatives récentes
        User.where('failed_attempts > 0 AND updated_at > ?', 1.hour.ago).count
      else
        0
      end
    rescue
      0
    end
  end

  def self.get_last_migration
    begin
      migrations = ActiveRecord::Base.connection.migration_context.get_all_versions
      last_version = migrations.max
      if last_version
        {
          version: last_version,
          formatted: Time.parse(last_version.to_s).strftime("%Y-%m-%d %H:%M")
        }
      else
        { status: "Aucune migration" }
      end
    rescue => e
      { error: e.message }
    end
  end

  def self.get_deployment_info
    {
      deployed_at: File.mtime(Rails.root.join("config", "application.rb")).strftime("%Y-%m-%d %H:%M:%S"),
      git_commit: ENV['HEROKU_SLUG_COMMIT'] || "Non disponible",
      release_version: ENV['HEROKU_RELEASE_VERSION'] || "Non disponible"
    }
  end

  def self.get_log_sizes
    log_dir = Rails.root.join("log")
    if Dir.exist?(log_dir)
      sizes = {}
      Dir.glob(log_dir.join("*.log")).each do |log_file|
        file_name = File.basename(log_file)
        size_mb = (File.size(log_file).to_f / 1024 / 1024).round(2)
        sizes[file_name] = "#{size_mb} MB"
      end
      sizes
    else
      { status: "Répertoire log non trouvé" }
    end
  end

  def self.get_cleanup_status
    {
      last_cleanup: "Non programmé",
      session_cleanup: "Auto (Rails)",
      log_rotation: Rails.env.production? ? "Configuré" : "Non nécessaire"
    }
  end

  def self.format_duration(seconds)
    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60

    if days > 0
      "#{days.to_i}j #{hours.to_i}h #{minutes.to_i}m"
    elsif hours > 0
      "#{hours.to_i}h #{minutes.to_i}m"
    else
      "#{minutes.to_i}m"
    end
  end
end
