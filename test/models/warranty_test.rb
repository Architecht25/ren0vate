require "test_helper"

class WarrantyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  test "la date de fin doit être postérieure à la date de début" do
    warranty = projects(:one).warranties.build(label: "Toiture", start_date: Date.current, end_date: Date.current - 1.day)
    assert_not warranty.valid?
  end

  test "expired? et expiring_soon? reflètent la date de fin" do
    expired = projects(:one).warranties.create!(label: "Expirée", start_date: 3.years.ago, end_date: 1.day.ago)
    assert expired.expired?
    assert_not expired.expiring_soon?

    soon = projects(:one).warranties.create!(label: "Bientôt", start_date: 1.year.ago, end_date: 30.days.from_now)
    assert_not soon.expired?
    assert soon.expiring_soon?

    far = projects(:one).warranties.create!(label: "Loin", start_date: Date.current, end_date: 5.years.from_now)
    assert_not far.expiring_soon?
  end
end
