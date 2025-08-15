class Api::UsersController < ApplicationController
  before_action :authenticate_user!

  def update_language_preference
    if current_user.update(preferred_locale: params[:preferred_locale])
      render json: { status: 'success', locale: current_user.preferred_locale }
    else
      render json: { status: 'error', errors: current_user.errors.full_messages }
    end
  end
end
