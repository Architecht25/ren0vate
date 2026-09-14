require "test_helper"

module Bots
  class SubsidyBotServiceTest < ActiveSupport::TestCase
    fixtures :users
    # Double léger pour Anthropic::Client — évite tout vrai appel réseau vers l'API
    # Claude. Enregistre les arguments reçus par #create pour pouvoir les inspecter,
    # et peut simuler soit une réponse normale, soit une erreur de l'API.
    class FakeAnthropicClient
      attr_reader :received_kwargs

      def initialize(response: nil, error: nil)
        @response = response
        @error = error
      end

      def messages
        self
      end

      def create(**kwargs)
        @received_kwargs = kwargs
        raise @error if @error
        @response
      end
    end

    FakeTextBlock = Struct.new(:type, :text)
    FakeMessage   = Struct.new(:content)

    setup do
      @previous_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      @previous_key = ENV["ANTHROPIC_API_KEY"]
      ENV["ANTHROPIC_API_KEY"] = "test-key"
      @user = users(:freemium_user)
      @user.update_column(:region, "wallonie")
    end

    teardown do
      Rails.cache = @previous_cache
      ENV["ANTHROPIC_API_KEY"] = @previous_key
    end

    def fake_success_response(text = "Réponse experte sur les primes.")
      FakeMessage.new([ FakeTextBlock.new(:text, text) ])
    end

    test "construit le payload envoyé à Claude avec le message utilisateur, le modèle et le contexte région" do
      fake_client = FakeAnthropicClient.new(response: fake_success_response)
      service = Bots::SubsidyBotService.new(user: @user, cache_key: "subsidy_bot:test:payload", region: "wallonie")

      result = nil
      stub_class_method(Anthropic::Client, :new, fake_client) do
        result = service.chat("Ai-je droit à une prime isolation toiture ?")
      end

      assert_equal "Réponse experte sur les primes.", result[:content]

      kwargs = fake_client.received_kwargs
      assert_equal Bots::SubsidyBotService::MODEL, kwargs[:model]
      assert_equal Bots::SubsidyBotService::MAX_TOKENS, kwargs[:max_tokens]
      assert_equal(
        { role: "user", content: "Ai-je droit à une prime isolation toiture ?" },
        kwargs[:messages].last
      )
      assert kwargs[:system_].is_a?(Array)
      assert kwargs[:system_].any? { |block| block[:text].include?("EXPERTISE TERRAIN") }
      assert kwargs[:system_].any? { |block| block[:text].include?("Wallonie") }
    end

    test "gère une erreur API Anthropic sans lever d'exception et renvoie un message de repli" do
      fake_client = FakeAnthropicClient.new(error: Anthropic::Errors::APITimeoutError.new(url: URI("https://api.anthropic.com")))
      service = Bots::SubsidyBotService.new(user: @user, cache_key: "subsidy_bot:test:error", region: "wallonie")

      result = nil
      assert_nothing_raised do
        stub_class_method(Anthropic::Client, :new, fake_client) do
          result = service.chat("Une question")
        end
      end

      assert_match(/problème technique momentané/, result[:content])
    end

    test "gère une erreur API générique (Anthropic::Errors::APIError) de la même façon" do
      api_error = Anthropic::Errors::APIError.new(
        url: URI("https://api.anthropic.com"),
        status: 500,
        headers: {},
        body: nil,
        request: nil,
        response: nil,
        message: "internal error"
      )
      fake_client = FakeAnthropicClient.new(error: api_error)
      service = Bots::SubsidyBotService.new(user: @user, cache_key: "subsidy_bot:test:api_error", region: "wallonie")

      result = nil
      stub_class_method(Anthropic::Client, :new, fake_client) do
        result = service.chat("Une autre question")
      end

      assert_match(/problème technique momentané/, result[:content])
    end

    test "l'historique est sauvegardé dans Rails.cache puis effacé par clear_history" do
      cache_key = "subsidy_bot:test:#{SecureRandom.hex(4)}"
      fake_client = FakeAnthropicClient.new(response: fake_success_response("Voici la réponse."))
      service = Bots::SubsidyBotService.new(user: @user, cache_key: cache_key, region: "wallonie")

      stub_class_method(Anthropic::Client, :new, fake_client) do
        service.chat("Première question")
      end

      history = Rails.cache.read(cache_key)
      assert history.present?
      assert_equal 2, history.length
      assert_equal({ role: "user", content: "Première question" }, history.first)
      assert_equal({ role: "assistant", content: "Voici la réponse." }, history.last)

      service.clear_history
      assert_nil Rails.cache.read(cache_key)
    end

    test "sans cache_key, aucun historique n'est lu ni écrit" do
      fake_client = FakeAnthropicClient.new(response: fake_success_response)
      service = Bots::SubsidyBotService.new(user: @user, cache_key: nil, region: "wallonie")

      stub_class_method(Anthropic::Client, :new, fake_client) do
        service.chat("Question sans historique")
      end

      # Rien à lire sans clé — pas d'exception, pas de clé fantôme écrite
      assert_nothing_raised { service.clear_history }
    end
  end
end
