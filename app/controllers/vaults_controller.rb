# V2 — Lot 6 : coffre-fort final (cahier des charges §4-5.E : "plans
# as-built, notices, garanties, dossier d'intervention ultérieure...
# exportable et transmissible à un acheteur ou locataire").
class VaultsController < ApplicationController
  # Types de documents considérés comme "pièces à transmettre" à la fin du
  # chantier — liste volontairement restreinte au catalogue existant de
  # ProjectDocument::DOCUMENT_TYPES (§5.B complet pas encore porté, voir
  # docs/AUDIT_V1.md) ; "notice"/"DIU" n'ont pas de type dédié aujourd'hui,
  # classés en "autre" en attendant un catalogue plus riche.
  VAULT_DOCUMENT_TYPES = %w[plan garantie attestation pv permis].freeze

  before_action :set_project

  def show
    @documents = policy_scope(ProjectDocument).where(project: @project, document_type: VAULT_DOCUMENT_TYPES).includes(:lot, current_version: {})
    @warranties = policy_scope(Warranty).where(project: @project).order(:end_date)
    @pv_reception = @project.pv_reception
  end

  def export
    documents = policy_scope(ProjectDocument).where(project: @project, document_type: VAULT_DOCUMENT_TYPES)

    buffer = Zip::OutputStream.write_buffer do |zip|
      documents.each do |document|
        version = document.current_version
        next unless version&.file&.attached?

        zip.put_next_entry(safe_entry_name(document, version))
        zip.write(version.file.download)
      end
    end

    AuditEvent.record!(action: "vault.exported", auditable: @project, actor: current_user, ip_address: request.remote_ip)

    send_data buffer.string, filename: "coffre-fort-#{@project.nom.parameterize}.zip", type: "application/zip"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end

  def safe_entry_name(document, version)
    base = document.title.presence || version.file_name || "document-#{document.id}"
    extension = File.extname(version.file_name.to_s)
    "#{document.id}-#{base.parameterize}#{extension}"
  end
end
