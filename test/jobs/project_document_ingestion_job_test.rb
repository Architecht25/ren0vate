require "test_helper"

class ProjectDocumentIngestionJobTest < ActiveSupport::TestCase
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

    @owner = users(:freemium_user)
    @project = projects(:one)
    # Les fixtures passent par un INSERT direct, sans callback after_create —
    # Project#seed_default_lots_and_phases ne s'applique qu'aux projets créés via .create!
    @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @project.phases.create!(key: "chantier", name: "Chantier", position: 0)
    @document = @project.project_documents.create!(title: "Devis", document_type: "devis", uploaded_by: @owner)
    @version = @document.versions.create!(
      created_by: @owner,
      file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf")
    )
  end

  teardown do
    ENV["ANTHROPIC_API_KEY"] = @previous_key
  end

  def fake_response(json_text)
    FakeMessage.new([FakeTextBlock.new(:text, json_text)])
  end

  test "stocke le texte OCR et la suggestion de classification sur la version" do
    suggestion_json = {
      document_type: "devis", lot_key: "toiture", phase_key: "chantier", montant_ttc: 1500.0, confidence: 0.92
    }.to_json

    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response(suggestion_json))) do
      ProjectDocumentIngestionJob.perform_now(@version.id)
    end

    @version.reload
    assert @version.ocr_text.present?
    assert_equal "devis", @version.extracted_metadata["ai_suggested_document_type"]
    assert_equal "toiture", @version.extracted_metadata["ai_suggested_lot_key"]
    assert_equal 0.92, @version.extracted_metadata["ai_confidence"]

    @document.reload
    assert_equal({ "ai_suggested_document_type" => "devis", "ai_suggested_lot_key" => "toiture", "ai_suggested_phase_key" => "chantier", "ai_suggested_montant_ttc" => 1500.0, "ai_confidence" => 0.92 }, @document.ai_suggestion)
  end

  test "une réponse non-JSON n'écrase pas les métadonnées et ne plante pas le job" do
    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response("ceci n'est pas du JSON"))) do
      ProjectDocumentIngestionJob.perform_now(@version.id)
    end

    @version.reload
    assert @version.ocr_text.present?
    assert_nil @document.reload.ai_suggestion
  end

  test "accept_suggestion applique le lot/phase suggérés et valide l'AiRun d'origine" do
    toiture = @project.lots.find_by(key: "toiture")
    suggestion_json = { document_type: "devis", lot_key: "toiture", phase_key: "chantier", confidence: 0.9 }.to_json

    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response(suggestion_json))) do
      ProjectDocumentIngestionJob.perform_now(@version.id)
    end

    @document.reload
    assert @document.apply_ai_suggestion!
    assert_equal toiture, @document.lot
    assert_equal "chantier", @document.phase.key
  end
end
