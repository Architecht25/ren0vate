class ProjectQuoteLine < ApplicationRecord
  belongs_to :project_quote, inverse_of: :lines

  validates :description, presence: true
  validates :quantite, numericality: { greater_than: 0 }
  validates :prix_unitaire_ht, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_montant_ht

  private

  def compute_montant_ht
    return if quantite.blank? || prix_unitaire_ht.blank?
    self.montant_ht = (quantite * prix_unitaire_ht).round(2)
  end
end
