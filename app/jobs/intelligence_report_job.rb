class IntelligenceReportJob < ApplicationJob
  queue_as :default

  def perform
    report = IntelligenceReport.find_or_initialize_for_current_week

    if report.completed?
      Rails.logger.info "IntelligenceReportJob — rapport #{report.week_of} déjà complété, skip."
      return
    end

    report.update!(status: 'processing')
    Rails.logger.info "IntelligenceReportJob — démarrage #{report.week_of}"

    # 1. Scraper les sources
    scraper_result = IntelligenceScraperService.new.fetch_all
    Rails.logger.info "IntelligenceReportJob — #{scraper_result[:total_items]} articles récupérés"

    # 1b. Ajouter les articles de veille presse importés manuellement
    veille_text   = format_veille_articles
    combined_text = [ scraper_result[:formatted_text], veille_text ].reject(&:blank?).join("\n\n")
    veille_count  = VeilleArticle.active.count
    Rails.logger.info "IntelligenceReportJob — #{veille_count} articles veille presse inclus" if veille_count > 0

    report.update!(
      raw_content:   combined_text,
      sources_count: scraper_result[:total_items] + veille_count
    )

    # 2. Analyser avec Claude
    analysis = IntelligenceAnalysisService.new.analyze(combined_text)

    if analysis.present?
      report.update!(status: 'completed', analysis: analysis)
      Rails.logger.info "IntelligenceReportJob — analyse complétée (#{analysis.length} chars)"
      AdminMailer.intelligence_report_digest(report).deliver_later
      export_for_marketing_agent(report)
      MarketingDraftJob.perform_later(report.id)
    else
      report.update!(status: 'failed', error_message: 'Analyse Claude vide ou timeout')
      Rails.logger.error "IntelligenceReportJob — analyse échouée"
    end

  rescue => e
    report&.update(status: 'failed', error_message: e.message.truncate(500))
    Rails.logger.error "IntelligenceReportJob — erreur: #{e.message}"
    raise e if Rails.env.development?
  end

  private

  def format_veille_articles
    articles = VeilleArticle.for_bot
    return nil if articles.empty?

    lines = [ "=== VEILLE PRESSE — Articles importés manuellement ===" ]
    articles.each do |a|
      lines << "\n[#{a.source} — #{a.source_date&.strftime('%-d %b %Y')}#{a.region.present? && a.region != 'belgique' ? " — #{a.region_label}" : ''}]"
      lines << "Titre : #{a.titre}"
      lines << "Thèmes : #{a.themes_list.join(', ')}" if a.themes_list.any?
      lines << a.contenu.to_s.strip
    end
    lines.join("\n")
  end

  # Exporte le rapport vers ~/agents-hub/ pour l'Agent Marketing.
  # Silencieux si le répertoire n'existe pas (production Heroku).
  def export_for_marketing_agent(report)
    export_dir = File.expand_path('~/agents-hub/Ren0vate/acquisition/outputs/veille')
    return unless Dir.exist?(export_dir)

    filename = "#{report.week_of}.json"
    path     = File.join(export_dir, filename)
    payload  = {
      week_of:       report.week_of,
      sources_count: report.sources_count,
      analysis:      report.analysis,
      exported_at:   Time.current.iso8601
    }
    File.write(path, JSON.pretty_generate(payload))
    Rails.logger.info "IntelligenceReportJob — export agents-hub : #{filename}"
  rescue => e
    Rails.logger.warn "IntelligenceReportJob — export agents-hub échoué : #{e.message}"
  end
end
