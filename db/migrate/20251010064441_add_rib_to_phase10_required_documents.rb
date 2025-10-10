class AddRibToPhase10RequiredDocuments < ActiveRecord::Migration[8.0]
  def up
    # Trouver la phase 10 (Phase Technique)
    phase = DocumentPhase.find_by(id: 10)

    if phase
      # Ajouter "rib" aux documents obligatoires s'il n'y est pas déjà
      current_required = phase.required_document_types || []
      unless current_required.include?('rib')
        updated_required = current_required + ['rib']
        phase.update!(required_document_types: updated_required)
        puts "✅ RIB ajouté aux documents obligatoires de la phase #{phase.name}"
      else
        puts "ℹ️ RIB déjà présent dans les documents obligatoires de la phase #{phase.name}"
      end
    else
      puts "⚠️ Phase 10 non trouvée"
    end
  end

  def down
    # Retirer "rib" des documents obligatoires
    phase = DocumentPhase.find_by(id: 10)

    if phase
      current_required = phase.required_document_types || []
      if current_required.include?('rib')
        updated_required = current_required - ['rib']
        phase.update!(required_document_types: updated_required)
        puts "✅ RIB retiré des documents obligatoires de la phase #{phase.name}"
      else
        puts "ℹ️ RIB n'était pas présent dans les documents obligatoires de la phase #{phase.name}"
      end
    else
      puts "⚠️ Phase 10 non trouvée"
    end
  end
end
