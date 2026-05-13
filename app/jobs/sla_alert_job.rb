class SlaAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Tickets ouverts dont le SLA (24h) va expirer dans les 2 prochaines heures
    # et qui n'ont pas encore reçu de réponse
    approaching = SupportTicket.waiting_response
                               .where('created_at BETWEEN ? AND ?',
                                      22.hours.ago, 22.hours.ago + 2.hours)

    approaching.each do |ticket|
      SupportMailer.sla_approaching(ticket).deliver_later
      Rails.logger.info "[SlaAlertJob] Alerte SLA envoyée pour ticket ##{ticket.id}"
    end

    Rails.logger.info "[SlaAlertJob] #{approaching.count} alerte(s) SLA envoyée(s)"
  end
end
