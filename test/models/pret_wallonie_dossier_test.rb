require "test_helper"

class PretWallonieDossierTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Maison Namur",
      rue: "Rue de Namur",
      numero: "1",
      code_postal: "5000",
      commune: "Namur",
      region: "wallonie",
      annee_construction: 2000,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation Namur",
      statut: "en_cours"
    )
  end

  def build_dossier(attrs = {})
    PretWallonieDossier.new({
      project: @project,
      user: @user,
      label_peb_depart: "F",
      montant_emprunte: 20_000,
      plafond_emprunt: 75_000,
      taux_reduction: 0.50
    }.merge(attrs))
  end

  test "statut par défaut à preparation" do
    dossier = build_dossier
    dossier.save!
    assert_equal "preparation", dossier.statut
  end

  test "un seul dossier par projet" do
    build_dossier.save!
    doublon = build_dossier
    assert_not doublon.valid?
    assert_includes doublon.errors[:project_id], "has already been taken"
  end

  test "calcule le label PEB cible selon le label de départ" do
    autre_projet = -> { Project.create!(user: @user, property: @property, nom: "Projet #{SecureRandom.hex(4)}", statut: "en_cours") }

    assert_equal "D", build_dossier(project: autre_projet.call, label_peb_depart: "G").tap(&:save!).label_peb_cible
    assert_equal "D", build_dossier(project: autre_projet.call, label_peb_depart: "F").tap(&:save!).label_peb_cible
    assert_equal "C", build_dossier(project: autre_projet.call, label_peb_depart: "E").tap(&:save!).label_peb_cible
  end

  test "calcule la date limite des travaux à 2 ans après la signature" do
    dossier = build_dossier(date_signature: Date.new(2026, 10, 1))
    dossier.save!
    assert_equal Date.new(2028, 10, 1), dossier.date_limite_travaux
  end

  test "échéance travaux proche dans les 60 jours" do
    dossier = build_dossier(statut: "travaux_en_cours", date_signature: 23.months.ago.to_date)
    dossier.save!
    assert dossier.echeance_travaux_proche?
  end

  test "pas d'échéance proche si le dossier est clôturé" do
    dossier = build_dossier(statut: "cloture", date_signature: 23.months.ago.to_date)
    dossier.save!
    assert_not dossier.echeance_travaux_proche?
  end

  test "objectif PEB atteint si le label après travaux dépasse le label cible" do
    dossier = build_dossier(label_peb_depart: "F", label_peb_apres_travaux: "C")
    dossier.save!
    assert dossier.objectif_peb_atteint?
  end

  test "objectif PEB non atteint si le label après travaux reste sous le label cible" do
    dossier = build_dossier(label_peb_depart: "F", label_peb_apres_travaux: "E")
    dossier.save!
    assert_equal false, dossier.objectif_peb_atteint?
  end

  test "objectif PEB indéterminé si le label après travaux n'est pas encore renseigné" do
    dossier = build_dossier(label_peb_depart: "F")
    dossier.save!
    assert_nil dossier.objectif_peb_atteint?
  end

  test "build_from_simulation reprend les valeurs de la simulation" do
    simulation = Simulation.create!(
      user: @user,
      property: @property,
      project: @project,
      titre: "Simulation test",
      region: "wallonie",
      regime: "reduction_pret",
      eligible: true,
      parameters: {
        montant_projet_retenu: 20_000,
        plafond_emprunt: 75_000,
        taux_reduction: 0.50,
        taux_interet: "zero",
        ecomateriaux: false
      }.to_json
    )

    dossier = PretWallonieDossier.build_from_simulation(simulation, user: @user)
    assert_equal @project, dossier.project
    assert_equal 20_000, dossier.montant_emprunte.to_i
    assert_equal 75_000, dossier.plafond_emprunt.to_i
    assert_equal 0.50, dossier.taux_reduction.to_f
  end
end
