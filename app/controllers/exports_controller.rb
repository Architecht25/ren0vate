class ExportsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_export_access!

  # GET /exports/comptable.csv?project_id=X  (optionnel : filtre par projet)
  # GET /exports/comptable.csv               (tous les projets)
  def comptable
    project_id = params[:project_id].presence
    period_from = params[:from].present? ? Date.parse(params[:from]) : nil
    period_to   = params[:to].present?   ? Date.parse(params[:to])   : nil

    @factures   = build_factures_scope(project_id, period_from, period_to)
    @devis      = build_devis_scope(project_id, period_from, period_to)

    respond_to do |format|
      format.csv do
        send_data generate_csv(@factures, @devis),
                  filename: "export_comptable_#{Date.current.strftime('%Y%m%d')}.csv",
                  type: 'text/csv; charset=utf-8',
                  disposition: 'attachment'
      end
    end
  rescue ArgumentError
    redirect_back fallback_location: dashboard_path, alert: "Date invalide."
  end

  private

  def check_export_access!
    return if plan_exempt?
    unless current_user.can_access_feature?(:export_comptable)
      redirect_back fallback_location: dashboard_path,
                    alert: "L'export comptable est disponible à partir de l'offre Entreprise."
    end
  end

  def build_factures_scope(project_id, from, to)
    scope = Facture.joins(:project)
                   .where(projects: { user_id: current_user.id })
                   .includes(:project)
                   .order(:date_facture)

    scope = scope.where(project_id: project_id) if project_id
    scope = scope.where('date_facture >= ?', from) if from
    scope = scope.where('date_facture <= ?', to)   if to
    scope
  end

  def build_devis_scope(project_id, from, to)
    scope = DevisDonnee.joins(:project)
                       .where(projects: { user_id: current_user.id })
                       .includes(:project)
                       .order(:date_devis)

    scope = scope.where(project_id: project_id) if project_id
    scope = scope.where('date_devis >= ?', from) if from
    scope = scope.where('date_devis <= ?', to)   if to
    scope
  end

  def generate_csv(factures, devis)
    require 'csv'

    CSV.generate(col_sep: ';', encoding: 'UTF-8', write_headers: true,
                 headers: csv_headers) do |csv|

      factures.each do |f|
        csv << [
          f.project&.title,
          f.date_facture&.strftime('%d/%m/%Y'),
          f.type_facture&.humanize,
          f.numero_facture,
          f.nom_entreprise,
          f.numero_tva_entreprise,
          f.numero_bce_entreprise,
          format_amount(f.montant_ht),
          format_amount(f.montant_tva),
          format_amount(f.taux_tva) + '%',
          format_amount(f.montant),
          f.statut_paiement&.humanize,
          f.date_echeance&.strftime('%d/%m/%Y'),
          f.date_limite_prime&.strftime('%d/%m/%Y'),
          f.type_intervenant&.humanize,
          'Facture'
        ]
      end

      devis.each do |d|
        csv << [
          d.project&.title,
          d.date_devis&.strftime('%d/%m/%Y'),
          'Devis',
          d.numero_devis,
          d.nom_entreprise,
          d.numero_tva_entreprise,
          d.numero_bce_entreprise,
          format_amount(d.montant_total_htva),
          format_amount(d.montant_total_htva.present? && d.montant_total_tvac.present? ? d.montant_total_tvac - d.montant_total_htva : nil),
          format_amount(d.taux_tva) + '%',
          format_amount(d.montant_total_tvac),
          'N/A',
          d.validite_devis&.strftime('%d/%m/%Y'),
          '',
          d.categorie_emetteur&.humanize,
          'Devis'
        ]
      end
    end
  end

  def csv_headers
    [
      'Projet', 'Date', 'Type', 'Numéro', 'Entreprise',
      'N° TVA', 'N° BCE', 'Montant HT (€)', 'TVA (€)', 'Taux TVA',
      'Montant TTC (€)', 'Statut paiement', 'Date échéance',
      'Date limite prime', 'Intervenant', 'Catégorie'
    ]
  end

  def format_amount(value)
    return '' if value.nil?
    '%.2f' % value.to_f
  end
end
