module BordereauChassis
  # Construit (sans la sauvegarder) un BordereauChassisDonnee à partir du résultat
  # OCR/Claude d'un document — même rôle que Factures::CreateFromOcrService, pour
  # le même besoin : OcrController#scan_bordereau_chassis (workflow dédié)
  # construit le sien inline, DocumentsController (upload générique, type_document:
  # "bordereau_chassis") le jetait jusqu'ici après l'appel Claude, sans jamais le
  # persister (bug trouvé lors du test E2E du 12/10/2026, même défaut que pour
  # les devis).
  class CreateFromOcrService
    def self.call(document:, ocr_result:, project:)
      new(document, ocr_result, project).call
    end

    def initialize(document, ocr_result, project)
      @document = document
      @ocr_result = ocr_result
      @project = project
    end

    def call
      BordereauChassisDonnee.new(bordereau_attributes)
    end

    private

    def bordereau_attributes
      {
        document: @document,
        project: @project,
        nom_fabricant: @ocr_result[:nom_fabricant],
        nom_poseur: @ocr_result[:nom_poseur],
        numero_bce_poseur: @ocr_result[:numero_bce_poseur],
        reference_produit: @ocr_result[:reference_produit],
        valeur_uw: @ocr_result[:valeur_uw],
        valeur_ug: @ocr_result[:valeur_ug],
        valeur_uf: @ocr_result[:valeur_uf],
        facteur_solaire: @ocr_result[:facteur_solaire],
        type_vitrage: @ocr_result[:type_vitrage],
        type_chassis: @ocr_result[:type_chassis],
        surface_totale: @ocr_result[:surface_totale],
        nombre_unites: @ocr_result[:nombre_unites],
        date_document: @ocr_result[:date_document],
        numero_document: @ocr_result[:numero_document],
        montant_htva: @ocr_result[:montant_htva],
        montant_tvac: @ocr_result[:montant_tvac],
        taux_tva: @ocr_result[:taux_tva],
        detail_chassis: @ocr_result[:detail_chassis] || [],
        confiance_ocr: @ocr_result[:confiance_extraction],
        extraction_complete: @ocr_result[:extraction_complete],
        texte_ocr_brut: @ocr_result[:texte_brut],
        donnees_extraites: @ocr_result[:donnees_bordereau].to_h
      }
    end
  end
end
