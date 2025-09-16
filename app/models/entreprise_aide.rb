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

  def montant_investissement_min_requis
    return nil if montant_min.blank? || taux_aide.blank? || taux_aide.zero?

    # Calcul : montant_min / (taux_aide / 100)
    # Exemple : 500€ / (50% / 100) = 1000€
    (montant_min / (taux_aide / 100)).round
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

  def montant_investissement_min_adaptatif(taille_entreprise = nil, age_entreprise = nil)
    # Pour la Prime Matériel ou Travaux, utiliser les montants spécifiques selon le type d'entreprise
    if slug == "bruxelles_prime_materiel_travaux"
      return calculate_minimum_for_materiel_travaux(taille_entreprise, age_entreprise)
    end

    # Pour la Prime Immobilier, montant fixe de 100.000€
    if slug == "bruxelles_prime_immobilier"
      return 100000
    end

    # Pour la Prime Conformité aux normes, montant fixe de 5.000€
    if slug == "bruxelles_prime_conformite_normes"
      return 5000
    end

    # Pour la Prime Sécurisation, montant fixe de 2.000€
    if slug == "bruxelles_prime_securisation"
      return 2000
    end

    # Pour la Prime Accessibilité, montant fixe de 1.000€
    if slug == "bruxelles_prime_accessibilite"
      return 1000
    end

    # Pour les Investissements Transition Économique, montant fixe de 2.000€
    if slug == "bruxelles_investissements_transition_economique"
      return 2000
    end

    # Pour la Prime Mobilité Vélo-cargo, montant fixe de 500€
    if slug == "bruxelles_mobilite_velo_cargo"
      return 500
    end

    # Pour la Prime Consultance, montant fixe de 500€
    if slug == "bruxelles_prime_consultance"
      return 500
    end

    # Pour la Prime Digitalisation, montant fixe de 500€
    if slug == "bruxelles_prime_digitalisation"
      return 500
    end

    # Pour les autres aides, utiliser le calcul standard
    montant_investissement_min_requis
  end

  private

  def calculate_minimum_for_materiel_travaux(taille_entreprise, age_entreprise)
    # Déterminer si c'est une entreprise "starter" (< 4 ans)
    is_starter = age_entreprise == "moins_4_ans" || age_entreprise == "moins_3_ans"

    # Si c'est une starter, minimum 5.000€ indépendamment de la taille
    return 5000 if is_starter

    # Sinon, selon la taille d'entreprise
    case taille_entreprise
    when "tpe", "micro"
      7500  # Micro > 4 ans
    when "pme", "petite"
      15000 # Petite > 4 ans
    when "moyenne"
      50000 # Moyenne > 4 ans
    else
      5000  # Valeur par défaut
    end
  end
end
