class UpdateAdministrativePhaseDocuments < ActiveRecord::Migration[8.0]
  def up
    # Trouver la phase Administrative
    phase = DocumentPhase.find_by(name: 'Phase Administrative', category: 'chantier')
    
    if phase
      puts "📋 Mise à jour de la Phase Administrative..."
      
      # Nouvelle configuration avec AER et RIB requis, permis_urbanisme en optionnel
      new_required = ['aer', 'rib', 'certificat_peb_avant']
      new_optional = ['permis_urbanisme', 'plan', 'dossier_prime', 'acte_notarial', 'compromis']
      
      # Mettre à jour les types de documents
      phase.update!(
        required_document_types: new_required,
        optional_document_types: new_optional
      )
      
      puts "  ✅ Phase Administrative mise à jour:"
      puts "     Documents obligatoires: #{new_required.join(', ')}"
      puts "     Documents optionnels: #{new_optional.join(', ')}"
    else
      puts "  ❌ Phase Administrative non trouvée"
    end
  end

  def down
    # Restaurer la configuration précédente
    phase = DocumentPhase.find_by(name: 'Phase Administrative', category: 'chantier')
    
    if phase
      puts "📋 Restauration de la Phase Administrative..."
      
      # Ancienne configuration
      old_required = ['permis_urbanisme', 'certificat_peb_avant']
      old_optional = ['plan', 'dossier_prime', 'acte_notarial', 'compromis']
      
      phase.update!(
        required_document_types: old_required,
        optional_document_types: old_optional
      )
      
      puts "  ✅ Phase Administrative restaurée"
    end
  end
end
