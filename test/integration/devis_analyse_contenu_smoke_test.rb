require "test_helper"

# Smoke tests de l'analyse de contenu des devis (ventilation par poste + graphique
# dans le comparateur de devis, cf. OcrController#scan_devis / #devis_analyse_contenu_statut,
# DevisContenuExtractionJob, Bots::DevisContenuClaudeService).
# Objectif : vérifier que project#show s'affiche sans 500 avec des DevisDonnee
# dans chaque statut d'analyse de contenu, et que le polling front-end répond
# correctement et reste scopé à l'utilisateur.
class DevisAnalyseContenuSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @user = users(:freemium_user)
    @project = projects(:one)
    sign_in @user
  end

  def build_devis_donnee(statut:, with_postes: false)
    document = Document.create!(
      project: @project,
      property: @project.property,
      user: @user,
      type_document: "devis",
      file_url: "https://example.com/devis.pdf"
    )
    DevisDonnee.create!(
      document: document,
      project: @project,
      categorie_emetteur: "entrepreneur",
      nom_entreprise: "Toitures Dupont",
      montant_total_htva: 15_000.0,
      confiance_ocr: 82.0,
      analyse_contenu_statut: statut,
      postes_json: with_postes ? [
        { libelle: "Isolation toiture", categorie: "isolation_toit", quantite: 80, unite: "m²", prix_unitaire_htva: 100, montant_htva: 8_000 },
        { libelle: "Châssis PVC", categorie: "chassis_vitrage", quantite: 5, unite: "pièce", prix_unitaire_htva: 1_400, montant_htva: 7_000 }
      ] : [],
      analyse_contenu_confiance: with_postes ? 88.0 : nil
    )
  end

  test "project#show s'affiche avec un devis dont l'analyse de contenu est terminée" do
    build_devis_donnee(statut: "termine", with_postes: true)
    get project_path(@project, locale: :fr)
    assert_response :success
  end

  test "project#show s'affiche avec un devis dont l'analyse de contenu est en cours" do
    build_devis_donnee(statut: "en_cours")
    get project_path(@project, locale: :fr)
    assert_response :success
  end

  test "project#show s'affiche avec un devis dont l'analyse de contenu a échoué" do
    build_devis_donnee(statut: "echec")
    get project_path(@project, locale: :fr)
    assert_response :success
  end

  test "polling renvoie la répartition une fois l'analyse terminée" do
    devis_donnee = build_devis_donnee(statut: "termine", with_postes: true)

    get ocr_devis_analyse_contenu_statut_path(locale: :fr), params: { devis_donnee_id: devis_donnee.id }
    assert_response :success

    body = JSON.parse(response.body)
    assert body["success"]
    assert_equal "termine", body["statut"]
    assert_equal 2, body["repartition"].size
    assert_equal 8_000.0, body["repartition"].first["montant_htva"]
  end

  test "polling renvoie en_cours tant que le job n'est pas terminé" do
    devis_donnee = build_devis_donnee(statut: "en_cours")

    get ocr_devis_analyse_contenu_statut_path(locale: :fr), params: { devis_donnee_id: devis_donnee.id }
    assert_response :success
    assert_equal "en_cours", JSON.parse(response.body)["statut"]
  end

  test "polling est scopé à l'utilisateur — un devis d'un autre projet renvoie 404" do
    other_user = User.create!(email: "other_devis@example.com", password: "password123", nom: "Other", role: 0)
    other_property = other_user.properties.create!(
      titre: "Bien Other", rue: "Rue A", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
    other_project = Project.create!(user: other_user, property: other_property, nom: "Projet Other", statut: "en_cours")
    other_document = Document.create!(
      project: other_project, property: other_property, user: other_user,
      type_document: "devis", file_url: "https://example.com/devis-other.pdf"
    )
    other_devis_donnee = DevisDonnee.create!(
      document: other_document, project: other_project, categorie_emetteur: "entrepreneur",
      montant_total_htva: 9_000.0, analyse_contenu_statut: "termine"
    )

    get ocr_devis_analyse_contenu_statut_path(locale: :fr), params: { devis_donnee_id: other_devis_donnee.id }
    assert_response :not_found
  end
end
