require "test_helper"

class ProjectTest < ActiveSupport::TestCase
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

  def build_simulation(attrs = {})
    Simulation.create!({
      user: @user, property: @property, project: @project,
      titre: "Simulation isolation toiture", region: "wallonie", total_simule: 5_000
    }.merge(attrs))
  end

  test "total_finance additionne les montants des sources de financement" do
    @project.financing_sources.create!(label: "Épargne", source_type: "fonds_propres", amount: 10_000)
    @project.financing_sources.create!(label: "Crédit classique", source_type: "emprunt_bancaire", amount: 15_000)
    assert_equal 25_000, @project.total_finance
  end

  test "reste_a_financer est la différence entre le coût total et le financé" do
    @project.financing_sources.create!(label: "Épargne", source_type: "fonds_propres", amount: 20_000)
    assert_equal @project.total_devis_montant - 20_000, @project.reste_a_financer
  end

  test "sync_financing_sources! crée une ligne prime simulée pour une simulation sans dossier associé" do
    build_simulation
    @project.sync_financing_sources!

    source = @project.financing_sources.find_by(source_type: "prime")
    assert source.present?
    assert source.simule?
    assert_equal 5_000, source.amount.to_i
  end

  test "sync_financing_sources! passe la ligne prime à confirmé quand une demande est en cours" do
    simulation = build_simulation
    request = Request.create!(user: @user, property: @property, project: @project, simulation: simulation, status: "draft")
    RequestProgress.create!(
      request: request, email_suivi: "suivi-#{SecureRandom.hex(4)}@ren0vate.be",
      step: 1, pourcentage: 30, status_administratif: "en_cours", form_type: "regional_wallonie"
    )

    @project.sync_financing_sources!

    source = @project.financing_sources.find_by(source_type: "prime")
    assert source.confirme?
  end

  test "sync_financing_sources! passe la ligne prime à obtenu avec le montant accordé quand la demande est accordée" do
    simulation = build_simulation
    request = Request.create!(user: @user, property: @property, project: @project, simulation: simulation, status: "draft")
    RequestProgress.create!(
      request: request, email_suivi: "suivi-#{SecureRandom.hex(4)}@ren0vate.be",
      step: 1, pourcentage: 100, status_administratif: "accorde", montant_accorde: 4_200, form_type: "regional_wallonie"
    )

    @project.sync_financing_sources!

    source = @project.financing_sources.find_by(source_type: "prime")
    assert source.obtenu?
    assert_equal 4_200, source.amount.to_i
  end

  test "sync_financing_sources! synchronise le prêt bonifié wallon lié au projet" do
    PretWallonieDossier.create!(project: @project, user: @user, montant_emprunte: 30_000, statut: "accepte")

    @project.sync_financing_sources!

    source = @project.financing_sources.find_by(source_type: "pret_taux_zero")
    assert source.present?
    assert source.confirme?
    assert_equal 30_000, source.amount.to_i
  end

  test "sync_financing_sources! est idempotent — ne duplique pas les lignes à chaque appel" do
    build_simulation
    PretWallonieDossier.create!(project: @project, user: @user, montant_emprunte: 30_000)

    2.times { @project.sync_financing_sources! }

    assert_equal 1, @project.financing_sources.where(source_type: "prime").count
    assert_equal 1, @project.financing_sources.where(source_type: "pret_taux_zero").count
  end
end
