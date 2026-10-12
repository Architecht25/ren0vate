require "test_helper"

class Documents::DocumentTest < ActiveSupport::TestCase
  fixtures :users

  test "file_name renvoie le nom du fichier attaché même sans file_url" do
    document = Document.new(user: users(:freemium_user), type_document: "plan")
    document.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_devis.pdf")),
      filename: "plan-toiture.pdf", content_type: "application/pdf"
    )
    document.save!

    assert_equal "plan-toiture.pdf", document.file_name
  end

  test "file_name retombe sur file_url quand aucun fichier n'est attaché" do
    document = Document.new(user: users(:freemium_user), type_document: "plan", file_url: "https://example.com/dossier/plan-chassis.pdf")
    document.save!(validate: false)

    assert_equal "plan-chassis.pdf", document.file_name
  end

  test "file_name renvoie nil sans fichier attaché ni file_url" do
    document = Document.new(user: users(:freemium_user), type_document: "plan")

    assert_nil document.file_name
  end
end
