# Service pour gérer les primes communales de Bruxelles depuis le fichier JSON
class PrimesCommunalesBruxellesService
  include Singleton

  FICHIER_PRIMES = Rails.root.join('public', 'data', 'primes_communales_bruxelles.json')

  def initialize
    @donnees = nil
    @derniere_lecture = nil
  end

  # Charger les données depuis le fichier JSON
  def charger_donnees
    # Cache simple basé sur la modification du fichier
    if @donnees.nil? || fichier_modifie?
      Rails.logger.info "Chargement des données primes communales Bruxelles depuis #{FICHIER_PRIMES}"

      begin
        contenu = File.read(FICHIER_PRIMES)
        @donnees = JSON.parse(contenu)
        @derniere_lecture = File.mtime(FICHIER_PRIMES)

        Rails.logger.info "✅ Données primes Bruxelles chargées : #{@donnees.dig('communes')&.count || 0} communes"

      rescue JSON::ParserError => e
        Rails.logger.error "❌ Erreur JSON dans #{FICHIER_PRIMES}: #{e.message}"
        @donnees = { 'communes' => {}, 'metadata' => {}, 'categories' => [], 'types_calcul' => [] }

      rescue Errno::ENOENT => e
        Rails.logger.error "❌ Fichier manquant #{FICHIER_PRIMES}: #{e.message}"
        @donnees = { 'communes' => {}, 'metadata' => {}, 'categories' => [], 'types_calcul' => [] }
      end
    end

    @donnees
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
    return 0.0 unless prime_data && montant_travaux.positive?

    montant_calcule = case prime_data['type_calcul']
    when 'pourcentage'
      calculer_pourcentage(prime_data, montant_travaux)
    when 'forfait'
      calculer_forfait(prime_data)
    when 'par_unite'
      calculer_par_unite(prime_data, parametres)
    else
      0.0
    end

    # Appliquer les limites minimum et maximum
    montant_calcule = [montant_calcule, prime_data['minimum'] || 0].max
    montant_calcule = [montant_calcule, prime_data['plafond'] || Float::INFINITY].min

    montant_calcule.round(2)
  end

  # Obtenir toutes les communes supportées
  def communes_supportees
    donnees = charger_donnees
    communes = donnees.dig('communes') || {}

    communes.map do |code_postal, commune_data|
      {
        code_postal: code_postal,
        nom: commune_data['nom'],
        province: commune_data['province'],
        nombre_primes: commune_data['primes']&.count(&method(:prime_active?)) || 0
      }
    end.sort_by { |c| c[:code_postal] }
  end

  # Obtenir les métadonnées du fichier
  def metadata
    donnees = charger_donnees
    donnees['metadata'] || {}
  end

  # Obtenir les catégories de primes
  def categories_primes
    donnees = charger_donnees
    donnees['categories'] || []
  end

  # Obtenir les types de calcul
  def types_calcul
    donnees = charger_donnees
    donnees['types_calcul'] || []
  end

  # Rechercher des primes par mots-clés
  def rechercher_primes(terme, code_postal_filtre = nil)
    donnees = charger_donnees
    resultats = []
    terme_normalise = terme.downcase.strip

    communes = code_postal_filtre ?
      { code_postal_filtre => donnees.dig('communes', code_postal_filtre) }.compact :
      donnees.dig('communes') || {}

    communes.each do |code_postal, commune_data|
      next unless commune_data

      primes_filtrees = (commune_data['primes'] || []).select do |prime|
        prime_active?(prime) && (
          prime['nom'].downcase.include?(terme_normalise) ||
          prime['description'].downcase.include?(terme_normalise) ||
          prime['categorie'].downcase.include?(terme_normalise)
        )
      end

      unless primes_filtrees.empty?
        resultats << {
          commune: commune_data['nom'],
          code_postal: code_postal,
          primes: primes_filtrees
        }
      end
    end

    resultats
  end

  # Obtenir une prime spécifique
  def obtenir_prime(code_postal, prime_id)
    commune_data = primes_par_code_postal(code_postal)
    return nil unless commune_data

    commune_data[:primes].find { |prime| prime['id'] == prime_id }
  end

  # Vérifier si une prime existe et est valide
  def prime_valide?(code_postal, prime_id)
    prime = obtenir_prime(code_postal, prime_id)
    prime && prime_active?(prime)
  end

  # Statistiques sur les primes
  def statistiques
    donnees = charger_donnees
    communes = donnees.dig('communes') || {}

    total_primes = 0
    communes_avec_primes = 0
    repartition_categories = Hash.new(0)
    repartition_types = Hash.new(0)

    communes.each do |code_postal, commune_data|
      primes_actives = (commune_data['primes'] || []).select(&method(:prime_active?))

      if primes_actives.any?
        communes_avec_primes += 1
        total_primes += primes_actives.count

        primes_actives.each do |prime|
          repartition_categories[prime['categorie']] += 1
          repartition_types[prime['type_calcul']] += 1
        end
      end
    end

    {
      nombre_communes: communes.count,
      communes_avec_primes: communes_avec_primes,
      total_primes: total_primes,
      moyenne_primes_par_commune: communes_avec_primes.positive? ? (total_primes.to_f / communes_avec_primes).round(1) : 0,
      repartition_categories: repartition_categories,
      repartition_types: repartition_types,
      derniere_maj: metadata['derniere_maj'],
      version: metadata['version']
    }
  end

  # Méthodes de classe pour l'interface publique
  class << self
    delegate :primes_par_code_postal, :calculer_prime, :obtenir_prime, :prime_valide?,
             :communes_supportees, :rechercher_primes, :categories_primes, :types_calcul,
             :metadata, :statistiques, to: :instance
  end

  private

  def fichier_modifie?
    return true unless @derniere_lecture
    return true unless File.exist?(FICHIER_PRIMES)

    File.mtime(FICHIER_PRIMES) > @derniere_lecture
  end

  def prime_active?(prime)
    prime['active'] == true
  end

  def calculer_pourcentage(prime_data, montant_travaux)
    pourcentage = prime_data['valeur'] || 0
    (montant_travaux * pourcentage / 100.0)
  end

  def calculer_forfait(prime_data)
    prime_data['valeur'] || 0
  end

  def calculer_par_unite(prime_data, parametres)
    valeur_unitaire = prime_data['valeur'] || 0
    quantite = parametres[:quantite] || parametres['quantite'] || 1

    valeur_unitaire * quantite.to_f
  end
end
