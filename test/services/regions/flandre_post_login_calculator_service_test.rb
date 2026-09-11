require "test_helper"

class FlandrePostLoginCalculatorServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
  end

  def service(user: @user, params: {})
    Regions::Flandre::FlandrePostLoginCalculatorService.new(params, user: user)
  end

  # -------------------------------------------------------------------------
  # Plafonds de groupe par catégorie (apply_group_ceilings_to_all)
  # -------------------------------------------------------------------------

  test "plafond de groupe toiture catégorie 3 : réduit proportionnellement les primes du groupe en cas de dépassement" do
    result = service.apply_group_ceilings_to_all({ "isolation_toiture" => 5000.0 }, "3")

    # Plafond toiture catégorie 3 = 4025€ ; 5000€ dépasse le plafond
    assert_in_delta 4025.0, result["isolation_toiture"], 0.01
  end

  test "plafond de groupe toiture catégorie 4 : plafond plus élevé, pas de réduction si sous le plafond" do
    result = service.apply_group_ceilings_to_all({ "isolation_toiture" => 5000.0 }, "4")

    # Plafond toiture catégorie 4 = 5750€ ; 5000€ reste sous le plafond => inchangé
    assert_in_delta 5000.0, result["isolation_toiture"], 0.01
  end

  test "plafond de groupe murs : catégorie 3 (3500€) plus bas que catégorie 4 (5000€) pour un même montant" do
    montants = { "isolation_murs" => 4200.0 }

    result_cat3 = service.apply_group_ceilings_to_all(montants, "3")
    result_cat4 = service.apply_group_ceilings_to_all(montants, "4")

    assert_in_delta 3500.0, result_cat3["isolation_murs"], 0.01
    assert_in_delta 4200.0, result_cat4["isolation_murs"], 0.01
    assert result_cat3["isolation_murs"] < result_cat4["isolation_murs"]
  end

  test "cas limite : catégories 1 et 2 ne subissent aucun plafonnement de groupe, contrairement aux catégories 3 et 4" do
    montants = { "isolation_toiture" => 9000.0, "isolation_murs" => 9000.0 }

    result_cat1 = service.apply_group_ceilings_to_all(montants, "1")
    result_cat2 = service.apply_group_ceilings_to_all(montants, "2")
    result_cat3 = service.apply_group_ceilings_to_all(montants, "3")
    result_cat4 = service.apply_group_ceilings_to_all(montants, "4")

    # Catégories 1-2 : aucun plafond appliqué, montants inchangés
    assert_in_delta 9000.0, result_cat1["isolation_toiture"], 0.01
    assert_in_delta 9000.0, result_cat2["isolation_murs"], 0.01

    # Catégories 3-4 : plafonnement effectif, et le plafonnement diffère entre 3 et 4
    assert_in_delta 4025.0, result_cat3["isolation_toiture"], 0.01
    assert_in_delta 5750.0, result_cat4["isolation_toiture"], 0.01
    assert result_cat3["isolation_toiture"] < result_cat4["isolation_toiture"]
  end

  test "plafond de groupe sol : répartition proportionnelle entre isolation_sol et renovation_sol du même groupe" do
    # Le groupe 'sol' regroupe isolation_sol et renovation_sol ; le plafond s'applique
    # au total du groupe et réduit chaque membre au même prorata.
    montants = { "isolation_sol" => 900.0, "renovation_sol" => 600.0 }

    result = service.apply_group_ceilings_to_all(montants, "3")

    # Plafond sol catégorie 3 = 1050€, total avant plafond = 1500€ => facteur 0.7
    assert_in_delta 630.0, result["isolation_sol"], 0.01
    assert_in_delta 420.0, result["renovation_sol"], 0.01
    assert_in_delta 1050.0, result["isolation_sol"] + result["renovation_sol"], 0.01
  end

  # -------------------------------------------------------------------------
  # Prime Amiante (calculate_all_primes) : 3 tarifs 8€ / 12€ / 4€ au m²
  # -------------------------------------------------------------------------

  test "prime amiante : 8€/m² pour la toiture seule" do
    result = service.calculate_all_primes({ "amiante" => { "surface_toiture" => 10, "surface_murs" => 0 } })

    assert_in_delta 80.0, result[:group_totals]["amiante"], 0.01
    assert_in_delta 80.0, result[:prime_results]["amiante"][:amount], 0.01
  end

  test "prime amiante : 4€/m² pour les murs seuls (sans toiture)" do
    result = service.calculate_all_primes({ "amiante" => { "surface_toiture" => 0, "surface_murs" => 5 } })

    assert_in_delta 20.0, result[:group_totals]["amiante"], 0.01
  end

  test "prime amiante : 12€/m² pour les murs quand la toiture est incluse" do
    result = service.calculate_all_primes({ "amiante" => { "surface_toiture" => 10, "surface_murs" => 5 } })

    # 10 m² toiture x 8€ + 5 m² murs x 12€ (tarif majoré car toiture incluse)
    assert_in_delta 140.0, result[:group_totals]["amiante"], 0.01
  end

  test "prime amiante : aucune surface spécifiée => pas de montant" do
    result = service.calculate_all_primes({ "amiante" => { "surface_toiture" => 0, "surface_murs" => 0 } })

    assert_nil result[:prime_results]["amiante"]
    assert_equal 0.0, result[:group_totals].fetch("amiante", 0.0)
  end

  # -------------------------------------------------------------------------
  # Intégration calculate_prime / calculate_all_primes avec de vraies primes
  # -------------------------------------------------------------------------

  test "calculate_all_primes plafonne bien le total du groupe toiture pour une catégorie 3 via de vraies primes" do
    category_record = Category.create!(code: "flandre_test_calc", description: "Catégorie test calcul Flandre", region: "flandre")

    # isolation_toiture et renovation_toiture appartiennent tous les deux au groupe
    # de plafond 'toiture' (cf. groupes_plafond dans apply_group_ceilings_to_all).
    # Chacun a individuellement un plafond de 4025€ (catégorie 3), mais c'est le
    # TOTAL du groupe qui doit être ramené à 4025€, pas chaque prime séparément.
    %w[isolation_toiture renovation_toiture].each do |slug|
      Prime.create!(
        slug: slug,
        titre: slug.humanize,
        region: "flandre",
        type_de_valeur: "dynamique",
        eligible_categories: %w[3 4],
        category_id: category_record.id,
        valeurs_par_categorie: {
          "3" => { "type" => "pourcentage_et_plafond", "pourcentage" => 35, "plafond" => 4025 },
          "4" => { "type" => "pourcentage_et_plafond", "pourcentage" => 50, "plafond" => 5750 }
        }
      )
    end

    calculator = service
    calculator.instance_variable_set(:@category, "3")

    # Facture de 20 000€ à 35% = 7 000€ chacun (déjà plafonné individuellement à 4025€ chacun),
    # soit 8050€ à eux deux : le plafond de GROUPE (4025€) doit encore réduire proportionnellement.
    result = calculator.calculate_all_primes({
      "primes" => {
        "isolation_toiture" => { "value" => 20_000 },
        "renovation_toiture" => { "value" => 20_000 }
      }
    })

    toiture = result[:prime_results]["isolation_toiture"][:calculated_amount]
    renovation = result[:prime_results]["renovation_toiture"][:calculated_amount]

    assert_in_delta 4025.0, toiture + renovation, 0.01
    assert_in_delta 2012.5, toiture, 0.01
    assert_in_delta 2012.5, renovation, 0.01
    assert result[:prime_results]["isolation_toiture"][:ceiling_applied]
    assert result[:prime_results]["renovation_toiture"][:ceiling_applied]
  end
end
