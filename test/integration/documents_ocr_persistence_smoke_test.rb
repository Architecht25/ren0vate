require "test_helper"

# Couvre le bug trouvé lors du test E2E du 12/10/2026 : un devis ou un
# bordereau châssis uploadé via le formulaire générique (documents#create)
# déclenchait bien l'appel Claude (payant) mais son résultat n'était jamais
# persisté — contrairement à la branche facture (creer_facture_depuis_ocr_doc).
class DocumentsOcrPersistenceSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects, :subscriptions

  setup do
    @owner = users(:individual_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:two)
    sign_in @owner
  end

  def uploaded_pdf
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf")
  end

  test "un devis uploadé via le formulaire générique crée un DevisDonnee" do
    fake_result = {
      success: true,
      donnees_devis: { nom_entreprise: "Toitures Dupont" },
      nom_entreprise: "Toitures Dupont",
      montant_total_htva: 25_850.0,
      montant_total_tvac: 27_401.0,
      taux_tva: 6,
      confiance_extraction: 90,
      extraction_complete: true
    }

    fake_service = Object.new
    fake_service.define_singleton_method(:extraire_donnees_devis) { fake_result }

    assert_difference "DevisDonnee.count", 1 do
      stub_class_method(Bots::DevisClaudeService, :new, fake_service) do
        post project_documents_path(@project, locale: :fr), params: {
          document: { type_document: "devis", file: uploaded_pdf }
        }
      end
    end

    devis_donnee = DevisDonnee.last
    assert_equal @project, devis_donnee.project
    assert_equal "Toitures Dupont", devis_donnee.nom_entreprise
    assert_equal 25_850.0, devis_donnee.montant_total_htva
  end

  test "un bordereau châssis uploadé via le formulaire générique crée un BordereauChassisDonnee" do
    fake_result = {
      success: true,
      donnees_bordereau: { nom_fabricant: "Chassis Pro" },
      nom_fabricant: "Chassis Pro",
      valeur_uw: 1.1,
      confiance_extraction: 85,
      extraction_complete: true
    }
    fake_service = Object.new
    fake_service.define_singleton_method(:extraire_donnees_bordereau) { fake_result }

    assert_difference "BordereauChassisDonnee.count", 1 do
      stub_class_method(Bots::BordereauChassisClaudeService, :new, fake_service) do
        post project_documents_path(@project, locale: :fr), params: {
          document: { type_document: "bordereau_chassis", file: uploaded_pdf }
        }
      end
    end

    bordereau = BordereauChassisDonnee.last
    assert_equal @project, bordereau.project
    assert_equal "Chassis Pro", bordereau.nom_fabricant
  end
end
