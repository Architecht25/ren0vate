class UpdatePhaseReceptionOptionalDocuments < ActiveRecord::Migration[8.0]
  def up
    # Mettre à jour la Phase Réception pour remplacer 'photo' par 'fiche_technique'
    # dans les documents optionnels
    phase_reception = DocumentPhase.find_by(name: 'Phase Réception')

    if phase_reception
      # Remplacer 'photo' par 'fiche_technique' dans les documents optionnels
      new_optional_types = phase_reception.optional_document_types.dup
      if new_optional_types.include?('photo')
        new_optional_types.delete('photo')
        new_optional_types << 'fiche_technique' unless new_optional_types.include?('fiche_technique')

        phase_reception.update!(optional_document_types: new_optional_types)

        puts "✅ Phase Réception mise à jour avec les fiches techniques"
        puts "   Documents optionnels: #{phase_reception.optional_document_types.join(', ')}"
      else
        puts "ℹ️  Phase Réception déjà à jour"
      end
    else
      puts "⚠️  Phase Réception non trouvée"
    end
  end

  def down
    # Revenir à l'état précédent (remettre 'photo' à la place de 'fiche_technique')
    phase_reception = DocumentPhase.find_by(name: 'Phase Réception')

    if phase_reception
      new_optional_types = phase_reception.optional_document_types.dup
      if new_optional_types.include?('fiche_technique')
        new_optional_types.delete('fiche_technique')
        new_optional_types << 'photo' unless new_optional_types.include?('photo')

        phase_reception.update!(optional_document_types: new_optional_types)

        puts "↩️  Phase Réception restaurée avec photos"
        puts "   Documents optionnels: #{phase_reception.optional_document_types.join(', ')}"
      end
    end
  end
end
