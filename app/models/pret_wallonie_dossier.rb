# Suivi du dossier de prêt bonifié wallon (Rénopack/Rénoprêt, dès le 01/10/2026).
# Contrairement aux primes cash historiques (voir Request/RequestProgress, adaptées à
# un formulaire traité par une administration régionale via courrier), ce régime est
# une demande de prêt auprès de la SWCS : pas de tracking email/OCR administratif,
# pas de délai de réponse de 24 mois — un cycle de vie propre (préparation → dépôt →
# instruction → accord → travaux → clôture), auto-déclaré par l'utilisateur.
#
# Les pièces justificatives (audit énergétique, devis, attestation de conformité,
# factures finales, PEB après travaux) restent gérées par le modèle Document existant
# (voir DocumentPhase) — pas dupliquées ici.
class PretWallonieDossier < ApplicationRecord
  belongs_to :project
  belongs_to :simulation, optional: true
  belongs_to :user

  validates :project_id, uniqueness: true

  STATUTS = %w[
    preparation
    dossier_depose
    en_instruction
    accepte
    refuse
    travaux_en_cours
    cloture
    abandonne
  ].freeze

  enum :statut, STATUTS.index_by(&:itself), default: "preparation", validate: true

  # G/F visent un label minimum D après travaux ; E vise un label minimum C.
  # Source : wallonie.be, décision gouvernementale du 16/07/2026.
  LABELS_CIBLES = { "G" => "D", "F" => "D", "E" => "C" }.freeze
  ORDRE_LABELS = %w[G F E D C B A A+].freeze

  DUREE_MAX_TRAVAUX = 2.years

  before_save :calculer_label_cible
  before_save :calculer_date_limite_travaux

  # Statuts à partir desquels le dossier est considéré "en cours" (ni clôturé ni abandonné/refusé)
  ACTIFS = %w[preparation dossier_depose en_instruction accepte travaux_en_cours].freeze

  scope :actifs, -> { where(statut: ACTIFS) }

  def actif?
    statut.in?(ACTIFS)
  end

  def finalise?
    statut.in?(%w[cloture refuse abandonne])
  end

  # Échéance travaux dans les 60 prochains jours (ou déjà dépassée), tant que le
  # dossier n'est pas encore clôturé.
  def echeance_travaux_proche?
    return false unless date_limite_travaux.present?
    return false if statut.in?(%w[cloture refuse abandonne])

    date_limite_travaux <= 60.days.from_now.to_date
  end

  def echeance_travaux_depassee?
    date_limite_travaux.present? && date_limite_travaux < Date.current && !statut.in?(%w[cloture refuse abandonne])
  end

  def jours_restants_travaux
    return nil unless date_limite_travaux
    (date_limite_travaux - Date.current).to_i
  end

  # nil si pas encore clôturé/renseigné, sinon true/false selon que le label après
  # travaux atteint (ou dépasse) le label cible.
  def objectif_peb_atteint?
    return nil if label_peb_cible.blank? || label_peb_apres_travaux.blank?

    idx_cible = ORDRE_LABELS.index(label_peb_cible.upcase)
    idx_apres = ORDRE_LABELS.index(label_peb_apres_travaux.upcase)
    return nil if idx_cible.nil? || idx_apres.nil?

    idx_apres >= idx_cible
  end

  def avancer_statut!(nouveau_statut, attrs = {})
    update!(attrs.merge(statut: nouveau_statut))
  end

  # Construit un dossier à partir d'une simulation "reduction_pret" existante et
  # éligible — snapshot des montants/taux/labels au moment du dépôt, pour garder une
  # trace même si la simulation est recalculée ensuite.
  def self.build_from_simulation(simulation, user:)
    property = simulation.property

    new(
      project: simulation.project,
      simulation: simulation,
      user: user,
      label_peb_depart: property&.peb_donnees&.avant_travaux&.order(created_at: :desc)&.first&.label_peb,
      montant_emprunte: simulation.montant_projet_retenu_saisi,
      plafond_emprunt: simulation.plafond_emprunt_saisi,
      taux_reduction: simulation.taux_reduction_saisi,
      taux_interet: simulation.taux_interet_saisi,
      ecomateriaux: simulation.ecomateriaux_saisi
    )
  end

  private

  def calculer_label_cible
    return unless label_peb_depart.present?

    self.label_peb_cible = LABELS_CIBLES[label_peb_depart.to_s.upcase] || label_peb_cible
  end

  def calculer_date_limite_travaux
    self.date_limite_travaux = date_signature + DUREE_MAX_TRAVAUX if date_signature.present? && date_signature_changed?
  end
end
