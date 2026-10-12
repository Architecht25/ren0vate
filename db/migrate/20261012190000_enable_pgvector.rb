# V2 — Lot 5 : extension PostgreSQL pour la recherche sémantique (cahier des
# charges V2 §2 : "pgvector pour les embeddings des documents"). Disponible
# sur Postgres local (vérifié : pg_available_extensions, vector 0.6.0) — à
# vérifier sur le plan Heroku réel avant déploiement (docs/QUESTIONS_OUVERTES.md Q12).
class EnablePgvector < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"
  end
end
