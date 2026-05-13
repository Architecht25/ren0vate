class PagesController < ApplicationController
  include PageTracking  # Ajout du concern de tracking

  skip_before_action :authenticate_user!, only: [:home, :flandre, :wallonie, :bruxelles, :select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie, :select_profile_bruxelles, :test_eligibility_bruxelles, :estimate_category_bruxelles, :legal, :privacy, :terms, :faq, :aide]
  # Ces endpoints publics reçoivent des requêtes Turbo Stream (qui incluent le token CSRF) depuis des pages
  # non authentifiées. Le skip est justifié : aucune mutation de données en base, résultats purement calculés.
  skip_before_action :verify_authenticity_token, only: [:select_profile_wallonie, :test_eligibility_wallonie, :estimate_category_wallonie]

  def home
    track_page_visit('home', page_type: 'accueil')
    @household_count = Project.count
  end

  def flandre
    track_page_visit('flandre_particuliers', region: 'Flandre', page_type: 'simulation')

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
                  .where.not(slug: "certificat_peb_apres_travaux")  # Exclure la prime PEB des primes principales
                  .order(:ordre_affichage)

    # Récupération spécifique de la prime PEB
    @prime_peb = Prime.find_by(slug: "certificat_peb_apres_travaux", region: "flandre")

    @plafonds_par_categorie = Prime.group(:category_id).maximum(:plafond)
    @groupes_plafond = Prime.distinct.pluck(:groupe)
  end

  def wallonie
    track_page_visit('wallonie_particuliers', region: 'Wallonie', page_type: 'simulation')

    # Page principale Wallonie - affiche la sélection de profil
    @primes = Prime.where(region: "wallonie").order(:ordre_affichage)
  end

  def bruxelles
    track_page_visit('bruxelles_particuliers', region: 'Bruxelles', page_type: 'simulation')

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
    # Fonctionnalité désactivée - Programme RENOLUTION suspendu
    redirect_to bruxelles_path, alert: "Le programme RENOLUTION est actuellement suspendu."
  end

  def test_eligibility_bruxelles
    # Fonctionnalité désactivée - Programme RENOLUTION suspendu
    redirect_to bruxelles_path, alert: "Le programme RENOLUTION est actuellement suspendu."
  end

  def estimate_category_bruxelles
    # Fonctionnalité désactivée - Programme RENOLUTION suspendu
    redirect_to bruxelles_path, alert: "Le programme RENOLUTION est actuellement suspendu."
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

  # Pages légales
  def legal
    # Page mentions légales
  end

  def privacy
    # Page politique de confidentialité
  end

  def terms
    # Conditions générales de vente et d'utilisation
  end

  def dpa
    # Accord de traitement des données (Data Processing Agreement) — B2B
  end

  def faq
    # FAQ publique — questions fréquentes
  end

  def aide
    # Centre d'aide — articles et guides
  end

  private

end
