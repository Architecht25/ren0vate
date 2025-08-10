class Api::EntreprisesController < ApplicationController
  def bce_lookup
    numero_bce = params[:numero_bce]

    # Simulation d'une réponse API BCE - à remplacer par vraie API
    company_data = simulate_bce_response(numero_bce)

    if company_data
      render json: {
        success: true,
        data: company_data
      }
    else
      render json: {
        success: false,
        message: "Entreprise non trouvée"
      }, status: 404
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

  def simulate_bce_response(numero_bce)
    # Simulation de données d'entreprise
    case numero_bce.gsub(/[^0-9]/, '')
    when '0833618097'
      {
        numero_bce: '0833.618.097',
        denomination: 'RenovaTech Solutions SPRL',
        forme_juridique: 'Société privée à responsabilité limitée',
        statut: 'ACTIF',
        date_creation: '2019-05-15',
        code_nace: '71121',
        adresse: {
          rue: 'Avenue des Arts 45',
          code_postal: '1040',
          commune: 'Etterbeek'
        },
        nombre_employes: 15,
        chiffre_affaires: 1200000,
        taille_entreprise: 'PME'
      }
    when '0123456789'
      {
        numero_bce: '0123.456.789',
        denomination: 'Innovation Tech Solutions SPRL',
        forme_juridique: 'Société privée à responsabilité limitée',
        statut: 'ACTIF',
        date_creation: '2020-01-15',
        code_nace: '62010',
        adresse: {
          rue: 'Avenue Louise 123',
          code_postal: '1050',
          commune: 'Ixelles'
        },
        nombre_employes: 25,
        chiffre_affaires: 2500000,
        taille_entreprise: 'PME'
      }
    when '0987654321'
      {
        numero_bce: '0987.654.321',
        denomination: 'EcoConsulting & Partners SA',
        forme_juridique: 'Société anonyme',
        statut: 'ACTIF',
        date_creation: '2018-06-10',
        code_nace: '70220',
        adresse: {
          rue: 'Rue de la Loi 200',
          code_postal: '1000',
          commune: 'Bruxelles'
        },
        nombre_employes: 12,
        chiffre_affaires: 1800000,
        taille_entreprise: 'PME'
      }
    when '0456789123'
      {
        numero_bce: '0456.789.123',
        denomination: 'Green Mobility Solutions SCRL',
        forme_juridique: 'Société coopérative à responsabilité limitée',
        statut: 'ACTIF',
        date_creation: '2021-03-20',
        code_nace: '49390',
        adresse: {
          rue: 'Boulevard du Souverain 25',
          code_postal: '1170',
          commune: 'Watermael-Boitsfort'
        },
        nombre_employes: 8,
        chiffre_affaires: 950000,
        taille_entreprise: 'Micro-entreprise'
      }
    else
      nil
    end
  end
end
