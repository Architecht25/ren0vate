class FactureValidationService
  include ActiveModel::Model

  attr_accessor :project

  def initialize(project)
    @project = project
  end

  # Méthode principale pour analyser toutes les factures d'un projet
  def analyser_factures
    {
      validation_globale: validation_globale,
      comparaison_devis: comparer_avec_devis,
      alertes_delais: analyser_delais,
      factures_manquantes: detecter_factures_manquantes,
      anomalies: detecter_anomalies,
      recommandations: generer_recommandations
    }
  end

  # Comparer le total des factures avec le devis
  def comparer_avec_devis
    devis = factures_devis.first
    factures_list = factures_travaux

    return { status: 'no_devis', message: 'Aucun devis trouvé' } unless devis
    return { status: 'no_factures', message: 'Aucune facture trouvée' } if factures_list.empty?

    montant_devis = devis.montant
    total_factures = factures_list.sum(&:montant)
    ecart = total_factures - montant_devis
    pourcentage_ecart = ((ecart / montant_devis) * 100).round(2)

    {
      status: determiner_status_ecart(pourcentage_ecart),
      montant_devis: montant_devis,
      total_factures: total_factures,
      ecart: ecart,
      pourcentage_ecart: pourcentage_ecart,
      tolerance: ecart.abs <= (montant_devis * 0.1), # Tolérance de 10%
      message: generer_message_ecart(ecart, pourcentage_ecart),
      details: {
        nombre_factures: factures_list.count,
        factures: factures_list.map { |f| facture_summary(f) }
      }
    }
  end

  # Analyser les délais pour les demandes de prime
  def analyser_delais
    facture_solde = detecter_facture_solde
    return { status: 'no_solde', message: 'Aucune facture de solde identifiée' } unless facture_solde

    aujourd_hui = Date.current
    date_limite = facture_solde.date_limite_prime
    jours_restants = facture_solde.jours_avant_expiration

    {
      status: determiner_status_delai(jours_restants),
      facture_solde: facture_summary(facture_solde),
      date_limite: date_limite,
      jours_restants: jours_restants,
      message: facture_solde.message_alerte_delai,
      couleur_alerte: facture_solde.couleur_alerte_delai,
      actions_recommandees: actions_delai(jours_restants)
    }
  end

  # Détecter les factures manquantes ou problématiques
  def detecter_factures_manquantes
    anomalies = []

    # Vérifier la présence d'un devis
    anomalies << {
      type: 'devis_manquant',
      severite: 'haute',
      message: 'Aucun devis trouvé pour ce projet'
    } if factures_devis.empty?

    # Vérifier la présence de factures
    anomalies << {
      type: 'factures_manquantes',
      severite: 'haute',
      message: 'Aucune facture trouvée pour ce projet'
    } if factures_travaux.empty?

    # Vérifier la cohérence temporelle
    dates_incoherentes = detecter_dates_incoherentes
    anomalies.concat(dates_incoherentes) if dates_incoherentes.any?

    # Vérifier les doublons
    doublons = detecter_doublons
    anomalies.concat(doublons) if doublons.any?

    anomalies
  end

  # Détecter diverses anomalies
  def detecter_anomalies
    anomalies = []

    # Montants anormaux
    factures_travaux.each do |facture|
      if facture.montant > 100_000
        anomalies << {
          type: 'montant_eleve',
          severite: 'moyenne',
          facture_id: facture.id,
          message: "Montant très élevé: #{facture.montant_formate}"
        }
      end

      if facture.confiance_ocr && facture.confiance_ocr < 60
        anomalies << {
          type: 'confiance_faible',
          severite: 'moyenne',
          facture_id: facture.id,
          message: "Confiance OCR faible: #{facture.confiance_display}"
        }
      end
    end

    # Entreprises différentes
    entreprises = factures_travaux.map(&:nom_entreprise).compact.uniq
    if entreprises.count > 1
      anomalies << {
        type: 'entreprises_multiples',
        severite: 'faible',
        message: "Plusieurs entreprises détectées: #{entreprises.join(', ')}"
      }
    end

    anomalies
  end

  # Générer des recommandations
  def generer_recommandations
    recommendations = []

    # Recommandations basées sur l'analyse
    validation = validation_globale

    if validation[:statut] == 'incomplete'
      recommendations << {
        type: 'extraction',
        priorite: 'haute',
        action: 'Vérifier et compléter les données extraites automatiquement',
        description: 'Certaines factures ont des données incomplètes'
      }
    end

    # Recommandations pour les délais
    delais = analyser_delais
    if delais[:status] == 'critique'
      recommendations << {
        type: 'delai',
        priorite: 'urgente',
        action: 'Introduire immédiatement la demande de prime',
        description: delais[:message]
      }
    end

    # Recommandations pour les écarts budgétaires
    comparaison = comparer_avec_devis
    if comparaison[:status] == 'depassement_important'
      recommendations << {
        type: 'budget',
        priorite: 'haute',
        action: 'Justifier le dépassement budgétaire',
        description: "Dépassement de #{comparaison[:pourcentage_ecart]}% par rapport au devis"
      }
    end

    recommendations
  end

  private

  def factures_devis
    @factures_devis ||= project.documents
                              .joins("LEFT JOIN factures ON factures.document_id = documents.id")
                              .where("documents.type_document = 'devis' OR factures.type_facture = 'devis'")
                              .includes(:facture)
                              .map(&:facture)
                              .compact
  end

  def factures_travaux
    @factures_travaux ||= project.documents
                                .joins("INNER JOIN factures ON factures.document_id = documents.id")
                                .where("factures.type_facture IN ('facture', 'acompte', 'solde')")
                                .includes(:facture)
                                .map(&:facture)
                                .compact
  end

  def detecter_facture_solde
    factures_travaux.find(&:facture_solde?) ||
    factures_travaux.select { |f| f.type_facture == 'solde' }.first ||
    factures_travaux.max_by { |f| f.date_facture || Date.new(0) }
  end

  def validation_globale
    total_factures = factures_count = factures_travaux.count
    factures_completes = factures_travaux.count(&:extraction_complete?)
    factures_validees = factures_travaux.count(&:valide_manuellement?)

    pourcentage_complete = total_factures > 0 ? (factures_completes.to_f / total_factures * 100).round(1) : 0
    pourcentage_validee = total_factures > 0 ? (factures_validees.to_f / total_factures * 100).round(1) : 0

    statut = if pourcentage_complete >= 90 && pourcentage_validee >= 50
               'complete'
             elsif pourcentage_complete >= 70
               'acceptable'
             else
               'incomplete'
             end

    {
      statut: statut,
      total_factures: total_factures,
      factures_completes: factures_completes,
      factures_validees: factures_validees,
      pourcentage_complete: pourcentage_complete,
      pourcentage_validee: pourcentage_validee
    }
  end

  def determiner_status_ecart(pourcentage_ecart)
    if pourcentage_ecart.abs <= 5
      'conforme'
    elsif pourcentage_ecart.abs <= 15
      'ecart_acceptable'
    elsif pourcentage_ecart > 15
      'depassement_important'
    else
      'sous_evaluation'
    end
  end

  def determiner_status_delai(jours_restants)
    return 'inconnu' if jours_restants.nil?
    return 'expire' if jours_restants < 0
    return 'critique' if jours_restants <= 30
    return 'attention' if jours_restants <= 90
    'ok'
  end

  def generer_message_ecart(ecart, pourcentage)
    if ecart > 0
      "Dépassement de #{ecart.round(2)} € (#{pourcentage}%) par rapport au devis"
    elsif ecart < 0
      "Économie de #{ecart.abs.round(2)} € (#{pourcentage.abs}%) par rapport au devis"
    else
      "Montant exact conforme au devis"
    end
  end

  def actions_delai(jours_restants)
    return ['Date de facture non renseignée — veuillez compléter la facture pour calculer le délai de prime'] if jours_restants.nil?

    if jours_restants < 0
      ['Vérifier si une demande a déjà été introduite', 'Contacter l\'administration pour une éventuelle régularisation']
    elsif jours_restants <= 15
      ['Préparer immédiatement la demande de prime', 'Rassembler tous les documents requis', 'Introduire la demande cette semaine']
    elsif jours_restants <= 30
      ['Programmer la préparation de la demande de prime', 'Vérifier tous les documents requis']
    elsif jours_restants <= 90
      ['Planifier la préparation de la demande de prime', 'Faire un inventaire des documents disponibles']
    else
      ['Délai confortable pour préparer la demande']
    end
  end

  def detecter_dates_incoherentes
    anomalies = []
    factures_avec_dates = factures_travaux.select { |f| f.date_facture.present? }

    return anomalies if factures_avec_dates.count < 2

    dates_triees = factures_avec_dates.sort_by(&:date_facture)

    # Vérifier les écarts temporels importants
    dates_triees.each_cons(2) do |facture1, facture2|
      ecart_jours = (facture2.date_facture - facture1.date_facture).to_i

      if ecart_jours > 365 # Plus d'un an d'écart
        anomalies << {
          type: 'ecart_temporel_important',
          severite: 'moyenne',
          message: "Écart de #{ecart_jours} jours entre factures"
        }
      end
    end

    anomalies
  end

  def detecter_doublons
    anomalies = []

    # Grouper par numéro de facture
    factures_par_numero = factures_travaux.group_by(&:numero_facture)

    factures_par_numero.each do |numero, factures|
      next if numero.blank? || factures.count == 1

      anomalies << {
        type: 'doublon_numero',
        severite: 'haute',
        message: "Numéro de facture dupliqué: #{numero}",
        factures_ids: factures.map(&:id)
      }
    end

    # Grouper par montant et date (possible doublon)
    groupes_suspects = factures_travaux.group_by { |f| [f.montant, f.date_facture] }

    groupes_suspects.each do |(montant, date), factures|
      next if factures.count == 1 || montant.blank? || date.blank?

      anomalies << {
        type: 'doublon_suspect',
        severite: 'moyenne',
        message: "Factures suspectes: même montant (#{montant} €) et date (#{date.strftime('%d/%m/%Y')})",
        factures_ids: factures.map(&:id)
      }
    end

    anomalies
  end

  def facture_summary(facture)
    {
      id: facture.id,
      type: facture.type_facture,
      montant: facture.montant,
      date: facture.date_facture,
      numero: facture.numero_facture,
      entreprise: facture.nom_entreprise,
      confiance: facture.confiance_ocr
    }
  end
end
