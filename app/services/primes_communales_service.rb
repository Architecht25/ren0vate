# Service pour gérer les primes communales depuis le fichier JSON
class PrimesCommunalesService
  include Singleton

  FICHIER_PRIMES = Rails.root.join('public', 'data', 'primes_communales_flandre.json')

  def initialize
    @data = nil
    @last_loaded = nil
  end

  # Charger les données depuis le fichier JSON
  def charger_donnees
    return @data if @data && fichier_non_modifie?

    Rails.logger.info "Chargement des données primes communales depuis #{FICHIER_PRIMES}"

    if File.exist?(FICHIER_PRIMES)
      begin
        contenu = File.read(FICHIER_PRIMES)
        @data = JSON.parse(contenu)
        @last_loaded = File.mtime(FICHIER_PRIMES)
        Rails.logger.info "✅ Données primes chargées : #{@data['metadata']['total_communes']} communes"
      rescue JSON::ParserError => e
        Rails.logger.error "❌ Erreur parsing JSON primes : #{e.message}"
        @data = donnees_fallback
      rescue => e
        Rails.logger.error "❌ Erreur chargement primes : #{e.message}"
        @data = donnees_fallback
      end
    else
      Rails.logger.warn "⚠️ Fichier primes non trouvé, utilisation fallback"
      @data = donnees_fallback
    end

    @data
  end

  # Trouver les primes pour un code postal donné
  def primes_par_code_postal(code_postal)
    return nil unless code_postal =~ /^\d{4}$/

    donnees = charger_donnees
    commune_data = donnees.dig('communes', code_postal)

    return nil unless commune_data

    {
      commune: commune_data['nom'],
      code_postal: code_postal,
      province: commune_data['province'],
      contact: commune_data['contact_primes'],
      site_web: commune_data['site_web'],
      derniere_maj: commune_data['derniere_maj'],
      nombre_primes: commune_data['primes']&.count(&method(:prime_active?)) || 0,
      primes: commune_data['primes']&.select(&method(:prime_active?)) || []
    }
  end

  # Calculer le montant d'une prime
  def calculer_prime(prime_data, montant_travaux, parametres = {})
    return 0 unless prime_data && montant_travaux.to_f > 0

    montant = montant_travaux.to_f
    type_calcul = prime_data['type_calcul']
    valeur = prime_data['valeur'].to_f
    plafond = prime_data['plafond']&.to_f
    minimum = prime_data['minimum']&.to_f

    resultat = case type_calcul
              when 'pourcentage'
                montant * valeur
              when 'forfait'
                valeur
              when 'par_kw'
                puissance_kw = parametres[:puissance_kw]&.to_f || 1.0
                puissance_kw * valeur
              when 'par_m2'
                surface_m2 = parametres[:surface_m2]&.to_f || 1.0
                surface_m2 * valeur
              else
                0
              end

    # Appliquer le plafond si défini
    resultat = [resultat, plafond].min if plafond && plafond > 0

    # Appliquer le minimum si défini
    resultat = [resultat, minimum].max if minimum && minimum > 0

    # Arrondir à 2 décimales
    resultat.round(2)
  end

  # Obtenir toutes les communes supportées
  def communes_supportees
    donnees = charger_donnees
    donnees['communes'].map do |code_postal, data|
      {
        code_postal: code_postal,
        nom: data['nom'],
        province: data['province'],
        nombre_primes: data['primes']&.count(&method(:prime_active?)) || 0
      }
    end.sort_by { |c| c[:nom] }
  end

  # Obtenir les métadonnées du fichier
  def metadata
    charger_donnees['metadata']
  end

  # Obtenir les catégories de primes
  def categories_primes
    charger_donnees['categories_primes']
  end

  # Rechercher des primes par mots-clés
  def rechercher_primes(terme_recherche, code_postal = nil)
    donnees = charger_donnees
    resultats = []

    communes_a_chercher = if code_postal
                           [donnees['communes'][code_postal]].compact
                         else
                           donnees['communes'].values
                         end

    communes_a_chercher.each do |commune_data|
      commune_data['primes']&.each do |prime|
        next unless prime_active?(prime)

        if prime_contient_terme?(prime, terme_recherche)
          resultats << {
            commune: commune_data['nom'],
            code_postal: commune_data['code_postal'],
            prime: prime
          }
        end
      end
    end

    resultats
  end

  # Valider qu'une prime existe et est active
  def prime_valide?(code_postal, prime_id)
    commune_data = charger_donnees.dig('communes', code_postal)
    return false unless commune_data

    prime = commune_data['primes']&.find { |p| p['id'] == prime_id }
    prime && prime_active?(prime)
  end

  # Obtenir une prime spécifique
  def obtenir_prime(code_postal, prime_id)
    commune_data = charger_donnees.dig('communes', code_postal)
    return nil unless commune_data

    commune_data['primes']&.find { |p| p['id'] == prime_id && prime_active?(p) }
  end

  # Statistiques sur les primes
  def statistiques
    donnees = charger_donnees
    total_primes = 0
    primes_par_categorie = Hash.new(0)
    primes_par_type = Hash.new(0)

    donnees['communes'].each do |_code, commune|
      commune['primes']&.each do |prime|
        next unless prime_active?(prime)

        total_primes += 1
        primes_par_categorie[prime['categorie']] += 1
        primes_par_type[prime['type_calcul']] += 1
      end
    end

    {
      total_communes: donnees['metadata']['total_communes'],
      total_primes_actives: total_primes,
      repartition_categories: primes_par_categorie,
      repartition_types: primes_par_type,
      derniere_maj: metadata['last_updated']
    }
  end

  private

  def fichier_non_modifie?
    return false unless @last_loaded && File.exist?(FICHIER_PRIMES)
    File.mtime(FICHIER_PRIMES) == @last_loaded
  end

  def prime_active?(prime)
    prime['active'] != false # Par défaut true si non spécifié
  end

  def prime_contient_terme?(prime, terme)
    terme_downcase = terme.downcase
    [
      prime['nom'],
      prime['description'],
      prime['categorie'],
      prime['conditions']&.join(' ')
    ].compact.any? { |texte| texte.downcase.include?(terme_downcase) }
  end

  def donnees_fallback
    Rails.logger.warn "Utilisation données fallback primes communales"
    {
      'metadata' => {
        'version' => '1.0.0-fallback',
        'region' => 'flandre',
        'last_updated' => Time.current.strftime('%Y-%m-%d'),
        'total_communes' => 0,
        'source' => 'fallback'
      },
      'communes' => {},
      'categories_primes' => {},
      'types_calcul' => {}
    }
  end

  # Méthodes de classe pour un accès facile
  class << self
    delegate :primes_par_code_postal, :calculer_prime, :communes_supportees,
             :metadata, :categories_primes, :rechercher_primes,
             :prime_valide?, :obtenir_prime, :statistiques,
             to: :instance
  end
end
