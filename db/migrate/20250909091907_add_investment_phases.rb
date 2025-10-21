class AddInvestmentPhases < ActiveRecord::Migration[8.0]
  def change
    # Recharger le modèle pour s'assurer que la colonne category est disponible
    DocumentPhase.reset_column_information

    # Phases d'investissement
    investment_phases = [
      {
        name: 'Administrative (Investissement)',
        description: 'Validation de l\'éligibilité et préparation administrative',
        icon: '🏛️',
        color: 'primary',
        position: 5,
        category: 'investissement',
        required_document_types: ['justificatif_identite', 'numero_entreprise_bce'],
        optional_document_types: ['statuts_entreprise', 'attestation_assurance']
      },
      {
        name: 'Introduction Préalable',
        description: 'Demande préalable et validation du projet d\'investissement',
        icon: '📝',
        color: 'info',
        position: 6,
        category: 'investissement',
        required_document_types: ['demande_prealable', 'devis'],
        optional_document_types: ['plan', 'budget_previsionnel']
      },
      {
        name: 'Exécution (Investissement)',
        description: 'Réalisation de l\'investissement et suivi des dépenses',
        icon: '🔧',
        color: 'warning',
        position: 7,
        category: 'investissement',
        required_document_types: ['facture', 'preuve_paiement'],
        optional_document_types: ['etat_avancement', 'photo', 'rapport_technique']
      },
      {
        name: 'Introduction Finale',
        description: 'Demande de liquidation et justification finale',
        icon: '✅',
        color: 'success',
        position: 8,
        category: 'investissement',
        required_document_types: ['demande_liquidation', 'rapport_final'],
        optional_document_types: ['attestation_conformite', 'garantie', 'manuel_utilisation']
      }
    ]

    investment_phases.each do |phase_data|
      DocumentPhase.create!(
        name: phase_data[:name],
        description: phase_data[:description],
        icon: phase_data[:icon],
        color: phase_data[:color],
        position: phase_data[:position],
        category: phase_data[:category],
        required_document_types: phase_data[:required_document_types],
        optional_document_types: phase_data[:optional_document_types]
      )
    end
  end

  def down
    DocumentPhase.where(category: 'investissement').destroy_all
  end
end
