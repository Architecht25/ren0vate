class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarding_done, only: %i[profile_selection set_profile]
  layout 'onboarding'

  # GET /onboarding/profil
  def profile_selection
  end

  # POST /onboarding/profil
  def set_profile
    profile = params[:profile].to_s
    unless User.user_profiles.key?(profile)
      flash.now[:alert] = t('onboarding.invalid_profile')
      return render :profile_selection, status: :unprocessable_entity
    end

    current_user.update!(user_profile: profile)
    session[:onboarding] = { profile: profile }

    case profile
    when 'proprietaire'  then redirect_to onboarding_proprietaire_bien_path(locale: I18n.locale)
    when 'architecte'    then redirect_to onboarding_architecte_profil_path(locale: I18n.locale)
    when 'entrepreneur'  then redirect_to onboarding_entrepreneur_invitation_path(locale: I18n.locale)
    when 'intermediaire' then redirect_to onboarding_intermediaire_structure_path(locale: I18n.locale)
    end
  end

  # ─── Tunnel Propriétaire ─────────────────────────────────────────────────────

  # GET /onboarding/proprietaire/bien
  def proprietaire_bien
    @property = Property.new
  end

  # POST /onboarding/proprietaire/bien
  def create_proprietaire_bien
    @property = current_user.properties.build(property_params)
    @property.skip_onboarding_validation = true

    if @property.save
      session[:onboarding_property_id] = @property.id
      redirect_to onboarding_proprietaire_projet_path(locale: I18n.locale)
    else
      render :proprietaire_bien, status: :unprocessable_entity
    end
  end

  # GET /onboarding/proprietaire/projet
  def proprietaire_projet
    @property = current_user.properties.find_by(id: session[:onboarding_property_id])
    redirect_to onboarding_proprietaire_bien_path(locale: I18n.locale) and return unless @property
    @project = Project.new
  end

  # POST /onboarding/proprietaire/projet
  def create_proprietaire_projet
    @property = current_user.properties.find_by(id: session[:onboarding_property_id])
    redirect_to onboarding_proprietaire_bien_path(locale: I18n.locale) and return unless @property

    @project = @property.projects.build(project_params)
    @project.user = current_user

    if @project.save
      finish_onboarding!
      redirect_to dashboard_path(locale: I18n.locale),
                  notice: t('onboarding.welcome_proprietaire')
    else
      render :proprietaire_projet, status: :unprocessable_entity
    end
  end

  # ─── Tunnel Architecte ───────────────────────────────────────────────────────

  # GET /onboarding/architecte/profil-pro
  def architecte_profil
  end

  # POST /onboarding/architecte/profil-pro
  def create_architecte_profil
    if current_user.update(architecte_params)
      finish_onboarding!
      redirect_to dashboard_path(locale: I18n.locale),
                  notice: t('onboarding.welcome_pro')
    else
      render :architecte_profil, status: :unprocessable_entity
    end
  end

  # ─── Tunnel Entrepreneur ─────────────────────────────────────────────────────

  # GET /onboarding/entrepreneur/invitation
  def entrepreneur_invitation
  end

  # POST /onboarding/entrepreneur/invitation
  def create_entrepreneur_invitation
    # L'entrepreneur peut saisir un token d'invitation ou passer directement
    token = params[:invitation_token].to_s.strip

    if token.present?
      member = ProjectMember.find_by(invite_token: token, status: :pending)
      if member
        member.update!(status: :active)
        finish_onboarding!
        redirect_to member_projects_path(locale: I18n.locale),
                    notice: t('onboarding.welcome_entrepreneur_joined')
        return
      else
        flash.now[:alert] = t('onboarding.invalid_token')
        return render :entrepreneur_invitation, status: :unprocessable_entity
      end
    end

    # Passer : onboarding terminé, dashboard vide avec CTA
    finish_onboarding!
    redirect_to member_projects_path(locale: I18n.locale),
                notice: t('onboarding.welcome_entrepreneur')
  end

  # ─── Tunnel Intermédiaire ────────────────────────────────────────────────────

  # GET /onboarding/intermediaire/structure
  def intermediaire_structure
  end

  # POST /onboarding/intermediaire/structure
  def create_intermediaire_structure
    if current_user.update(intermediaire_params)
      finish_onboarding!
      redirect_to dashboard_path(locale: I18n.locale),
                  notice: t('onboarding.welcome_intermediaire')
    else
      render :intermediaire_structure, status: :unprocessable_entity
    end
  end

  private

  def finish_onboarding!
    current_user.update_column(:onboarding_completed_at, Time.current)
    session.delete(:onboarding)
    session.delete(:onboarding_property_id)
  end

  def redirect_if_onboarding_done
    redirect_to dashboard_path(locale: I18n.locale) if current_user.onboarding_done?
  end

  def property_params
    params.require(:property).permit(:rue, :numero, :code_postal, :commune, :region)
  end

  def project_params
    params.require(:project).permit(:nom, :project_type)
  end

  def architecte_params
    params.require(:user).permit(:nom_cabinet, :num_bce)
  end

  def intermediaire_params
    params.require(:user).permit(:nom_cabinet, :num_bce)
  end
end
