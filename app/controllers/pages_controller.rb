class PagesController < ApplicationController
  def home
    @primes = Prime.all
    @categorie_id = 3 # ou toute logique que tu veux pour déterminer la catégorie en front
    @plafonds_par_categorie = Prime.group(:category_id).maximum(:plafond)
    @groupes_plafond = Prime.distinct.pluck(:groupe)
  end
end
