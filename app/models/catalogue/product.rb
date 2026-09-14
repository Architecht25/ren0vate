class Product < ApplicationRecord
  # ── Catégories disponibles ────────────────────────────────────────────────
  CATEGORIES = {
    'insulation' => 'Isolants',
    'windows'    => 'Châssis & Vitrages',
    'heating'    => 'Chauffage',
    'solar'      => 'Panneaux solaires',
    'hot_water'  => 'Chauffe-eau'
  }.freeze

  SUBCATEGORIES = {
    'toiture'  => 'Toiture',
    'murs'     => 'Murs',
    'plancher' => 'Plancher / Sous-sol',
    'pvc'      => 'PVC',
    'alu'      => 'Aluminium',
    'bois'     => 'Bois'
  }.freeze

  PRICE_UNITS = %w[m2 unit kWc].freeze

  # Uw de référence par matériau châssis (W/m²K) — source Bobex mai 2026
  # Plus la valeur est basse, meilleure est l'isolation.
  # Seuil prime régionale : Uw ≤ 1,0 — vitrage seul Ug ≤ 1,1
  UW_BY_MATERIAL = {
    'pvc'  => 0.98,
    'alu'  => 0.85,
    'bois' => 0.77
  }.freeze

  # ── Validations ───────────────────────────────────────────────────────────
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
  validates :name,     presence: true
  validates :price_per_unit, numericality: { greater_than: 0 }, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active,            -> { where(active: true) }
  scope :by_category,       ->(cat) { where(category: cat) }
  scope :by_subcategory,    ->(sub) { where(subcategory: sub) }
  scope :ordered,           -> { order(display_order: :asc, name: :asc) }
  scope :wallonie_eligible, -> { where(wallonie_grant_eligible: true) }
  scope :flanders_eligible, -> { where(flanders_grant_eligible: true) }
  scope :brussels_eligible, -> { where(brussels_grant_eligible: true) }
  scope :vat_reduced,       -> { where(vat_6_eligible: true) }

  # ── Helpers ───────────────────────────────────────────────────────────────

  # Libellé catégorie
  def category_label
    CATEGORIES[category] || category
  end

  # Libellé sous-catégorie
  def subcategory_label
    SUBCATEGORIES[subcategory] || subcategory
  end

  # Prime éligible selon région
  def grant_eligible_for?(region)
    case region&.downcase
    when 'wallonie'  then wallonie_grant_eligible?
    when 'flandre'   then flanders_grant_eligible?
    when 'bruxelles' then brussels_grant_eligible?
    else false
    end
  end

  # Uw effectif : valeur produit si renseignée, sinon référence matériau
  def uw_value
    technical_specs['uw_value']&.to_f || UW_BY_MATERIAL[subcategory]
  end

  # Vitrage éligible prime régionale (Ug ≤ 1,1 W/m²K)
  def prime_glazing_eligible?
    ug = technical_specs['ug_value']&.to_f
    ug.present? ? ug <= 1.1 : false
  end

  # R-value selon épaisseur (cm) — isolants uniquement
  def r_value_at(thickness_cm)
    return nil unless technical_specs['r_value_per_cm'].present?
    (technical_specs['r_value_per_cm'].to_f * thickness_cm).round(2)
  end

  # Prix total pour une surface donnée
  def price_for_surface(surface_m2)
    return nil unless price_per_unit.present? && price_unit == 'm2'
    (price_per_unit * surface_m2).round(0)
  end

  # Économie annuelle estimée en € (isolants — formule simplifiée)
  # base_energy_cost : coût énergie annuel actuel en €
  # improvement_factor : gain relatif (0..1)
  def annual_saving_euros(surface_m2:, current_r_value: 0, energy_cost_per_kwh: 0.25)
    return nil unless thermal_performance.present?
    new_r   = thermal_performance
    old_r   = current_r_value.to_f
    return 0 if new_r <= old_r

    # Q = ΔU × Surface × DDJ (°h·m²/W → kWh)
    # DDJ Belgique ≈ 80_000 °h/an
    delta_u    = (1.0 / (old_r + 0.13 + 0.04)) - (1.0 / (new_r + 0.13 + 0.04))
    kwh_saved  = delta_u * surface_m2 * 80_000 / 1_000.0
    (kwh_saved * energy_cost_per_kwh).round(0)
  end

  # ROI en années
  def roi_years(surface_m2:, current_r_value: 0, grant_amount: 0)
    saving = annual_saving_euros(surface_m2: surface_m2, current_r_value: current_r_value)
    return nil unless saving&.positive? && price_per_unit.present?

    net_cost = price_for_surface(surface_m2).to_f - grant_amount.to_f
    return nil if net_cost <= 0

    (net_cost / saving).ceil
  end

  # Score global pondéré /10 selon priorités utilisateur
  def weighted_score(priorities: %w[performance ecology price])
    scores = {
      'performance' => performance_score,
      'ecology'     => ecology_score,
      'price'       => price_score,
      'durability'  => durability_score
    }
    weights = build_weights(priorities)
    total = weights.sum { |key, w| (scores[key] || 5) * w }
    total.round(1)
  end

  private

  def performance_score
    return 5.0 unless thermal_performance.present?
    case category
    when 'insulation'
      # R ≥ 6 = 10/10, R ≤ 2 = 3/10
      [(thermal_performance / 6.0 * 10).clamp(3, 10), 10].min
    when 'heating'
      # COP : 1 = gaz condensation, 3-4 = PAC
      cop = technical_specs['cop']&.to_f || thermal_performance
      [(cop / 4.5 * 10).clamp(2, 10), 10].min
    when 'windows'
      # Uw : plus bas = meilleur. Seuil prime ≤ 1,0. Bois 0,77 = 10/10
      uw = uw_value
      return 5.0 unless uw
      [(((1.0 - uw) / (1.0 - 0.7)) * 7 + 3).clamp(3, 10), 10].min
    else
      5.0
    end
  end

  def ecology_score
    score = 5.0
    score += 2.0 if biosourced?
    score += 1.0 if recyclable?
    score -= 2.0 if grey_energy_kwh.to_i > 500
    score += 1.0 if grey_energy_kwh.present? && grey_energy_kwh < 100
    score.clamp(1, 10)
  end

  def price_score
    return 5.0 unless price_per_unit.present?
    # Score inversé : moins cher = meilleur score prix
    # Benchmark : isolants 40-80€/m², châssis 400-1200€/unit
    case category
    when 'insulation'
      base = price_per_unit.to_f
      [(10 - (base - 40) / 40.0 * 4).clamp(3, 10), 10].min
    when 'windows'
      base = price_per_unit.to_f
      [(10 - (base - 400) / 800.0 * 4).clamp(3, 10), 10].min
    else
      5.0
    end
  end

  def durability_score
    return 5.0 unless lifespan_years.present?
    [(lifespan_years / 50.0 * 10).clamp(3, 10), 10].min
  end

  def build_weights(priorities)
    all_keys = %w[performance ecology price durability]
    base = all_keys.index_with { 0.1 }
    priorities.each_with_index do |key, i|
      next unless base.key?(key)
      base[key] = case i
                  when 0 then 0.5
                  when 1 then 0.3
                  when 2 then 0.15
                  else 0.05
                  end
    end
    # Normaliser
    total = base.values.sum
    base.transform_values { |v| v / total }
  end
end
