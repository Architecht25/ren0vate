class ContractTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [:show, :download, :preview]

  def index
    @templates = [
      {
        id: 'architecte_mission_complete',
        title: 'Contrat d\'architecte - Mission complète',
        description: 'Contrat type pour une mission complète d\'architecture incluant conception, dépôt de permis, suivi de chantier et réception des travaux.',
        category: 'Architecte',
        pages: 8,
        sections: ['Objet de la mission', 'Honoraires', 'Délais', 'Responsabilités', 'Assurances', 'Résiliation'],
        legal_compliance: ['Loi Breyne', 'Ordre des Architectes', 'Code civil belge'],
        updated_at: Date.new(2024, 12, 1)
      },
      {
        id: 'architecte_mission_partielle',
        title: 'Contrat d\'architecte - Mission partielle',
        description: 'Contrat pour une mission limitée (plans uniquement, conseil, expertise ponctuelle).',
        category: 'Architecte',
        pages: 6,
        sections: ['Définition de la mission', 'Honoraires', 'Livraisons', 'Propriété intellectuelle'],
        legal_compliance: ['Ordre des Architectes', 'Droit d\'auteur'],
        updated_at: Date.new(2024, 12, 1)
      },
      {
        id: 'entrepreneur_general',
        title: 'Contrat d\'entreprise générale',
        description: 'Contrat type pour travaux de rénovation avec un entrepreneur général. Conforme à la loi Breyne.',
        category: 'Entrepreneur',
        pages: 12,
        sections: ['Description des travaux', 'Prix et révision', 'Délais et pénalités', 'Garanties', 'Réception', 'Assurances obligatoires'],
        legal_compliance: ['Loi Breyne', 'TVA 6%', 'Garantie décennale', 'Assurance RC'],
        updated_at: Date.new(2024, 12, 1)
      },
      {
        id: 'sous_traitant_specialise',
        title: 'Contrat de sous-traitance spécialisée',
        description: 'Contrat pour travaux spécifiques (isolation, chauffage, électricité, etc.) avec garanties adaptées.',
        category: 'Entrepreneur',
        pages: 10,
        sections: ['Travaux spécifiques', 'Conformité technique', 'Garanties produits', 'Coordination chantier'],
        legal_compliance: ['Garantie biennale', 'Certifications produits', 'Normes PEB'],
        updated_at: Date.new(2024, 12, 1)
      },
      {
        id: 'coordinateur_securite',
        title: 'Contrat de coordination sécurité',
        description: 'Contrat pour coordinateur sécurité-santé sur chantier (obligatoire selon taille).',
        category: 'Coordination',
        pages: 7,
        sections: ['Mission de coordination', 'Plan de sécurité', 'Visites de chantier', 'Responsabilités'],
        legal_compliance: ['Arrêté Royal chantiers temporaires', 'Code du bien-être au travail'],
        updated_at: Date.new(2024, 12, 1)
      },
      {
        id: 'bureau_etudes_techniques',
        title: 'Contrat de bureau d\'études techniques',
        description: 'Contrat pour études de stabilité, techniques spéciales (HVAC, électricité), PEB.',
        category: 'Études',
        pages: 8,
        sections: ['Objet des études', 'Livrables', 'Honoraires', 'Responsabilité professionnelle'],
        legal_compliance: ['Ordre des Ingénieurs', 'Assurance RC professionnelle'],
        updated_at: Date.new(2024, 12, 1)
      }
    ]

    @categories = @templates.map { |t| t[:category] }.uniq.sort
  end

  def show
    # Template details page
  end

  def download
    # Generate personalized PDF contract
    respond_to do |format|
      format.pdf do
        render pdf: @template[:id],
               template: 'contract_templates/pdf_template',
               locals: { template: @template },
               disposition: 'attachment'
      end
    end
  end

  def preview
    # Preview template in browser
    respond_to do |format|
      format.html { render layout: 'pdf_preview' }
      format.pdf do
        render pdf: @template[:id],
               template: 'contract_templates/pdf_template',
               locals: { template: @template },
               disposition: 'inline'
      end
    end
  end

  private

  def set_template
    @template = get_all_templates.find { |t| t[:id] == params[:id] }
    redirect_to contract_templates_path, alert: 'Template non trouvé' unless @template
  end

  def get_all_templates
    [
      {
        id: 'architecte_mission_complete',
        title: 'Contrat d\'architecte - Mission complète',
        description: 'Contrat type pour une mission complète d\'architecture incluant conception, dépôt de permis, suivi de chantier et réception des travaux.',
        category: 'Architecte',
        pages: 8,
        sections: ['Objet de la mission', 'Honoraires', 'Délais', 'Responsabilités', 'Assurances', 'Résiliation'],
        legal_compliance: ['Loi Breyne', 'Ordre des Architectes', 'Code civil belge'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_architecte_mission_complete_content
      },
      {
        id: 'architecte_mission_partielle',
        title: 'Contrat d\'architecte - Mission partielle',
        description: 'Contrat pour une mission limitée (plans uniquement, conseil, expertise ponctuelle).',
        category: 'Architecte',
        pages: 6,
        sections: ['Définition de la mission', 'Honoraires', 'Livraisons', 'Propriété intellectuelle'],
        legal_compliance: ['Ordre des Architectes', 'Droit d\'auteur'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_architecte_mission_partielle_content
      },
      {
        id: 'entrepreneur_general',
        title: 'Contrat d\'entreprise générale',
        description: 'Contrat type pour travaux de rénovation avec un entrepreneur général. Conforme à la loi Breyne.',
        category: 'Entrepreneur',
        pages: 12,
        sections: ['Description des travaux', 'Prix et révision', 'Délais et pénalités', 'Garanties', 'Réception', 'Assurances obligatoires'],
        legal_compliance: ['Loi Breyne', 'TVA 6%', 'Garantie décennale', 'Assurance RC'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_entrepreneur_general_content
      },
      {
        id: 'sous_traitant_specialise',
        title: 'Contrat de sous-traitance spécialisée',
        description: 'Contrat pour travaux spécifiques (isolation, chauffage, électricité, etc.) avec garanties adaptées.',
        category: 'Entrepreneur',
        pages: 10,
        sections: ['Travaux spécifiques', 'Conformité technique', 'Garanties produits', 'Coordination chantier'],
        legal_compliance: ['Garantie biennale', 'Certifications produits', 'Normes PEB'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_sous_traitant_content
      },
      {
        id: 'coordinateur_securite',
        title: 'Contrat de coordination sécurité',
        description: 'Contrat pour coordinateur sécurité-santé sur chantier (obligatoire selon taille).',
        category: 'Coordination',
        pages: 7,
        sections: ['Mission de coordination', 'Plan de sécurité', 'Visites de chantier', 'Responsabilités'],
        legal_compliance: ['Arrêté Royal chantiers temporaires', 'Code du bien-être au travail'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_coordinateur_content
      },
      {
        id: 'bureau_etudes_techniques',
        title: 'Contrat de bureau d\'études techniques',
        description: 'Contrat pour études de stabilité, techniques spéciales (HVAC, électricité), PEB.',
        category: 'Études',
        pages: 8,
        sections: ['Objet des études', 'Livrables', 'Honoraires', 'Responsabilité professionnelle'],
        legal_compliance: ['Ordre des Ingénieurs', 'Assurance RC professionnelle'],
        updated_at: Date.new(2024, 12, 1),
        content: generate_bureau_etudes_content
      }
    ]
  end

  # Content generators for each template type
  def generate_architecte_mission_complete_content
    {
      parties: {
        client: '[NOM ET PRÉNOM DU CLIENT]',
        adresse_client: '[ADRESSE COMPLÈTE]',
        architecte: '[NOM DE L\'ARCHITECTE]',
        numero_ordre: '[N° ORDRE DES ARCHITECTES]',
        adresse_architecte: '[ADRESSE CABINET]'
      },
      sections: {
        objet: 'Mission complète de conception et de suivi de travaux de rénovation énergétique...',
        honoraires: 'Les honoraires sont calculés selon le barème de l\'Ordre des Architectes...',
        delais: 'Planning prévisionnel de la mission...',
        assurances: 'L\'architecte dispose d\'une assurance responsabilité civile professionnelle...'
      }
    }
  end

  def generate_architecte_mission_partielle_content
    { sections: { mission: 'Mission limitée définie comme suit...', livraisons: 'Plans et documents à livrer...' } }
  end

  def generate_entrepreneur_general_content
    {
      sections: {
        travaux: 'Description détaillée des travaux de rénovation...',
        prix: 'Prix forfaitaire conforme à la loi Breyne...',
        garanties: 'Garantie décennale, biennale et parfait achèvement...',
        assurances: 'Assurances obligatoires: RC chantier, tous risques...'
      }
    }
  end

  def generate_sous_traitant_content
    { sections: { specialite: 'Travaux spécialisés définis...', conformite: 'Respect des normes techniques...' } }
  end

  def generate_coordinateur_content
    { sections: { mission: 'Coordination sécurité-santé...', visites: 'Planning des visites de chantier...' } }
  end

  def generate_bureau_etudes_content
    { sections: { etudes: 'Études techniques à réaliser...', responsabilite: 'Responsabilité professionnelle...' } }
  end
end
