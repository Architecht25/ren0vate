class PagesController < ApplicationController
  def home
    @primes = Prime.all
  end
end
