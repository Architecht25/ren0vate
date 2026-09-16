module PropertySaleReadiness
  extend ActiveSupport::Concern

  # Documents légaux incontournables pour une vente (selon droit belge)
  DOCS_VENTE_OBLIGATOIRES = {
    'certificat_peb'           => 'Certificat PEB (obligatoire lors de la vente)',
    'attestation_conformite'   => 'Attestation de conformité électrique',
    'permis_urbanisme'         => 'Permis d\'urbanisme des travaux réalisés',
    'acte_notarial'            => 'Acte notarial / titre de propriété'
  }.freeze

  # Documents DIU à transmettre à l'acheteur
  DOCS_DIU_TRANSMISSION = {
    'plan_diu'                 => 'Plans des travaux (DIU)',
    'fiche_technique'          => 'Fiches techniques matériaux',
    'notice_equipement'        => 'Notices d\'équipements',
    'fiche_securite_materiaux' => 'Fiches de sécurité matériaux',
    'certificat_garantie'      => 'Certificats de garantie',
    'instruction_entretien'    => 'Instructions d\'entretien',
    'assurance_decennale'      => 'Assurances décennales entrepreneurs',
    'facture'                  => 'Factures des travaux réalisés'
  }.freeze

  def statut_vente_label
    case statut_vente
    when 'en_vente' then 'En vente'
    when 'vendu'    then 'Vendu'
    else 'Actif'
    end
  end

  def statut_vente_badge_class
    case statut_vente
    when 'en_vente' then 'bg-warning text-dark'
    when 'vendu'    then 'bg-success'
    else 'bg-secondary'
    end
  end

  # Vérifie la présence des documents légaux obligatoires pour la vente
  def checklist_vente
    all_docs = documents.pluck(:type_document).uniq
    # Aussi chercher dans les projets liés
    project_docs = Document.where(project_id: projects.pluck(:id)).pluck(:type_document).uniq
    present_types = (all_docs + project_docs).uniq

    DOCS_VENTE_OBLIGATOIRES.map do |type, label|
      present = present_types.include?(type) ||
                (type == 'certificat_peb' && peb_certificate_value.present?)
      { type: type, label: label, present: present }
    end
  end

  # Vérifie la présence des documents DIU à transmettre
  def checklist_diu
    project_docs = Document.where(project_id: projects.pluck(:id)).pluck(:type_document)
    property_docs = documents.pluck(:type_document)
    present_types = (project_docs + property_docs).uniq

    DOCS_DIU_TRANSMISSION.map do |type, label|
      { type: type, label: label, present: present_types.include?(type) }
    end
  end

  def vente_readiness_score
    items = checklist_vente + checklist_diu
    return 0 if items.empty?
    (items.count { |i| i[:present] }.to_f / items.size * 100).round
  end
end
