class PvVisite < ApplicationRecord
  belongs_to :project
  belongs_to :auteur, class_name: "User"

  STATUTS = %w[draft envoye].freeze
  METEOS  = %w[Ensoleillé Nuageux Pluvieux Neige Vent].freeze

  # Points : {description, localisation, nature, priorite, responsable, delai, statut}
  # Lots   : {numero, intitule, entreprise, avancement_pct, travaux_realises, travaux_en_cours, conforme_plans, points_bloquants}
  # Décisions : {description, responsable, delai}

  validates :statut,      inclusion: { in: STATUTS }
  validates :date_visite, presence: true
  validates :numero,      uniqueness: { scope: :project_id }
  validate  :date_visite_coherente

  before_create :set_numero
  before_create :generate_tokens

  scope :chronologique, -> { order(date_visite: :desc, numero: :desc) }

  # ── Statut ──────────────────────────────────────────────────────────────────
  def draft?  = statut == "draft"
  def envoye? = statut == "envoye"

  def statut_label = statut == "draft" ? "Brouillon" : "Envoyé"
  def statut_color = statut == "draft" ? "secondary" : "success"

  # ── Titre ───────────────────────────────────────────────────────────────────
  def titre
    label = "Visite n°#{numero} — #{date_visite.strftime('%d/%m/%Y')}"
    label += " #{heure_visite}" if heure_visite.present?
    label
  end

  # ── JSONB helpers ────────────────────────────────────────────────────────────
  def points_liste
    Array(points).map(&:with_indifferent_access)
  end

  def lots_liste
    Array(lots).map(&:with_indifferent_access)
  end

  def decisions_liste
    Array(decisions).map(&:with_indifferent_access)
  end

  def nb_points_ouverts
    points_liste.count { |p| p[:statut] != "résolu" }
  end

  # ── Tokens de partage (lecture seule) ───────────────────────────────────────
  def self.find_by_token(token)
    return nil if token.blank?
    where(token_owner: token).or(where(token_entrepreneur: token)).first
  end

  def role_pour_token(token)
    return :owner        if token_owner == token
    return :entrepreneur if token_entrepreneur == token
    nil
  end

  private

  def set_numero
    dernier = project.pv_visites.maximum(:numero) || 0
    self.numero = dernier + 1
  end

  def generate_tokens
    self.token_owner        = SecureRandom.urlsafe_base64(32) if project.user.email.present?
    entr = project.project_members.active.find_by(role: "entrepreneur")
    self.token_entrepreneur = SecureRandom.urlsafe_base64(32) if entr&.user&.email.present?
  end

  def date_visite_coherente
    return unless date_visite.present? && project&.date_début.present?
    if date_visite < project.date_début
      errors.add(:date_visite, "ne peut pas être antérieure au début du chantier")
    end
  end
end
