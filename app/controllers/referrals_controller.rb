class ReferralsController < ApplicationController
  def index
    @referrals = Referral.all
  end

  def show
    @referral = Referral.find(params[:id])
  end

  def new
    @referral = Referral.new
  end

  def create
    @referral = Referral.new(referral_params)
    if @referral.save
      redirect_to @referral
    else
      render :new
    end
  end

  def edit
    @referral = Referral.find(params[:id])
  end

  def update
    @referral = Referral.find(params[:id])
    if @referral.update(referral_params)
      redirect_to @referral
    else
      render :edit
    end
  end

  def destroy
    @referral = Referral.find(params[:id])
    @referral.destroy
    redirect_to referrals_path
  end

  private

  def referral_params
    params.require(:referral).permit(:name, :email, :message)
  end
end
