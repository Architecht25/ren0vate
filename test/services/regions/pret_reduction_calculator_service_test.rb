require "test_helper"

class PretReductionCalculatorServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(situation_familiale: "celibataire", nombre_enfants: 0, revenu_demandeur: 28_900)
  end

  def calculate(montant_projet, property: nil, ecomateriaux: false)
    Regions::Wallonie::PretReduction::CalculatorService.new(
      @user, montant_projet: montant_projet, property: property, ecomateriaux: ecomateriaux
    ).calculate
  end

  def build_property(type_bien_wallonie: nil, profil_demandeur: nil, nombre_lots_copropriete: nil)
    @user.properties.create!(
      titre: "Bien test",
      rue: "Rue de Namur",
      numero: "1",
      code_postal: "5000",
      commune: "Namur",
      region: "wallonie",
      annee_construction: 2000,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire",
      type_bien_wallonie: type_bien_wallonie,
      profil_demandeur: profil_demandeur,
      nombre_lots_copropriete: nombre_lots_copropriete,
      skip_onboarding_validation: true
    )
  end

  test "réduction = montant projet x taux quand sous le plafond" do
    result = calculate(20_000)
    assert_equal 20_000, result[:montant_projet_retenu]
    assert_equal 0.50, result[:taux_reduction]
    assert_equal 10_000.0, result[:reduction_solde]
  end

  test "montant projet plafonné à 75 000€ pour une maison unifamiliale (défaut sans property)" do
    result = calculate(90_000)
    assert_equal 75_000, result[:plafond_emprunt]
    assert_equal 75_000, result[:montant_projet_retenu]
    assert_equal 37_500.0, result[:reduction_solde]
  end

  test "montant projet plafonné à 75 000€ pour une maison unifamiliale explicite" do
    property = build_property(type_bien_wallonie: "maison_unifamiliale")
    result = calculate(90_000, property: property)
    assert_equal 75_000, result[:plafond_emprunt]
    assert_equal 75_000, result[:montant_projet_retenu]
  end

  test "montant projet plafonné à 60 000€ pour un appartement/studio" do
    property = build_property(type_bien_wallonie: "appartement_studio")
    result = calculate(90_000, property: property)
    assert_equal 60_000, result[:plafond_emprunt]
    assert_equal 60_000, result[:montant_projet_retenu]
    assert_equal 30_000.0, result[:reduction_solde]
  end

  test "réduction nulle pour la tranche à taux 0%" do
    @user.update!(revenu_demandeur: 122_800)
    result = calculate(50_000)
    assert_equal 0.0, result[:taux_reduction]
    assert_equal 0.0, result[:reduction_solde]
    assert_equal :reduit, result[:taux_interet]
  end

  test "majoration écomatériaux : +5 points ajoutés au taux de la tranche" do
    result = calculate(20_000, ecomateriaux: true)
    assert_equal 0.50, result[:taux_reduction_base]
    assert_equal 0.55, result[:taux_reduction]
    assert_equal 11_000.0, result[:reduction_solde]
  end

  test "pas de majoration écomatériaux par défaut" do
    result = calculate(20_000)
    assert_equal false, result[:ecomateriaux]
    assert_equal result[:taux_reduction_base], result[:taux_reduction]
  end

  test "taux d'intérêt du prêt renvoyé selon la tranche de revenu" do
    result = calculate(20_000)
    assert_equal :zero, result[:taux_interet]
    assert_equal "0%", result[:taux_interet_label]
  end

  test "plafond parties communes copropriété à 600 000€ si moins de 20 lots" do
    property = build_property(profil_demandeur: "syndic_copropriété", nombre_lots_copropriete: 12)
    result = calculate(700_000, property: property)
    assert_equal 600_000, result[:plafond_emprunt]
    assert_equal 600_000, result[:montant_projet_retenu]
  end

  test "plafond parties communes copropriété à 750 000€ si 20 lots ou plus" do
    property = build_property(profil_demandeur: "syndic_copropriété", nombre_lots_copropriete: 20)
    result = calculate(800_000, property: property)
    assert_equal 750_000, result[:plafond_emprunt]
    assert_equal 750_000, result[:montant_projet_retenu]
  end

  test "plafond parties communes par défaut à 600 000€ si nombre de lots non renseigné" do
    property = build_property(profil_demandeur: "syndic_copropriété")
    result = calculate(700_000, property: property)
    assert_equal 600_000, result[:plafond_emprunt]
  end
end
