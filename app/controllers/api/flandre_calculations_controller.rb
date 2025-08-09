class Api::FlandreCalculationsController < ApplicationController
  before_action :authenticate_user!

  def calculate_prime
    prime_slug = params[:prime_slug]
    input_value = params[:input_value]
    input_type = params[:input_type]

    calculator = Regions::Flandre::FlandrePostLoginCalculatorService.new({}, user: current_user)
    result = calculator.calculate_prime(prime_slug, input_value, input_type)

    render json: result
  end

  def calculate_all
    inputs = params[:inputs] || {}

    calculator = Regions::Flandre::FlandrePostLoginCalculatorService.new({}, user: current_user)
    results = calculator.calculate_all_primes(inputs)

    render json: results
  end

  private

  def current_property
    @current_property ||= current_user.properties.first
  end
end
