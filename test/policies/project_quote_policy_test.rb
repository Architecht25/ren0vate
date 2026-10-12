require "test_helper"

class ProjectQuotePolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @roofer = User.create!(email: "roofer_quote@example.com", password: "password123", nom: "Couvreur")
    roofer_membership = @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active")
    roofer_membership.project_member_lots.create!(lot: @toiture)

    @outsider = User.create!(email: "outsider_quote@example.com", password: "password123", nom: "Outsider")

    @quote = @project.project_quotes.create!(entreprise_nom: "Couvreur SA", lot: @toiture, submitted_by: @roofer)
  end

  test "le propriétaire voit et décide, l'entrepreneur dépose dans son lot mais ne décide pas" do
    assert ProjectQuotePolicy.new(@owner, @quote).show?
    assert ProjectQuotePolicy.new(@owner, @quote).decide?
    assert ProjectQuotePolicy.new(@roofer, @quote).show?
    assert_not ProjectQuotePolicy.new(@roofer, @quote).decide?
  end

  test "un entrepreneur scopé à un autre lot ne voit pas le devis" do
    other_roofer = User.create!(email: "other_roofer_quote@example.com", password: "password123", nom: "Autre couvreur")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)

    assert_not ProjectQuotePolicy.new(other_roofer, @quote).show?
  end

  test "un tiers hors chantier ne voit rien" do
    assert_not ProjectQuotePolicy.new(@outsider, @quote).show?
  end

  test "l'entrepreneur peut modifier son devis tant qu'il est en brouillon, pas après envoi" do
    assert ProjectQuotePolicy.new(@roofer, @quote).update?
    @quote.update!(status: "envoye")
    assert_not ProjectQuotePolicy.new(@roofer, @quote).update?
  end
end
