class AddPreuvePaiementAuditToPhaseTechnique < ActiveRecord::Migration[8.0]
  def up
    phase = DocumentPhase.find_by(name: 'Phase Technique', category: 'chantier')
    return unless phase

    phase.update!(optional_document_types: (phase.optional_document_types + ['preuve_paiement_audit']).uniq)
  end

  def down
    phase = DocumentPhase.find_by(name: 'Phase Technique', category: 'chantier')
    return unless phase

    phase.update!(optional_document_types: phase.optional_document_types - ['preuve_paiement_audit'])
  end
end
