class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :flandre, :wallonie, :bruxelles]

  def home
  end

  def flandre
    categorie = params[:categorie].to_i
    categorie_estimee = params[:categorieEstimee].to_i

    @categorie_id =
      if categorie == 1
        1
      elsif categorie == 4
        categorie_estimee.in?(1..4) ? categorie_estimee : 1
      else
        1
      end

    @primes = Prime.where(region: "flandre")
                  .where("eligible_categories @> ARRAY[?]::varchar[]", [@categorie_id.to_s])
                  .order(:ordre_affichage)

    @plafonds_par_categorie = Prime.group(:category_id).maximum(:plafond)
    @groupes_plafond = Prime.distinct.pluck(:groupe)
  end

end
