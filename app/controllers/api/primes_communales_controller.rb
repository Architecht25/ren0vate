class Api::PrimesCommunalesController < ActionController::Base
  # Protection CSRF désactivée pour l'API
  protect_from_forgery with: :null_session

  before_action :set_cors_headers
  before_action :validate_code_postal, only: [:index, :calculate]

  # GET /api/primes_communales?code_postal=9000
  # Retourne les primes disponibles pour un code postal
  def index
    primes_data = PrimesCommunalesService.primes_par_code_postal(@code_postal)

    if primes_data
      render json: {
        success: true,
        data: {
          commune: primes_data[:commune],
          code_postal: primes_data[:code_postal],
          province: primes_data[:province],
          contact: primes_data[:contact],
          site_web: primes_data[:site_web],
          derniere_maj: primes_data[:derniere_maj],
          nombre_primes: primes_data[:nombre_primes],
          primes: primes_data[:primes].map do |prime|
            format_prime_for_api(prime)
          end
        },
        metadata: {
          timestamp: Time.current.iso8601,
          source: 'json_local'
        }
      }
    else
      render json: {
        success: false,
        error: {
          code: 'COMMUNE_NOT_FOUND',
          message: "Aucune commune trouvée pour le code postal #{@code_postal}",
          suggestions: communes_suggestions(@code_postal)
        }
      }, status: :not_found
    end
  end

  # POST /api/primes_communales/calculate
  # Calcule le montant d'une prime
  # Params: { code_postal: "9000", prime_id: "isolation_toiture_gent", montant_travaux: 10000, parametres: {} }
  def calculate
    prime_id = params[:prime_id]
    montant_travaux = params[:montant_travaux].to_f
    parametres = params[:parametres]&.permit! || {}

    # Validation des paramètres
    if prime_id.blank?
      return render json: {
        success: false,
        error: {
          code: 'MISSING_PRIME_ID',
          message: 'Identifiant de prime requis'
        }
      }, status: :bad_request
    end

    if montant_travaux <= 0
      return render json: {
        success: false,
        error: {
          code: 'INVALID_AMOUNT',
          message: 'Montant des travaux doit être supérieur à 0'
        }
      }, status: :bad_request
    end

    # Vérifier que la prime existe
    unless PrimesCommunalesService.prime_valide?(@code_postal, prime_id)
      return render json: {
        success: false,
        error: {
          code: 'PRIME_NOT_FOUND',
          message: "Prime #{prime_id} non trouvée pour le code postal #{@code_postal}"
        }
      }, status: :not_found
    end

    # Obtenir les données de la prime
    prime_data = PrimesCommunalesService.obtenir_prime(@code_postal, prime_id)

    # Calculer le montant
    montant_calcule = PrimesCommunalesService.calculer_prime(
      prime_data,
      montant_travaux,
      parametres.to_h
    )

    render json: {
      success: true,
      data: {
        prime: format_prime_for_api(prime_data),
        calcul: {
          montant_travaux: montant_travaux,
          montant_prime: montant_calcule,
          parametres_utilises: parametres,
          type_calcul: prime_data['type_calcul'],
          details_calcul: generer_details_calcul(prime_data, montant_travaux, montant_calcule, parametres)
        }
      },
      metadata: {
        timestamp: Time.current.iso8601,
        source: 'json_local'
      }
    }
  end

  # GET /api/primes_communales/communes
  # Liste toutes les communes supportées
  def communes
    communes = PrimesCommunalesService.communes_supportees

    render json: {
      success: true,
      data: {
        communes: communes,
        total: communes.count
      },
      metadata: PrimesCommunalesService.metadata
    }
  end

  # GET /api/primes_communales/search?q=isolation&code_postal=9000
  # Recherche de primes par mots-clés
  def search
    terme = params[:q]&.strip
    code_postal_search = params[:code_postal]

    if terme.blank?
      return render json: {
        success: false,
        error: {
          code: 'MISSING_SEARCH_TERM',
          message: 'Terme de recherche requis'
        }
      }, status: :bad_request
    end

    resultats = PrimesCommunalesService.rechercher_primes(terme, code_postal_search)

    render json: {
      success: true,
      data: {
        terme_recherche: terme,
        resultats: resultats.map do |resultat|
          {
            commune: resultat[:commune],
            code_postal: resultat[:code_postal],
            prime: format_prime_for_api(resultat[:prime])
          }
        end,
        total: resultats.count
      }
    }
  end

  # GET /api/primes_communales/categories
  # Liste des catégories de primes disponibles
  def categories
    render json: {
      success: true,
      data: {
        categories: PrimesCommunalesService.categories_primes,
        types_calcul: PrimesCommunalesService.charger_donnees['types_calcul']
      }
    }
  end

  # GET /api/primes_communales/stats
  # Statistiques sur les primes
  def stats
    render json: {
      success: true,
      data: PrimesCommunalesService.statistiques
    }
  end

  private

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  def validate_code_postal
    @code_postal = params[:code_postal]&.strip

    if @code_postal.blank?
      render json: {
        success: false,
        error: {
          code: 'MISSING_CODE_POSTAL',
          message: 'Code postal requis'
        }
      }, status: :bad_request
      return false
    end

    unless @code_postal =~ /^\d{4}$/
      render json: {
        success: false,
        error: {
          code: 'INVALID_CODE_POSTAL',
          message: 'Code postal doit contenir exactement 4 chiffres'
        }
      }, status: :bad_request
      return false
    end

    true
  end

  def format_prime_for_api(prime)
    {
      id: prime['id'],
      nom: prime['nom'],
      categorie: prime['categorie'],
      type_calcul: prime['type_calcul'],
      valeur: prime['valeur'],
      plafond: prime['plafond'],
      minimum: prime['minimum'],
      unite: prime['unite'],
      description: prime['description'],
      conditions: prime['conditions'] || [],
      pieces_requises: prime['pieces_requises'] || [],
      delai_traitement: prime['delai_traitement'],
      active: prime['active'] != false
    }
  end

  def generer_details_calcul(prime_data, montant_travaux, montant_calcule, parametres)
    case prime_data['type_calcul']
    when 'pourcentage'
      "#{(prime_data['valeur'] * 100).to_i}% de #{montant_travaux}€ = #{montant_calcule}€"
    when 'forfait'
      "Forfait fixe = #{montant_calcule}€"
    when 'par_kw'
      puissance = parametres[:puissance_kw] || parametres['puissance_kw'] || 1
      "#{puissance} kW × #{prime_data['valeur']}€/kW = #{montant_calcule}€"
    when 'par_m2'
      surface = parametres[:surface_m2] || parametres['surface_m2'] || 1
      "#{surface} m² × #{prime_data['valeur']}€/m² = #{montant_calcule}€"
    else
      "Calcul spécifique"
    end
  end

  def communes_suggestions(code_postal)
    # Suggérer des codes postaux proches si possible
    communes = PrimesCommunalesService.communes_supportees

    if code_postal.length == 4
      prefix = code_postal[0..1]
      suggestions = communes.select { |c| c[:code_postal].start_with?(prefix) }
      return suggestions.first(3).map { |c| "#{c[:code_postal]} (#{c[:nom]})" }
    end

    communes.first(5).map { |c| "#{c[:code_postal]} (#{c[:nom]})" }
  end
end
