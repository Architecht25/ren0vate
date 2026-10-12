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

  test "parse une réponse encadrée en ```json ... ``` (comportement réel de Claude malgré la consigne)" do
    suggestion_json = { document_type: "devis", lot_key: "toiture", phase_key: "chantier", confidence: 0.9 }.to_json
    fenced = "```json\n#{suggestion_json}\n```"

    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response(fenced))) do
      ProjectDocumentIngestionJob.perform_now(@version.id)
    end

    @document.reload
    assert_equal "devis", @document.ai_suggestion["ai_suggested_document_type"]
    assert_equal "toiture", @document.ai_suggestion["ai_suggested_lot_key"]
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

  test "indexe le texte OCR en chunks avec embeddings quand Voyage AI est disponible (Lot 5)" do
    previous_voyage_key = ENV["VOYAGE_API_KEY"]
    ENV["VOYAGE_API_KEY"] = "test-key"

    fake_voyage_response = Struct.new(:success?, :parsed_response).new(
      true, { "data" => [{ "index" => 0, "embedding" => Array.new(1024, 0.1) }] }
    )

    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response('{"document_type":"devis"}'))) do
      stub_class_method(HTTParty, :post, ->(*) { fake_voyage_response }) do
        ProjectDocumentIngestionJob.perform_now(@version.id)
      end
    end

    assert @version.chunks.any?
    assert_equal 1024, @version.chunks.first.embedding.to_a.length
  ensure
    ENV["VOYAGE_API_KEY"] = previous_voyage_key
  end

  test "un certificat PEB déposé en V2 crée un PebDonnee et synchronise la propriété (bug trouvé lors du test E2E du 12/10/2026)" do
    property = @project.property
    # La fixture property ne porte pas d'adresse complète (hors scope de ce
    # test) — update_columns contourne la validation pour isoler ce qu'on
    # teste ici : la synchronisation PEB, pas la validité de l'adresse.
    property.update_columns(rue: "Rue Test", numero: "1", code_postal: "1000", commune: "Bruxelles", region: "wallonie")
    peb_document = @project.project_documents.create!(title: "Certificat PEB", document_type: "certificat_peb_avant", uploaded_by: @owner)
    peb_version = peb_document.versions.create!(
      created_by: @owner,
      file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf")
    )

    fake_peb_result = {
      success: true, region: "wallonie", label_peb: "D", score_ep: 320,
      date_certificat: Date.current, confiance_ocr: 90, extraction_complete: true
    }
    fake_peb_service = Object.new
    fake_peb_service.define_singleton_method(:extraire_donnees_peb) { fake_peb_result }

    assert_difference "PebDonnee.count", 1 do
      stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response('{"document_type":"certificat_peb_avant"}'))) do
        stub_class_method(Ocr::PebOcrService, :new, fake_peb_service) do
          ProjectDocumentIngestionJob.perform_now(peb_version.id)
        end
      end
    end

    peb_donnee = PebDonnee.order(created_at: :desc).first
    assert_equal property, peb_donnee.property
    assert_equal "D", peb_donnee.label_peb
    assert_equal "D", peb_donnee.property.reload.certificat_peb_wallonie
  end

  test "n'indexe rien sans clé Voyage AI, sans faire échouer le job" do
    ENV["VOYAGE_API_KEY"] = nil

    stub_class_method(Anthropic::Client, :new, FakeAnthropicClient.new(response: fake_response('{"document_type":"devis"}'))) do
      ProjectDocumentIngestionJob.perform_now(@version.id)
    end

    assert @version.chunks.none?
    assert @version.reload.ocr_text.present?
  end
end
