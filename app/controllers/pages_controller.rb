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
            # Déterminer si l'affinage est nécessaire et la catégorie automatique
            profile_type = result[:profile]
            needs_refinement = profile_type == 'particulier'
            auto_category = get_automatic_category_bruxelles(profile_type) unless needs_refinement

            render turbo_stream: turbo_stream.replace(
              "eligibility_content",
              partial: "pages/partials_bruxelles/resultat_eligible",
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

      # Récupération des primes pour Bruxelles
      @primes = Prime.where(region: "bruxelles").order(:ordre_affichage)

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

end
