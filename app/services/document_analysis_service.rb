class DocumentAnalysisService
  def initialize(property, region)
    @property = property
    @region = region.downcase
  end

  def required_documents
    @required_documents ||= case @region
    when 'bruxelles'
      bruxelles_required_documents
    when 'wallonie'
      wallonie_required_documents
    when 'flandre'
      flandre_required_documents
    else
      general_required_documents
    end
  end

  def missing_documents
    existing_types = @property.documents.pluck(:type_document).map(&:downcase)
    required_documents.reject { |doc| existing_types.include?(doc[:type].downcase) }
  end

  def completion_percentage
    return 0 if required_documents.empty?

    existing_count = required_documents.count { |doc|
      @property.documents.exists?(type_document: doc[:type])
    }
    (existing_count.to_f / required_documents.count * 100).round
  end

  def next_actions
    missing = missing_documents
    return [] if missing.empty?

    actions = []

    # Priorité haute
    critical_missing = missing.select { |doc| doc[:priority] == 'critical' }
    if critical_missing.any?
      actions << {
        type: 'critical',
        title: 'Documents critiques manquants',
        description: "#{critical_missing.count} documents obligatoires à fournir",
        action: 'Uploader maintenant',
        documents: critical_missing
      }
    end

    # Priorité normale
    normal_missing = missing.select { |doc| doc[:priority] == 'normal' }
    if normal_missing.any?
      actions << {
        type: 'normal',
        title: 'Documents complémentaires',
        description: "#{normal_missing.count} documents recommandés",
        action: 'Compléter le dossier',
        documents: normal_missing
      }
    end

    actions
  end

  def timing_status
    case @region
    when 'bruxelles'
      { deadline: '12 mois après facture solde', processing_time: '3-6 mois' }
    when 'wallonie'
      { deadline: '24 mois après facture solde', processing_time: '2-4 mois' }
    when 'flandre'
      { deadline: '12 mois après facture solde', processing_time: '2-3 mois' }
    else
      { deadline: 'Variable selon région', processing_time: '3-6 mois' }
    end
  end

  private

  def bruxelles_required_documents
    [
      { type: 'facture_travaux', name: 'Factures des travaux', priority: 'critical', description: 'Factures émises maximum 12 mois avant la demande' },
      { type: 'certificat_peb', name: 'Certificat PEB', priority: 'critical', description: 'Certificat de performance énergétique du bâtiment' },
      { type: 'bce_entrepreneur', name: 'Numéro BCE entrepreneur', priority: 'critical', description: 'Attestation BCE de l\'entrepreneur agréé' },
      { type: 'photos_travaux', name: 'Photos avant/après', priority: 'normal', description: 'Photos documentant la réalisation des travaux' },
      { type: 'devis_detaille', name: 'Devis détaillés', priority: 'normal', description: 'Devis préalables aux travaux réalisés' }
    ]
  end

  def wallonie_required_documents
    [
      { type: 'facture_travaux', name: 'Factures des travaux', priority: 'critical', description: 'Factures émises maximum 24 mois avant la demande' },
      { type: 'devis_detaille', name: 'Devis détaillés', priority: 'critical', description: 'Devis préalables aux travaux avec détail technique' },
      { type: 'attestation_entrepreneur', name: 'Attestation entrepreneur', priority: 'critical', description: 'Attestation technique complétée par l\'entrepreneur' },
      { type: 'rib_bancaire', name: 'RIB bancaire', priority: 'critical', description: 'Relevé d\'identité bancaire avec signature banque' },
      { type: 'photos_travaux', name: 'Photos représentatives', priority: 'normal', description: 'Photos documentant la réalisation des travaux' }
    ]
  end

  def flandre_required_documents
    [
      { type: 'facture_travaux', name: 'Factures avec TVA', priority: 'critical', description: 'Factures détaillées avec mention TVA' },
      { type: 'code_ean', name: 'Code EAN logement', priority: 'critical', description: 'Code EAN du compteur du logement rénové' },
      { type: 'attestation_conformite', name: 'Attestation conformité', priority: 'critical', description: 'Attestation de conformité aux normes flamandes' },
      { type: 'preuve_achevement', name: 'Preuves achèvement', priority: 'normal', description: 'Documents prouvant l\'achèvement complet des travaux' },
      { type: 'photos_travaux', name: 'Photos des travaux', priority: 'normal', description: 'Documentation visuelle des travaux réalisés' }
    ]
  end

  def general_required_documents
    [
      { type: 'facture_travaux', name: 'Factures des travaux', priority: 'critical', description: 'Factures relatives aux travaux réalisés' },
      { type: 'documents_techniques', name: 'Documents techniques', priority: 'critical', description: 'Plans, devis et spécifications techniques' },
      { type: 'preuve_conformite', name: 'Preuves conformité', priority: 'normal', description: 'Attestations de conformité réglementaire' }
    ]
  end
end
