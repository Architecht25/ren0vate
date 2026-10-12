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

  # Vue unifiée d'un document, quelle que soit sa base d'origine — voir
  # #vault_documents.
  VaultDocument = Struct.new(:ref, :title, :path, :attachment, keyword_init: true)

  def show
    @documents = vault_documents
    @warranties = policy_scope(Warranty).where(project: @project).order(:end_date)
    @pv_reception = @project.pv_reception
  end

  def export
    buffer = Zip::OutputStream.write_buffer do |zip|
      vault_documents.each do |document|
        next unless document.attachment&.attached?

        zip.put_next_entry(safe_entry_name(document))
        zip.write(document.attachment.download)
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

  # Le coffre-fort doit agréger "tous les documents utiles à exporter", pas
  # seulement ceux déposés via la base documentaire V2 (ProjectDocument) — la
  # base V1 (Document) n'a jamais été migrée ni synchronisée vers V2 (voir
  # mémoire project_v2_reception_differentiation_audit). Unification côté
  # lecture uniquement : pas de migration de données, les deux tables restent
  # indépendantes, ce endpoint se contente de fusionner les deux résultats.
  #
  # Les documents V1 ne sont inclus que pour le propriétaire du chantier : la
  # base V1 n'a aucune notion de membre/pro (contrairement à ProjectDocument,
  # filtré par policy_scope selon visibility/rôle) — DocumentsController#can_access_document?
  # n'autorise que le propriétaire (document.project.user_id). Les inclure pour
  # tout le monde exposerait aux entrepreneurs/architectes des documents du
  # propriétaire auxquels ils n'ont normalement pas accès.
  def vault_documents
    v2_docs = policy_scope(ProjectDocument)
      .where(project: @project, document_type: VAULT_DOCUMENT_TYPES)
      .includes(:lot, current_version: {})
      .map do |d|
        VaultDocument.new(ref: "v2-#{d.id}", title: d.title, path: project_document_path(d), attachment: d.current_version&.file)
      end

    v1_docs =
      if current_user.id == @project.user_id
        Document.where(project: @project, type_document: VAULT_DOCUMENT_TYPES)
          .with_attached_file
          .map do |d|
            # Document#file_name renvoie toujours nil tant que file_url est
            # vide, même si file est bien attaché (bug de précédence sur le
            # "if" final dans app/models/documents/document.rb — pas corrigé
            # ici, hors périmètre, on passe directement par l'attachment).
            title = d.file.attached? ? d.file.filename.to_s : nil
            VaultDocument.new(ref: "v1-#{d.id}", title: title.presence || d.type_document.humanize, path: document_path(d), attachment: d.file)
          end
      else
        []
      end

    v2_docs + v1_docs
  end

  def safe_entry_name(document)
    base = document.title.presence || "document"
    extension = document.attachment.filename.present? ? File.extname(document.attachment.filename.to_s) : ""
    "#{document.ref}-#{base.parameterize}#{extension}"
  end
end
