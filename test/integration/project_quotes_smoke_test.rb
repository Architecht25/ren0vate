require "test_helper"

class ProjectQuotesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects, :subscriptions

  setup do
    @owner = users(:individual_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:two)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    sign_in @owner
  end

  test "index et new s'affichent sans erreur" do
    get project_project_quotes_path(@project, locale: :fr)
    assert_response :success

    get new_project_project_quote_path(@project, locale: :fr)
    assert_response :success
  end

  test "créer un devis avec des lignes calcule les totaux" do
    post project_project_quotes_path(@project, locale: :fr), params: {
      project_quote: {
        entreprise_nom: "Couvreur SA",
        lot_id: @toiture.id,
        lines_attributes: { "0" => { description: "Pose", quantite: 10, unite: "m2", prix_unitaire_ht: 50 } }
      }
    }

    quote = ProjectQuote.last
    assert_redirected_to project_quote_path(quote, locale: :fr)
    assert_equal 500, quote.montant_ht
  end

  test "comparatif de devis d'un lot s'affiche sans erreur" do
    get project_lot_quotes_comparison_path(@project, @toiture, locale: :fr)
    assert_response :success
  end

  test "index des avenants et proposition s'affichent sans erreur" do
    get project_project_amendments_path(@project, locale: :fr)
    assert_response :success

    get new_project_project_amendment_path(@project, locale: :fr)
    assert_response :success
  end

  test "proposer puis valider un avenant" do
    post project_project_amendments_path(@project, locale: :fr), params: {
      project_amendment: { motif: "Isolation supplémentaire", delta_montant: 1200 }
    }
    amendment = ProjectAmendment.last
    assert_redirected_to project_project_amendments_path(@project, locale: :fr)

    patch decide_project_amendment_path(amendment, locale: :fr, status: "valide")
    assert amendment.reload.valide?
  end
end
