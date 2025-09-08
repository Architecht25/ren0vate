class UpdatePhaseAdministrativeAuditDocuments < ActiveRecord::Migration[8.0]
  def up
    # Trouver la Phase Administrative
    phase_administrative = DocumentPhase.find_by(name: 'Phase Administrative')
    
    if phase_administrative
      # Ajouter les nouveaux documents obligatoires pour l'audit énergétique
      current_required = phase_administrative.required_document_types || []
      new_required_docs = ['preuve_paiement_audit', 'rapport_audit_energetique', 'copie_carte_identite']
      
      # Fusionner sans doublons
      updated_required = (current_required + new_required_docs).uniq
      
      phase_administrative.update!(required_document_types: updated_required)
      
      puts "✅ Phase Administrative mise à jour avec les documents d'audit obligatoires:"
      new_required_docs.each { |doc| puts "   - #{doc}" }
    else
      puts "❌ Phase Administrative non trouvée"
    end
  end

  def down
    # Retirer les documents d'audit de la Phase Administrative
    phase_administrative = DocumentPhase.find_by(name: 'Phase Administrative')
    
    if phase_administrative
      current_required = phase_administrative.required_document_types || []
      audit_docs = ['preuve_paiement_audit', 'rapport_audit_energetique', 'copie_carte_identite']
      
      updated_required = current_required - audit_docs
      
      phase_administrative.update!(required_document_types: updated_required)
      
      puts "✅ Documents d'audit retirés de la Phase Administrative"
    end
  end
end
