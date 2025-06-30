class PrimesController < ApplicationController
  def index
    @primes = Prime.all
  end

  def show
    @prime = Prime.find(params[:id])
  end
end
