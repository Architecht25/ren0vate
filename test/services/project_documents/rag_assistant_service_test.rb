require "test_helper"

module ProjectDocuments
  # V2 — Lot 5 : test obligatoire du cahier des charges §8 — "Test
  # automatisé obligatoire : un entrepreneur ne doit jamais obtenir, via
  # l'assistant, le contenu d'un document qu'il ne peut pas ouvrir."
  class RagAssistantServiceTest < ActiveSupport::TestCase
    fixtures :users, :properties, :projects

    class FakeEmbeddingClient
      def initialize(vector)
        @vector = vector
      end

      def embed(_texts)
        [@vector]
      end
    end

    setup do
      @owner = users(:freemium_user)
      @project = projects(:one)
      @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
      @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

      @roofer = User.create!(email: "roofer_rag@example.com", password: "password123", nom: "Couvreur")
      @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

      # Document privé : visible du propriétaire et de son déposant uniquement — jamais de l'entrepreneur.
      @private_document = @project.project_documents.create!(
        title: "Rapport financier confidentiel", document_type: "autre", visibility: "private", uploaded_by: @owner
      )
      version = @private_document.versions.create!(created_by: @owner, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf"))
      @secret_chunk = version.chunks.create!(project: @project, content: "Le code du coffre est 1234, montant caché 999999€.", chunk_index: 0, embedding: Array.new(1024, 0.9))

      # Document public (visibilité "all") — visible de tous les membres actifs.
      @public_document = @project.project_documents.create!(
        title: "Garantie toiture", document_type: "autre", visibility: "all", uploaded_by: @owner
      )
      public_version = @public_document.versions.create!(created_by: @owner, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf"))
      @public_chunk = public_version.chunks.create!(project: @project, content: "La toiture est garantie 10 ans à partir du 1er janvier 2026.", chunk_index: 0, embedding: Array.new(1024, 0.9))
    end

    test "un entrepreneur n'obtient jamais le contenu d'un document privé via l'assistant, même si c'est le plus proche sémantiquement" do
      service = RagAssistantService.new(user: @roofer, project: @project)

      stub_class_method(Ai::EmbeddingClient, :new, FakeEmbeddingClient.new(Array.new(1024, 0.9))) do
        stub_class_method(Ai::Client, :new, FakeNoApiKeyClient.new) do
          result = service.ask("Quel est le montant caché dans le rapport financier ?")

          assert_not_includes result[:sources], @private_document
        end
      end
    end

    test "le propriétaire peut accéder au document privé via l'assistant" do
      service = RagAssistantService.new(user: @owner, project: @project)

      stub_class_method(Ai::EmbeddingClient, :new, FakeEmbeddingClient.new(Array.new(1024, 0.9))) do
        stub_class_method(Ai::Client, :new, FakeNoApiKeyClient.new) do
          result = service.ask("Quel est le montant caché ?")
          assert_includes result[:sources], @private_document
        end
      end
    end

    test "un document public reste accessible à l'entrepreneur" do
      service = RagAssistantService.new(user: @roofer, project: @project)

      stub_class_method(Ai::EmbeddingClient, :new, FakeEmbeddingClient.new(Array.new(1024, 0.9))) do
        stub_class_method(Ai::Client, :new, FakeNoApiKeyClient.new) do
          result = service.ask("Quelle garantie sur la toiture ?")
          assert_includes result[:sources], @public_document
        end
      end
    end

    test "un tiers hors chantier n'obtient aucun résultat" do
      outsider = User.create!(email: "outsider_rag@example.com", password: "password123", nom: "Outsider")
      service = RagAssistantService.new(user: outsider, project: @project)

      result = service.ask("Quelque chose")
      assert_equal [], result[:sources]
      assert_nil result[:answer]
    end

    private

    # Double léger — AiRun échoue proprement sans clé API (comportement
    # normal), on vérifie seulement le filtrage des sources, pas la synthèse.
    class FakeNoApiKeyClient
      def run(*)
        "réponse factice"
      end
    end
  end
end
