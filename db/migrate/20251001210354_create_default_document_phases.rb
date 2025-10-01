class CreateDefaultDocumentPhases < ActiveRecord::Migration[8.0]
  def up
    # Phases par défaut pour les chantiers
    default_phases = [
      {
        name: 'Phase Administrative',
        description: 'Permis, autorisations et diagnostics réglementaires',
        icon: '🏛️',
        color: 'primary',
        position: 1,
        required_document_types: ['permis_urbanisme', 'certificat_peb'],
        optional_document_types: ['plan', 'dossier_prime', 'acte_notarial', 'compromis'],
        category: 'chantier'
      },
      {
        name: 'Phase Technique',
        description: 'Plans, devis et études techniques',
        icon: '🔧',
        color: 'info',
        position: 2,
        required_document_types: ['devis', 'bordereau_chassis', 'certificat_label'],
        optional_document_types: [],
        category: 'chantier'
      },
      {
        name: 'Phase Exécution',
        description: 'Factures, états d\'avancement et rapports de chantier',
        icon: '📋',
        color: 'warning',
        position: 3,
        required_document_types: ['facture', 'attestation_entrepreneur', 'photo_chassis'],
        optional_document_types: ['etat_avancement', 'photo', 'attestation_conformite'],
        category: 'chantier'
      },
      {
        name: 'Phase Réception',
        description: 'Conformité, garanties et finalisation',
        icon: '✅',
        color: 'success',
        position: 4,
        required_document_types: ['certificat_peb', 'attestation_conformite'],
        optional_document_types: ['certificat_protection', 'photo'],
        category: 'chantier'
      }
    ]

    default_phases.each do |phase_data|
      # Vérifier si la phase existe déjà
      existing_phase = DocumentPhase.find_by(name: phase_data[:name], category: phase_data[:category])

      unless existing_phase
        DocumentPhase.create!(phase_data)
        puts "✅ Phase créée: #{phase_data[:name]}"
      else
        puts "✅ Phase existante: #{phase_data[:name]}"
      end
    end
  end

  def down
    # Supprimer les phases par défaut créées
    phase_names = ['Phase Administrative', 'Phase Technique', 'Phase Exécution', 'Phase Réception']
    DocumentPhase.where(name: phase_names, category: 'chantier').destroy_all
  end
end
