require "test_helper"

module Ai
  class TranslationServiceTest < ActiveSupport::TestCase
    fixtures :users, :properties, :projects

    class FakeAnthropicClient
      def initialize(response:)
        @response = response
      end

      def messages
        self
      end

      def create(**)
        @response
      end
    end

    FakeTextBlock = Struct.new(:type, :text)
    FakeMessage = Struct.new(:content)

    setup do
      @previous_key = ENV["ANTHROPIC_API_KEY"]
      ENV["ANTHROPIC_API_KEY"] = "test-key"
      @project = projects(:one)
    end

    teardown do
      ENV["ANTHROPIC_API_KEY"] = @previous_key
    end

    test "traduit le texte en appelant Ai::Client avec la fonction translation" do
      fake_response = FakeMessage.new([FakeTextBlock.new(:text, "Het dak is beschadigd.")])

      result = nil
      stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response)) do
        result = TranslationService.new(project: @project).translate("Le toit est endommagé.", to: "nl")
      end

      assert_equal "Het dak is beschadigd.", result
    end

    test "une langue cible inconnue lève ArgumentError" do
      assert_raises(ArgumentError) { TranslationService.new(project: @project).translate("texte", to: "de") }
    end
  end
end
