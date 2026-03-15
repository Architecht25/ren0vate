class BackupStatusService
  def self.call
    new.call
  end

  def call
    {
      heroku_backup: heroku_backup_status,
      last_manual_backup: last_manual_backup_data,
      backup_frequency: get_backup_frequency,
      local_backups: get_local_backup_count,
      backup_health: calculate_backup_health
    }
  end

  private

  # Memoized accessors to avoid duplicate calls within the same request
  def heroku_backup_status
    @heroku_backup_status ||= get_heroku_backup_status
  end

  def last_manual_backup_data
    @last_manual_backup_data ||= get_last_manual_backup
  end

  def get_heroku_backup_status
    return development_mock_data if Rails.env.development?

    begin
      # En production, on peut utiliser l'API Heroku ou vérifier les logs
      heroku_backup_info = fetch_heroku_backup_info
      {
        status: heroku_backup_info[:status] || 'active',
        last_backup: heroku_backup_info[:last_backup] || 24.hours.ago,
        next_backup: heroku_backup_info[:next_backup] || Time.current.beginning_of_day + 1.day + 2.hours,
        size: heroku_backup_info[:size] || 'N/A',
        retention: heroku_backup_info[:retention] || '7 jours',
        simulated: heroku_backup_info[:simulated] || false
      }
    rescue => e
      Rails.logger.error "Erreur récupération statut backup Heroku: #{e.message}"
      {
        status: 'unknown',
        last_backup: nil,
        next_backup: nil,
        size: 'N/A',
        retention: 'N/A',
        error: e.message
      }
    end
  end

  def get_last_manual_backup
    # Scan for archives (bin/backup_production.sh) and JSON user exports (rake backup:critical_data)
    backup_dir = Rails.root.join('tmp', 'backups')
    backup_files = Dir.glob(backup_dir.join('*.tar.gz')) +
                   Dir.glob(backup_dir.join('users_*.json'))
    return nil if backup_files.empty?

    latest_backup = backup_files.max_by { |f| File.mtime(f) }
    {
      file: File.basename(latest_backup),
      created_at: File.mtime(latest_backup),
      size: format_file_size(File.size(latest_backup)),
      path: latest_backup
    }
  rescue => e
    Rails.logger.error "Erreur vérification backup manuel: #{e.message}"
    nil
  end

  def get_backup_frequency
    {
      heroku_automatic: 'Quotidien à 02:00 (Europe/Brussels)',
      manual_scripts: 'Disponible à la demande',
      json_exports: 'Inclus dans backup complet'
    }
  end

  def get_local_backup_count
    backup_dir = Rails.root.join('tmp', 'backups')
    return 0 unless Dir.exist?(backup_dir)

    Dir.glob(File.join(backup_dir, '*.tar.gz')).count
  rescue
    0
  end

  def calculate_backup_health
    heroku_status = heroku_backup_status
    manual_backup = last_manual_backup_data

    score = 0
    max_score = 100

    # Heroku backup actif (40 points)
    score += 40 if heroku_status[:status] == 'active'

    # Backup récent (moins de 48h) (30 points)
    if heroku_status[:last_backup] && heroku_status[:last_backup] > 48.hours.ago
      score += 30
    end

    # Backup manuel disponible (20 points)
    if manual_backup && manual_backup[:created_at] > 7.days.ago
      score += 20
    end

    # Scripts de backup disponibles (10 points)
    backup_script = Rails.root.join('bin', 'backup_production.sh')
    score += 10 if File.exist?(backup_script) && File.executable?(backup_script)

    {
      score: score,
      percentage: (score.to_f / max_score * 100).round,
      status: backup_health_status(score),
      recommendations: generate_recommendations(score, heroku_status, manual_backup)
    }
  end

  def backup_health_status(score)
    case score
    when 90..100
      'excellent'
    when 70..89
      'good'
    when 50..69
      'average'
    else
      'needs_attention'
    end
  end

  def generate_recommendations(score, heroku_status, manual_backup)
    recommendations = []

    if heroku_status[:status] != 'active'
      recommendations << "Activer les backups automatiques Heroku"
    end

    if !manual_backup || manual_backup[:created_at] < 7.days.ago
      recommendations << "Effectuer un backup manuel récent"
    end

    if heroku_status[:last_backup] && heroku_status[:last_backup] < 48.hours.ago
      recommendations << "Vérifier la configuration des backups automatiques"
    end

    if score < 70
      recommendations << "Consulter la documentation BACKUP_STRATEGY.md"
    end

    recommendations.empty? ? ["Configuration optimale"] : recommendations
  end

  def fetch_heroku_backup_info
    require 'open3'
    app_name = ENV.fetch('HEROKU_APP_NAME', 'ren0vate')
    stdout, _stderr, status = Open3.capture3('heroku', 'pg:backups', '--app', app_name)
    return simulated_defaults unless status.success?

    # Parse first data line: " a204 2026-03-15 01:03:36 +0000 Completed 2026-03-15 01:04:18 +0000 970.62KB  DATABASE"
    # Lines are indented with a leading space in heroku CLI output
    first_backup = stdout.lines.find { |l| l.match?(/\A\s+(a|b)\d+\s/) }
    return simulated_defaults unless first_backup

    parts = first_backup.split
    last_backup_time = Time.parse("#{parts[1]} #{parts[2]} #{parts[3]}") rescue nil

    {
      status: parts[4]&.downcase == 'completed' ? 'active' : 'error',
      last_backup: last_backup_time,
      next_backup: last_backup_time ? last_backup_time + 1.day : nil,
      size: parts[8] || 'N/A',
      retention: '7 jours',
      simulated: false
    }
  rescue => e
    Rails.logger.warn "Lecture backups Heroku via CLI impossible: #{e.message}"
    simulated_defaults
  end

  def simulated_defaults
    {
      status: 'active',
      last_backup: 24.hours.ago,
      next_backup: Time.current.beginning_of_day + 1.day + 2.hours,
      size: 'N/A',
      retention: '7 jours',
      simulated: true
    }
  end

  def development_mock_data
    {
      status: 'active',
      last_backup: 6.hours.ago,
      next_backup: Time.current.beginning_of_day + 1.day + 2.hours,
      size: '42.3 MB',
      retention: '7 jours',
      simulated: true
    }
  end

  def format_file_size(size_bytes)
    return '0 B' if size_bytes == 0

    units = ['B', 'KB', 'MB', 'GB']
    base = 1024

    if size_bytes < base
      "#{size_bytes} B"
    else
      exp = (Math.log(size_bytes) / Math.log(base)).floor
      exp = [exp, units.length - 1].min

      size = size_bytes.to_f / (base ** exp)
      "#{size.round(1)} #{units[exp]}"
    end
  end
end
