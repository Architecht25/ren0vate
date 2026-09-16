# Configuration d'affichage des types de documents pour le dashboard "documents"
# (legacy pour transition — le nouveau système de phases via DocumentPhase/
# DocumentPhaseCalculatorService fait progressivement le même travail).
module DocumentTypeCatalog
  CONFIG = {
      'aer' => {
        title: '📋 AER - Avertissements Extrait de Rôle',
        image: 'aer.webp',
        conditions: [
          'Avertissements extrait de rôle récents',
          'Documents fiscaux officiels',
          'Maximum 1 an d\'ancienneté'
        ],
        priority: 'required'
      },
      'rib' => {
        title: '🏦 RIB - Relevé d\'Identité Bancaire',
        image: 'rib.webp',
        conditions: [
          'Relevé d\'identité bancaire officiel',
          'Compte au nom du demandeur',
          'Document récent et lisible'
        ],
        priority: 'required'
      },
      'devis' => {
        title: '📄 Devis/métré',
        image: 'devis.webp',
        conditions: [
          'Être signé par l\'architecte, budgété et quantifié obligatoirement',
          'Minimum 3 devis recommandés'
        ],
        priority: 'required'
      },
      'facture' => {
        title: '🧾 Factures',
        image: 'facture.webp',
        conditions: [
          'Établies au nom du demandeur de la prime',
          'Adresse du chantier + description travaux + budget',
          'Montant total = montant du devis',
          'Maximum 2 ans d\'ancienneté'
        ],
        priority: 'required'
      },
      'etat_avancement' => {
        title: '📸 États d\'avancement',
        image: 'avancement.webp',
        conditions: [
          'Photos pendant les travaux',
          'Progression documentée'
        ],
        priority: 'recommended'
      },
      'attestation_entrepreneur' => {
        title: '📋 Attestations entrepreneur',
        image: 'entrepreneur.webp',
        conditions: [
          'Signées et cachetées par l\'entrepreneur',
          'Types: Avant/Pendant/Après'
        ],
        priority: 'required'
      },
      'certificat_peb' => {
        title: '📋 Certificat PEB',
        image: 'certificat.webp',
        conditions: [
          'PEB avant ET après travaux',
          'Ventilation conforme'
        ],
        priority: 'required'
      },
      'photo' => {
        title: '📸 Preuves photo',
        image: 'photo.webp',
        conditions: [
          'Obligatoire pour châssis',
          'Recommandé pour autres travaux',
          'Étapes: Avant/Pendant/Après'
        ],
        priority: 'recommended'
      },
      'certificat_label' => {
        title: '🏷️ Certificats label européen',
        image: 'label.avif',
        conditions: [
          'Pompe à chaleur ou chauffe-eau thermodynamique',
          'Label énergétique certifié'
        ],
        priority: 'optional'
      },
      'attestation_conformite' => {
        title: '⚡ Attestation conformité électrique',
        image: 'conformité.webp',
        conditions: [
          'Attestation après travaux',
          'Conformité électrique certifiée'
        ],
        priority: 'required'
      },
      'plan' => {
        title: '🏠 Plans',
        image: 'plan.webp',
        conditions: [
          'Plans avant travaux',
          'Schémas techniques si nécessaire'
        ],
        priority: 'optional'
      },
      'permis_urbanisme' => {
        title: '🏛️ Permis d\'urbanisme',
        image: 'Permis.jpeg',
        conditions: [
          'Si requis selon travaux',
          'Permis accordé avant travaux'
        ],
        priority: 'optional'
      },
      'dossier_prime' => {
        title: '💰 Dossier primes',
        image: 'prime.jpg',
        conditions: [
          'Primes acceptées/refusées',
          'Historique des demandes'
        ],
        priority: 'optional'
      },
      'certificat_protection' => {
        title: '🛡️ Client protégé',
        image: 'protege.jpg',
        conditions: [
          'Certificat de protection consommateur',
          'Si applicable'
        ],
        priority: 'optional'
      },
      'acte_notarial' => {
        title: '📜 Acte notarial',
        image: 'acte_notarial.jpg',
        conditions: [
          'Acte notarié de la propriété',
          'Document officiel de propriété'
        ],
        priority: 'optional'
      },
      'compromis' => {
        title: '🤝 Compromis',
        image: 'compromis.jpg',
        conditions: [
          'Compromis de vente signé',
          'Accord préliminaire d\'achat'
        ],
        priority: 'optional'
      },
      'rapport_audit_energetique' => {
        title: '📊 Rapport d\'audit énergétique',
        image: 'audit_energetique.webp',
        conditions: [
          'Rapport d\'audit énergétique certifié',
          'Analyse complète de la performance',
          'Recommandations d\'amélioration'
        ],
        priority: 'required'
      }
  }.freeze
end
