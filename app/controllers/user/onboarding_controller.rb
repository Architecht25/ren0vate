class OnboardingController < ApplicationController
  # Options des champs régionaux du tunnel (identiques aux formulaires de bien).
  ONBOARDING_REGIONAL_OPTIONS = {
    'wallonie' => {
      type_field: :type_propriete_wallonie,
      type_label: "Type de propriété",
      types: [
        ["Unique propriétaire", "unique_proprietaire"],
        ["Copropriétaire avec mon conjoint (couple marié, cohabitants légaux, cohabitants de fait) figurant sur ma composition de ménage", "copropriete_conjoint"],
        ["Copropriétaire avec d'autres", "copropriete_autres"],
        ["Usufruitier", "usufruitier"],
        ["Nu-propriétaire", "nu_proprietaire"],
        ["Représentant d'une association de copropriétaires", "representant_association"],
        ["Autre (droit d'habitation, emphytéote...)", "autre"]
      ],
      profils: [
        ["Propriétaire occupant ou futur occupant", "propriétaire_occupant_ou_futur_occupant"],
        ["Syndic de copropriété", "syndic_copropriété"],
        ["Bailleur social", "bailleur_social"]
      ]
    },
    'flandre' => {
      type_field: :type_bien_flandre,
      type_label: "Type de bien",
      types: [
        ["Maison unifamiliale", "maison"],
        ["Appartement en copropriété", "appartement_copro"],
        ["Appartement non en copropriété", "appartement"],
        ["Immeuble à plusieurs unités d'habitation", "immeuble_appartements"],
        ["Non logement", "non_logement"]
      ],
      profils: [
        ["Propriétaire occupant ou futur occupant", "proprietaire_occupant_ou_futur_occupant"],
        ["ASBL/Coopérative", "asbl_cooperative"]
      ]
    },
    'bruxelles' => {
      type_field: :type_bien_bruxelles,
      type_label: "Type de bien",
      types: [
        ["Maison unifamiliale", "maison"],
        ["Appartement", "appartement"],
        ["Immeuble avec plusieurs unités", "immeuble de rapport"]
      ],
      profils: [
        ["Propriétaire occupant ou futur occupant", "proprietaire_occupant_ou_futur_occupant"],
        ["Entreprise", "entreprise"],
        ["Syndic de copropriété, ACP, Copropriété forcée", "syndic_de_copropriete_acp_copropriete_forcee"],
        ["Propriétaire en indivision", "proprietaire_en_indivision"],
        ["Copropriétaire volontaire ou fortuit", "coproprietaire_volontaire_ou_fortuit"],
        ["Locataire", "locataire"],
        ["Propriétaire bailleur", "proprietaire_bailleur"],
        ["Propriétaire bailleur via AIS", "proprietaire_bailleur_via_ais"],
        ["ASBL/Coopérative", "asbl_cooperative"],
        ["Amphythéote", "amphyteote"]
      ]
    }
  }.freeze

  before_action :authenticate_user!
  before_action :redirect_if_onboarding_done, only: %i[profile_selection set_profile]
  layout 'onboarding'

  # GET /onboarding/profil
  # Si le profil pro a déjà été choisi à l'inscription (mini-sélecteur du
  # formulaire d'inscription), on ne redemande pas la même question ici.
  def profile_selection
    return unless current_user.professional_type.present?

    profile = professional_type_to_user_profile(current_user.professional_type)
    apply_profile_and_redirect(profile) if profile
  end

  # POST /onboarding/profil
  def set_profile
    profile = params[:profile].to_s
    unless User.user_profiles.key?(profile)
      flash.now[:alert] = t('onboarding.invalid_profile')
      return render :profile_selection, status: :unprocessable_entity
    end

    apply_profile_and_redirect(profile)
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

    if regional_fields_missing?(@property)
      @property.errors.add(:base, "Indiquez le type de bien et le profil du demandeur.")
      render :proprietaire_bien, status: :unprocessable_entity
    elsif @property.save
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
      redirect_to project_path(@project, locale: I18n.locale, tab: :preparation),
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
      member = ProjectMember.find_by(invite_token: token)

      if member&.pending?
        member.update!(status: :active)
        finish_onboarding!
        redirect_to member_projects_path(locale: I18n.locale),
                    notice: t('onboarding.welcome_entrepreneur_joined')
        return
      elsif member&.active? && member.user_id == current_user.id
        # Déjà accepté entre-temps (ex: via le lien email InvitationsController) :
        # ne pas afficher "token invalide", juste finaliser l'onboarding resté en suspens.
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

  def apply_profile_and_redirect(profile)
    current_user.update!(user_profile: profile)
    session[:onboarding] = { profile: profile }

    case profile
    when 'proprietaire'  then redirect_to onboarding_proprietaire_bien_path(locale: I18n.locale)
    when 'architecte'    then redirect_to onboarding_architecte_profil_path(locale: I18n.locale)
    when 'entrepreneur'  then redirect_to onboarding_entrepreneur_invitation_path(locale: I18n.locale)
    when 'intermediaire' then redirect_to onboarding_intermediaire_structure_path(locale: I18n.locale)
    end
  end

  def professional_type_to_user_profile(professional_type)
    case professional_type
    when 'architect'    then 'architecte'
    when 'entrepreneur' then 'entrepreneur'
    when 'intermediary' then 'intermediaire'
    end
  end

  def finish_onboarding!
    current_user.update_column(:onboarding_completed_at, Time.current)
    session.delete(:onboarding)
    session.delete(:onboarding_property_id)
  end

  def redirect_if_onboarding_done
    redirect_to dashboard_path(locale: I18n.locale) if current_user.onboarding_done?
  end

  def property_params
    params.require(:property).permit(:rue, :numero, :code_postal, :commune, :region,
                                     :type_propriete_wallonie, :type_bien_flandre, :type_bien_bruxelles,
                                     :profil_demandeur)
  end

  # Type de bien régional et profil demandeur : demandés dès le tunnel, sur la base
  # des mêmes valeurs que les formulaires de bien (properties/_form_*).
  def regional_fields_missing?(property)
    type_field = ONBOARDING_REGIONAL_OPTIONS.dig(property.region.to_s.downcase, :type_field)
    return false unless type_field

    property[type_field].blank? || property.profil_demandeur.blank?
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
