class AdminMailer < ApplicationMailer
  default from: ENV.fetch('ADMIN_MAILER_FROM', 'noreply@ren0vate.be'),
          to: ENV.fetch('ADMIN_EMAIL', 'robin@primes-services.be')

  # Notification lorsqu'un utilisateur dépose des documents
  def document_uploaded(user, documents, context = {})
    @user = user
    @documents = documents
    @property = context[:property]
    @project = context[:project]
    @request = context[:request]
    @simulation = context[:simulation]

    # Compter les documents par type
    @documents_by_type = @documents.group_by(&:type_document)

    mail(
      subject: "📄 Nouveaux documents déposés par #{user.email}"
    )
  end

  # Notification pour document de suivi (request_progress)
  def tracking_document_uploaded(user, request_progress)
    @user = user
    @request_progress = request_progress
    @prime = request_progress.prime

    mail(
      subject: "📧 Document de suivi déposé - #{@prime&.titre || 'Demande'}"
    )
  end

  # Notification pour réponse à une demande de complément
  def complement_response_uploaded(user, complement_request)
    @user = user
    @complement_request = complement_request
    @request = complement_request.request

    mail(
      subject: "📎 Réponse à demande de complément - #{user.email}"
    )
  end

  # Rapport de veille hebdomadaire IA
  def intelligence_report_digest(report)
    @report = report

    mail(
      to:      ENV.fetch('INTELLIGENCE_REPORT_EMAIL', 'robin@architecht.be'),
      subject: "🔭 Veille Ren0vate — #{report.week_label} (#{report.sources_count} articles)"
    )
  end

  # Alerte : une ou plusieurs pages réglementaires officielles suivies ont changé
  # (RegulatoryWatchJob, mensuel) — signal "va vérifier", pas une analyse de contenu.
  def regulatory_sources_changed(sources)
    @sources = sources

    mail(
      subject: "⚖️ #{sources.size} page#{'s' if sources.size > 1} réglementaire#{'s' if sources.size > 1} modifiée#{'s' if sources.size > 1} — à vérifier"
    )
  end
end
