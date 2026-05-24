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

    report.update!(
      raw_content:   scraper_result[:formatted_text],
      sources_count: scraper_result[:total_items]
    )

    # 2. Analyser avec Claude
    analysis = IntelligenceAnalysisService.new.analyze(scraper_result[:formatted_text])

    if analysis.present?
      report.update!(status: 'completed', analysis: analysis)
      Rails.logger.info "IntelligenceReportJob — analyse complétée (#{analysis.length} chars)"
      AdminMailer.intelligence_report_digest(report).deliver_later
    else
      report.update!(status: 'failed', error_message: 'Analyse Claude vide ou timeout')
      Rails.logger.error "IntelligenceReportJob — analyse échouée"
    end

  rescue => e
    report&.update(status: 'failed', error_message: e.message.truncate(500))
    Rails.logger.error "IntelligenceReportJob — erreur: #{e.message}"
    raise e if Rails.env.development?
  end
end
