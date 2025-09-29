class AiConsultationService
  include ActiveModel::Model

  # Configuration OpenAI
  OPENAI_MODEL = "gpt-4o-mini" # Plus économique que gpt-4
  MAX_TOKENS = 1000
  TEMPERATURE = 0.7

  attr_accessor :user_message, :conversation_history, :context

  def initialize(user_message:, conversation_history: [], context: {})
    @user_message = user_message
    @conversation_history = conversation_history || []
    @context = context || {}
    @client = OpenAI::Client.new
  end

  def call
    begin
      response = @client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages: build_messages,
          max_tokens: MAX_TOKENS,
          temperature: TEMPERATURE,
          stream: false
        }
      )

      ai_response = response.dig("choices", 0, "message", "content")

      {
        success: true,
        response: ai_response,
        usage: response["usage"],
        model: OPENAI_MODEL
      }
    rescue OpenAI::Error => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      {
        success: false,
        error: "Erreur de l'API OpenAI: #{e.message}",
        fallback_response: generate_fallback_response
      }
    rescue StandardError => e
      Rails.logger.error "Service Error: #{e.message}"
      {
        success: false,
        error: "Erreur interne du service",
        fallback_response: generate_fallback_response
      }
    end
  end

  private

  def build_messages
    messages = []

    # Message système avec contexte de Renovate
    messages << {
      role: "system",
      content: system_prompt
    }

    # Historique de conversation
    @conversation_history.each do |msg|
      messages << {
        role: msg[:role],
        content: msg[:content]
      }
    end

    # Message utilisateur actuel
    messages << {
      role: "user",
      content: @user_message
    }

    messages
  end

  def system_prompt
    <<~PROMPT
      Tu es un consultant expert en rénovation énergétique et primes gouvernementales belges pour Renovate.
      Tu maîtrises parfaitement les réglementations wallonnes ET bruxelloises en 2025.

      SPÉCIALISATIONS CLÉS :
      • Primes Habitation Plus (Wallonie) et Renolution (Bruxelles)
      • Audit énergétique PEB et conseils techniques détaillés
      • Optimisation ROI et planification de travaux
      • Obligations légales et délais administratifs
      • Entrepreneurs RGE/qualifiés et négociation
      • ACP/copropriétés et spécificités entreprises

      #{get_regional_context}

      CONTEXTE UTILISATEUR :
      #{format_context}

      INSTRUCTIONS DE RÉPONSE :
      1. 🎯 ANALYSE d'abord la situation spécifique (région, type de bien, budget, délais)
      2. 💡 CONSEILS CONCRETS avec étapes prioritaires numérotées
      3. 💰 OPTIMISATION financière (cumuls de primes, timing, négociation)
      4. ⚠️ ALERTES sur délais critiques ou pièges à éviter
      5. 📋 ACTIONS CONCRÈTES à entreprendre immédiatement

      STYLE :
      • Réponses structurées avec émojis pour la lisibilité
      • Entre 150-400 mots selon la complexité
      • Ton professionnel mais accessible
      • Chiffres précis quand disponibles

      Si tu manques d'infos, demande PRÉCISÉMENT ce dont tu as besoin.
    PROMPT
  end

  def format_context
    return "Aucun contexte spécifique fourni." if @context.empty?

    formatted = []

    # Informations de base
    if @context[:region] && @context[:simulation_title]
      formatted << "📍 SIMULATION ACTIVE: #{@context[:simulation_title]} (#{@context[:region]&.capitalize})"
      formatted << "📅 Créée le: #{@context[:created_at]}" if @context[:created_at]
    end

    # Données de propriété
    if @context[:property_type]
      property_info = "🏠 PROPRIÉTÉ: #{@context[:property_type]&.capitalize}"
      property_info += " (#{@context[:surface]}m²)" if @context[:surface]
      property_info += " - Construction: #{@context[:construction_year]}" if @context[:construction_year]
      property_info += " 🏢 [ENTREPRISE]" if @context[:is_enterprise]
      formatted << property_info
    end

    if @context[:address]
      formatted << "📮 Adresse: #{@context[:address]}"
    end

    # Données financières
    if @context[:total_primes] && @context[:total_primes] > 0
      formatted << "💰 PRIMES CALCULÉES: #{@context[:total_primes]}€"
    end

    if @context[:budget] && @context[:budget] > 0
      formatted << "💵 Budget disponible: #{@context[:budget]}€"
    end

    # Aperçu des principales primes
    if @context[:main_primes]&.any?
      formatted << "🎯 PRINCIPALES PRIMES IDENTIFIÉES:"
      @context[:main_primes].first(3).each do |prime|
        formatted << "   • #{prime[:name]}: #{prime[:amount]}€"
      end
    end

    # Priorités utilisateur
    if @context[:priorities]&.any?
      formatted << "⭐ Priorités déclarées: #{@context[:priorities].join(', ')}"
    end

    # Contexte géographique spécifique
    if @context[:region]
      case @context[:region].downcase
      when 'wallonie'
        formatted << "⚡ RÉGLEMENTATION: Habitation Plus (Wallonie) - Nouvelles conditions 2025"
      when 'bruxelles'
        formatted << "⚡ RÉGLEMENTATION: Renolution (Bruxelles) - Programme exemplarité disponible"
      when 'flandre'
        formatted << "⚡ RÉGLEMENTATION: Vlaanderen Renoveert (Flandre)"
      end
    end

    formatted.empty? ? "Aucun contexte spécifique fourni." : formatted.join("\n")
  end

  def get_regional_context
    region = @context[:region]&.downcase

    case region
    when 'wallonie'
      <<~WALLONIE
        🏛️ SPÉCIFICITÉ WALLONNE 2025 :
        • Programme Habitation Plus - Nouvelle grille tarifaire
        • Audit énergétique obligatoire (sauf exceptions)
        • Primes majorées jusqu'à 70% pour revenus modestes
        • Délai 12 mois après travaux pour demande
        • Prime isolation : 6-30€/m² selon revenus
        • Prime chauffage : jusqu'à 4000€ pour pompe à chaleur
        • Obligation entrepreneur RGE pour certaines primes
      WALLONIE
    when 'bruxelles'
      <<~BRUXELLES
        🏛️ SPÉCIFICITÉ BRUXELLOISE 2025 :
        • Programme Renolution - Focus sur exemplarité
        • Primes jusqu'à 50% + bonus exemplarité 30%
        • Audit énergétique recommandé mais non obligatoire
        • Entreprises : primes majorées + consultance
        • Rénovation globale privilégiée
        • Délai 4 ans après audit pour travaux
        • Prime isolation : 20-50€/m² selon performance
      BRUXELLES
    when 'flandre'
      <<~FLANDRE
        🏛️ SPÉCIFICITÉ FLAMANDE 2025 :
        • Programme Vlaanderen Renoveert
        • Focus sur rénovation globale obligatoire
        • Prêt sans intérêt disponible
        • Trajectoire rénovation sur 5-13 ans
      FLANDRE
    else
      "🏛️ MULTI-RÉGIONAL : Adapte tes conseils selon la région (Wallonie/Bruxelles/Flandre)"
    end
  end

  def generate_fallback_response
    "Je rencontre actuellement des difficultés techniques. En attendant, je vous recommande de consulter nos guides de rénovation ou de contacter notre équipe support pour une assistance personnalisée."
  end
end
