class PrimesController < ApplicationController
  def index
    @primes = Prime.all
  end

  def show
    @prime = Prime.find(params[:id])
  end

  def new
    @prime = Prime.new
  end

  def create
    @prime = Prime.new(prime_params)
    if @prime.save
      redirect_to @prime, notice: 'Prime créée avec succès.'
    else
      render :new
    end
  end

  def edit
    @prime = Prime.find(params[:id])
  end

  def update
    @prime = Prime.find(params[:id])
    if @prime.update(prime_params)
      redirect_to @prime, notice: 'Prime mise à jour avec succès.'
    else
      render :edit
    end
  end

  def destroy
    @prime = Prime.find(params[:id])
    @prime.destroy
    redirect_to primes_path, notice: 'Prime supprimée avec succès.'
  end

  private

  def prime_params
    params.require(:prime).permit(:name, :category_id, :value, :description, :slug)
  end
end
