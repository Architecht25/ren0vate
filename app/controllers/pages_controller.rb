class PagesController < ApplicationController
  def home
    @primes = Prime.all
    @categorie_id = 3 # ou toute logique que tu veux pour déterminer la catégorie en front
  end
end
