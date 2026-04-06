class LoansHubController < ApplicationController
  before_action :authenticate_user!
  before_action :load_property

  def index
  end

  def credit_classique
  end

  def verbouwlening
    @categories_flandre = Category.flandre
                                  .where(eligible_pour_verbouwlening: true)
                                  .order(:seuil_seul)
  end

  def renopack
  end

  def ecoreno
  end

  private

  def load_property
    @property = current_user.properties.find_by(id: params[:property_id]) if params[:property_id].present?
  end
end
