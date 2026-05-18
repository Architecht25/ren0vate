# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Sources de base
    policy.default_src :self

    # Scripts : nos scripts + CDNs de confiance + nonces pour inline + eval pour Turbo
    # 'unsafe-inline' supprimé le 22 avril 2026 — tous les <script> utilisent désormais des nonces
    # :https générique supprimé — CDNs listés explicitement ci-dessous
    policy.script_src  :self,
                       "'unsafe-eval'",   # Nécessaire pour Turbo Rails
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://unpkg.com",
                       "https://api.mapbox.com"

    # Styles : nos styles + CDNs + inline styles pour les composants dynamiques
    policy.style_src   :self,
                       :https,
                       "'unsafe-inline'", # Nécessaire pour Bootstrap, SweetAlert2, Turbo et nos composants
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://fonts.googleapis.com",
                       "https://api.mapbox.com"

    # Directives plus spécifiques pour les navigateurs modernes
    policy.style_src_elem :self,
                          :https,
                          "'unsafe-inline'", # Pour les balises <style> générées dynamiquement
                          "https://cdn.jsdelivr.net",
                          "https://cdnjs.cloudflare.com"

    policy.style_src_attr "'unsafe-inline'" # Pour les attributs style="" nécessaires aux composants UI

    # Directive spécifique pour les éléments <script>
    # 'unsafe-inline' supprimé le 22 avril 2026 — nonces utilisés sur tous les éléments <script>
    # :https générique supprimé — CDNs listés explicitement ci-dessous
    policy.script_src_elem :self,
                           "'unsafe-eval'",   # Nécessaire pour Turbo Rails
                           "https://cdn.jsdelivr.net",
                           "https://cdnjs.cloudflare.com",
                           "https://unpkg.com",
                           "https://api.mapbox.com",
                           "https://plausible.io",
                           # Hashes des scripts inline générés par Turbo lors des navigations
                           "'sha256-428cnxCfeQxvp/bW2Z3UuFfBBP0pXGmafBREYA3qPbM='",
                           "'sha256-YNw62I+4BSARy5Ai85IqwTlWvm58279O8hGEOm48Gck='",
                           "'sha256-S2OTTMDowYbtZdX48OgZt58QypfWEy7TyIbBuEgIxfY='",
                           "'sha256-66/hRq/pZaNOtfE4AadRDwCqTquAXAA3vt0X5xFhWSo='",
                           "'sha256-KgTFVOTAR06haNrZ9m/ea8WEAjUBIOE7QMDIB1waxfY='",
                           "'sha256-WHFe3NDoq2auiN7B1i/wxGpCweJJ8cJcXcJZ4U1nyvE='",
                           "'sha256-BzNcgSQenaJbvARk9sUhkBjC6WaPeI7mDhmtjPUUqiQ='"

    policy.script_src_attr "'unsafe-inline'" # Pour les event handlers onclick, onload, etc. dans les attributs

    # Polices : sources locales + CDNs + data URLs
    policy.font_src    :self,
                       :https,
                       :data,
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://fonts.gstatic.com"

    # Images : sources locales + Cloudinary + data URLs + autres domaines de confiance
    policy.img_src     :self,
                       :https,
                       :data,
                       "http://localhost:3000", # Pour Active Storage en développement
                       "http://localhost:3000/rails/active_storage/*", # Routes Active Storage avec wildcards
                       "https://*.cloudinary.com",     # Wildcard pour tous les sous-domaines Cloudinary (couvre res, res-1, res-2, etc.)
                       "http://*.cloudinary.com",      # HTTP pour développement
                       "https://via.placeholder.com", # Pour les placeholders éventuels
                       "https://api.mapbox.com",       # Images Mapbox (sprites, etc.)
                       "https://*.tiles.mapbox.com"    # Tiles de carte Mapbox

    # Connections (XHR/fetch) : notre app + APIs externes utilisées
    policy.connect_src :self,
                       :https,
                       "http://localhost:3000", # Pour les requêtes AJAX en développement
                       "https://geo.onroerenderfgoed.be", # API monuments Flandre
                       "https://www.premiezoeker.be",      # API primes communales
                       "https://api.mapbox.com",           # API Mapbox pour tiles et géocodage
                       "https://events.mapbox.com",        # Télémétrie Mapbox
                       "https://*.tiles.mapbox.com",       # Tiles Mapbox
                       "https://plausible.io"              # Plausible Analytics hits

    # Medias : sources locales + Cloudinary si utilisé pour vidéos
    policy.media_src   :self,
                       :https,
                       "https://res.cloudinary.com"

    # Interdire les objets et plugins (Flash, etc.)
    policy.object_src  :none

    # Frames : uniquement notre domaine (pour éviter le clickjacking)
    policy.frame_src   :self

    # Base URI : restreindre où peuvent pointer les liens relatifs
    policy.base_uri    :self

    # Form actions : limiter où les formulaires peuvent envoyer des données
    # checkout.stripe.com autorisé car Rails redirige (302) vers Stripe après le POST /pricing/checkout
    # Chrome applique form-action aux redirects aussi, pas seulement à l'URL d'action initiale
    policy.form_action :self, "https://checkout.stripe.com"

    # Web Workers : pour Mapbox GL JS
    policy.worker_src  :self, :blob

    # Spécifier l'URI pour les rapports de violation
    policy.report_uri "/csp-violation-report-endpoint"
  end

  # Générer des nonces pour les scripts et styles inline autorisés
  # Nonce par session (pas par requête) pour assurer la compatibilité avec Turbo Drive :
  # lors d'une navigation Turbo, le navigateur conserve le nonce CSP de la page initiale.
  # Si on génère un nouveau nonce à chaque requête, les scripts inline des pages suivantes
  # ont un nonce différent → bloqués. En utilisant un nonce par session, le nonce reste
  # cohérent durant toute la navigation Turbo.
  config.content_security_policy_nonce_generator = ->(request) {
    request.session[:csp_nonce] ||= SecureRandom.base64(16)
  }

  # Appliquer les nonces aux directives script-src et style-src
  config.content_security_policy_nonce_directives = %w(script-src script-src-elem style-src)

  # Configuration environment-specific
  if Rails.env.development?
    # En développement, on assouplit pour Active Storage et localhost
    config.content_security_policy_report_only = true
    Rails.logger.info "🔓 CSP en mode rapport uniquement (développement)"
  else
    # En production, CSP stricte
    config.content_security_policy_report_only = false
    Rails.logger.info "🔒 CSP en mode strict (#{Rails.env})"
  end

  # Option pour forcer le mode strict en développement si nécessaire
  # Utilisez: CSP_ENFORCE=true rails server
  if Rails.env.development? && ENV['CSP_ENFORCE'] == 'true'
    config.content_security_policy_report_only = false
    Rails.logger.info "� CSP forcé en mode strict (développement)"
  end
end
