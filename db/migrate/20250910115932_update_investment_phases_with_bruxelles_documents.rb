class UpdateInvestmentPhasesWithBruxellesDocuments < ActiveRecord::Migration[8.0]
  def up
    # Mise à jour des phases d'investissement avec les documents des aides Bruxelles

    # Phase 1: Administrative & Éligibilité
    phase1 = DocumentPhase.find_by(name: 'Administrative (Investissement)') ||
             DocumentPhase.find_by(position: 5, category: 'investissement')
    if phase1
      phase1.update!(
        name: 'Administrative & Éligibilité',
        description: 'Validation de l\'éligibilité entreprise et préparation administrative complète',
        required_document_types: [
          'attestation_bancaire_rib',
          'justificatifs_eligibilite_entreprise',
          'numero_entreprise_bce',
          'comptes_annuels_conformes'
        ],
        optional_document_types: [
          'copie_mandat',
          'statuts_entreprise',
          'attestation_assurance',
          'plan_diversite_actif',
          'pourcentage_financement_public',
          'preuve_exemplarite_sociale',
          'preuve_exemplarite_environnementale'
        ]
      )
    end

    # Phase 2: Demande & Autorisations Préalables
    phase2 = DocumentPhase.find_by(name: 'Introduction Préalable') ||
             DocumentPhase.find_by(position: 6, category: 'investissement')
    if phase2
      phase2.update!(
        name: 'Demande & Autorisations Préalables',
        description: 'Introduction des demandes officielles et obtention des autorisations préalables',
        required_document_types: [
          'demande_via_monbee',
          'formulaire_autorisation_prealable',
          'devis_detailles_investissements',
          'avis_reception_confirmant_introduction'
        ],
        optional_document_types: [
          'annexes_selon_plateforme',
          'documentation_technique_vehicule',
          'devis_detaille_consultant',
          'cv_references_consultant',
          'documentation_systemes_securisation',
          'engagement_signe_charte_numerique',
          'annexes_consultance_transition',
          'annexes_labels_certificats',
          'documentation_label_vise',
          'budget_previsionnel',
          'plan_investissement'
        ]
      )
    end

    # Phase 3: Exécution & Justificatifs de Réalisation
    phase3 = DocumentPhase.find_by(name: 'Exécution (Investissement)') ||
             DocumentPhase.find_by(position: 7, category: 'investissement')
    if phase3
      phase3.update!(
        name: 'Exécution & Justificatifs de Réalisation',
        description: 'Réalisation des investissements et fourniture des justificatifs de dépenses',
        required_document_types: [
          'factures_acquittees',
          'preuves_paiement',
          'preuves_installation_mise_service',
          'preuves_realisation_programme'
        ],
        optional_document_types: [
          'etat_avancement',
          'photo_chantier',
          'rapport_technique',
          'preuves_utilisation_vehicule',
          'attestation_installateur_fournisseur',
          'justification_efficacite_energetique',
          'justification_economie_ressources',
          'factures_borne_recharge',
          'certificat_conformite_carte_grise',
          'factures_formations',
          'attestation_participation_formation',
          'factures_consultant_preuves_paiement',
          'acte_achat_signe_paye',
          'certificat_immatriculation_vehicule',
          'preuve_transformation_retrofit',
          'preuve_homologation_vehicule'
        ]
      )
    end

    # Phase 4: Liquidation & Finalisation
    phase4 = DocumentPhase.find_by(name: 'Introduction Finale') ||
             DocumentPhase.find_by(position: 8, category: 'investissement')
    if phase4
      phase4.update!(
        name: 'Liquidation & Finalisation',
        description: 'Demande de liquidation finale et clôture administrative du dossier',
        required_document_types: [
          'demande_liquidation',
          'declaration_creance_completee',
          'rapport_final_mission',
          'notification_decision_octroi'
        ],
        optional_document_types: [
          'rapport_mission_livrables',
          'preuves_mise_oeuvre_recommandations',
          'attestation_conformite',
          'garantie_equipements',
          'manuel_utilisation',
          'preuves_respect_charte_numerique',
          'information_depart_travailleur',
          'preuves_installation_accessibilite',
          'rapport_expert_investissements',
          'expert_independant_specialise',
          'bilan_financier_final',
          'mesure_performance_reelle',
          'avis_radiation_vehicule_remplace',
          'preuve_remplacement_zone_basses_emissions'
        ]
      )
    end
  end

  def down
    # Restore original phases if needed
    phase1 = DocumentPhase.find_by(name: 'Administrative & Éligibilité')
    phase1&.update!(
      name: 'Administrative (Investissement)',
      description: 'Validation de l\'éligibilité et préparation administrative',
      required_document_types: ['justificatif_identite', 'numero_entreprise_bce'],
      optional_document_types: ['statuts_entreprise', 'attestation_assurance']
    )

    phase2 = DocumentPhase.find_by(name: 'Demande & Autorisations Préalables')
    phase2&.update!(
      name: 'Introduction Préalable',
      description: 'Demande préalable et validation du projet d\'investissement',
      required_document_types: ['demande_prealable', 'devis'],
      optional_document_types: ['plan', 'budget_previsionnel']
    )

    phase3 = DocumentPhase.find_by(name: 'Exécution & Justificatifs de Réalisation')
    phase3&.update!(
      name: 'Exécution (Investissement)',
      description: 'Réalisation de l\'investissement et suivi des dépenses',
      required_document_types: ['facture', 'preuve_paiement'],
      optional_document_types: ['etat_avancement', 'photo', 'rapport_technique']
    )

    phase4 = DocumentPhase.find_by(name: 'Liquidation & Finalisation')
    phase4&.update!(
      name: 'Introduction Finale',
      description: 'Demande de liquidation et justification finale',
      required_document_types: ['demande_liquidation', 'rapport_final'],
      optional_document_types: ['attestation_conformite', 'garantie', 'manuel_utilisation']
    )
  end
end
