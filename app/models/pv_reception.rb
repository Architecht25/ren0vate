class PvReception < ApplicationRecord
  belongs_to :project

  STATUTS = %w[draft envoye finalise].freeze

  validates :statut, inclusion: { in: STATUTS }
  validate  :date_reception_coherente

  before_create :generate_tokens

  # ── Scopes ──────────────────────────────────────────────────────────────────
  scope :finalises, -> { where(statut: "finalise") }

  # ── Helpers statut ──────────────────────────────────────────────────────────
  def draft?       = statut == "draft"
  def envoye?      = statut == "envoye"
  def finalise?    = statut == "finalise"

  def statut_label
    case statut
    when "draft"    then "Brouillon"
    when "envoye"   then "En attente de signatures"
    when "finalise" then "Finalisé"
    end
  end

  def statut_color
    case statut
    when "draft"    then "secondary"
    when "envoye"   then "warning"
    when "finalise" then "success"
    end
  end

  def statut_icon
    case statut
    when "draft"    then "bi-pencil-square"
    when "envoye"   then "bi-send"
    when "finalise" then "bi-patch-check-fill"
    end
  end

  # ── Signatures ──────────────────────────────────────────────────────────────
  def signed_owner?        = signed_owner_at.present?
  def signed_architect?    = signed_architect_at.present?
  def signed_entrepreneur? = signed_entrepreneur_at.present?

  # Rôles attendus (ceux qui ont un email configuré)
  def roles_attendus
    roles = [:owner]
    roles << :architect    if email_architect.present?
    roles << :entrepreneur if email_entrepreneur.present?
    roles
  end

  def toutes_signatures_recues?
    roles_attendus.all? do |role|
      case role
      when :owner        then signed_owner?
      when :architect    then signed_architect?
      when :entrepreneur then signed_entrepreneur?
      end
    end
  end

  def nb_signatures
    [signed_owner?, signed_architect?, signed_entrepreneur?].count(true)
  end

  def nb_signatures_attendues
    roles_attendus.size
  end

  # ── Finalisation auto après dernière signature ───────────────────────────────
  def check_and_finalise!
    if toutes_signatures_recues? && !finalise?
      update!(statut: "finalise")
    end
  end

  # ── Signer via token ─────────────────────────────────────────────────────────
  def signer!(role, commentaire: nil)
    now = Time.current
    case role
    when :owner
      update!(signed_owner_at: now, commentaire_owner: commentaire)
    when :architect
      update!(signed_architect_at: now, commentaire_architect: commentaire)
    when :entrepreneur
      update!(signed_entrepreneur_at: now, commentaire_entrepreneur: commentaire)
    end
    check_and_finalise!
  end

  # ── Trouver le rôle d'un token ───────────────────────────────────────────────
  def self.find_by_token(token)
    return nil if token.blank?
    where(token_owner: token).or(
      where(token_architect: token)
    ).or(
      where(token_entrepreneur: token)
    ).first
  end

  def role_pour_token(token)
    return :owner        if token_owner == token
    return :architect    if token_architect == token
    return :entrepreneur if token_entrepreneur == token
    nil
  end

  def deja_signe_avec_token?(token)
    role = role_pour_token(token)
    return false unless role
    case role
    when :owner        then signed_owner?
    when :architect    then signed_architect?
    when :entrepreneur then signed_entrepreneur?
    end
  end

  def nom_pour_role(role)
    case role
    when :owner        then nom_owner
    when :architect    then nom_architect
    when :entrepreneur then nom_entrepreneur
    end
  end

  # ── Snapshot réserves ────────────────────────────────────────────────────────
  def reserves_liste
    return [] if reserves_snapshot.blank?
    JSON.parse(reserves_snapshot) rescue []
  end

  private

  def generate_tokens
    self.token_owner        = SecureRandom.urlsafe_base64(32)
    self.token_architect    = SecureRandom.urlsafe_base64(32) if email_architect.present?
    self.token_entrepreneur = SecureRandom.urlsafe_base64(32) if email_entrepreneur.present?
  end

  def date_reception_coherente
    return unless date_reception.present? && project&.date_début.present?
    if date_reception < project.date_début
      errors.add(:date_reception, "ne peut pas être antérieure au début du chantier")
    end
  end
end
