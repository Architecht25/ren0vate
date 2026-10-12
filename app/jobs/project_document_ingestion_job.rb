# V2 — Lot 2 : ingestion intelligente (cahier des charges §8.1). Toujours en
# job asynchrone, jamais en requête HTTP — pattern déjà établi en V1 pour
# l'OCR/extraction Claude (PebExtractionJob, AudioEnergExtractionJob) après
# deux incidents H12 Heroku en traitement synchrone (voir docs/AUDIT_V1.md
# §2.3). OCR via Ocr::OcrService (réutilisé tel quel — accepte directement
# un attachment Active Storage). Classification via Ai::Client : l'IA ne
# fait que PROPOSER type/lot/phase/montant, jamais appliqué automatiquement
# — voir ProjectDocumentsController#accept_suggestion pour la confirmation
# humaine explicite.
class ProjectDocumentIngestionJob < ApplicationJob
  queue_as :default

  def perform(project_document_version_id)
    version = ProjectDocumentVersion.find_by(id: project_document_version_id)
    return unless version&.file&.attached?

    ocr_result = version.file.blob.open do |tempfile|
      adapter = Documents::ActiveStorageFileAdapter.new(tempfile, version.file.content_type)
      Ocr::OcrService.new(adapter).call
    end
    ocr_text = ocr_result[:text].presence

    suggestion = classify(version, ocr_text)
    version.update_columns(ocr_text: ocr_text, extracted_metadata: version.extracted_metadata.merge(suggestion || {}))

    sync_peb_donnee(version)
    index_for_search(version, ocr_text)

    AuditEvent.record!(
      action: "project_document.ingested",
      auditable: version.project_document,
      event_data: { ocr_confidence: ocr_result[:confidence], ocr_method: ocr_result[:method] }
    )
  rescue Ai::BudgetExceededError => e
    Rails.logger.warn "[ProjectDocumentIngestionJob] #{e.message}"
  end

  private

  # Un certificat PEB déposé via la base documentaire V2 (ProjectDocument)
  # n'alimentait jusqu'ici jamais PebDonnee (base V1, lue par le simulateur de
  # primes via Property#peb_donnees / Subsidies::BudgetEstimatorService) — le
  # PEB existait bien dans l'app, juste invisible du simulateur (silo trouvé
  # lors du test E2E toiture Wallonie du 12/10/2026). Même extraction que le
  # flux V1 dédié (OcrController#scan_peb + PebExtractionJob), appliquée ici
  # en synchrone car l'ingestion V2 tourne déjà en job asynchrone.
  PEB_DOCUMENT_TYPES_TO_PHASE = {
    "certificat_peb" => "avant_travaux",
    "certificat_peb_avant" => "avant_travaux",
    "certificat_peb_apres" => "apres_travaux"
  }.freeze

  def sync_peb_donnee(version)
    document = version.project_document
    phase = PEB_DOCUMENT_TYPES_TO_PHASE[document.document_type]
    property = document.project.property
    return unless phase && property

    peb_donnee = PebDonnee.create!(property: property, project: document.project, user: version.created_by, phase: phase, statut: "en_cours")

    result = version.file.blob.open do |tempfile|
      adapter = Documents::ActiveStorageFileAdapter.new(tempfile, version.file.content_type)
      Ocr::PebOcrService.new(adapter).extraire_donnees_peb
    end

    if result[:success]
      peb_donnee.appliquer_resultat_extraction!(result)
      peb_donnee.synchroniser_propriete!(result)
    else
      peb_donnee.marquer_echec_extraction!(result[:error])
    end
  rescue StandardError => e
    Rails.logger.error "[ProjectDocumentIngestionJob] sync_peb_donnee échoué pour version##{version.id}: #{e.message}"
  end

  # V2 — Lot 5 : indexation pour l'assistant sur dossier (cahier des charges
  # §8.7). Pas d'exception propagée si Voyage AI est indisponible/sans clé —
  # l'ingestion (OCR + classification) reste utile même sans RAG.
  def index_for_search(version, ocr_text)
    return if ocr_text.blank?

    chunks = ProjectDocuments::ChunkingService.call(ocr_text)
    return if chunks.empty?

    embeddings = Ai::EmbeddingClient.new.embed(chunks)
    return if embeddings.nil?

    version.chunks.delete_all
    chunks.each_with_index do |content, index|
      version.chunks.create!(
        project: version.project_document.project,
        content: content,
        chunk_index: index,
        embedding: embeddings[index]
      )
    end
  end

  def classify(version, ocr_text)
    return nil if ocr_text.blank?

    document = version.project_document
    client = Ai::Client.new(project: document.project)
    response = client.run(
      :document_classification,
      system: system_prompt(document.project),
      messages: [{ role: "user", content: ocr_text.truncate(6000) }],
      subject: version
    )
    parse_response(response)
  end

  def system_prompt(project)
    lot_keys = project.lots.ordered.pluck(:key)
    phase_keys = project.phases.ordered.pluck(:key)

    <<~PROMPT
      Tu classes un document déposé sur un chantier de rénovation belge.
      Réponds UNIQUEMENT avec un objet JSON valide, sans aucun texte autour, avec exactement ces clés :
      {
        "document_type": un type parmi #{ProjectDocument::DOCUMENT_TYPES.join(', ')},
        "lot_key": un lot parmi #{lot_keys.join(', ')}, ou null si incertain,
        "phase_key": une phase parmi #{phase_keys.join(', ')}, ou null si incertaine,
        "montant_ttc": le montant total TTC en euros si présent dans le texte, sinon null,
        "confidence": ta confiance entre 0 et 1
      }
      Le texte du document (extrait par OCR, peut contenir des erreurs de reconnaissance) suit.
    PROMPT
  end

  def parse_response(response)
    return nil if response.blank?

    # Claude encadre parfois sa réponse en ```json ... ``` malgré la consigne
    # de ne renvoyer que du JSON brut — même contournement que
    # Bots::DevisClaudeService#parse_claude_response (bug trouvé lors du test
    # E2E du 12/10/2026 : JSON.parse direct échouait systématiquement,
    # désactivant complètement la proposition de classification IA).
    json_str = response[/\{.*\}/m]
    return nil unless json_str

    json = JSON.parse(json_str)
    {
      "ai_suggested_document_type" => json["document_type"],
      "ai_suggested_lot_key" => json["lot_key"],
      "ai_suggested_phase_key" => json["phase_key"],
      "ai_suggested_montant_ttc" => json["montant_ttc"],
      "ai_confidence" => json["confidence"]
    }.compact
  rescue JSON::ParserError => e
    Rails.logger.warn "[ProjectDocumentIngestionJob] réponse IA non-JSON : #{e.message}"
    nil
  end
end
