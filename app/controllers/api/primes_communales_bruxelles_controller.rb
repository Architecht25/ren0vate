class Api::PrimesCommunalesBruxellesController < ActionController::Base
  # Protection CSRF désactivée pour l'API
  protect_from_forgery with: :null_session

  before_action :set_cors_headers
  before_action :validate_code_postal, only: [:index, :calculate]

  # GET /api/primes_communales_bruxelles?code_postal=1000
  # Retourne les primes disponibles pour un code postal bruxellois
  def index
    primes_data = PrimesCommunalesBruxellesService.primes_par_code_postal(@code_postal)

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
          region: 'Bruxelles-Capitale',
          version: PrimesCommunalesBruxellesService.metadata['version']
        }
      }
    else
      render json: {
        success: false,
        error: {
          code: 'CODE_POSTAL_NOT_SUPPORTED',
          message: "Aucune prime trouvée pour le code postal #{@code_postal}",
          suggestions: communes_suggestions(@code_postal)
        }
      }, status: :not_found
    end
  end

  # POST /api/primes_communales_bruxelles/calculate
  # Calcule le montant d'une prime
  # Params: { code_postal: "1000", prime_id: "isolation_toiture_bruxelles_ville", montant_travaux: 10000, parametres: {} }
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
    unless PrimesCommunalesBruxellesService.prime_valide?(@code_postal, prime_id)
      return render json: {
        success: false,
        error: {
          code: 'PRIME_NOT_FOUND',
          message: "Prime #{prime_id} non trouvée pour le code postal #{@code_postal}"
        }
      }, status: :not_found
    end

    # Obtenir les données de la prime
    prime_data = PrimesCommunalesBruxellesService.obtenir_prime(@code_postal, prime_id)

    # Calculer le montant
    montant_calcule = PrimesCommunalesBruxellesService.calculer_prime(
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
          pourcentage_couverture: montant_travaux.positive? ? ((montant_calcule / montant_travaux) * 100).round(1) : 0,
          details: generer_details_calcul(prime_data, montant_travaux, montant_calcule, parametres)
        },
        metadata: {
          timestamp: Time.current.iso8601,
          code_postal: @code_postal,
          prime_id: prime_id
        }
      }
    }
  rescue => e
    Rails.logger.error "Erreur calcul prime Bruxelles: #{e.message}"
    render json: {
      success: false,
      error: {
        code: 'CALCULATION_ERROR',
        message: 'Erreur lors du calcul de la prime'
      }
    }, status: :internal_server_error
  end

  # GET /api/primes_communales_bruxelles/communes
  # Liste toutes les communes bruxelloises supportées
  def communes
    communes = PrimesCommunalesBruxellesService.communes_supportees

    render json: {
      success: true,
      data: {
        communes: communes,
        total: communes.count,
        region: 'Bruxelles-Capitale'
      },
      metadata: {
        timestamp: Time.current.iso8601,
        version: PrimesCommunalesBruxellesService.metadata['version']
      }
    }
  end

  # GET /api/primes_communales_bruxelles/search?q=isolation&code_postal=1000
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

    resultats = PrimesCommunalesBruxellesService.rechercher_primes(terme, code_postal_search)

    render json: {
      success: true,
      data: {
        terme_recherche: terme,
        resultats: resultats.map do |resultat|
          {
            commune: resultat[:commune],
            code_postal: resultat[:code_postal],
            primes: resultat[:primes].map { |prime| format_prime_for_api(prime) }
          }
        end,
        total_resultats: resultats.sum { |r| r[:primes].count }
      },
      metadata: {
        timestamp: Time.current.iso8601,
        region: 'Bruxelles-Capitale'
      }
    }
  end

  # GET /api/primes_communales_bruxelles/categories
  # Liste des catégories de primes disponibles
  def categories
    categories = PrimesCommunalesBruxellesService.categories_primes

    render json: {
      success: true,
      data: {
        categories: categories,
        types_calcul: PrimesCommunalesBruxellesService.types_calcul
      },
      metadata: {
        timestamp: Time.current.iso8601,
        region: 'Bruxelles-Capitale'
      }
    }
  end

  # GET /api/primes_communales_bruxelles/stats
  # Statistiques sur les primes bruxelloises
  def stats
    render json: {
      success: true,
      data: PrimesCommunalesBruxellesService.statistiques
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

    # Vérifier que c'est un code postal bruxellois
    unless code_postal_bruxellois?(@code_postal)
      render json: {
        success: false,
        error: {
          code: 'NOT_BRUSSELS_POSTAL_CODE',
          message: 'Ce code postal ne correspond pas à la Région de Bruxelles-Capitale',
          suggestions: ['Utilisez un code postal entre 1000 et 1210']
        }
      }, status: :bad_request
      return false
    end

    true
  end

  def code_postal_bruxellois?(code_postal)
    code_int = code_postal.to_i
    # Codes postaux bruxellois principaux
    bruxelles_codes = [
      1000, 1020, 1030, 1040, 1050, 1060, 1070, 1080,
      1081, 1082, 1083, 1090, 1120, 1130, 1140, 1150,
      1160, 1170, 1180, 1190, 1200, 1210
    ]
    bruxelles_codes.include?(code_int)
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
      documents_requis: prime['documents_requis'] || [],
      active: prime['active']
    }
  end

  def generer_details_calcul(prime_data, montant_travaux, montant_calcule, parametres)
    case prime_data['type_calcul']
    when 'pourcentage'
      pourcentage = prime_data['valeur']
      base_calcul = montant_travaux * pourcentage / 100.0
      plafond = prime_data['plafond']

      details = "#{pourcentage}% de #{montant_travaux}€ = #{base_calcul.round(2)}€"
      details += ", plafonné à #{plafond}€" if plafond && base_calcul > plafond
      details

    when 'forfait'
      "Forfait fixe de #{prime_data['valeur']}€"

    when 'par_unite'
      quantite = parametres[:quantite] || parametres['quantite'] || 1
      valeur_unitaire = prime_data['valeur']
      unite = prime_data['unite'] || 'unité'

      "#{valeur_unitaire}€ × #{quantite} #{unite} = #{montant_calcule}€"

    else
      "Calcul spécifique"
    end
  end

  def communes_suggestions(code_postal)
    # Suggérer des codes postaux bruxellois proches
    communes = PrimesCommunalesBruxellesService.communes_supportees

    if code_postal.length == 4
      prefix = code_postal[0..1]
      suggestions = communes.select { |c| c[:code_postal].start_with?(prefix) }
      return suggestions.first(3).map { |c| "#{c[:code_postal]} (#{c[:nom]})" }
    end

    # Suggérer quelques communes principales
    principales = ['1000 (Bruxelles-Ville)', '1050 (Ixelles)', '1180 (Uccle)', '1200 (Woluwe-Saint-Lambert)']
    principales
  end
end
