class BordereauChassisDonnee < ApplicationRecord
  belongs_to :document
  belongs_to :project, optional: true

  # ── Validations ───────────────────────────────────────────────────────────────
  validates :confiance_ocr,   numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :valeur_uw,       numericality: { greater_than: 0, less_than: 5 }, allow_nil: true
  validates :valeur_ug,       numericality: { greater_than: 0, less_than: 5 }, allow_nil: true
  validates :valeur_uf,       numericality: { greater_than: 0, less_than: 5 }, allow_nil: true
  validates :facteur_solaire, numericality: { greater_than: 0, less_than: 1 }, allow_nil: true
  validates :nombre_unites,   numericality: { greater_than: 0 }, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────────
  scope :extraction_fiable,    -> { where(arel_table[:confiance_ocr].gteq(70)) }
  scope :extraction_complete,  -> { where(extraction_complete: true) }
  scope :pour_project,         ->(project_id) { where(project_id: project_id) }
  scope :avec_uw,              -> { where.not(valeur_uw: nil) }
  scope :eligibles_wallonie,   -> { where(eligible_prime_wallonie: true) }
  scope :eligibles_bruxelles,  -> { where(eligible_prime_bruxelles: true) }

  # Seuils par région (W/m²K)
  SEUILS_UW = {
    'wallonie'   => 1.0,
    'bruxelles'  => 1.1,
    'flandre'    => 1.0
  }.freeze
  SEUIL_UG_WALLONIE = 0.7

  # ── Callbacks ─────────────────────────────────────────────────────────────────
  before_save :calculer_eligibilite_primes

  # ── Méthodes d'affichage ──────────────────────────────────────────────────────
  def uw_formate
    return nil unless valeur_uw.present?
    "#{valeur_uw} W/m²K"
  end

  def ug_formate
    return nil unless valeur_ug.present?
    "#{valeur_ug} W/m²K"
  end

  def surface_formatee
    return nil unless surface_totale.present?
    "#{surface_totale.to_f.round(2)} m²"
  end

  def montant_htva_formate
    return nil unless montant_htva.present?
    ActiveSupport::NumberHelper.number_to_currency(montant_htva, unit: '€', separator: ',', delimiter: '.', format: '%n %u')
  end

  def montant_tvac_formate
    return nil unless montant_tvac.present?
    ActiveSupport::NumberHelper.number_to_currency(montant_tvac, unit: '€', separator: ',', delimiter: '.', format: '%n %u')
  end

  def nb_postes
    detail_chassis.present? ? detail_chassis.length : 0
  end

  # Surface calculée en m² depuis le détail (somme cotes × quantité)
  def surface_detail_calculee
    return nil unless detail_chassis.present?
    surfaces = detail_chassis.filter_map do |d|
      next unless d['surface_m2'].to_f > 0
      d['surface_m2'].to_f * (d['quantite'] || 1)
    end
    return nil unless surfaces.any?
    surfaces.sum.round(2)
  end

  def date_document_display
    date_document&.strftime('%d/%m/%Y') || '—'
  end

  def extraction_fiable?
    confiance_ocr.to_f >= 70
  end

  def type_vitrage_libelle
    case type_vitrage
    when 'triple'     then 'Triple vitrage'
    when 'double'     then 'Double vitrage'
    when 'hr_plus'    then 'HR+'
    when 'hr_plus_plus' then 'HR++'
    when 'monolithique' then 'Vitrage simple'
    else type_vitrage&.humanize || '—'
    end
  end

  def type_chassis_libelle
    case type_chassis
    when 'pvc'       then 'PVC'
    when 'aluminium' then 'Aluminium'
    when 'bois'      then 'Bois'
    when 'mixte'     then 'Bois-Aluminium'
    else type_chassis&.humanize || '—'
    end
  end

  # Badge couleur selon Uw vs seuil Wallonie
  def uw_badge_class
    return 'bg-secondary' unless valeur_uw.present?
    valeur_uw.to_f <= SEUILS_UW['wallonie'] ? 'bg-success' : 'bg-danger'
  end

  # Message éligibilité prime châssis pour la région du projet
  def message_eligibilite(region = 'wallonie')
    seuil = SEUILS_UW[region] || 1.0
    return "⚠️ Uw non extrait — éligibilité non vérifiable" unless valeur_uw.present?

    if valeur_uw.to_f <= seuil
      "✅ Éligible prime châssis #{region.capitalize} (Uw #{valeur_uw} ≤ #{seuil} W/m²K)"
    else
      "❌ Non éligible prime châssis #{region.capitalize} (Uw #{valeur_uw} > #{seuil} W/m²K)"
    end
  end

  private

  def calculer_eligibilite_primes
    return unless valeur_uw.present?

    uw = valeur_uw.to_f
    ug = valeur_ug.to_f if valeur_ug.present?

    self.eligible_prime_wallonie  = uw <= SEUILS_UW['wallonie']  && (ug.nil? || ug <= SEUIL_UG_WALLONIE)
    self.eligible_prime_bruxelles = uw <= SEUILS_UW['bruxelles']
    self.eligible_prime_flandre   = uw <= SEUILS_UW['flandre']
  end
end
