require "test_helper"

class RegulatorySourceTest < ActiveSupport::TestCase
  test "url et label requis" do
    source = RegulatorySource.new(region: "wallonie")
    assert_not source.valid?
    assert_includes source.errors[:url], "can't be blank"
    assert_includes source.errors[:label], "can't be blank"
  end

  test "url unique" do
    RegulatorySource.create!(url: "https://example.be/a", label: "A")
    doublon = RegulatorySource.new(url: "https://example.be/a", label: "B")
    assert_not doublon.valid?
    assert_includes doublon.errors[:url], "has already been taken"
  end

  test "région limitée aux valeurs connues" do
    source = RegulatorySource.new(url: "https://example.be/b", label: "B", region: "france")
    assert_not source.valid?
  end

  test "active par défaut" do
    source = RegulatorySource.create!(url: "https://example.be/c", label: "C")
    assert source.active?
  end

  test "checked_recently? vrai si vérifié dans les 25 derniers jours" do
    source = RegulatorySource.create!(url: "https://example.be/d", label: "D", last_checked_at: 5.days.ago)
    assert source.checked_recently?
  end

  test "checked_recently? faux si jamais vérifié ou trop ancien" do
    jamais = RegulatorySource.create!(url: "https://example.be/e", label: "E")
    assert_not jamais.checked_recently?

    ancien = RegulatorySource.create!(url: "https://example.be/f", label: "F", last_checked_at: 40.days.ago)
    assert_not ancien.checked_recently?
  end
end
