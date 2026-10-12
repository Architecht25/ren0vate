require "test_helper"

class ProjectDocumentPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @architect = User.create!(email: "architect@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")

    @roofer = User.create!(email: "roofer@example.com", password: "password123", nom: "Couvreur")
    roofer_membership = @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active")
    roofer_membership.project_member_lots.create!(lot: @toiture)

    @other_roofer = User.create!(email: "other_roofer@example.com", password: "password123", nom: "Autre couvreur")
    @project.project_members.create!(user: @other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)

    @outsider = User.create!(email: "outsider@example.com", password: "password123", nom: "Outsider")

    @public_doc = build_document(visibility: "all", lot: nil, uploaded_by: @owner)
    @lot_scoped_doc = build_document(visibility: "lot", lot: @toiture, uploaded_by: @owner)
    @private_doc = build_document(visibility: "private", lot: nil, uploaded_by: @roofer)
    @custom_doc = build_document(visibility: "custom", lot: nil, uploaded_by: @owner)
    @custom_doc.shares.create!(user: @roofer)
  end

  test "le propriétaire voit tout, quelle que soit la visibilité" do
    [@public_doc, @lot_scoped_doc, @private_doc, @custom_doc].each do |doc|
      assert ProjectDocumentPolicy.new(@owner, doc).show?, "owner devrait voir #{doc.visibility}"
    end
  end

  test "visibilité 'all' : tout membre actif voit le document" do
    assert ProjectDocumentPolicy.new(@architect, @public_doc).show?
    assert ProjectDocumentPolicy.new(@roofer, @public_doc).show?
  end

  test "visibilité 'lot' : seul un membre scopé à ce lot (ou non restreint) le voit" do
    assert ProjectDocumentPolicy.new(@architect, @lot_scoped_doc).show?, "l'architecte n'est pas restreint à un lot"
    assert ProjectDocumentPolicy.new(@roofer, @lot_scoped_doc).show?, "le couvreur est scopé au lot toiture"
    assert_not ProjectDocumentPolicy.new(@other_roofer, @lot_scoped_doc).show?, "l'autre entrepreneur est scopé à un lot différent"
  end

  test "visibilité 'private' : seuls le déposant et le propriétaire voient le document" do
    assert ProjectDocumentPolicy.new(@roofer, @private_doc).show?, "le déposant voit toujours son propre document"
    assert_not ProjectDocumentPolicy.new(@architect, @private_doc).show?
    assert_not ProjectDocumentPolicy.new(@other_roofer, @private_doc).show?
  end

  test "visibilité 'custom' : seuls les utilisateurs explicitement partagés voient le document" do
    assert ProjectDocumentPolicy.new(@roofer, @custom_doc).show?
    assert_not ProjectDocumentPolicy.new(@architect, @custom_doc).show?
  end

  test "un tiers hors chantier ne voit jamais rien" do
    [@public_doc, @lot_scoped_doc, @private_doc, @custom_doc].each do |doc|
      assert_not ProjectDocumentPolicy.new(@outsider, doc).show?
    end
  end

  test "seuls le propriétaire et l'architecte peuvent revoir un document — jamais un entrepreneur" do
    assert ProjectDocumentPolicy.new(@owner, @public_doc).review?
    assert ProjectDocumentPolicy.new(@architect, @public_doc).review?
    assert_not ProjectDocumentPolicy.new(@roofer, @public_doc).review?
  end

  test "le scope ne retourne que les documents visibles par l'utilisateur" do
    scope = ProjectDocumentPolicy::Scope.new(@roofer, ProjectDocument).resolve
    assert_includes scope, @public_doc
    assert_includes scope, @lot_scoped_doc
    assert_includes scope, @private_doc
    assert_includes scope, @custom_doc
    assert_not_includes ProjectDocumentPolicy::Scope.new(@other_roofer, ProjectDocument).resolve, @lot_scoped_doc
  end

  private

  def build_document(visibility:, lot:, uploaded_by:)
    @project.project_documents.create!(
      title: "Document test #{SecureRandom.hex(4)}",
      document_type: "plan",
      visibility: visibility,
      lot: lot,
      uploaded_by: uploaded_by
    )
  end
end
