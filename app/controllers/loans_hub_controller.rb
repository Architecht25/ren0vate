class LoansHubController < ApplicationController
  before_action :authenticate_user!

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
end
