class Api::EntreprisesController < ApplicationController
  # Permettre l'accès sans authentification pour les APIs publiques d'entreprises
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def bce_lookup
    numero_bce = params[:numero_bce]

    # Nettoyer le numéro (enlever espaces et points)
    clean_numero = numero_bce.gsub(/[^0-9]/, '')
    formatted_numero = "#{clean_numero[0..3]}.#{clean_numero[4..6]}.#{clean_numero[7..9]}"

    # Rechercher d'abord dans nos données locales BCE
    enterprise = BceEnterprise.find_by_number(formatted_numero)

    if enterprise
      # Récupérer les données associées
      denomination = enterprise.bce_denominations.official.first&.denomination ||
                    enterprise.bce_denominations.first&.denomination ||
                    "Dénomination non disponible"

      address = enterprise.bce_addresses.first
      all_activities = enterprise.bce_activities.order(:nace_version, :activity_group)
      main_activity = all_activities.where(classification: 'MAIN').first

      # Construire la liste des codes NACE
      nace_codes = all_activities.map do |activity|
        {
          code: activity.nace_code,
          version: activity.nace_version,
          classification: activity.classification,
          activity_group: activity.activity_group
        }
      end

      # Construire l'adresse complète
      full_address = if address
        street = "#{address.street_fr || address.street_nl || ''} #{address.house_number || ''}".strip
        {
          rue: street,
          numero: address.house_number || '',
          code_postal: address.zipcode || '',
          commune: address.municipality_fr || address.municipality_nl || ''
        }
      else
        { rue: 'N/A', numero: '', code_postal: 'N/A', commune: 'N/A' }
      end

      # Formater la forme juridique
      forme_juridique_libelle = case enterprise.juridical_form
      when '610' then 'Société privée à responsabilité limitée (SPRL)'
      when '620' then 'Société anonyme (SA)'
      when '000' then 'Personne physique'
      else enterprise.juridical_form || 'N/A'
      end

      company_data = {
        numero_bce: enterprise.enterprise_number,
        denomination: denomination,
        forme_juridique: forme_juridique_libelle,
        statut: enterprise.status == 'AC' ? 'ACTIF' : enterprise.status,
        date_creation: enterprise.start_date&.strftime('%Y-%m-%d'),
        code_nace: main_activity&.nace_code || 'N/A',
        codes_nace: nace_codes,
        adresse: full_address,
        taille_entreprise: 'Non déterminée' # À calculer si nécessaire
      }

      render json: {
        success: true,
        data: company_data,
        source: 'local_database'
      }
    else
      # Fallback vers l'API BCE officielle
      begin
        bce_response = Entreprises::BceApiService.search_company(formatted_numero)
        
        if bce_response[:success]
          render json: {
            success: true,
            data: bce_response[:data],
            source: 'bce_api'
          }
        else
          render json: {
            success: false,
            message: "Entreprise non trouvée dans la base locale ni via l'API BCE",
            error: bce_response[:error]
          }, status: 404
        end
      rescue StandardError => e
        render json: {
          success: false,
          message: "Erreur lors de la recherche BCE",
          error: e.message
        }, status: 500
      end
    end
  end

  def bruxelles_aides
    aids = EntrepriseAide.where(region: 'bruxelles')
                        .where(statut: 'active')
                        .select(:id, :titre, :categorie, :description,
                               :taux_aide, :montant_min, :montant_max,
                               :conditions_eligibilite, :modalites_paiement,
                               :secteurs_eligibles, :tailles_eligibles, :url_officielle)

    render json: aids
  end

  private

  # Méthode de simulation conservée pour référence en cas de besoin
  # def simulate_bce_response(numero_bce)
  #   # Ancienne simulation - remplacée par vraies données BCE
  # end
end
