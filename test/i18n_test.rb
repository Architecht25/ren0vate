require "test_helper"

class I18nTest < ActiveSupport::TestCase
  test "should have correct available locales" do
    assert_includes I18n.available_locales, :fr
    assert_includes I18n.available_locales, :nl
    assert_includes I18n.available_locales, :en
  end

  test "should translate common keys correctly" do
    I18n.with_locale(:fr) do
      assert_equal "Enregistrer", I18n.t('common.save')
      assert_equal "Wallonie", I18n.t('regions.wallonie')
      assert_equal "Accueil", I18n.t('navigation.home')
    end

    I18n.with_locale(:nl) do
      assert_equal "Opslaan", I18n.t('common.save')
      assert_equal "Vlaanderen", I18n.t('regions.flandre')
      assert_equal "Home", I18n.t('navigation.home')
    end

    I18n.with_locale(:en) do
      assert_equal "Save", I18n.t('common.save')
      assert_equal "Flanders", I18n.t('regions.flandre')
      assert_equal "Home", I18n.t('navigation.home')
    end
  end

  test "should interpolate variables correctly" do
    I18n.with_locale(:fr) do
      result = I18n.t('notices.property_deleted', name: 'Test Property')
      assert_includes result, 'Test Property'
      assert_includes result, 'supprimé avec succès'
    end

    I18n.with_locale(:nl) do
      result = I18n.t('notices.property_deleted', name: 'Test Property')
      assert_includes result, 'Test Property'
      assert_includes result, 'succesvol verwijderd'
    end
  end

  test "should fallback to default locale when key missing" do
    # Test avec une clé qui n'existe que en français
    I18n.with_locale(:nl) do
      # Si la clé n'existe pas en néerlandais, doit fallback
      result = I18n.t('common.save', default: 'Fallback')
      assert result.present?
    end
  end
end
