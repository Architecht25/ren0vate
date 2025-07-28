class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :flandre, :wallonie, :bruxelles, :select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie, :select_profile_bruxelles, :test_eligibility_bruxelles, :estimate_category_bruxelles]
  skip_before_action :verify_authenticity_token, only: [:select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie, :select_profile_bruxelles, :test_eligibility_bruxelles, :estimate_category_bruxelles]

  def home
  end

  def flandre
    categorie = params[:categorie].to_i
    categorie_estimee = params[:categorieEstimee].to_i

    @categorie_id =
      if categorie == 1
        1
      elsif categorie == 4
        categorie_estimee.in?(1..4) ? categorie_estimee : 1
      else
        1
      end

    @primes = Prime.where(region: "flandre")
                  .where("eligible_categories @> ARRAY[?]::varchar[]", [@categorie_id.to_s])
                  .where.not(slug: "certificat_peb_apres_travaux")  # Exclure la prime PEB des primes principales
                  .order(:ordre_affichage)

    # Récupération spécifique de la prime PEB
    @prime_peb = Prime.find_by(slug: "certificat_peb_apres_travaux", region: "flandre")

    @plafonds_par_categorie = Prime.group(:category_id).maximum(:plafond)
    @groupes_plafond = Prime.distinct.pluck(:groupe)
  end

  def wallonie
    # Page principale Wallonie - affiche la sélection de profil
    @primes = Prime.where(region: "wallonie").order(:ordre_affichage)
  end

  def bruxelles
    # Page principale Bruxelles - affiche la sélection de profil
    @primes = Prime.where(region: "bruxelles").order(:ordre_affichage)
  end

  def select_profile_wallonie
    @user_type = params[:profile_type]

    # Logique de redirection selon le type d'utilisateur
    case @user_type
    when "entreprise"
      handle_ineligible_profile("Les entreprises ne sont pas éligibles aux primes")
    when "syndic"
      handle_ineligible_profile("Les syndicats de copropriété doivent passer par une EnergieHuis pour effectuer une introduction de demandes.")
    when "bailleur"
      handle_ineligible_profile("Les bailleurs sociaux doivent passer par une EnergieHuis pour effectuer une introduction de demandes.")
    when "prive", "asbl"
      handle_eligible_profile
    else
      handle_invalid_profile
    end
  end

  def select_profile_bruxelles
    @profile_type = params[:profile_type]

    # Tous les profils sont maintenant éligibles avec leurs questionnaires spécifiques
    case @profile_type
    when "prive", "entreprise", "syndic", "bailleur", "asbl"
      handle_eligible_profile_bruxelles
    else
      handle_invalid_profile_bruxelles
    end
  end

  def test_eligibility_bruxelles
    Rails.logger.info "=== Test Eligibility Bruxelles Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # Utilisation du service d'éligibilité Bruxelles
      eligibility_service = BruxellesEligibilityService.new(params)
      result = eligibility_service.check_eligibility
      Rails.logger.info "Eligibility result: #{result}"

      respond_to do |format|
        format.turbo_stream do
          if result[:eligible]
            render turbo_stream: turbo_stream.replace(
              "eligibility_content",
              partial: "pages/partials_bruxelles/resultat_eligible",
              locals: {
                profile: result[:profile],
                message: result[:message]
              }
            )
          else
            render turbo_stream: turbo_stream.replace(
              "eligibility_content",
              partial: "pages/partials_bruxelles/resultat_ineligible",
              locals: {
                profile: result[:profile],
                message: result[:message],
                reasons: result[:reasons]
              }
            )
          end
        end
        format.html { redirect_to bruxelles_path }
      end

    rescue => e
      Rails.logger.error "Eligibility test error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "pages/partials_bruxelles/resultat_ineligible",
            locals: {
              message: "Erreur lors du calcul d'éligibilité",
              reasons: ["Erreur technique : #{e.message}"],
              profile: "erreur"
            }
          )
        end
        format.html { redirect_to bruxelles_path, alert: "Erreur technique" }
      end
    end
  end

  def estimate_category_bruxelles
    Rails.logger.info "=== Estimate Category Bruxelles Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # Récupération des paramètres
      statut_familial = params[:statut_familial]
      enfants_charge = params[:enfants_charge].to_i
      personnes_agees_charge = params[:personnes_agees_charge].to_i
      revenu_net = params[:revenu_net]

      # Validation
      if statut_familial.blank? || revenu_net.blank?
        raise ArgumentError, "Paramètres manquants"
      end

      # Le revenu_net contient déjà la catégorie (z1, z2, etc.)
      category = revenu_net.upcase

      # Couleur selon la catégorie
      category_color = case category
                      when 'Z1', 'Z2', 'Z3' then 'success'
                      when 'Z4', 'Z5', 'Z6', 'Z7' then 'warning'
                      else 'primary'
                      end

      # Détails de la catégorie
      category_details = case category
                        when 'Z1' then 'Revenus très faibles - Primes maximales'
                        when 'Z2' then 'Revenus faibles - Primes élevées'
                        when 'Z3' then 'Revenus modérés-bas - Primes importantes'
                        when 'Z4' then 'Revenus modérés - Primes substantielles'
                        when 'Z5' then 'Revenus moyens-bas - Primes moyennes'
                        when 'Z6' then 'Revenus moyens - Primes modérées'
                        when 'Z7' then 'Revenus moyens-élevés - Primes réduites'
                        when 'Z8' then 'Revenus élevés-bas - Primes minimales'
                        when 'Z9' then 'Revenus élevés - Primes très réduites'
                        when 'Z10' then 'Revenus très élevés - Primes limitées'
                        else 'Catégorie déterminée'
                        end

      # Récupération des primes pour cette catégorie
      @primes = Prime.where(region: "bruxelles")
                   .where("eligible_categories @> ARRAY[?]::varchar[]", [category])
                   .order(:ordre_affichage)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "pages/partials_bruxelles/resultat_categorie",
            locals: {
              category: category,
              category_color: category_color,
              category_details: category_details,
              primes: @primes
            }
          )
        end
        format.html { redirect_to bruxelles_path }
      end

    rescue => e
      Rails.logger.error "Category estimation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "shared/alert",
            locals: {
              message: "Erreur lors du calcul de catégorie: #{e.message}",
              type: "danger",
              title: "❌ Erreur"
            }
          )
        end
        format.html { redirect_to bruxelles_path, alert: "Erreur technique" }
      end
    end
  end

  def test_eligibility_wallonie
    Rails.logger.info "=== Test Eligibility Wallonie Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    begin
      eligibility_service = WallonieEligibilityService.new(params)
      result = eligibility_service.check_eligibility
      Rails.logger.info "Service result: #{result}"
    rescue => e
      Rails.logger.error "Service error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "shared/alert",
            locals: {
              message: "Erreur technique: #{e.message}",
              type: "danger",
              title: "❌ Erreur"
            }
          )
        end
        format.html { redirect_to wallonie_path, alert: "Erreur technique" }
      end
      return
    end

    respond_to do |format|
      format.turbo_stream do
        if result[:eligible]
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "pages/partials_wallonie/resultat_eligible",
            locals: {
              category: result[:category],
              show_refine: result[:needs_refinement]
            }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "pages/partials_wallonie/resultat_ineligible",
            locals: {
              message: result[:message]
            }
          )
        end
      end
      format.html { redirect_to wallonie_path }
    end
  end

  def estimate_category_wallonie
    category_service = WallonieCategoryService.new(params)
    result = category_service.estimate_category

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "pages/partials_wallonie/resultat_categorie",
          locals: {
            category: result[:category],
            category_color: result[:color],
            category_details: result[:details]
          }
        )
      end
      format.html { redirect_to wallonie_path }
    end
  end

  private

  def handle_eligible_profile
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "pages/partials_wallonie/questionnaire_eligibilite"
        )
      end
      format.html { redirect_to wallonie_path, notice: "Profil sélectionné avec succès" }
    end
  end

  def handle_ineligible_profile(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "shared/alert",
          locals: {
            message: message,
            type: "warning",
            title: "⚠️ Attention"
          }
        )
      end
      format.html { redirect_to wallonie_path, alert: message }
    end
  end

  def handle_invalid_profile
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "shared/alert",
          locals: {
            message: "Type de profil non reconnu",
            type: "danger",
            title: "❌ Erreur"
          }
        )
      end
      format.html { redirect_to wallonie_path, alert: "Type de profil non reconnu" }
    end
  end

  # ===== ACTIONS BRUXELLES =====

