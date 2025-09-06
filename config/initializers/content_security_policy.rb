# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Sources de base
    policy.default_src :self

    # Scripts : permettre nos scripts + CDNs de confiance + nonces pour inline + eval pour Turbo
    policy.script_src  :self,
                       :https,
                       "'unsafe-inline'", # Temporaire pour les onclick handlers
                       "'unsafe-eval'",   # Nécessaire pour Turbo Rails
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://unpkg.com"

    # Styles : nos styles + CDNs + inline styles pour les composants dynamiques
    policy.style_src   :self,
                       :https,
                       "'unsafe-inline'", # Nécessaire pour Bootstrap, SweetAlert2, Turbo et nos composants
                       "https://cdn.jsdelivr.net",
                       "https://cdnjs.cloudflare.com",
                       "https://fonts.googleapis.com"

    # Directives plus spécifiques pour les navigateurs modernes
    policy.style_src_elem :self,
                          :https,
                          "'unsafe-inline'", # Pour les balises <style> générées dynamiquement
                          "https://cdn.jsdelivr.net",
                          "https://cdnjs.cloudflare.com"

    policy.style_src_attr "'unsafe-inline'" # Pour les attributs style="" nécessaires aux composants UI

    # Directive spécifique pour les éléments <script>
    policy.script_src_elem :self,
                           :https,
                           "'unsafe-inline'",
                           "'unsafe-eval'",   # Nécessaire pour Turbo Rails
                           "https://cdn.jsdelivr.net",
                           "https://cdnjs.cloudflare.com",
                           "https://unpkg.com"

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
                       "https://res.cloudinary.com", # Cloudinary principal
                       "https://res-2.cloudinary.com", # Cloudinary CDN secondaire
                       "https://res-1.cloudinary.com", # Cloudinary CDN alternatif
                       "https://via.placeholder.com" # Pour les placeholders éventuels

    # Connections (XHR/fetch) : notre app + APIs externes utilisées
    policy.connect_src :self,
                       :https,
                       "https://geo.onroerenderfgoed.be", # API monuments Flandre
                       "https://www.premiezoeker.be"      # API primes communales

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
    policy.form_action :self

    # Spécifier l'URI pour les rapports de violation
    policy.report_uri "/csp-violation-report-endpoint"
  end

  # Générer des nonces pour les scripts et styles inline autorisés
  config.content_security_policy_nonce_generator = ->(request) {
    # Utiliser un générateur de nonce sécurisé
    SecureRandom.base64(16)
  }

  # Appliquer les nonces aux directives script-src et style-src
  config.content_security_policy_nonce_directives = %w(script-src style-src)

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
