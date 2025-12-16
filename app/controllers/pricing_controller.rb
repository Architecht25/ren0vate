class PricingController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    # Page principale du pricing - accessible sans connexion
    @pricing_tiers = pricing_tiers_data
  end

  def select
    # Page de sélection de profil pour utilisateurs connectés
    @pricing_tiers = pricing_tiers_data
    @current_user_context = build_user_context
  end

  def summary
    # Page de résumé d'abonnement (Subscription Summary)
    @tier = params[:tier].to_sym

    unless valid_tier?(@tier)
      redirect_to pricing_select_path, alert: "Tier de pricing invalide"
      return
    end

    @pricing_tiers = pricing_tiers_data
    @selected_tier = @pricing_tiers[@tier]
    @current_user_context = build_user_context if user_signed_in?
  end

  def success
    # Page de confirmation après paiement réussi
    @tier = params[:tier]
    @session_id = params[:session_id]
  end

  def cancel
    # Page si utilisateur annule le paiement
    redirect_to pricing_select_path, notice: "Paiement annulé. Vous pouvez réessayer quand vous voulez."
  end

  def checkout
    # Création d'une session Stripe Checkout pour abonnement
    tier = params[:tier].to_sym
    billing_cycle = params[:billing_cycle] || 'monthly'

    unless valid_tier?(tier)
      redirect_to pricing_select_path, alert: "Tier de pricing invalide"
      return
    end

    # Si pas de clés Stripe configurées, rediriger vers une démo
    unless stripe_configured?
      redirect_to pricing_success_path(tier: tier, session_id: 'demo_session'),
                  notice: "Mode démo : Paiement simulé avec succès !"
      return
    end

    begin
      # Configuration de la session Stripe
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        mode: 'subscription',
        customer_email: current_user&.email,

        line_items: [{
          price_data: {
            currency: 'eur',
            product_data: {
              name: pricing_tiers_data[tier][:name],
              description: pricing_tiers_data[tier][:description],
            },
            unit_amount: (pricing_tiers_data[tier][:price] * 100).to_i, # Stripe utilise les centimes
            recurring: {
              interval: billing_cycle == 'yearly' ? 'year' : 'month',
            }
          },
          quantity: 1,
        }],

        metadata: {
          user_id: current_user&.id,
          tier: tier.to_s,
          billing_cycle: billing_cycle
        },

        success_url: pricing_success_url(tier: tier, session_id: '{CHECKOUT_SESSION_ID}'),
        cancel_url: pricing_cancel_url,

        automatic_tax: { enabled: true },

        subscription_data: {
          metadata: {
            user_id: current_user&.id,
            tier: tier.to_s
          }
        }
      )

      redirect_to session.url, allow_other_host: true

    rescue Stripe::StripeError => e
      redirect_to pricing_summary_path(tier: tier), alert: "Erreur lors de la création du paiement : #{e.message}"
    end
  end

  private

  def pricing_tiers_data
    {
      freemium: {
        name: "Découverte",
        price: 0,
        period: "gratuit",
        description: "Parfait pour débuter",
        features: [
          "1 propriété enregistrée",
          "1 projet de rénovation",
          "1 simulation complète",
          "Consultation primes disponibles",
          "Recherche BCE limitée (5/mois)",
          "Support email basique (48h)"
        ],
        limitations: [
          "Pas de multi-propriétés",
          "Pas d'import PEB/Audit",
          "Pas de ROI Calculator",
          "Pas de gestion permis urbanisme",
          "Pas de suivi chantier",
          "Pas de comparateur entrepreneurs",
          "Support basique uniquement"
        ],
        cta: "Commencer gratuitement",
        popular: false,
        target: "Découverte"
      },

      individual: {
        name: "Propriétaire Solo",
        price: 39,
        period: "mois",
        description: "Gestion complète 1-3 propriétés",
        features: [
          "🏠 Jusqu'à 3 propriétés",
          "📊 Simulations illimitées primes/prêts",
          "📋 Import & Analyse certificat PEB/Audit",
          "💰 ROI Calculator complet (projections 20 ans)",
          "🎯 Roadmap évolution label énergétique",
          "📁 Gestion documentaire de base",
          "🏛️ Assistant permis urbanisme (évaluation + checklist)",
          "💼 Planificateur budgétaire intelligent",
          "👷 Comparateur entrepreneurs (3 devis/mois)",
          "🔍 Recherche BCE illimitée",
          "📧 Support prioritaire (24h)",
          "📄 Export rapports PDF"
        ],
        roi: "Économisez 40h admin • +25% d'aides détectées • ROI moyen : 15.000€ sur projet 50K€",
        cta: "Démarrer avec Propriétaire Solo",
        popular: true,
        target: "B2C Particuliers",
        new_badge: "Gestion complète"
      },

      portfolio: {
        name: "Portfolio Manager",
        price: 89,
        period: "mois",
        description: "Gestion avancée 4-10 propriétés + Suivi chantier",
        features: [
          "✅ Tout Individual PLUS :",
          "🏘️ Jusqu'à 10 propriétés",
          "🔧 Suivi chantier avec état d'avancement",
          "👥 Collaboration multi-acteurs (architecte, entrepreneurs)",
          "📝 PV numériques et validation phases",
          "✅ Checklist clôture complète (garanties, certifications)",
          "📦 Génération dossier final complet (ZIP + PDF)",
          "👷 Comparateur entrepreneurs illimité",
          "📈 Dashboard analytics avancé multi-propriétés",
          "⚡ Assistant conformité technique",
          "🎯 Priorisation intelligente investissements",
          "📞 Support expert (12h)",
          "🎓 Webinaires formation exclusifs"
        ],
        roi: "ROI minimum : 300% • Valorisation +5-10% par bien • Conformité 100%",
        cta: "Choisir Portfolio Manager",
        popular: false,
        target: "B2C Multi-propriétaires",
        new_badge: "Suivi chantier inclus"
      },

      premium_mixed: {
        name: "Premium Mixed",
        price: 189,
        period: "mois",
        description: "Investisseurs-entrepreneurs : patrimoine perso + entreprises",
        features: [
          "Jusqu'à 15 propriétés résidentielles",
          "Jusqu'à 8 entreprises (BCE illimitée)",
          "Ren0Chat : 200 questions/mois",
          "Ren0Bot : Support 24/7 illimité",
          "Decision Hub hybride : Optimisation mixte",
          "Dashboard unifié perso + pro",
          "Cross-analytics fiscal mixte",
          "Recommendations IA hybrides",
          "Support expert spécialisé (24h)",
          "3 comptes utilisateurs équipe",
          "Reporting semi-automatisé",
          "API accès limité",
          "Exports avancés : Reporting fiscal mixte"
        ],
        roi: "ROI minimum : 1500% • ROI réaliste : 3400%+",
        cta: "Choisir Premium Mixed",
        popular: true,
        target: "Hybride B2C+B2B"
      },

      professional: {
        name: "Expert",
        price: 99,
        period: "mois",
        description: "Architectes, entrepreneurs, bureaux d'études",
        features: [
          "Propriétés clients illimitées",
          "Multi-utilisateurs équipe (5 comptes)",
          "Interface personnalisable (logo client)",
          "Reporting clients automatisé",
          "Tools B2B avancés",
          "Analytics multi-clients",
          "Support prioritaire expert (4h)",
          "Intégrations comptabilité de base",
          "Accès API limité (à venir)",
          "Formations spécialisées"
        ],
        roi: "Break-even : 3-5 clients aidés/an • Scaling 5x+ ROI",
        cta: "Choisir Expert",
        popular: false,
        target: "B2B Professionnels"
      },

      enterprise: {
        name: "Enterprise",
        price: 299,
        period: "mois",
        description: "Solution complète syndics, promoteurs, bureaux d'études",
        features: [
          "✅ Tout Portfolio PLUS :",
          "♾️ Propriétés et utilisateurs illimités",
          "🔌 API access complet pour intégrations",
          "🎨 White-label (votre marque)",
          "👥 Gestion équipes multi-niveaux",
          "📊 Reporting automatisé clients",
          "💼 SLA 99.9% + Account manager dédié",
          "🎓 Formations personnalisées équipe",
          "🔧 Développements spécifiques sur-mesure",
          "💾 Export comptable automatisé",
          "📱 Applications mobiles dédiées",
          "🔒 Sécurité renforcée + SSO",
          "🌍 Support multi-régional 24/7"
        ],
        roi: "Break-even : 10-15 clients • ROI minimum : 500% • Scaling illimité",
        cta: "Contacter notre équipe",
        popular: false,
        target: "B2B Enterprise",
        new_badge: "Solution pro complète"
      }
    }
  end

  def build_user_context
    return {} unless user_signed_in?

    {
      properties_count: current_user.properties.count,
      simulations_count: current_user.simulations.count,
      projects_count: current_user.projects.count,
      current_tier: detect_current_tier,
      recommended_tier: recommend_tier_for_user
    }
  end

  def detect_current_tier
    # Utiliser les vraies données d'abonnement
    return :freemium unless user_signed_in?

    current_user.subscription_tier.to_sym
  end

  def recommend_tier_for_user
    properties_count = current_user.properties.count
    has_enterprises = current_user.respond_to?(:enterprises) && current_user.enterprises.any?

    # Logique de recommandation hybride
    if has_enterprises && properties_count >= 4
      :premium_mixed
    elsif properties_count >= 11
      :premium_mixed
    elsif properties_count >= 4
      :portfolio
    elsif properties_count >= 2
      :individual
    else
      :individual
    end
  end

  def valid_tier?(tier)
    pricing_tiers_data.keys.map(&:to_s).include?(tier.to_s)
  end

  def stripe_configured?
    stripe_key = ENV['STRIPE_SECRET_KEY'] || Rails.application.credentials.stripe_secret_key
    stripe_key.present? && stripe_key != 'sk_test_dummy_key_for_development' && !stripe_key.include?('dummy')
  end
end
