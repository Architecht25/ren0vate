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

    @billing_cycle = %w[monthly yearly].include?(params[:billing_cycle]) ? params[:billing_cycle] : 'monthly'
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

  def portal
    unless stripe_configured?
      redirect_to pricing_select_path, notice: "Portail de gestion non disponible en mode démo."
      return
    end

    unless current_user.stripe_customer_id.present?
      redirect_to pricing_select_path, alert: "Aucun abonnement actif trouvé."
      return
    end

    portal_session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: pricing_select_url
    })

    redirect_to portal_session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to pricing_select_path, alert: "Erreur d'accès au portail : #{e.message}"
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
      # Utiliser le customer_id existant si disponible (pré-remplit la CB)
      customer_params = if current_user&.stripe_customer_id.present?
        { customer: current_user.stripe_customer_id }
      else
        { customer_email: current_user&.email }
      end

      # Montant à facturer : annuel = annual_total, mensuel = price (en centimes)
      billable_amount = if billing_cycle == 'yearly'
        (pricing_tiers_data[tier][:annual_total] || pricing_tiers_data[tier][:price] * 10) * 100
      else
        pricing_tiers_data[tier][:price] * 100
      end

      # Tiers Pro : trial 14j sans CB requise — conversion automatique à J+14
      pro_tiers = %i[professional]
      is_pro_tier = pro_tiers.include?(tier)

      # Configuration de la session Stripe
      session_params = {
        payment_method_types: ['card'],
        mode: 'subscription',
        **customer_params,

        # Collecte adresse de facturation — requis pour auto_tax et conformité TVA belge
        billing_address_collection: 'required',
        # Mise à jour du profil Stripe customer (adresse, nom)
        customer_update: { address: 'auto', name: 'auto' },
        # Collecte numéro TVA (B2B) — optionnel, aucun blocage si absent
        tax_id_collection: { enabled: true },

        # Consentement CGV affiché dans la page Stripe — preuve de consentement côté Stripe
        consent_collection: { terms_of_service: 'required' },
        custom_text: {
          terms_of_service_acceptance: {
            message: "J'accepte les <a href=\"https://ren0vate.be/conditions-generales\">CGV d'ArchiTecht SRL</a> (BCE BE 1020.345.473) et reconnais avoir été informé de mon droit de rétractation de 14 jours calendrier (art. VI.47 Code de droit économique belge)."
          }
        },

        line_items: [{
          price_data: {
            currency: 'eur',
            product_data: {
              name: pricing_tiers_data[tier][:name],
              description: pricing_tiers_data[tier][:description],
            },
            unit_amount: billable_amount.to_i,
            tax_behavior: 'inclusive', # Prix TTC — TVA incluse dans le montant affiché
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
      }

      if is_pro_tier
        # Trial 14j sans CB — CB collectée uniquement si l'utilisateur confirme après le trial
        session_params[:payment_method_collection] = 'if_required'
        session_params[:subscription_data][:trial_period_days] = 14
      end

      session = Stripe::Checkout::Session.create(session_params)

      redirect_to session.url, allow_other_host: true

    rescue Stripe::StripeError => e
      redirect_to pricing_summary_path(tier: tier), alert: "Erreur lors de la création du paiement : #{e.message}"
    end
  end

  private

  def pricing_tiers_data
    {
      freemium: {
        name: "Starter",
        price: 0,
        period: "gratuit",
        description: "Découvrez Ren0vate — sans engagement",
        features: [
          "1 bien enregistré",
          "1 projet de rénovation",
          "Simulation de primes (1×)",
          "Estimation budget IA (aperçu)"
        ],
        limitations: [
          "Pas de suivi chantier",
          "Pas d'Expert IA",
          "Pas de comparateur entrepreneurs",
          "Pas de dossier documentaire",
          "Support communautaire uniquement"
        ],
        cta: "Commencer gratuitement",
        popular: false,
        target: "Découverte"
      },

      individual: {
        name: "Propriétaire",
        price: 39,
        annual_total: 390,
        period: "mois",
        description: "Gérez votre rénovation de A à Z — 1 à 3 biens",
        features: [
          "🏠 Jusqu'à 3 biens",
          "📊 Simulations de primes illimitées",
          "💰 ROI Calculator — projections 20 ans",
          "🎯 Recommandations PEB",
          "📋 Import & analyse PEB / Audit énergie",
          "🏛️ Prédicteur permis urbanisme IA (87%)",
          "👷 Comparateur entrepreneurs (3/mois)",
          "� Bordereaux d'avancement IA — suivi structuré",
          "�📁 Dossier documentaire de base",
          "📞 Support prioritaire (24h)"
        ],
        roi: "Économisez 40h d'admin • +25% d'aides détectées • ROI moyen : 15 000€ sur projet 50K€",
        cta: "Gérer mon projet",
        popular: true,
        target: "Propriétaire particulier",
        new_badge: "Gestion complète"
      },

      portfolio: {
        name: "Investisseur",
        price: 89,
        annual_total: 890,
        period: "mois",
        description: "Multi-biens + suivi de chantier en temps réel",
        features: [
          "✅ Tout Propriétaire PLUS :",
          "🏘️ Jusqu'à 10 biens",
          "🔧 Suivi chantier IA — avancement temps réel",
          "📸 Détection progression IA (photos)",
          "📊 Score Santé Projet /10 avec alertes",
          "👥 Espace collaboratif (architecte, entrepreneurs)",
          "📝 PV numériques & validation de phases",
          "✅ Checklist clôture (garanties, certifs)",
          "👷 Comparateur entrepreneurs illimité",
          "📈 Dashboard analytics multi-biens",
          "🤖 Expert IA 24/7 (100 questions/mois)",
          "📞 Support expert (12h)",
          "📦 Dossier final ZIP/PDF (à venir)"
        ],
        roi: "ROI minimum 300% • Valorisation +5-10% par bien • Conformité garantie",
        cta: "Gérer mon patrimoine",
        popular: false,
        target: "Investisseur multi-biens",
        new_badge: "Suivi chantier IA"
      },

      premium_mixed: {
        name: "Premium",
        price: 149,
        annual_total: 1490,
        period: "mois",
        description: "Multi-biens + usage professionnel mixte",
        features: [
          "✅ Tout Investisseur PLUS :",
          "🤖 Expert IA 24/7 illimité",
          "📊 Decision Hub hybride perso + pro",
          "💼 Dashboard unifié patrimonial",
          "📞 Support expert dédié (8h)",
          "🧮 Cross-analytics fiscal mixte (à venir)",
          "👥 3 comptes utilisateurs (à venir)",
          "📡 API accès limité (à venir)",
          "🎓 Formations & webinaires (à venir)"
        ],
        roi: "ROI minimum 1 500% • Idéal profils patrimoniaux et entrepreneuriaux",
        cta: "Choisir Premium",
        popular: false,
        target: "Hybride particulier + professionnel"
      },

      professional: {
        name: "Pro",
        price: 99,
        annual_total: 990,
        period: "mois",
        description: "Architectes, entrepreneurs, bureaux d'études",
        features: [
          "♾️ Projets clients illimités",
          "� Tableau de bord multi-clients",
          "🤖 Expert IA illimité pour vos clients",
          "📋 Bordereaux d'avancement IA par chantier",
          "📄 Rapports clients PDF automatisés",
          "📈 Analytics multi-clients",
          "📞 Support prioritaire expert (4h)",
          "👥 5 comptes équipe (à venir)",
          "🎨 Interface marque personnalisée (à venir)",
          "🔌 Intégrations comptabilité tierces (à venir)",
          "🎓 Formations spécialisées (à venir)"
        ],
        roi: "Break-even : 3-5 clients aidés/an • Scaling 5× ROI",
        cta: "Démarrer en Pro",
        popular: false,
        target: "Architecte / Entrepreneur / Bureau d'études"
      },

      enterprise: {
        name: "Entreprise",
        price: 299,
        annual_total: 2990,
        period: "mois",
        description: "Syndics, promoteurs, grandes équipes — solution sur-mesure",
        features: [
          "✅ Tout Pro PLUS :",
          "♾️ Biens, utilisateurs et projets illimités",
          "� Reporting automatisé clients",
          "💼 SLA 99,9% + Account Manager dédié",
          "🔧 Développements sur-mesure",
          "💾 Export comptable CSV automatisé",
          "🌍 Support multi-régional 24/7",
          "🔌 API complète intégrations métier (à venir)",
          "🎨 White-label — votre marque (à venir)",
          "👥 Gestion équipes multi-niveaux (à venir)",
          "🎓 Formations personnalisées équipe (à venir)",
          "🔒 Sécurité renforcée — SSO (à venir)"
        ],
        roi: "Break-even : 10-15 clients • ROI minimum 500% • Scaling illimité",
        cta: "Nous contacter",
        popular: false,
        target: "Syndic / Promoteur / Grande équipe",
        new_badge: "Solution sur-mesure"
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
    projects_count = current_user.projects.count

    if has_enterprises && properties_count >= 4
      :premium_mixed
    elsif properties_count >= 11
      :premium_mixed
    elsif properties_count >= 4 || projects_count >= 3
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
  helper_method :stripe_configured?
end
