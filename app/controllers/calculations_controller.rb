# Contrôleur pour tester la nouvelle architecture de calculs
# Temporaire pour validation avant migration complète

class CalculationsController < ApplicationController
  def test_wallonie
    params_test = {
      localisation: "oui",
      destination: "oui",
      propriete: "oui",
      residence_principale: "oui",
      age_logement: "oui",
      audit: "oui",
      entrepreneur: "oui",
      factures_anciennes: "non",
      revenus: "non",
      revenu_net: "r2"
    }

    # Test pré-login
    result_pre = CalculationEngineService.new(
      region: 'wallonie',
      calculation_type: 'pre_login',
      params: params_test
    ).calculate

    # Test post-login (si utilisateur connecté)
    result_post = nil
    if current_user
      result_post = CalculationEngineService.new(
        region: 'wallonie',
        calculation_type: 'post_login',
        params: params_test,
        user: current_user
      ).calculate
    end

    render json: {
      pre_login: result_pre,
      post_login: result_post,
      status: "Architecture fonctionnelle"
    }
  rescue => e
    render json: { error: e.message, status: "Erreur architecture" }
  end

  def test_bruxelles
    params_test = {
      localisation: "oui",
      destination: "oui",
      propriete: "oui",
      residence_principale: "oui",
      age_logement: "oui",
      entrepreneur: "oui",
      factures_anciennes: "non",
      revenus_bas: "oui"
    }

    result_pre = CalculationEngineService.new(
      region: 'bruxelles',
      calculation_type: 'pre_login',
      params: params_test
    ).calculate

    result_post = nil
    if current_user
      result_post = CalculationEngineService.new(
        region: 'bruxelles',
        calculation_type: 'post_login',
        params: params_test,
        user: current_user
      ).calculate
    end

    render json: {
      pre_login: result_pre,
      post_login: result_post,
      status: "Architecture fonctionnelle"
    }
  rescue => e
    render json: { error: e.message, status: "Erreur architecture" }
  end
end
