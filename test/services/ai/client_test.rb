require "test_helper"

module Ai
  class ClientTest < ActiveSupport::TestCase
    fixtures :users, :properties, :projects

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
    FakeUsage = Struct.new(:input_tokens, :output_tokens)
    FakeMessage = Struct.new(:content, :usage)

    setup do
      @previous_key = ENV["ANTHROPIC_API_KEY"]
      ENV["ANTHROPIC_API_KEY"] = "test-key"
      @project = projects(:one)
      @user = users(:freemium_user)
    end

    teardown do
      ENV["ANTHROPIC_API_KEY"] = @previous_key
    end

    def fake_response(text)
      FakeMessage.new([FakeTextBlock.new(:text, text)], FakeUsage.new(500, 200))
    end

    test "run crée un AiRun et retourne le texte de la réponse" do
      client = Ai::Client.new(project: @project, actor: @user)

      result = nil
      stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response('{"document_type":"devis"}'))) do
        result = client.run(:document_classification, system: "system prompt", messages: [{ role: "user", content: "texte" }])
      end

      assert_equal '{"document_type":"devis"}', result
      ai_run = AiRun.last
      assert_equal "document_classification", ai_run.function
      assert_equal "success", ai_run.status
      assert_equal @project, ai_run.project
      assert ai_run.estimated_cost_cents.present?
    end

    test "une erreur API journalise un AiRun en erreur et retourne nil" do
      client = Ai::Client.new(project: @project, actor: @user)

      result = "non nil"
      stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(error: Anthropic::Errors::APIError.new(url: nil, status: 500, body: nil, request: nil, response: nil, message: "boom"))) do
        result = client.run(:document_classification, system: "s", messages: [{ role: "user", content: "x" }])
      end

      assert_nil result
      assert_equal "error", AiRun.last.status
    end

    test "une fonction inconnue lève ArgumentError" do
      client = Ai::Client.new(project: @project)
      assert_raises(ArgumentError) { client.run(:fonction_inexistante, system: "s", messages: []) }
    end

    test "le budget mensuel dépassé bloque l'appel sans toucher l'API" do
      AiRun.create!(project: @project, function: "document_classification", model: "claude-haiku-4-5-20251001", status: "success", estimated_cost_cents: Ai::Client::DEFAULT_MONTHLY_BUDGET_CENTS)

      client = Ai::Client.new(project: @project)
      assert_raises(Ai::BudgetExceededError) do
        client.run(:document_classification, system: "s", messages: [])
      end
    end
  end
end
