class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :flandre, :wallonie, :bruxelles, :bruxelles_entreprises, :select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie, :select_profile_bruxelles, :test_eligibility_bruxelles, :estimate_category_bruxelles, :test_eligibility_bruxelles_entreprises, :legal, :privacy]
  skip_before_action :verify_authenticity_token, only: [:select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie, :select_profile_bruxelles, :test_eligibility_bruxelles, :estimate_category_bruxelles, :test_eligibility_bruxelles_entreprises]

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

    # Mapper les types de profils pour correspondre aux partials
    mapped_profile = case @user_type
    when "prive"
      "particulier"
    when "entreprise"
      "entreprise"
    when "syndic"
      "syndic"
    when "bailleur"
      "bailleur"
    when "asbl"
      "asbl"
    else
      @user_type
    end

    @profile_type = mapped_profile

    # Logique de redirection selon le type d'utilisateur pour Wallonie
    case @user_type
    when "entreprise", "syndic", "bailleur", "prive", "asbl"
      handle_eligible_profile
    else
      handle_invalid_profile
    end
  end

  def select_profile_bruxelles
    @profile_type = params[:profile_type]

    # Tous les profils sont maintenant éligibles avec leurs questionnaires spécifiques
    case @profile_type
    when "prive", "entreprise", "syndic", "bailleur", "asbl", "coproprietaire", "emphytheote", "locataire", "particulier_bailleur", "particulier_indivision"
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
      eligibility_service = Regions::Bruxelles::BruxellesEligibilityService.new(
        params: params,
        user: current_user,
        is_post_login: user_signed_in?
      )
      result = eligibility_service.check_eligibility
      Rails.logger.info "Eligibility result: #{result}"

      # Sauvegarder les données d'éligibilité dans la session pour le filtrage des primes
      session[:bruxelles_eligibility_data] = params.except(:controller, :action, :authenticity_token)
      Rails.logger.info "💾 Données d'éligibilité sauvegardées: usage_bien = #{params[:usage_bien]}"

      respond_to do |format|
        format.turbo_stream do
          if result[:eligible]
            # Déterminer si l'affinage est nécessaire et la catégorie automatique
            profile_type = result[:profile]
            needs_refinement = profile_type == 'particulier'
            auto_category = get_automatic_category_bruxelles(profile_type) unless needs_refinement

            render turbo_stream: turbo_stream.replace(
              "eligibility_content",
              partial: "pages/partials_bruxelles/resultat_eligible_debug",
              locals: {
                profile: result[:profile],
                message: result[:message],
                needs_refinement: needs_refinement,
                auto_category: auto_category
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
      revenu_net = params[:revenu_net]

      # Validation
      if statut_familial.blank? || revenu_net.blank?
        raise ArgumentError, "Paramètres manquants"
      end

      # Déterminer la catégorie selon la tranche de revenus
      category_info = determine_bruxelles_category_simple(revenu_net, statut_familial, enfants_charge)

      # Récupération des données d'éligibilité pour déterminer le statut du bien
      eligibility_data = session[:bruxelles_eligibility_data] || {}
      usage_bien = eligibility_data['usage_bien'] || 'residentiel'

      # Filtrage des primes selon le statut du bien
      if usage_bien == 'mixte'
        # Usage mixte : seulement les primes avec statut_compatible incluant "non_residentiel"
        @primes = Prime.where(region: "bruxelles")
                      .where("statut_compatible @> ?", ["non_residentiel"].to_json)
                      .order(:ordre_affichage)
        Rails.logger.info "🏢 Usage mixte détecté - #{@primes.count} primes compatibles affichées"
      else
        # Usage résidentiel : toutes les primes
        @primes = Prime.where(region: "bruxelles").order(:ordre_affichage)
        Rails.logger.info "🏠 Usage résidentiel détecté - #{@primes.count} primes affichées"
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "eligibility_content",
            partial: "pages/partials_bruxelles/resultat_categorie",
            locals: {
              category: category_info[:category],
              category_color: category_info[:color],
              category_details: category_info[:details],
              primes: @primes,
              composition_familiale: {
                statut: statut_familial,
                enfants: enfants_charge,
                tranche_revenu: revenu_net
              }
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
          partial: "pages/partials_wallonie/questionnaire_eligibilite",
          locals: { profile_type: @profile_type }
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

  def get_automatic_category_bruxelles(profile_type)
    case profile_type
    when 'entreprise'
      {
        category: 'Catégorie I',
        color: 'primary',
        details: 'Catégorie automatique pour les entreprises - Accès aux primes professionnelles'
      }
    when 'syndic'
      {
        category: 'Catégorie II',
        color: 'info',
        details: 'Catégorie automatique pour les syndics de copropriété - Primes pour parties communes'
      }
    when 'bailleur'
      {
        category: 'Catégorie III',
        color: 'success',
        details: 'Catégorie automatique pour les bailleurs sociaux (AIS) - Primes logement social'
      }
    when 'asbl'
      {
        category: 'Catégorie I',
        color: 'primary',
        details: 'Catégorie automatique pour les ASBL - Accès aux primes institutionnelles'
      }
    else
      nil
    end
  end

  def determine_bruxelles_category_simple(revenu_net, statut_familial, enfants_charge)
    # Logique simplifiée pour 3 tranches de revenus
    case revenu_net
    when 'faible'
      {
        category: 'Revenus Faibles',
        color: 'success',
        details: 'Primes maximales disponibles - Vous bénéficiez des montants les plus élevés'
      }
    when 'moyen'
      {
        category: 'Revenus Moyens',
        color: 'warning',
        details: 'Primes moyennes disponibles - Vous bénéficiez de montants substantiels'
      }
    when 'eleve'
      {
        category: 'Revenus Élevés',
        color: 'info',
        details: 'Primes réduites disponibles - Vous bénéficiez de montants de base'
      }
    else
      {
        category: 'Catégorie Non Déterminée',
        color: 'primary',
        details: 'Merci de préciser votre tranche de revenus'
      }
    end
  end

  # Nouveau simulateur pour les aides aux entreprises Bruxelles
  def bruxelles_entreprises
    # Page principale du simulateur d'éligibilité aux aides pour entreprises à Bruxelles
  end

  def test_eligibility_bruxelles_entreprises
    Rails.logger.info "=== Test Eligibility Bruxelles Entreprises Action Called ==="
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # Utilisation d'un service d'éligibilité spécialisé pour les entreprises
      eligibility_service = Entreprises::BruxellesEntreprisesEligibilityService.new(params)
      result = eligibility_service.check_eligibility
      Rails.logger.info "Business eligibility result: #{result}"

      respond_to do |format|
        format.turbo_stream do
          if result[:eligible]
            render turbo_stream: turbo_stream.update("result",
              partial: "shared/business_eligibility_result",
              locals: {
                result: result[:message],
                is_eligible: true,
                recommendations: result[:recommendations] || [],
                subsidy_categories: result[:subsidy_categories] || []
              }
            )
          else
            render turbo_stream: turbo_stream.update("result",
              partial: "shared/business_eligibility_result",
              locals: {
                result: result[:message],
                is_eligible: false,
                recommendations: result[:recommendations] || []
              }
            )
          end
        end
        format.html { redirect_to bruxelles_entreprises_path }
      end
    rescue => e
      Rails.logger.error "Error in business eligibility check: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("result",
            partial: "shared/business_eligibility_result",
            locals: {
              result: "❌ Une erreur est survenue lors de la vérification d'éligibilité. Veuillez réessayer.",
              is_eligible: false,
              recommendations: ["Vérifiez vos réponses et réessayez", "Contactez le support si le problème persiste"]
            }
          )
        end
        format.html { redirect_to bruxelles_entreprises_path }
      end
    end
  end

  # Pages légales
  def legal
    # Page mentions légales
  end

  def privacy
    # Page politique de confidentialité
  end

end
