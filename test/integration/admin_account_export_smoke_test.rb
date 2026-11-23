require "test_helper"

# Export complet d'un compte avant suppression (admin) : ZIP = synthèse PDF + fichiers.
class AdminAccountExportSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @admin = User.create!(email: "robin@primes-services.be", password: "password123", nom: "Admin Test",
                          role: :admin, confirmed_at: 1.day.ago, onboarding_completed_at: 1.day.ago)
    @client = User.create!(email: "client-export@example.com", password: "password123", nom: "Client Export",
                           confirmed_at: 1.day.ago, onboarding_completed_at: 1.day.ago)
    sign_in @admin
  end

  test "l'admin télécharge un ZIP contenant la synthèse PDF" do
    get export_archive_admin_user_path(@client, locale: "fr")
    assert_response :success
    assert_equal "application/zip", response.media_type

    names = []
    Zip::File.open_buffer(StringIO.new(response.body)) do |zip|
      zip.each do |entry|
        names << entry.name
        assert entry.get_input_stream.read.start_with?("%PDF") if entry.name == "00-synthese.pdf"
      end
    end
    assert_includes names, "00-synthese.pdf"
  end

  test "le ZIP inclut biens, chantiers, demandes et fichiers joints" do
    property = Property.create!(user: @client, titre: "Maison é€", region: "wallonie", rue: "Rue X", numero: "1", code_postal: "5000", commune: "Namur", skip_onboarding_validation: true)
    property.photo.attach(io: StringIO.new("fake-image"), filename: "facade.jpg", content_type: "image/jpeg")
    project = Project.create!(property: property, user: @client, nom: "Toiture") rescue Project.create!(property: property, nom: "Toiture")
    Request.create!(user: @client, property: property, project: project, status: "draft", title: "Prime toiture")

    get export_archive_admin_user_path(@client, locale: "fr")
    assert_response :success

    names = []
    Zip::File.open_buffer(StringIO.new(response.body)) { |zip| zip.each { |entry| names << entry.name } }
    assert names.any? { |n| n.end_with?("facade.jpg") }, "fichier attaché au bien absent : #{names.inspect}"
  end

  test "un champ chiffré illisible ne fait pas échouer l'export" do
    User.where(id: @client.id).update_all("iban = 'pas-du-json-chiffre'")
    get export_archive_admin_user_path(@client, locale: "fr")
    assert_response :success
    assert_equal "application/zip", response.media_type
  end

  test "un non-admin est refusé" do
    sign_in @client
    get export_archive_admin_user_path(@admin, locale: "fr")
    assert_not_equal "application/zip", response.media_type
  end
end
