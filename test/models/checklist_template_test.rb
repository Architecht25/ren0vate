require "test_helper"

class ChecklistTemplateTest < ActiveSupport::TestCase
  test "la phase contrat est valide et fournit label/icone/couleur" do
    template = ChecklistTemplate.new(name: "Test contrat", phase: "contrat")
    assert template.valid?
    assert_equal "Contrat", template.phase_label
    assert_equal "bi-file-earmark-text", template.phase_icon
    assert_equal "info", template.phase_color
  end
end
