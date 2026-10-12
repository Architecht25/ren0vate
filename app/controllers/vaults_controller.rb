# V2 — Lot 6 : coffre-fort final (cahier des charges §4-5.E : "plans
# as-built, notices, garanties, dossier d'intervention ultérieure...
# exportable et transmissible à un acheteur ou locataire").
class VaultsController < ApplicationController
  # Types de documents considérés comme "pièces à transmettre" à la fin du
  # chantier (cahier des charges §4-5.E : "plans as-built, notices,
  # garanties, dossier d'intervention ultérieure") — mis à jour le
  # 12/10/2026 avec le catalogue complet de ProjectDocument::DOCUMENT_TYPES.
  # Le PV de réception n'est pas dans cette liste : il a son propre modèle
  # (PvReception, affiché séparément ci-dessous), pas de type ProjectDocument
  # dédié.
  VAULT_DOCUMENT_TYPES = %w[
    plan plan_urbanisme_signe plan_diu
    certificat_garantie notice_equipement instruction_entretien
    fiche_technique fiche_securite_materiaux
    attestation_conformite permis_urbanisme
    certificat_peb certificat_peb_avant certificat_peb_apres
    assurance_decennale assurance_rc_pro
  ].freeze

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
