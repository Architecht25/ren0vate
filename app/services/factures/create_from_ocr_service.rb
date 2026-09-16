module Factures
  # Construit (sans la sauvegarder) une Facture à partir du résultat OCR/Claude
  # d'un document — utilisé par FacturesController (workflow dédié factures) et
  # DocumentsController (facture créée en sous-produit d'un upload générique).
  # Chaque appelant garde la responsabilité du save/save! et de la gestion d'erreur,
  # qui diffère entre les deux flux (API JSON vs upload multi-documents tolérant).
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
      Facture.new(facture_attributes)
    end

    private

    def facture_attributes
      donnees = @ocr_result[:donnees_facture]

      {
        document: @document,
        project: @project,
        property: @document.property || @project.property,
        montant: donnees[:montant] || 0,
        numero_facture: donnees[:numero_facture],
        date_facture: donnees[:date_facture],
        type_facture: donnees[:type_facture] || 'facture',
        nom_entreprise: donnees[:nom_entreprise],
        numero_bce_entreprise: donnees[:numero_bce],
        adresse_entreprise: donnees[:adresse_entreprise],
        telephone_entreprise: donnees[:telephone_entreprise],
        email_entreprise: donnees[:email_entreprise],
        montant_ht: donnees[:montant_ht],
        montant_tva: donnees[:montant_tva],
        taux_tva: donnees[:taux_tva],
        confiance_ocr: @ocr_result[:confiance_extraction],
        extraction_complete: @ocr_result[:extraction_complete],
        texte_ocr_brut: @ocr_result[:texte_brut],
        donnees_extraites: donnees,
        type_intervenant: Factures::TypeIntervenantDetector.call(donnees[:nom_entreprise], @project),
        valide_manuellement: false
      }
    end
  end
end
