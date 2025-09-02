class UsersController < ApplicationController
  before_action :authenticate_user!

  def profile
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profil mis à jour avec succès."
    else
      flash.now[:alert] = "Erreur lors de la mise à jour."
      render :profile
    end
  end

private

  def user_params
  params.require(:user).permit(
    :first_name, :last_name, :email, :phone, :iban,
    :street, :number, :postal_code, :city, :region,
    :protected_client,
    :situation_familiale, :revenu_demandeur, :annee_revenus_demandeur,
    :revenu_conjoint, :annee_revenus_conjoint, :nombre_enfants
    )
  end
end
