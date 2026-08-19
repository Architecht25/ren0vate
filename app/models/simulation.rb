class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project, optional: true
  has_many :documents, dependent: :destroy

  has_one :request, dependent: :destroy

  validates :region, :titre, :property_id, presence: true

  before_create :assign_wallonie_regime

  # Scope pour récupérer les simulations récentes
  scope :recent, -> { order(created_at: :desc) }

  # Méthodes utiles pour l'interface
  def total_primes_amount
    total_simule || 0
  end

  # Régime wallon applicable ("primes_cash" ou "reduction_pret") — voir
  # Regions::Wallonie::WallonieRegimeRouter. Pertinent uniquement pour region == "wallonie".
  def regime_effectif
    regime.presence || "primes_cash"
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

  # Prime PEB/EPC-label Flandre supprimée définitivement (clôturée)
  def montant_peb_calcule
    0
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

  def processing_step
    return 1 unless eligible.present?
    return 2 if eligible && category.blank?
    return 3 if eligible && category.present? && total_simule.to_f <= 0
    return 4 if eligible && category.present? && total_simule.to_f > 0
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

  # Accès aux données du régime "reduction_pret" (Wallonie, dès le 01/10/2026) stockées dans parameters
  def montant_projet_saisi
    parsed_simulation_parameter('montant_projet')
  end

  def montant_projet_retenu_saisi
    parsed_simulation_parameter('montant_projet_retenu') || 0
  end

  def taux_reduction_saisi
    parsed_simulation_parameter('taux_reduction')
  end

  def plafond_emprunt_saisi
    parsed_simulation_parameter('plafond_emprunt')
  end

  def ecomateriaux_saisi
    ActiveModel::Type::Boolean.new.cast(parsed_simulation_parameter('ecomateriaux'))
  end

  def taux_reduction_base_saisi
    parsed_simulation_parameter('taux_reduction_base')
  end

  def taux_interet_label_saisi
    parsed_simulation_parameter('taux_interet_label')
  end

  # Méthode pour extraire les primes depuis le JSON parameters
  def primes
    @primes_collection ||= PrimesCollection.new(self)
  end

  def primes_count
    return 0 unless parameters.present?

    begin
      parsed_params = JSON.parse(parameters)
      count = 0

      if parsed_params['prime_cards'].present?
        parsed_params['prime_cards'].each do |_category_key, category_data|
          next unless category_data.is_a?(Hash) && category_data['primes'].present?

          category_data['primes'].each do |prime|
            amount = (prime['calculated_amount'] || prime['amount'] || 0).to_f
            count += 1 if amount > 0
          end
        end
      end

      count
    rescue JSON::ParserError, StandardError
      0
    end
  end

  # Classe helper pour simuler une collection ActiveRecord
  class PrimesCollection
    def initialize(simulation)
      @simulation = simulation
    end

    def count
      @simulation.primes_count
    end

    def any?
      count > 0
    end

    def empty?
      count == 0
    end
  end

  # Fixé une fois pour toutes à la création, selon la date — une simulation
  # wallonne gardera son régime même si on la rouvre après la bascule du 01/10/2026.
  private def assign_wallonie_regime
    return unless region&.downcase == 'wallonie'

    self.regime = Regions::Wallonie::WallonieRegimeRouter.regime_for
  end

  private def parsed_simulation_parameter(key)
    return nil unless parameters.present?
    JSON.parse(parameters)[key]
  rescue JSON::ParserError
    nil
  end
end
