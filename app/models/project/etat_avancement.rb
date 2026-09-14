class EtatAvancement < ApplicationRecord
  self.table_name = "etats_avancement"

  belongs_to :project
  belongs_to :created_by, class_name: 'User'
  belongs_to :devis_donnee, optional: true
  has_many   :lignes, class_name: 'EtatAvancementLigne', dependent: :destroy, inverse_of: :etat_avancement

  STATUTS = %w[brouillon soumis approuve rejete].freeze
  SOURCE_TYPES = %w[devis_entrepreneur metre_architecte manuel].freeze

  validates :statut,      inclusion: { in: STATUTS }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :numero,      numericality: { greater_than: 0 }
  validates :numero,      uniqueness: { scope: :project_id }

  before_validation :set_numero, on: :create
  before_save       :recalculate_totals

  scope :chronologique, -> { order(numero: :asc) }
  scope :approuves,     -> { where(statut: 'approuve') }
  scope :en_attente,    -> { where(statut: %w[soumis]) }

  # ── Statut helpers ──────────────────────────────────────────────────────────
  def brouillon? = statut == 'brouillon'
  def soumis?    = statut == 'soumis'
  def approuve?  = statut == 'approuve'
  def rejete?    = statut == 'rejete'

  def statut_label
    { 'brouillon' => 'Brouillon', 'soumis' => 'Soumis', 'approuve' => 'Approuvé', 'rejete' => 'Rejeté' }[statut]
  end

  def statut_color
    { 'brouillon' => 'secondary', 'soumis' => 'warning', 'approuve' => 'success', 'rejete' => 'danger' }[statut]
  end

  def statut_icon
    { 'brouillon' => 'bi-pencil-square', 'soumis' => 'bi-send', 'approuve' => 'bi-patch-check-fill', 'rejete' => 'bi-x-circle-fill' }[statut]
  end

  def source_label
    { 'devis_entrepreneur' => 'Devis entrepreneur', 'metre_architecte' => 'Métré architecte', 'manuel' => 'Saisie manuelle' }[source_type]
  end

  # ── Transitions ──────────────────────────────────────────────────────────────
  def soumettre!
    update!(statut: 'soumis', soumis_at: Time.current)
  end

  def approuver!(commentaire: nil)
    transaction do
      update!(statut: 'approuve', approuve_at: Time.current,
              commentaire_architecte: commentaire)
      lignes.update_all("pct_cumule_precedent = pct_cumule_actuel")
    end
  end

  def rejeter!(commentaire: nil)
    update!(statut: 'rejete', rejete_at: Time.current,
            commentaire_architecte: commentaire)
  end

  # ── Calcul des totaux ────────────────────────────────────────────────────────
  def recalculate_totals
    total_reclame = lignes.sum do |l|
      delta_pct = (l.pct_cumule_actuel.to_i - l.pct_cumule_precedent.to_i).clamp(0, 100)
      (l.montant_marche.to_f * delta_pct / 100.0)
    end
    self.montant_reclame_periode  = total_reclame.round(2)
    self.montant_cumule_actuel    = (montant_cumule_precedent.to_f + total_reclame).round(2)
    self.montant_total_marche     = lignes.sum { |l| l.montant_marche.to_f }.round(2)
  end

  # ── Avancement global calculé ────────────────────────────────────────────────
  def avancement_global_pct
    total_marche = lignes.sum { |l| l.montant_marche.to_f }
    return 0 if total_marche.zero?
    cumul = lignes.sum { |l| l.montant_marche.to_f * l.pct_cumule_actuel.to_i / 100.0 }
    (cumul / total_marche * 100).round
  end

  # ── Lignes groupées par thématique ───────────────────────────────────────────
  def lignes_par_thematique
    lignes.order(:position).group_by(&:thematique_code)
  end

  private

  def set_numero
    dernier = project.etats_avancement.maximum(:numero) || 0
    self.numero = dernier + 1
    # Copier le cumul approuvé précédent
    dernier_approuve = project.etats_avancement.approuves.order(numero: :desc).first
    self.montant_cumule_precedent = dernier_approuve&.montant_cumule_actuel || 0
    # Reporter les % cumulés précédents sur les nouvelles lignes (fait dans le service)
  end
end
