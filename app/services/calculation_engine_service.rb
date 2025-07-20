# Service orchestrateur pour tous les calculs de primes
# Gère les 6 niveaux : pré-login et post-login pour les 3 régions

class CalculationEngineService
  REGIONS = %w[flandre wallonie bruxelles].freeze
  CALCULATION_TYPES = %w[pre_login post_login].freeze

  def self.calculate(region, calculation_type, params = {}, user = nil)
    new(
      region: region,
      calculation_type: calculation_type,
      params: params,
      user: user
    ).calculate
  end

  def initialize(region:, calculation_type:, params: {}, user: nil)
    @region = region.to_s.downcase
    @calculation_type = calculation_type.to_s
    @params = params
    @user = user

    validate_inputs!
  end

  def calculate
    {
      eligibility: check_eligibility,
      category: determine_category,
      primes: calculate_primes,
      metadata: calculation_metadata
    }
  end

  private

  def validate_inputs!
    unless REGIONS.include?(@region)
      raise ArgumentError, "Région non supportée: #{@region}. Régions disponibles: #{REGIONS.join(', ')}"
    end

    unless CALCULATION_TYPES.include?(@calculation_type)
      raise ArgumentError, "Type de calcul non supporté: #{@calculation_type}. Types disponibles: #{CALCULATION_TYPES.join(', ')}"
    end

    if @calculation_type == 'post_login' && @user.nil?
      raise ArgumentError, "Un utilisateur est requis pour les calculs post-login"
    end
  end

  def check_eligibility
    eligibility_service.check_eligibility
  end

  def determine_category
    return nil unless check_eligibility[:eligible]

    category_service.determine_category
  end

  def calculate_primes
    eligibility_result = check_eligibility
    return [] unless eligibility_result[:eligible]

    category_result = determine_category
    return [] unless category_result

    calculator_service.calculate_primes(category_result)
  end

  def eligibility_service
    @eligibility_service ||= service_class('eligibility').new(@params, user: @user)
  end

  def category_service
    @category_service ||= service_class('category').new(@params, user: @user)
  end

  def calculator_service
    @calculator_service ||= service_class(@calculation_type + '_calculator').new(@params, user: @user)
  end

  def service_class(service_type)
    class_name = "Regions::#{@region.capitalize}::#{@region.capitalize}#{service_type.camelize}Service"
    class_name.constantize
  rescue NameError
    raise NotImplementedError, "Service non implémenté: #{class_name}"
  end

  def calculation_metadata
    {
      region: @region,
      calculation_type: @calculation_type,
      timestamp: Time.current,
      user_id: @user&.id,
      version: '1.0'
    }
  end
end
