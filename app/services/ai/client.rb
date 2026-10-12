# V2 — Lot 2 : couche d'abstraction unique pour tout appel à Claude (cahier
# des charges §8 : "choix du modèle par fonction, cache, limites de débit,
# budget de coût par projet et par mois, journalisation dans AiRun").
#
# Construite volontairement à côté de Bots::ClaudeChatClient (le concern
# partagé par les ~15 bots V1), pas en le modifiant : ce concern est inclus
# par des services déjà en production, le risque de régression d'un
# changement de signature partagé est plus élevé que la petite duplication
# de la logique d'appel ci-dessous (voir docs/AUDIT_V1.md §2.2).
module Ai
  class BudgetExceededError < StandardError; end

  class Client
    # Choix du modèle par fonction (cahier des charges §8) — mêmes identifiants
    # de modèle que Bots::ContextualBotService (GUIDE_MODEL/EXPERT_MODEL), pour
    # rester cohérent avec ce qui tourne déjà en production sur ce compte Anthropic.
    FUNCTIONS = {
      document_classification: { model: "claude-haiku-4-5-20251001", max_tokens: 1000 },
      quote_comparison: { model: "claude-sonnet-4-6", max_tokens: 1500 }
    }.freeze

    # Tarifs approximatifs (cents par million de tokens) — PLACEHOLDER, à
    # confirmer avec la grille tarifaire Anthropic réelle avant de piloter un
    # budget réel dessus (voir docs/QUESTIONS_OUVERTES.md). Le mécanisme de
    # budget fonctionne dès maintenant ; seule la précision du coût est à
    # affiner.
    PRICING_CENTS_PER_MILLION_TOKENS = {
      "claude-haiku-4-5-20251001" => { input: 100, output: 500 },
      "claude-sonnet-4-6" => { input: 300, output: 1500 }
    }.freeze

    DEFAULT_MONTHLY_BUDGET_CENTS = ENV.fetch("AI_MONTHLY_BUDGET_CENTS", 5_000).to_i

    def initialize(project:, actor: nil)
      @project = project
      @actor = actor
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    # Exécute un appel IA pour une `function` déclarée dans FUNCTIONS. Lève
    # Ai::BudgetExceededError si le budget mensuel du projet est dépassé —
    # à charge de l'appelant de décider quoi faire (ex: ne pas enqueuer de
    # job supplémentaire). Retourne le texte brut de la réponse, ou nil en
    # cas d'échec — jamais d'exception sur une erreur API, journalisée dans
    # AiRun à la place.
    def run(function, system:, messages:, subject: nil)
      config = FUNCTIONS.fetch(function) { raise ArgumentError, "fonction IA inconnue : #{function}" }
      raise BudgetExceededError, "budget IA mensuel dépassé pour le projet ##{@project.id}" if budget_exceeded?

      ai_run = AiRun.create!(project: @project, actor: @actor, subject: subject, function: function.to_s, model: config[:model], status: "pending")

      content, usage = call_claude(config[:model], system, messages, config[:max_tokens])

      ai_run.update!(
        status: content ? "success" : "error",
        output: { text: content }.compact,
        estimated_cost_cents: estimate_cost_cents(config[:model], usage)
      )

      content
    end

    private

    def budget_exceeded?
      return false if DEFAULT_MONTHLY_BUDGET_CENTS <= 0 # 0 ou négatif = pas de plafond (désactivé)
      AiRun.monthly_cost_cents(@project).to_i >= DEFAULT_MONTHLY_BUDGET_CENTS
    end

    def call_claude(model, system, messages, max_tokens)
      return [nil, nil] unless @api_key.present?

      message = client.messages.create(
        model: model,
        max_tokens: max_tokens,
        system_: system,
        messages: messages,
        request_options: { timeout: 60 }
      )

      text_block = message.content.find { |b| b.type == :text }
      [text_block&.text&.strip, message.respond_to?(:usage) ? message.usage : nil]
    rescue Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIError => e
      Rails.logger.error "[Ai::Client] #{model} erreur : #{e.message}"
      [nil, nil]
    end

    def client
      @client ||= Anthropic::Client.new(api_key: @api_key)
    end

    def estimate_cost_cents(model, usage)
      return nil unless usage
      pricing = PRICING_CENTS_PER_MILLION_TOKENS[model]
      return nil unless pricing

      input_tokens = usage.respond_to?(:input_tokens) ? usage.input_tokens.to_i : 0
      output_tokens = usage.respond_to?(:output_tokens) ? usage.output_tokens.to_i : 0

      ((input_tokens * pricing[:input] + output_tokens * pricing[:output]) / 1_000_000.0).round
    end
  end
end
