module WalloniePrimesHelper
  # Helper pour récupérer la condition d'une prime depuis la base de données
  def condition_prime_wallonie(slug)
    prime = Prime.find_by(slug: slug)
    prime&.condition || ""
  end

  # Helper pour récupérer le conseil d'une prime depuis la base de données
  def conseil_prime_wallonie(slug)
    prime = Prime.find_by(slug: slug)
    prime&.conseil || ""
  end
end
