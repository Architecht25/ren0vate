class Request < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  has_many :request_progresses
  has_many :documents

  # Support pour les fichiers Flandre
  has_many_attached :document_devis
  has_many_attached :document_factures
  has_one_attached :document_aer
  has_one_attached :document_peb
  has_many_attached :document_attestations
  has_many_attached :document_photos
  has_many_attached :document_autres

  validates :status, presence: true
  validates :title, presence: true
  validates :description, presence: true
  validates :region, presence: true

  # Validations spécifiques pour Flandre
  validates :domicile, inclusion: { in: [true, false] }, if: :flandre?
  validates :type_demandeur, presence: true, if: :flandre?
  validates :registre_national, presence: true, if: :flandre?
  validates :nom, presence: true, if: :flandre?
  validates :prenom, presence: true, if: :flandre?
  validates :telephone, presence: true, if: :flandre?
  validates :email, presence: true, if: :flandre?
  validates :adresse, presence: true, if: :flandre?
  validates :code_postal, presence: true, if: :flandre?
  validates :commune, presence: true, if: :flandre?
  validates :type_bien, presence: true, if: :flandre?
  validates :usage, presence: true, if: :flandre?
  validates :chauffage_post_renovation, presence: true, if: :flandre?
  validates :revenus_annuels, presence: true, numericality: { greater_than: 0 }, if: :flandre?
  validates :personnes_charge, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :flandre?
  validates :annee_aer, presence: true, if: :flandre?
  validates :email_contact, presence: true, if: :flandre?
  validates :confirmation_veracite, acceptance: true, if: :flandre?
  validates :acceptation_conditions, acceptance: true, if: :flandre?

  # Documents obligatoires pour Flandre
  validates :document_devis, attached: true, if: :flandre?
  validates :document_factures, attached: true, if: :flandre?
  validates :document_aer, attached: true, if: :flandre?

  # Scope pour récupérer les demandes récentes
  scope :recent, -> { order(created_at: :desc) }

  private

  def flandre?
    region == 'flandre'
  end
end
