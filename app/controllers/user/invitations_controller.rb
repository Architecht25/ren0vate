class InvitationsController < ApplicationController
  before_action :find_member, only: [:accept, :show]

  INVALID_TOKEN_MSG  = "Ce lien d'invitation est invalide ou a déjà été utilisé."
  EXPIRED_MSG        = "Ce lien d'invitation a expiré. Demandez une nouvelle invitation."
  ALREADY_ACTIVE_MSG = "Vous êtes déjà membre de ce projet."

  # GET /invitations/:token
  def show
    if @member.nil?
      # Token introuvable : si l'utilisateur est déjà connecté et membre actif, l'envoyer à son projet
      if user_signed_in?
        membership = current_user.project_members.active.includes(:project).order(accepted_at: :desc).first
        return redirect_to pro_view_project_path(membership.project) if membership
      end
      redirect_to root_path, alert: INVALID_TOKEN_MSG
    elsif @member.expired?
      redirect_to root_path, alert: EXPIRED_MSG
    elsif @member.active?
      redirect_to pro_view_project_path(@member.project), notice: ALREADY_ACTIVE_MSG
    end
  end

  # POST /invitations/:token/accept
  def accept
    if @member.nil?
      redirect_to root_path, alert: INVALID_TOKEN_MSG and return
    end

    if @member.expired?
      redirect_to root_path, alert: EXPIRED_MSG and return
    end

    if @member.active?
      sign_in(@member.user) unless user_signed_in?
      redirect_to pro_view_project_path(@member.project), notice: ALREADY_ACTIVE_MSG and return
    end

    # Si l'utilisateur n'est pas connecté et que le compte est incomplet, rediriger vers l'onboarding
    if !user_signed_in? && @member.user.first_name.blank?
      session[:pending_invitation_token] = params[:token]
      redirect_to new_onboarding_invitation_path(token: params[:token]) and return
    end

    # Activer le membre
    @member.accept!
    ProjectMailer.member_joined(@member).deliver_later

    unless user_signed_in?
      store_location_for(:user, pro_view_project_path(@member.project))
      sign_in(@member.user)
    end

    redirect_to pro_view_project_path(@member.project),
                notice: "Bienvenue ! Vous avez rejoint le projet « #{@member.project.name} » en tant que #{@member.role_label}."
  end

  # GET /invitations/:token/onboarding  (nouveau compte → compléter profil)
  def new_onboarding
    @member = ProjectMember.find_by(invite_token: params[:token])
    redirect_to root_path, alert: INVALID_TOKEN_MSG unless @member
  end

  # POST /invitations/:token/onboarding
  def create_onboarding
    @member = ProjectMember.find_by(invite_token: params[:token])
    redirect_to root_path, alert: INVALID_TOKEN_MSG and return unless @member

    user = @member.user
    if user.update(onboarding_params)
      @member.accept!
      ProjectMailer.member_joined(@member).deliver_later
      store_location_for(:user, pro_view_project_path(@member.project))
      sign_in(user)
      redirect_to pro_view_project_path(@member.project),
                  notice: "Bienvenue ! Votre compte est créé et vous avez rejoint « #{@member.project.name} »."
    else
      render :new_onboarding, status: :unprocessable_entity
    end
  end

  private

  def find_member
    @member = ProjectMember.find_by(invite_token: params[:token])
  end

  def onboarding_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end
end
