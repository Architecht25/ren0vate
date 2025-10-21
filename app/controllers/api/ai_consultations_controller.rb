class Api::AiConsultationsController < ApplicationController
  # Protection CSRF pour les API internes
  protect_from_forgery with: :null_session
  before_action :validate_request

  def create
    begin
      # Extraction des données de la requête
      user_message = ai_params[:message]
      conversation_history = ai_params[:conversation_history] || []
      context = build_context

      # Appel du service IA
      ai_service = AiConsultationService.new(
        user_message: user_message,
        conversation_history: conversation_history,
        context: context
      )

      result = ai_service.call

      if result[:success]
        render json: {
          success: true,
          response: result[:response],
          timestamp: Time.current.iso8601,
          usage: result[:usage],
          model: result[:model]
        }
      else
        render json: {
          success: false,
          error: result[:error],
          fallback_response: result[:fallback_response],
          timestamp: Time.current.iso8601
        }, status: :unprocessable_entity
      end

    rescue ActionController::ParameterMissing => e
      render json: {
        success: false,
        error: "Paramètre manquant: #{e.param}",
        timestamp: Time.current.iso8601
      }, status: :bad_request

    rescue StandardError => e
      Rails.logger.error "AI Controller Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        success: false,
        error: "Erreur interne du serveur",
        fallback_response: "Désolé, je rencontre des difficultés techniques. Veuillez réessayer dans quelques instants.",
        timestamp: Time.current.iso8601
      }, status: :internal_server_error
    end
  end

  private

  def ai_params
    params.require(:ai_consultation).permit(
      :message,
      conversation_history: [:role, :content],
      context: [
        :location, :property_type, :budget, :total_primes,
        priorities: []
      ]
    )
  end

  def validate_request
    # Validation de base de la requête
    unless request.format.json?
      render json: {
        success: false,
        error: "Format de requête non supporté. Utilisez application/json."
      }, status: :not_acceptable
      return false
    end

    # Vérification de présence du message
    if params.dig(:ai_consultation, :message).blank?
      render json: {
        success: false,
        error: "Le message ne peut pas être vide."
      }, status: :bad_request
      return false
    end

    # Limite de longueur du message
    message_length = params.dig(:ai_consultation, :message).to_s.length
    if message_length > 2000
      render json: {
        success: false,
        error: "Le message est trop long (maximum 2000 caractères)."
      }, status: :bad_request
      return false
    end

    true
  end

  def build_context
    context_params = ai_params[:context] || {}

    # Récupération de la simulation active depuis la session ou les paramètres
    current_simulation = nil
    if session[:current_simulation_id].present?
      # ✅ SÉCURITÉ: Vérifier que la simulation appartient à l'utilisateur connecté
      current_simulation = current_user.simulations.find_by(id: session[:current_simulation_id])
    end

    # Context enrichi avec données réelles de simulation
    context = {
      # Données de localisation et propriété
      location: context_params[:location] || current_simulation&.region || session[:user_location],
      property_type: context_params[:property_type] || current_simulation&.property&.type_propriete || current_simulation&.property&.type || session[:property_type],

      # Données financières
      budget: context_params[:budget] || session[:estimated_budget],
      total_primes: context_params[:total_primes] || current_simulation&.total_simule || session[:total_primes],

      # Données spécifiques de la simulation
      simulation_id: current_simulation&.id,
      region: current_simulation&.region,
      simulation_title: current_simulation&.titre,
      created_at: current_simulation&.created_at&.strftime("%d/%m/%Y"),

      # Données de propriété
      address: current_simulation&.property&.adresse,
      surface: current_simulation&.property&.surface_habitable_wallonie,
      construction_year: current_simulation&.property&.annee_construction,
      is_enterprise: current_simulation&.property&.is_entreprise?,

      # Primes calculées (aperçu des principales)
      main_primes: get_simulation_primes_summary(current_simulation),

      # Priorités et préférences
      priorities: context_params[:priorities] || session[:renovation_priorities] || []
    }

    # Nettoyage des valeurs vides
    context.compact
  end

  private

  def get_simulation_primes_summary(simulation)
    return [] unless simulation

    # Récupérer un aperçu des principales primes calculées
    # (adapté selon votre modèle de données primes)
    begin
      primes_data = []

      # Si vous avez un modèle SimulationPrime ou similaire
      if defined?(SimulationPrime) && simulation.simulation_primes.any?
        simulation.simulation_primes.limit(5).each do |prime|
          primes_data << {
            name: prime.prime_name || prime.name,
            amount: prime.amount || 0,
            status: prime.status || 'calculated'
          }
        end
      else
        # Fallback : essayons de récupérer depuis les paramètres ou autres attributs disponibles
        if simulation.respond_to?(:parameters) && simulation.parameters.present?
          # Si les paramètres contiennent des données de primes
          params_data = simulation.parameters.is_a?(String) ? JSON.parse(simulation.parameters) : simulation.parameters
          if params_data.is_a?(Hash) && params_data['primes']
            params_data['primes'].first(5).each do |prime|
              primes_data << {
                name: prime['nom'] || prime['name'] || 'Prime calculée',
                amount: prime['montant'] || prime['amount'] || 0,
                status: 'calculated'
              }
            end
          end
        end
      end

      primes_data
    rescue StandardError => e
      Rails.logger.warn "Error getting primes summary: #{e.message}"
      []
    end
  end
end
