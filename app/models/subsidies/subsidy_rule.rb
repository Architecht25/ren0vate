# V2 — Lot 3 : règle de prime versionnée et datée (cahier des charges §9).
# Remplace les services Regions::* V1 (règles codées en dur) : une réforme
# = une nouvelle ligne (nouveau valid_from, ancienne version close par
# valid_to), jamais une modification de code applicatif.
#
# `conditions` : liste de { "field", "operator", "value" } évaluées en ET
# par Subsidies::RuleEngine. `amount_formula` : { "type" => "flat" |
# "percentage" | "per_unit", ... } — voir Subsidies::RuleEngine pour le
# détail. Les deux sont volontairement une petite DSL JSON, pas du code
# Ruby exécuté dynamiquement (aucun eval), pour rester éditable sans risque
# depuis une future interface d'administration.
class SubsidyRule < ApplicationRecord
  has_many :subsidy_document_requirements, dependent: :destroy
  has_many :subsidy_case_results, dependent: :restrict_with_error

  REGIONS = %w[wallonie flandre bruxelles].freeze
  FAR_FUTURE = Date.new(9999, 12, 31)

  validates :region, inclusion: { in: REGIONS }
  validates :key, presence: true
  validates :label, presence: true
  validates :valid_from, presence: true
  validate :no_overlap_with_other_versions

  scope :active_for_region, ->(region, date: Date.current) {
    where(region: region)
      .where("valid_from <= ?", date)
      .where("valid_to IS NULL OR valid_to > ?", date)
  }

  scope :active, ->(region:, key:, date: Date.current) {
    active_for_region(region, date: date).where(key: key)
  }

  def active_on?(date)
    valid_from <= date && (valid_to.nil? || valid_to > date)
  end

  private

  def no_overlap_with_other_versions
    return if valid_from.blank? || key.blank? || region.blank?

    my_to = valid_to || FAR_FUTURE
    overlap = SubsidyRule.where(region: region, key: key).where.not(id: id).any? do |other|
      other_to = other.valid_to || FAR_FUTURE
      valid_from < other_to && other.valid_from < my_to
    end

    errors.add(:base, "chevauche une autre version active de #{region}/#{key}") if overlap
  end
end
