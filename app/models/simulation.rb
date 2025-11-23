class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project, optional: true
  has_many :simulation_prime_cards, dependent: :destroy
  has_many :primes, through: :simulation_prime_cards
  has_many :documents, dependent: :destroy

  has_one :request, dependent: :destroy

  validates :region, :titre, :property_id, presence: true

  # Scope pour récupérer les simulations récentes
  scope :recent, -> { order(created_at: :desc) }

  # Méthodes utiles pour l'interface
  def total_primes_amount
    simulation_prime_cards.sum(:montant_simule)
  end

  # Calcul du total complet incluant PEB et amiante pour Flandre
  def total_complet_amount
    base_total = total_primes_amount

    # Ajouter les montants PEB et amiante si la simulation est en Flandre
    if region&.downcase == 'flandre'
      base_total += montant_peb_calcule + montant_amiante_calcule
    end

    base_total
  end

  # Calcul du montant PEB à partir des données sauvegardées
  def montant_peb_calcule
    return 0 unless parameters.present?

    begin
      parsed_params = JSON.parse(parameters)
      peb_data = parsed_params['peb_data']

      return 0 unless peb_data.present?

      # Logique de calcul PEB (même que côté frontend)
      label_initial = peb_data['label_initial']
      type_logement = peb_data['type_logement']
      ventilation = peb_data['ventilation']
      label_final = peb_data['label_final']

      return 0 unless label_initial.present? && label_final.present? && type_logement.present?

      # Calcul selon la matrice PEB Flandre
      if label_initial == 'F' && label_final == 'A' && type_logement == 'maison'
        if ventilation == 'avec_ventilation'
          return 4000
        else
          return 2000
        end
      elsif label_initial == 'E' && label_final == 'A' && type_logement == 'maison'
        return 3000
      elsif label_initial == 'D' && label_final == 'A'
        return 2000
      # Ajouter d'autres conditions selon la matrice PEB
      end

      return 0
    rescue JSON::ParserError, NoMethodError
      0
    end
  end

  # Calcul du montant amiante à partir des données sauvegardées
  def montant_amiante_calcule
    return 0 unless parameters.present?

    begin
      parsed_params = JSON.parse(parameters)
      amiante_data = parsed_params['amiante_data']

      return 0 unless amiante_data.present?

      surface_toiture = amiante_data['surface_toiture'].to_f
      surface_murs = amiante_data['surface_murs'].to_f

      montant_total = 0

      # Logique de calcul amiante Flandre (même que côté frontend)
      # 8€/m² pour la toiture
      # 4€/m² pour les murs si pas de toiture
      # 12€/m² pour les murs si toiture incluse
      if surface_toiture > 0
        montant_total += surface_toiture * 8 # 8€/m² toiture

        if surface_murs > 0
          montant_total += surface_murs * 12 # 12€/m² murs si toiture incluse
        end
      elsif surface_murs > 0
        montant_total += surface_murs * 4 # 4€/m² murs uniquement
      end

      montant_total
    rescue JSON::ParserError, NoMethodError
      0
    end
  end

  def eligibility_status
    case eligible
    when true
      'eligible'
    when false
      'not_eligible'
    else
      'pending'
    end
  end

  # Méthodes pour la double éligibilité (finalité économique)
  def dual_eligibility_status
    if project&.finalite_economique?
      {
        investment: investment_eligibility_status,
        renolution: renolution_eligibility_status
      }
    else
      nil
    end
  end

  def investment_eligibility_status
    case eligible_investment
    when true
      'eligible'
    when false
      'not_eligible'
    else
      'pending'
    end
  end

  def renolution_eligibility_status
    case eligible_renolution
    when true
      'eligible'
    when false
      'not_eligible'
    else
      'pending'
    end
  end

  def processing_step
    return 1 unless eligible.present?
    return 2 if eligible && category.blank?
    return 3 if eligible && category.present? && simulation_prime_cards.empty?
    return 4 if eligible && category.present? && simulation_prime_cards.any?
  end

  def step_name
    case processing_step
    when 1
      'Test d\'éligibilité'
    when 2
      'Détermination de la catégorie'
    when 3
      'Calcul des primes'
    when 4
      'Simulation terminée'
    end
  end

  # Accès aux données de catégorie stockées dans parameters
  def exact_income
    return nil unless parameters.present?
    parsed_params = JSON.parse(parameters)
    parsed_params['exact_income']
  rescue JSON::ParserError
    nil
  end

  def thresholds_used
    return nil unless parameters.present?
    parsed_params = JSON.parse(parameters)
    parsed_params['thresholds_used']
  rescue JSON::ParserError
    nil
  end
end
