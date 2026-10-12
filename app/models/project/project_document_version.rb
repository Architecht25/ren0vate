# V2 — Lot 1 : une version = un fichier, jamais écrasé (cahier des charges
# §4 : "Jamais d'écrasement : toute modification crée une version."). Le
# numéro de version et le hash SHA-256 sont calculés automatiquement ; il
# n'existe volontairement aucune action de contrôleur pour remplacer le
# fichier d'une version existante — seule la création d'une nouvelle version
# est permise.
class ProjectDocumentVersion < ApplicationRecord
  belongs_to :project_document
  belongs_to :created_by, class_name: "User"
  has_many :comments, class_name: "ProjectDocumentComment", dependent: :nullify
  has_many :reviews, class_name: "ProjectDocumentReview", dependent: :nullify

  has_one_attached :file

  validates :file, presence: true

  before_validation :assign_version_number, on: :create

  after_commit :finalize_file_metadata!, on: :create
  after_commit :promote_to_current_version!, on: :create

  def finalize_file_metadata!
    return unless file.attached?

    update_columns(
      sha256: Digest::SHA256.hexdigest(file.download),
      file_name: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size
    )
  end

  def promote_to_current_version!
    project_document.update_column(:current_version_id, id)
  end

  private

  def assign_version_number
    return if version_number.present?
    last_number = project_document&.versions&.maximum(:version_number) || 0
    self.version_number = last_number + 1
  end
end
