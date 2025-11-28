class UpdateTechnicalPhaseAuditDocument < ActiveRecord::Migration[8.0]
  def change
    # Mettre à jour la Phase Technique pour inclure le rapport_audit_energetique
    phase = DocumentPhase.find_by(name: 'Phase Technique')
    if phase
      current_required = phase.required_document_types || []
      new_required_docs = current_required + ['rapport_audit_energetique']

      phase.update!(
        required_document_types: new_required_docs.uniq
      )

      puts "📋 Mise à jour de la Phase Technique..."
      puts "✅ Phase Technique mise à jour: Documents obligatoires: #{phase.required_document_types.join(', ')}"
    else
      puts "❌ Phase Technique non trouvée"
    end
  end
end
