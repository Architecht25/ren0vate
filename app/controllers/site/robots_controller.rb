class RobotsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    respond_to do |format|
      format.text { render plain: robots_txt_content }
    end
  end

  private

  def robots_txt_content
    base_url = Rails.application.config.force_ssl ? "https://" : "http://"
    base_url += request.host_with_port

    <<~ROBOTS
      # Robots.txt pour Ren0vate - Aides à la rénovation en Belgique
      # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file

      # Autoriser tous les robots sur les pages publiques
      User-agent: *
      Allow: /

      # Pages à ne pas indexer (administration, données privées)
      Disallow: /admin/
      Disallow: /dashboard/
      Disallow: /users/
      Disallow: /properties/
      Disallow: /requests/
      Disallow: /simulations/
      Disallow: /projects/
      Disallow: /documents/
      Disallow: /api/
      Disallow: /webhooks/
      Disallow: /rails/

      # Fichiers et dossiers techniques
      Disallow: /assets/
      Disallow: /_next/
      Disallow: /.well-known/

      # Autoriser explicitement les pages importantes
      Allow: /fr/
      Allow: /nl/
      Allow: /en/
      Allow: /flandre
      Allow: /bruxelles
      Allow: /wallonie
      Allow: /flandre-entreprises
      Allow: /bruxelles-entreprises
      Allow: /wallonie-entreprises
      Allow: /pricing

      # Sitemap
      Sitemap: #{base_url}/sitemap.xml

      # Délai entre les requêtes (en secondes)
      Crawl-delay: 1
    ROBOTS
  end
end
