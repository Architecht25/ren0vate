require "test_helper"

class FinancingSourceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Maison Namur",
      rue: "Rue de Namur",
      numero: "1",
      code_postal: "5000",
      commune: "Namur",
      region: "wallonie",
      annee_construction: 2000,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation Namur",
      statut: "en_cours",
      architecte_devis_montant: 20_000,
      contractor_devis_montant: 100_000
    )
  end

  def build_source(attrs = {})
    FinancingSource.new({ project: @project, label: "Épargne", source_type: "fonds_propres", amount: 10_000 }.merge(attrs))
  end

  test "valide avec label et montant positif" do
    assert build_source.valid?
  end

  test "invalide sans label" do
    source = build_source(label: nil)
    assert_not source.valid?
    assert_includes source.errors[:label], "can't be blank"
  end

  test "invalide avec un montant négatif" do
    source = build_source(amount: -1)
    assert_not source.valid?
    assert_includes source.errors[:amount], "must be greater than or equal to 0"
  end

  test "percent_of calcule la proportion par rapport à un total" do
    source = build_source(amount: 30_000)
    assert_equal 25.0, source.percent_of(120_000)
  end

  test "percent_of renvoie 0 si le total est nul" do
    source = build_source(amount: 30_000)
    assert_equal 0, source.percent_of(0)
  end

  test "auto_synced? est faux pour une ligne saisie manuellement" do
    assert_not build_source.auto_synced?
  end

  test "auto_synced? est vrai pour une ligne liée à une simulation ou un dossier de prêt" do
    simulation = Simulation.create!(user: @user, property: @property, project: @project, titre: "Sim", region: "wallonie")
    assert build_source(simulation: simulation).auto_synced?

    dossier = PretWallonieDossier.create!(project: @project, user: @user, montant_emprunte: 20_000)
    assert build_source(pret_wallonie_dossier: dossier).auto_synced?
  end
end
