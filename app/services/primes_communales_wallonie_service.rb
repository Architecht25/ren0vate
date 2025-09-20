class PrimesCommunalesWallonieService
  include Singleton

  WALLONIE_DATA_PATH = Rails.root.join('public', 'data', 'primes_communales_wallonie.json').freeze

  def self.method_missing(method_name, *args, &block)
    instance.send(method_name, *args, &block)
  end

  def self.respond_to_missing?(method_name, include_private = false)
    instance.respond_to?(method_name) || super
  end

  def initialize
    @data_cache = nil
    @last_loaded = nil
    load_data
  end

  # Chargement et mise en cache des données
  def load_data
    return @data_cache if data_fresh?

    Rails.logger.info "Chargement des données primes communales Wallonie depuis #{WALLONIE_DATA_PATH}"

    unless File.exist?(WALLONIE_DATA_PATH)
      Rails.logger.error "Fichier primes Wallonie non trouvé : #{WALLONIE_DATA_PATH}"
      return { "communes" => {}, "metadata" => {} }
    end

    @data_cache = JSON.parse(File.read(WALLONIE_DATA_PATH))
    @last_loaded = Time.current

    Rails.logger.info "✅ Données primes Wallonie chargées : #{@data_cache.dig('communes')&.size || 0} communes"
    @data_cache
  rescue JSON::ParserError => e
    Rails.logger.error "Erreur parsing JSON Wallonie : #{e.message}"
    { "communes" => {}, "metadata" => {} }
  end

  # Vérifier si les données sont fraîches (moins de 1 heure)
  def data_fresh?
    @data_cache && @last_loaded && @last_loaded > 1.hour.ago
  end

  # Recherche par code postal (alias pour compatibilité API)
  def primes_par_code_postal(code_postal)
    rechercher_par_code_postal(code_postal)
  end

  # Recherche par code postal
  def rechercher_par_code_postal(code_postal)
    data = load_data
    commune_data = data.dig('communes', code_postal.to_s)

    return nil unless commune_data

    {
      commune: commune_data['nom'],
      code_postal: code_postal.to_s,
      province: commune_data['province'],
      contact: commune_data['contact'],
      site_web: commune_data['site_web'],
      derniere_maj: commune_data['derniere_maj'],
      nombre_primes: commune_data['primes']&.size || 0,
      primes: commune_data['primes'] || []
    }
  end

  # Vérifier si une prime est valide
  def prime_valide?(code_postal, prime_id)
    commune_data = rechercher_par_code_postal(code_postal)
    return false unless commune_data

    commune_data[:primes].any? { |prime| prime['id'] == prime_id && prime['active'] }
  end

  # Obtenir une prime spécifique
  def obtenir_prime(code_postal, prime_id)
    commune_data = rechercher_par_code_postal(code_postal)
    return nil unless commune_data

    commune_data[:primes].find { |prime| prime['id'] == prime_id }
  end

  # Calculer le montant d'une prime
  def calculer_prime(prime_data, montant_travaux, parametres = {})
    return 0 unless prime_data&.dig('active')

    type_calcul = prime_data['type_calcul']
    valeur = prime_data['valeur'].to_f
    plafond = prime_data['plafond']&.to_f
    minimum = prime_data['minimum']&.to_f

    montant_calcule = case type_calcul
    when 'pourcentage'
      montant_travaux * (valeur / 100.0)
    when 'forfait'
      valeur
    when 'montant_m2'
      surface = parametres[:surface]&.to_f || parametres['surface']&.to_f || 0
      surface * valeur
    when 'montant_unite'
      quantite = parametres[:quantite]&.to_f || parametres['quantite']&.to_f || 0
      quantite * valeur
    else
      0
    end

    # Appliquer plafond et minimum
    montant_calcule = [montant_calcule, plafond].compact.min if plafond
    montant_calcule = [montant_calcule, minimum].compact.max if minimum

    montant_calcule.round(0)
  end

  # Lister toutes les communes supportées
  def communes_supportees
    data = load_data
    communes = data.dig('communes') || {}

    communes.map do |code_postal, commune_data|
      {
        code_postal: code_postal,
        nom: commune_data['nom'],
        province: commune_data['province'],
        nombre_primes: commune_data['primes']&.size || 0
      }
    end.sort_by { |c| c[:nom] }
  end

  # Recherche par nom de commune
  def rechercher_par_nom(nom_commune)
    communes = communes_supportees
    communes.select do |commune|
      commune[:nom].downcase.include?(nom_commune.downcase)
    end
  end

  # Statistiques globales
  def statistiques
    data = load_data
    communes = data.dig('communes') || {}

    total_communes = communes.size
    total_primes = communes.values.sum { |c| c['primes']&.size || 0 }

    categories = communes.values
                        .flat_map { |c| c['primes'] || [] }
                        .group_by { |p| p['categorie'] }
                        .transform_values(&:size)

    {
      total_communes: total_communes,
      total_primes: total_primes,
      repartition_categories: categories,
      derniere_mise_a_jour: data.dig('metadata', 'derniere_mise_a_jour'),
      version: data.dig('metadata', 'version')
    }
  end

  # Codes postaux wallons valides (approximation)
  def codes_postaux_wallons
    %w[
      1300 1301 1310 1315 1320 1325 1330 1332 1340 1341 1342 1348 1350 1357 1360 1367 1370 1380 1390
      4000 4020 4030 4031 4032 4040 4041 4042 4050 4051 4052 4053 4100 4101 4102 4120 4121 4122 4130
      4140 4141 4160 4161 4162 4163 4170 4171 4180 4181 4190 4219 4250 4252 4253 4254 4260 4261 4263
      4280 4317 4340 4347 4350 4351 4357 4360 4361 4367 4400 4420 4432 4450 4452 4458 4460 4480 4500
      4520 4530 4537 4540 4557 4560 4570 4577 4590 4601 4602 4607 4608 4620 4621 4623 4624 4630 4631
      4632 4633 4650 4651 4652 4653 4654 4670 4671 4672 4680 4681 4682 4683 4684 4690 4691 4692 4700
      4701 4702 4710 4711 4720 4721 4722 4728 4730 4731 4732 4750 4760 4761 4762 4771 4780 4782 4783
      4784 4790 4791 4800 4801 4802 4820 4821 4830 4831 4834 4837 4845 4850 4851 4860 4861 4870 4877
      4880 4890 4900 4910 4920 4950 4960 4970 4980 4987 4990
      5000 5001 5002 5003 5004 5020 5021 5022 5024 5030 5031 5032 5060 5070 5080 5081 5100 5101 5140
      5150 5170 5190 5300 5310 5330 5332 5333 5334 5336 5500 5501 5502 5503 5504 5520 5521 5522 5523
      5524 5530 5537 5540 5541 5542 5543 5544 5550 5555 5560 5561 5562 5563 5564 5570 5571 5572 5573
      5574 5575 5576 5580 5590 5600 5620 5630 5640 5641 5644 5646 5650 5651 5660 5670 5680 5681 5690
      6000 6001 6010 6020 6030 6031 6032 6040 6041 6042 6043 6044 6060 6061 6110 6111 6120 6140 6141
      6142 6143 6150 6200 6210 6211 6220 6221 6222 6223 6224 6230 6238 6240 6250 6280 6460 6461 6462
      6463 6464 6470 6500 6511 6530 6531 6532 6533 6534 6536 6540 6542 6543 6560 6567 6590 6591 6592
      6593 6594 6595 6596 6600 6637 6640 6660 6661 6662 6663 6666 6670 6671 6672 6673 6674 6680 6681
      6686 6687 6688 6690 6692 6700 6701 6704 6706 6717 6720 6721 6723 6724 6730 6740 6741 6742 6743
      6744 6747 6750 6760 6761 6762 6767 6769 6780 6781 6782 6790 6791 6792 6793 6794 6795 6820 6821
      6823 6824 6830 6831 6832 6833 6834 6836 6838 6840 6850 6851 6852 6856 6860 6870 6880 6887 6890
      6900 6920 6921 6922 6924 6927 6929 6940 6941 6950 6951 6952 6953 6960 6970 6971 6972 6980 6982
      6990 6997
      7000 7011 7012 7020 7021 7022 7030 7031 7032 7033 7034 7040 7041 7050 7060 7061 7062 7070 7080
      7090 7100 7110 711 7120 7130 7131 7133 7134 7140 7141 7160 7170 7180 7181 7190 7300 7301 7320
      7321 7322 7330 7331 7332 7333 7334 7340 7350 7370 7380 7387 7390 7500 7501 7502 7503 7506 7520
      7521 7522 7530 7531 7532 7533 7534 7536 7540 7542 7543 7548 7600 7601 7602 7608 7700 7711 7712
      7730 7740 7742 7743 7800 7801 7802 7803 7804 7810 7812 7822 7823 7830 7831 7832 7833 7850 7860
      7863 7864 7866 7870 7880 7890 7900 7901 7903 7904 7906 7910 7911 7912 7940 7950 7970 7971 7972
      7973
    ]
  end

  # Valider qu'un code postal est wallon
  def code_postal_wallon?(code_postal)
    codes_postaux_wallons.include?(code_postal.to_s)
  end

  # Obtenir les métadonnées du fichier
  def metadata
    data = load_data
    data['metadata'] || {}
  end

  # Rechercher des primes par mots-clés
  def rechercher_primes(terme, code_postal_filtre = nil)
    data = load_data
    resultats = []
    terme_normalise = terme.downcase.strip

    communes = code_postal_filtre ?
      { code_postal_filtre => data.dig('communes', code_postal_filtre) }.compact :
      data.dig('communes') || {}

    communes.each do |code_postal, commune_data|
      next unless commune_data

      primes_filtrees = (commune_data['primes'] || []).select do |prime|
        prime['active'] && (
          prime['nom'].downcase.include?(terme_normalise) ||
          prime['description'].downcase.include?(terme_normalise) ||
          prime['categorie'].downcase.include?(terme_normalise)
        )
      end

      if primes_filtrees.any?
        resultats << {
          commune: commune_data['nom'],
          code_postal: code_postal,
          province: commune_data['province'],
          primes: primes_filtrees
        }
      end
    end

    resultats
  end

  private

  # Reload des données (pour les tests ou admin)
  def reload_data!
    @data_cache = nil
    @last_loaded = nil
    load_data
  end
end