private

  def handle_eligible_profile_bruxelles
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "pages/partials_bruxelles/questionnaire_eligibilite",
          locals: { profile_type: @profile_type }
        )
      end
      format.html { redirect_to bruxelles_path }
    end
  end

  def handle_ineligible_profile_bruxelles(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "shared/alert",
          locals: {
            message: message,
            type: "warning",
            title: "⚠️ Attention"
          }
        )
      end
      format.html { redirect_to bruxelles_path, alert: message }
    end
  end

  def handle_invalid_profile_bruxelles
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "shared/alert",
          locals: {
            message: "Type de profil non reconnu",
            type: "danger",
            title: "❌ Erreur"
          }
        )
      end
      format.html { redirect_to bruxelles_path, alert: "Type de profil non reconnu" }
    end
  end

  private

  def calculate_bruxelles_category(income, marital_status, children_count)
    # Seuils de revenus pour Bruxelles RENOLUTION 2024
    thresholds = {
      "Z1" => { single: 22090, married: 32390 },
      "Z2" => { single: 26510, married: 38900 },
      "Z3" => { single: 30930, married: 45410 },
      "Z4" => { single: 35350, married: 51920 },
      "Z5" => { single: 39770, married: 58430 },
      "Z6" => { single: 44190, married: 64940 },
      "Z7" => { single: 48610, married: 71450 },
      "Z8" => { single: 53030, married: 77960 },
      "Z9" => { single: 57450, married: 84470 },
      "Z10" => { single: 61870, married: 90980 }
    }

    # Ajustement pour les enfants (4420€ par enfant)
    child_adjustment = children_count * 4420
    status_key = marital_status == 'single' ? :single : :married

    # Trouver la catégorie appropriée
    thresholds.each do |category, limits|
      adjusted_limit = limits[status_key] + child_adjustment
      if income <= adjusted_limit
        return {
          code: category,
          description: get_category_description(category),
          max_income: adjusted_limit,
          eligible: true
        }
      end
    end

    # Si revenus trop élevés
    {
      code: "Non éligible",
      description: "Revenus supérieurs aux plafonds RENOLUTION",
      max_income: nil,
      eligible: false
    }
  end

  def get_category_description(category)
    descriptions = {
      "Z1" => "Revenus très faibles - Primes maximales",
      "Z2" => "Revenus faibles - Primes élevées",
      "Z3" => "Revenus modérés-bas - Primes importantes",
      "Z4" => "Revenus modérés - Primes substantielles",
      "Z5" => "Revenus moyens-bas - Primes moyennes",
      "Z6" => "Revenus moyens - Primes modérées",
      "Z7" => "Revenus moyens-élevés - Primes réduites",
      "Z8" => "Revenus élevés-bas - Primes minimales",
      "Z9" => "Revenus élevés - Primes très réduites",
      "Z10" => "Revenus très élevés - Primes limitées"
    }
    descriptions[category] || "Catégorie inconnue"
  end

end
