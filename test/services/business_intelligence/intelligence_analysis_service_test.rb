require "test_helper"

module BusinessIntelligence
  class IntelligenceAnalysisServiceTest < ActiveSupport::TestCase
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
      @previous_key = ENV["ANTHROPIC_API_KEY"]
      ENV["ANTHROPIC_API_KEY"] = "test-key"
    end

    teardown do
      ENV["ANTHROPIC_API_KEY"] = @previous_key
    end

    test "analyze envoie le texte scrapé à Claude et renvoie le texte de la réponse" do
      response = FakeMessage.new([ FakeTextBlock.new(:text, "## Résumé exécutif\nTout va bien.") ])
      fake_client = FakeAnthropicClient.new(response: response)
      service = BusinessIntelligence::IntelligenceAnalysisService.new

      result = nil
      stub_class_method(Anthropic::Client, :new, fake_client) do
        result = service.analyze("=== VEILLE ===\nUn article important.")
      end

      assert_equal "## Résumé exécutif\nTout va bien.", result
      kwargs = fake_client.received_kwargs
      assert_equal BusinessIntelligence::IntelligenceAnalysisService::MODEL, kwargs[:model]
      assert_includes kwargs[:messages].first[:content], "Un article important."
      assert kwargs[:system_].any? { |block| block[:text].include?("Ren0vate") }
    end

    test "renvoie nil sans lever d'exception si l'API Claude échoue" do
      fake_client = FakeAnthropicClient.new(error: Anthropic::Errors::APITimeoutError.new(url: URI("https://api.anthropic.com")))
      service = BusinessIntelligence::IntelligenceAnalysisService.new

      result = "not nil"
      assert_nothing_raised do
        stub_class_method(Anthropic::Client, :new, fake_client) do
          result = service.analyze("texte")
        end
      end

      assert_nil result
    end

    test "renvoie un message de repli si ANTHROPIC_API_KEY est absente" do
      ENV["ANTHROPIC_API_KEY"] = nil
      service = BusinessIntelligence::IntelligenceAnalysisService.new

      result = service.analyze("texte")

      assert_match(/ANTHROPIC_API_KEY manquante/, result)
    end
  end
end
