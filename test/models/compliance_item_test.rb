require "test_helper"

class ComplianceItemTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  test "une obligation sans échéance n'est jamais en retard" do
    item = projects(:one).compliance_items.create!(label: "PEB", region: "wallonie", category: "peb")
    assert_not item.overdue?
  end

  test "une obligation avec échéance passée et non obtenue est en retard" do
    item = projects(:one).compliance_items.create!(label: "Permis", region: "wallonie", category: "permis", due_date: 1.day.ago)
    assert item.overdue?
  end

  test "une obligation obtenue n'est jamais en retard, même avec échéance passée" do
    item = projects(:one).compliance_items.create!(label: "Permis", region: "wallonie", category: "permis", due_date: 1.day.ago, status: "obtenu")
    assert_not item.overdue?
  end
end
