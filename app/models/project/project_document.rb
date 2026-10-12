# V2 — Lot 1 : base documentaire commune du chantier (cahier des charges §4-6).
# Distinct du modèle Document V1 (app/models/documents/document.rb), laissé
# intact — voir le commentaire de
# db/migrate/20261012100100_create_project_documents_system.rb pour pourquoi.
class ProjectDocument < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :phase, optional: true
  belongs_to :uploaded_by, class_name: "User"
  belongs_to :current_version, class_name: "ProjectDocumentVersion", optional: true

  # Doit être déclaré AVANT `has_many :versions, dependent: :destroy` : les
  # callbacks before_destroy s'exécutent dans l'ordre de déclaration, et
  # current_version_id (FK vers project_document_versions) doit être mis à
  # nil avant que Rails ne tente de détruire les versions, sinon
  # PG::ForeignKeyViolation (le document référence encore la version qu'on
  # essaie de supprimer).
  before_destroy :detach_current_version

  has_many :versions, class_name: "ProjectDocumentVersion", dependent: :destroy
  has_many :comments, class_name: "ProjectDocumentComment", dependent: :destroy
  # delete_all, pas destroy : ProjectDocumentReview est append-only (voir son
  # before_destroy) — dependent: :destroy appellerait #destroy sur chaque
  # ligne et lèverait ActiveRecord::ReadOnlyRecord. delete_all fait un DELETE
  # SQL direct, sans passer par les callbacks du modèle.
  has_many :reviews, class_name: "ProjectDocumentReview", dependent: :delete_all
  has_many :shares, class_name: "ProjectDocumentShare", dependent: :destroy
  has_many :shared_users, through: :shares, source: :user

  accepts_nested_attributes_for :versions

  # Catalogue complet (cahier des charges §5.B), repris du catalogue V1
  # (Documents::Document — app/models/documents/document.rb) pour couvrir la
  # totalité des documents réellement déposés sur un chantier, moins les
  # 4 types du module locatif (bail_signe, etat_lieux_entrant/sortant,
  # assurance_locataire) — explicitement hors périmètre du MVP (cahier des
  # charges §13 : "module locatif... hors MVP").
  DOCUMENT_TYPES = %w[
    devis facture etat_avancement attestation_entrepreneur
    certificat_peb certificat_peb_avant certificat_peb_apres
    photo photo_avant photo_pendant photo_apres
    certificat_label attestation_conformite
    plan metre permis_urbanisme plan_urbanisme_signe dossier_prime plan_diu
    acte_notarial compromis
    bordereau_chassis photo_chassis
    preuve_paiement_audit rapport_audit_energetique copie_carte_identite
    rib aer
    fiche_technique notice_equipement fiche_securite_materiaux
    certificat_garantie instruction_entretien assurance_decennale assurance_rc_pro
    autre
  ].freeze

  # Libellés lisibles — .humanize seul produit des résultats peu présentables
  # pour les sigles (ex. "Peb".humanize => "Peb", "Aer".humanize => "Aer").
  DOCUMENT_TYPE_LABELS = {
    "devis" => "Devis",
    "facture" => "Facture",
    "etat_avancement" => "État d'avancement",
    "attestation_entrepreneur" => "Attestation entrepreneur",
    "certificat_peb" => "Certificat PEB",
    "certificat_peb_avant" => "Certificat PEB (avant travaux)",
    "certificat_peb_apres" => "Certificat PEB (après travaux)",
    "photo" => "Photo",
    "photo_avant" => "Photo (avant travaux)",
    "photo_pendant" => "Photo (pendant travaux)",
    "photo_apres" => "Photo (après travaux)",
    "certificat_label" => "Certificat label énergétique",
    "attestation_conformite" => "Attestation de conformité",
    "plan" => "Plan",
    "metre" => "Métré",
    "permis_urbanisme" => "Permis d'urbanisme",
    "plan_urbanisme_signe" => "Plan d'urbanisme signé",
    "dossier_prime" => "Dossier de prime",
    "plan_diu" => "Plan DIU (dossier d'intervention ultérieure)",
    "acte_notarial" => "Acte notarial",
    "compromis" => "Compromis de vente",
    "bordereau_chassis" => "Bordereau de commande châssis",
    "photo_chassis" => "Photo châssis",
    "preuve_paiement_audit" => "Preuve de paiement de l'audit",
    "rapport_audit_energetique" => "Rapport d'audit énergétique",
    "copie_carte_identite" => "Copie de carte d'identité",
    "rib" => "RIB (relevé d'identité bancaire)",
    "aer" => "AER (avertissement extrait de rôle)",
    "fiche_technique" => "Fiche technique",
    "notice_equipement" => "Notice d'équipement",
    "fiche_securite_materiaux" => "Fiche de sécurité matériaux",
    "certificat_garantie" => "Certificat de garantie",
    "instruction_entretien" => "Instruction d'entretien",
    "assurance_decennale" => "Assurance décennale",
    "assurance_rc_pro" => "Assurance RC professionnelle",
    "autre" => "Autre"
  }.freeze

  enum :visibility, { private_doc: "private", lot: "lot", all: "all", custom: "custom" }, default: "all", prefix: :visibility

  # Libellés affichés dans les formulaires — les clés d'enum ("private_doc",
  # "all"...) ne sont pas présentables telles quelles (voir retour UX).
  VISIBILITY_LABELS = {
    "private_doc" => "Privé (déposant et propriétaire uniquement)",
    "lot" => "Visible du lot uniquement",
    "all" => "Visible de tout le chantier",
    "custom" => "Partage ciblé"
  }.freeze
  enum :status, { brouillon: "brouillon", soumis: "soumis", valide: "valide", refuse: "refuse", a_corriger: "a_corriger" }, default: "brouillon"

  validates :title, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validate :lot_belongs_to_project
  validate :phase_belongs_to_project

  # V2 — Lot 2 : proposition de classification IA (cahier des charges §8 :
  # "proposition de rattachement, validation en un clic"). Stockée sur la
  # version courante par ProjectDocumentIngestionJob, jamais appliquée
  # automatiquement — voir #apply_ai_suggestion!.
  def document_type_label
    DOCUMENT_TYPE_LABELS[document_type] || document_type.humanize
  end

  def ai_suggestion
    current_version&.extracted_metadata&.slice(
      "ai_suggested_document_type", "ai_suggested_lot_key", "ai_suggested_phase_key",
      "ai_suggested_montant_ttc", "ai_confidence"
    )&.presence
  end

  # Confirmation humaine explicite — appelé uniquement depuis un clic
  # contrôleur (ProjectDocumentsController#accept_suggestion), jamais par
  # l'ingestion elle-même.
  def apply_ai_suggestion!
    suggestion = ai_suggestion
    return false if suggestion.blank?

    update!(
      document_type: suggestion["ai_suggested_document_type"].presence || document_type,
      lot: suggestion["ai_suggested_lot_key"].present? ? project.lots.find_by(key: suggestion["ai_suggested_lot_key"]) : lot,
      phase: suggestion["ai_suggested_phase_key"].present? ? project.phases.find_by(key: suggestion["ai_suggested_phase_key"]) : phase
    )
  end

  private

  def detach_current_version
    update_column(:current_version_id, nil) if current_version_id.present?
  end

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end

  def phase_belongs_to_project
    return if phase.blank?
    errors.add(:phase, "n'appartient pas à ce chantier") if phase.project_id != project_id
  end
end
