module Devis
  # Construit (sans la sauvegarder) un DevisDonnee à partir du résultat OCR/Claude
  # d'un document — même rôle que Factures::CreateFromOcrService, pour le même
  # besoin : OcrController#scan_devis (workflow dédié) construit son DevisDonnee
  # inline, DocumentsController (upload générique, type_document: "devis") le
  # jetait jusqu'ici après l'appel Claude, sans jamais le persister (bug trouvé
  # lors du test E2E du 12/10/2026 — le devis n'apparaissait alors ni dans le
  # budget, ni dans le Gantt, ni dans le comparateur, ni dans Garanties).
  class CreateFromOcrService
    def self.call(document:, ocr_result:, project:, categorie_emetteur: "entrepreneur")
      new(document, ocr_result, project, categorie_emetteur).call
    end

    def initialize(document, ocr_result, project, categorie_emetteur)
      @document = document
      @ocr_result = ocr_result
      @project = project
      @categorie_emetteur = categorie_emetteur
    end

    def call
      DevisDonnee.new(devis_attributes)
    end

    private

    def devis_attributes
      {
        document: @document,
        project: @project,
        categorie_emetteur: @categorie_emetteur,
        nom_entreprise: @ocr_result[:nom_entreprise],
        numero_bce_entreprise: @ocr_result[:numero_bce_entreprise],
        numero_tva_entreprise: @ocr_result[:numero_tva_entreprise],
        montant_total_htva: @ocr_result[:montant_total_htva],
        montant_total_tvac: @ocr_result[:montant_total_tvac],
        taux_tva: @ocr_result[:taux_tva],
        date_devis: @ocr_result[:date_devis],
        numero_devis: @ocr_result[:numero_devis],
        validite_devis: @ocr_result[:validite_devis],
        types_travaux_detectes: @ocr_result[:types_travaux_detectes],
        surface_travaux: @ocr_result[:surface_travaux],
        confiance_ocr: @ocr_result[:confiance_extraction],
        extraction_complete: @ocr_result[:extraction_complete],
        texte_ocr_brut: @ocr_result[:texte_brut],
        donnees_extraites: @ocr_result[:donnees_devis].to_h,
        analyse_contenu_statut: "en_cours"
      }
    end
  end
end
