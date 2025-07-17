require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @property = properties(:one)
    @document = Document.new(
      user: @user,
      property: @property,
      type_document: 'devis',
      status: 'pending'
    )
  end

  test "should be valid with file attached" do
    # Simulation d'un fichier attaché
    @document.file_url = "http://example.com/test.pdf"
    assert @document.valid?
  end

  test "should be invalid without file or url" do
    assert_not @document.valid?
    assert_includes @document.errors[:base], "Un fichier ou une URL doit être fourni"
  end

  test "should be invalid without type_document" do
    @document.file_url = "http://example.com/test.pdf"
    @document.type_document = nil
    assert_not @document.valid?
    assert_includes @document.errors[:type_document], "can't be blank"
  end

  test "file_name should return correct filename" do
    @document.file_url = "http://example.com/test-document.pdf"
    assert_equal "test-document.pdf", @document.file_name
  end

  test "is_pdf should return false for non-attached file" do
    assert_not @document.is_pdf?
  end

  test "completion_stats_for_property should return correct stats" do
    # Créer quelques documents test
    Document.create!(
      user: @user,
      property: @property,
      type_document: 'devis',
      status: 'approved',
      file_url: "http://example.com/devis.pdf"
    )

    Document.create!(
      user: @user,
      property: @property,
      type_document: 'facture',
      status: 'pending',
      file_url: "http://example.com/facture.pdf"
    )

    stats = Document.completion_stats_for_property(@property)
    assert_equal 2, stats[:completed] # 1 approved sur les types distincts
    assert stats[:percentage] > 0
  end
end
