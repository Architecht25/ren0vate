require "test_helper"

module ProjectQuotes
  class ComparatorServiceTest < ActiveSupport::TestCase
    fixtures :users, :properties, :projects

    setup do
      @owner = users(:freemium_user)
      @project = projects(:one)
      @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)

      @cheap_quote = @project.project_quotes.create!(
        entreprise_nom: "Entreprise A", lot: @toiture,
        lines_attributes: [{ description: "Démontage", quantite: 1, unite: "forfait", prix_unitaire_ht: 500 }]
      )
      @expensive_quote = @project.project_quotes.create!(
        entreprise_nom: "Entreprise B", lot: @toiture,
        lines_attributes: [
          { description: "Démontage", quantite: 1, unite: "forfait", prix_unitaire_ht: 800 },
          { description: "Évacuation gravats", quantite: 1, unite: "forfait", prix_unitaire_ht: 200 }
        ]
      )
    end

    test "identifie le devis le moins cher et le plus cher" do
      result = ComparatorService.new(@toiture).call
      assert_equal @cheap_quote, result[:cheapest]
      assert_equal @expensive_quote, result[:most_expensive]
    end

    test "signale les postes présents chez un entrepreneur mais absents chez un autre" do
      result = ComparatorService.new(@toiture).call
      assert_equal ["Évacuation gravats"], result[:missing_lines_by_quote][@cheap_quote]
      assert_equal [], result[:missing_lines_by_quote][@expensive_quote]
    end

    test "retourne une liste vide si aucun devis n'a été déposé pour ce lot" do
      empty_lot = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)
      result = ComparatorService.new(empty_lot).call
      assert_equal [], result[:quotes]
    end
  end
end
