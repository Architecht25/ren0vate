class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_analytics_access!

  # GET /analytics
  def index
    @projects = current_user.projects.includes(:property, :factures, :simulations, :chantier_analyses)

    # Chiffres globaux
    @total_projects   = @projects.count
    @active_projects  = @projects.where.not(statut: ['termine', 'annule', nil]).count
    @done_projects    = @projects.where(statut: 'termine').count

    # Budget global
    @budget_total     = total_factures_amount
    @budget_par_statut = budget_by_payment_status

    # Répartition par type de travaux (depuis factures + devis)
    @repartition_travaux = repartition_par_type_travaux

    # Avancement moyen des chantiers actifs
    @avancement_moyen = avancement_moyen_chantiers

    # Synthèse par projet (tableau)
    @projet_stats = projet_stats_table

    # Évolution mensuelle des dépenses (12 derniers mois)
    @depenses_mensuelles = depenses_par_mois(12)

    # Simulations : montant total des primes potentielles
    @total_primes_potentielles = current_user.simulations.sum(:total_simule).to_i
  end

  private

  def check_analytics_access!
    return if plan_exempt?
    unless current_user.can_access_feature?(:analytics)
      redirect_to pricing_select_path,
                  alert: "Les analytics sont disponibles à partir de l'offre Propriétaire."
    end
  end

  def total_factures_amount
    Facture.joins(:project)
           .where(projects: { user_id: current_user.id })
           .where(type_facture: %w[facture acompte solde etat_avancement])
           .sum(:montant).to_f
  end

  def budget_by_payment_status
    Facture.joins(:project)
           .where(projects: { user_id: current_user.id })
           .where(type_facture: %w[facture acompte solde etat_avancement])
           .group(:statut_paiement)
           .sum(:montant)
           .transform_values(&:to_f)
  end

  def avancement_moyen_chantiers
    analyses = ChantierAnalyse.joins(:project)
                              .where(projects: { user_id: current_user.id })
                              .order(:project_id, analysed_at: :desc)
                              .select('DISTINCT ON (project_id) *')
    return 0 if analyses.empty?
    (analyses.sum(&:avancement).to_f / analyses.count).round
  end

  def repartition_par_type_travaux
    DevisDonnee.joins(:project)
               .where(projects: { user_id: current_user.id })
               .where.not(types_travaux_detectes: '[]')
               .pluck(:types_travaux_detectes)
               .flatten
               .tally
               .sort_by { |_, count| -count }
               .first(8)
               .to_h
  end

  def projet_stats_table
    current_user.projects.includes(:property, :factures, :chantier_analyses).map do |project|
      derniere_analyse = project.chantier_analyses.order(analysed_at: :desc).first
      total_facture = project.factures
                             .where(type_facture: %w[facture acompte solde etat_avancement])
                             .sum(:montant).to_f
      total_devis = project.devis_donnees.sum(:montant_total_tvac).to_f

      {
        project:      project,
        avancement:   derniere_analyse&.avancement || 0,
        total_facture: total_facture,
        total_devis:   total_devis,
        nb_factures:  project.factures.where(type_facture: %w[facture acompte solde etat_avancement]).count,
        nb_devis:     project.devis_donnees.count
      }
    end
  end

  def depenses_par_mois(nb_mois)
    debut = nb_mois.months.ago.beginning_of_month

    Facture.joins(:project)
           .where(projects: { user_id: current_user.id })
           .where(type_facture: %w[facture acompte solde etat_avancement])
           .where('date_facture >= ?', debut)
           .group("TO_CHAR(date_facture, 'YYYY-MM')")
           .sum(:montant)
           .sort_by { |k, _| k }
           .map { |mois, total| { mois: mois, total: total.to_f } }
  rescue
    # Fallback SQLite (dev)
    Facture.joins(:project)
           .where(projects: { user_id: current_user.id })
           .where(type_facture: %w[facture acompte solde etat_avancement])
           .where('date_facture >= ?', debut)
           .group("strftime('%Y-%m', date_facture)")
           .sum(:montant)
           .sort_by { |k, _| k }
           .map { |mois, total| { mois: mois, total: total.to_f } }
  end
end
