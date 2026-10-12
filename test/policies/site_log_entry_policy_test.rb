require "test_helper"

class SiteLogEntryPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @roofer = User.create!(email: "roofer_siteLog@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

    @entry = @project.site_log_entries.create!(body: "Pose terminée", lot: @toiture, author: @roofer, observed_at: Time.current)
  end

  test "l'auteur peut modifier/supprimer sa propre observation" do
    assert SiteLogEntryPolicy.new(@roofer, @entry).update?
    assert SiteLogEntryPolicy.new(@roofer, @entry).destroy?
  end

  test "un autre membre ne peut pas modifier l'observation d'un autre, même visible" do
    other_roofer = User.create!(email: "other_roofer_siteLog@example.com", password: "password123", nom: "Autre")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

    assert SiteLogEntryPolicy.new(other_roofer, @entry).show?
    assert_not SiteLogEntryPolicy.new(other_roofer, @entry).update?
  end

  test "un entrepreneur scopé à un autre lot ne voit pas l'observation" do
    other_roofer = User.create!(email: "menuiserie_roofer@example.com", password: "password123", nom: "Menuisier")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)

    assert_not SiteLogEntryPolicy.new(other_roofer, @entry).show?
  end

  test "le propriétaire peut toujours supprimer, même l'observation d'un autre" do
    assert SiteLogEntryPolicy.new(@owner, @entry).destroy?
  end
end
