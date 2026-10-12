require "test_helper"

module Ai
  class EmbeddingClientTest < ActiveSupport::TestCase
    setup do
      @previous_key = ENV["VOYAGE_API_KEY"]
    end

    teardown do
      ENV["VOYAGE_API_KEY"] = @previous_key
    end

    test "retourne nil sans clé API, sans lever d'exception" do
      ENV["VOYAGE_API_KEY"] = nil
      assert_nil Ai::EmbeddingClient.new.embed(["texte"])
    end

    test "retourne un tableau vide pour une entrée vide, sans appel réseau" do
      ENV["VOYAGE_API_KEY"] = "test-key"
      assert_equal [], Ai::EmbeddingClient.new.embed([])
      assert_equal [], Ai::EmbeddingClient.new.embed(nil)
    end

    test "parse la réponse Voyage AI dans l'ordre des index, pas l'ordre d'arrivée" do
      ENV["VOYAGE_API_KEY"] = "test-key"
      fake_response = Struct.new(:success?, :parsed_response).new(
        true,
        { "data" => [
          { "index" => 1, "embedding" => [0.2, 0.2] },
          { "index" => 0, "embedding" => [0.1, 0.1] }
        ] }
      )

      stub_class_method(HTTParty, :post, ->(*) { fake_response }) do
        result = Ai::EmbeddingClient.new.embed(["a", "b"])
        assert_equal [[0.1, 0.1], [0.2, 0.2]], result
      end
    end

    test "retourne nil si la requête échoue, sans lever d'exception" do
      ENV["VOYAGE_API_KEY"] = "test-key"
      fake_response = Struct.new(:success?).new(false)

      stub_class_method(HTTParty, :post, ->(*) { fake_response }) do
        assert_nil Ai::EmbeddingClient.new.embed(["a"])
      end
    end
  end
end
