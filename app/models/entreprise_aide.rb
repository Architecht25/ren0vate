class EntrepriseAide < ApplicationRecord
  validates :slug, :titre, :region, presence: true
  validates :slug, uniqueness: true

  scope :actives, -> { where(statut: 'active') }
  scope :par_region, ->(region) { where(region: region) }
  scope :par_categorie, ->(categorie) { where(categorie: categorie) }
  scope :pour_taille, ->(taille) { where("tailles_eligibles::jsonb @> ?", [taille].to_json) }

  # Méthodes d'instance
  def montant_aide_estime(montant_projet)
    return 0 if montant_projet.blank? || taux_aide.blank?

    aide_calculee = (montant_projet * taux_aide / 100).round(2)

    # Application des plafonds
    aide_calculee = [aide_calculee, montant_max].min if montant_max.present?
    aide_calculee = [aide_calculee, montant_min].max if montant_min.present?

    aide_calculee
  end

  def compatible_avec_secteur?(code_nace)
    # Logique de compatibilité avec secteurs NACE
    # À implémenter selon les exclusions spécifiques
    true # Temporaire
  end

  def compatible_avec_taille?(taille_entreprise)
    return true if tailles_eligibles.blank?
    tailles_eligibles.include?(taille_entreprise)
  end
end
