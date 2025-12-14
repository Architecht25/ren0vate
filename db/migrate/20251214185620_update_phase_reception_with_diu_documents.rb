class UpdatePhaseReceptionWithDiuDocuments < ActiveRecord::Migration[8.0]
  def change
    # Trouver la phase Réception
    phase_reception = DocumentPhase.find_by(name: 'Phase Réception')

    if phase_reception
      # Mettre à jour la liste des documents optionnels avec les nouveaux types DIU
      phase_reception.update(
        optional_document_types: [
          'plan_diu',
          'fiche_technique',
          'notice_equipement',
          'fiche_securite_materiaux',
          'certificat_garantie',
          'instruction_entretien'
        ]
      )
    end
  end
end
