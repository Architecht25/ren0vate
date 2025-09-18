class FactureAlertService
  include ActiveModel::Model

  def self.verifier_alertes_automatiques
    new.verifier_alertes_automatiques
  end

  def verifier_alertes_automatiques
    Rails.logger.info "Début vérification alertes factures automatiques"

    resultats = {
      delais_critiques: [],
      depassements_budget: [],
      extractions_faibles: [],
      factures_orphelines: [],
      notifications_creees: 0
    }

    # 1. Alertes délais critiques (factures de solde expiration < 30 jours)
    resultats[:delais_critiques] = verifier_delais_critiques

    # 2. Alertes dépassements budgétaires importants (> 15%)
    resultats[:depassements_budget] = verifier_depassements_budget

    # 3. Alertes extractions OCR faibles (< 60% confiance)
    resultats[:extractions_faibles] = verifier_extractions_faibles

    # 4. Alertes factures orphelines (sans projet associé proprement)
    resultats[:factures_orphelines] = verifier_factures_orphelines

    # Créer les notifications
    resultats[:notifications_creees] = creer_notifications(resultats)

    Rails.logger.info "Fin vérification alertes: #{resultats[:notifications_creees]} notifications créées"
    resultats
  end

  private

  def verifier_delais_critiques
    factures_critiques = Facture.joins(:project)
                                .where(facture_solde: true)
                                .where('jours_avant_expiration <= ? AND jours_avant_expiration >= 0', 30)
                                .includes(:project, project: :user)

    factures_critiques.map do |facture|
      {
        type: 'delai_critique',
        severite: facture.jours_avant_expiration <= 7 ? 'urgente' : 'haute',
        facture: facture,
        project: facture.project,
        user: facture.project.user,
        message: "Délai prime expire dans #{facture.jours_avant_expiration} jours",
        details: {
          jours_restants: facture.jours_avant_expiration,
          date_limite: facture.date_limite_prime,
          montant_facture: facture.montant
        }
      }
    end
  end

  def verifier_depassements_budget
    projets_avec_depassement = []

    Project.joins(:factures).group(:id).each do |project|
      validation_service = FactureValidationService.new(project)
      comparaison = validation_service.comparer_avec_devis

      if comparaison[:status] == 'depassement_important' &&
         comparaison[:pourcentage_ecart] > 15

        projets_avec_depassement << {
          type: 'depassement_budget',
          severite: comparaison[:pourcentage_ecart] > 25 ? 'haute' : 'moyenne',
          project: project,
          user: project.user,
          message: "Dépassement budgétaire de #{comparaison[:pourcentage_ecart]}%",
          details: {
            montant_devis: comparaison[:montant_devis],
            total_factures: comparaison[:total_factures],
            ecart: comparaison[:ecart],
            pourcentage_ecart: comparaison[:pourcentage_ecart]
          }
        }
      end
    end

    projets_avec_depassement
  end

  def verifier_extractions_faibles
    factures_problematiques = Facture.joins(:project)
                                    .where('confiance_ocr < ? OR confiance_ocr IS NULL', 60)
                                    .where(valide_manuellement: false)
                                    .where(extraction_complete: false)
                                    .includes(:project, project: :user)

    factures_problematiques.map do |facture|
      {
        type: 'extraction_faible',
        severite: 'moyenne',
        facture: facture,
        project: facture.project,
        user: facture.project.user,
        message: "Extraction OCR incomplète ou peu fiable",
        details: {
          confiance_ocr: facture.confiance_ocr,
          extraction_complete: facture.extraction_complete,
          numero_facture: facture.numero_facture
        }
      }
    end
  end

  def verifier_factures_orphelines
    factures_orphelines = Facture.left_joins(:project)
                                .where(projects: { id: nil })
                                .or(Facture.joins(:project).where(projects: { statut: nil }))

    factures_orphelines.map do |facture|
      {
        type: 'facture_orpheline',
        severite: 'faible',
        facture: facture,
        project: facture.project,
        user: facture.project&.user,
        message: "Facture non associée correctement à un projet",
        details: {
          facture_id: facture.id,
          montant: facture.montant
        }
      }
    end
  end

  def creer_notifications(resultats)
    notifications_creees = 0

    # Regrouper les alertes par utilisateur pour éviter le spam
    alertes_par_utilisateur = {}

    # Collecter toutes les alertes
    toutes_les_alertes = []
    toutes_les_alertes.concat(resultats[:delais_critiques])
    toutes_les_alertes.concat(resultats[:depassements_budget])
    toutes_les_alertes.concat(resultats[:extractions_faibles])
    toutes_les_alertes.concat(resultats[:factures_orphelines])

    # Grouper par utilisateur
    toutes_les_alertes.each do |alerte|
      next unless alerte[:user]

      user_id = alerte[:user].id
      alertes_par_utilisateur[user_id] ||= []
      alertes_par_utilisateur[user_id] << alerte
    end

    # Créer les notifications groupées
    alertes_par_utilisateur.each do |user_id, alertes_user|
      user = User.find(user_id)

      # Priorité: délais critiques > dépassements > extractions > orphelines
      alertes_urgentes = alertes_user.select { |a| a[:severite] == 'urgente' }
      alertes_hautes = alertes_user.select { |a| a[:severite] == 'haute' }
      alertes_moyennes = alertes_user.select { |a| a[:severite] == 'moyenne' }

      # Créer notification pour alertes urgentes
      if alertes_urgentes.any?
        creer_notification_groupee(user, alertes_urgentes, 'urgente')
        notifications_creees += 1
      end

      # Créer notification pour alertes hautes (si pas d'urgentes récentes)
      if alertes_hautes.any? && !notification_recente_existe?(user, 'haute')
        creer_notification_groupee(user, alertes_hautes, 'haute')
        notifications_creees += 1
      end

      # Créer notification pour alertes moyennes (maximum 1 par semaine)
      if alertes_moyennes.any? && !notification_recente_existe?(user, 'moyenne', 7.days)
        creer_notification_groupee(user, alertes_moyennes, 'moyenne')
        notifications_creees += 1
      end
    end

    notifications_creees
  end

  def creer_notification_groupee(user, alertes, severite)
    # Déterminer le titre et message selon les types d'alertes
    types = alertes.map { |a| a[:type] }.uniq

    titre = case severite
           when 'urgente'
             "🚨 Action urgente requise sur vos factures"
           when 'haute'
             "⚠️ Attention importante sur vos projets"
           when 'moyenne'
             "📋 Points à vérifier sur vos documents"
           else
             "ℹ️ Informations sur vos projets"
           end

    # Construire le message détaillé
    message_parts = []

    alertes.group_by { |a| a[:type] }.each do |type, alertes_type|
      case type
      when 'delai_critique'
        if alertes_type.count == 1
          alerte = alertes_type.first
          message_parts << "• Délai prime expire dans #{alerte[:details][:jours_restants]} jours (projet: #{alerte[:project].nom})"
        else
          message_parts << "• #{alertes_type.count} projets avec délais proches d'expiration"
        end
      when 'depassement_budget'
        if alertes_type.count == 1
          alerte = alertes_type.first
          message_parts << "• Dépassement budgétaire de #{alerte[:details][:pourcentage_ecart].round(1)}% (projet: #{alerte[:project].nom})"
        else
          message_parts << "• #{alertes_type.count} projets avec dépassements budgétaires"
        end
      when 'extraction_faible'
        message_parts << "• #{alertes_type.count} facture(s) nécessitent une vérification manuelle"
      when 'facture_orpheline'
        message_parts << "• #{alertes_type.count} facture(s) non associées correctement"
      end
    end

    message = message_parts.join("\n")

    # Déterminer l'URL de redirection (vers le premier projet concerné)
    premier_projet = alertes.first[:project]
    url = premier_projet ? "/projects/#{premier_projet.id}/factures_dashboard" : "/projects"

    # Créer la notification
    Notification.create!(
      user: user,
      titre: titre,
      message: message,
      type_notification: 'facture_alerte',
      priorite: severite,
      url: url,
      metadata: {
        alertes: alertes.map do |alerte|
          {
            type: alerte[:type],
            severite: alerte[:severite],
            project_id: alerte[:project]&.id,
            facture_id: alerte[:facture]&.id,
            details: alerte[:details]
          }
        end
      }
    )
  end

  def notification_recente_existe?(user, severite, delai = 1.day)
    Notification.where(
      user: user,
      type_notification: 'facture_alerte',
      priorite: severite,
      created_at: delai.ago..Time.current
    ).exists?
  end
end
