class PagesController < ApplicationController
  def home
    @categorie_id = 1

    @categorie_id_str = @categorie_id.to_s

    @primes = Prime.where(region: "flandre")
               .where("eligible_categories @> ARRAY[?]::varchar[]", [@categorie_id_str])
               .order(:ordre_affichage)


    @plafonds_par_categorie = Prime.group(:category_id).maximum(:plafond)
    @groupes_plafond = Prime.distinct.pluck(:groupe)
  end
end
