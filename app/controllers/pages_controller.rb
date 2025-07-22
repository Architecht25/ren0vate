class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :flandre, :wallonie, :bruxelles, :select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie]

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

  def select_profile_bruxelles
    @user_type = params[:profile_type]

    # Logique de redirection selon le type d'utilisateur pour Bruxelles
    case @user_type
    when "entreprise"
      handle_ineligible_profile_bruxelles("Les entreprises ne sont pas éligibles aux primes RENOLUTION")
    when "syndic"
      handle_ineligible_profile_bruxelles("Les syndicats de copropriété doivent passer par un organisme agréé pour effectuer une introduction de demandes.")
    when "bailleur"
      handle_ineligible_profile_bruxelles("Les bailleurs sociaux doivent passer par un organisme agréé pour effectuer une introduction de demandes.")
    when "prive", "asbl"
      handle_eligible_profile_bruxelles
    else
      handle_invalid_profile_bruxelles
    end
  end

  def test_eligibility_bruxelles
    Rails.logger.info "=== Test Eligibility Bruxelles Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # TODO: Créer BruxellesEligibilityService
      # eligibility_service = BruxellesEligibilityService.new(params)
      # result = eligibility_service.check_eligibility

      # En attendant, renvoyer une réponse temporaire
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "shared/alert",
            locals: {
              message: "Service d'éligibilité Bruxelles en cours de développement",
              type: "info",
              title: "🚧 En construction"
            }
          )
        end
        format.html { redirect_to bruxelles_path, notice: "Service en cours de développement" }
      end

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
        format.html { redirect_to bruxelles_path, alert: "Erreur technique" }
      end
    end
  end

  def estimate_category_bruxelles
    Rails.logger.info "=== Estimate Category Bruxelles Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    # TODO: Implémenter le service de calcul de catégorie pour Bruxelles
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "shared/alert",
          locals: {
            message: "Calcul de catégorie Bruxelles en cours de développement",
            type: "info",
            title: "🚧 En construction"
          }
        )
      end
      format.html { redirect_to bruxelles_path, notice: "Service en cours de développement" }
    end
  end

private

  def handle_eligible_profile_bruxelles
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "eligibility_content",
          partial: "pages/partials_bruxelles/questionnaire_eligibilite"
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

end
