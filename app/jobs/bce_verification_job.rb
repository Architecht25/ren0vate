class BceVerificationJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return unless project
    return unless project.entrepreneur_principal_numero_tva.present?

    result = BceVerificationService.new(project.entrepreneur_principal_numero_tva).verifier

    project.update_columns(
      entrepreneur_bce_statut:    result[:statut],
      entrepreneur_bce_verifie_at: Time.current
    )

    Rails.logger.info "BCE verification for project #{project_id}: #{result[:statut]} (#{project.entrepreneur_principal_numero_tva})"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "BceVerificationJob: project #{project_id} not found"
  end
end
