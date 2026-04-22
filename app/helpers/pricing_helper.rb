module PricingHelper
  # Affiche une feature de pricing : grise + badge "À venir" si le texte contient "(à venir)"
  def render_pricing_feature(feature, icon_class: "bi-check-circle-fill text-success", small: false)
    coming_soon = feature.include?("(à venir)")
    label = coming_soon ? feature.sub(" (à venir)", "") : feature
    label_html = small ? content_tag(:small, label.html_safe) : label.html_safe

    content_tag(:li, class: "mb-2#{coming_soon ? ' text-muted' : ''}") do
      icon  = content_tag(:i, "", class: "bi #{coming_soon ? 'bi-hourglass-split text-secondary' : icon_class} me-2")
      badge = coming_soon ? content_tag(:span, "À venir", class: "badge bg-secondary ms-1", style: "font-size:0.65rem;vertical-align:middle;") : "".html_safe
      icon + label_html + badge
    end
  end

  def current_user_tier
    # Pour l'instant, tous les utilisateurs sont en freemium
    # À adapter quand le billing sera implémenté
    return :freemium unless user_signed_in?

    # Future logique basée sur subscription
    :freemium
  end

  def recommended_tier_for_current_user
    return :individual unless user_signed_in?

    properties_count = current_user.properties.count

    case properties_count
    when 0..1
      :individual
    when 2..3
      :individual
    when 4..10
      :portfolio
    else
      :professional
    end
  end

  def tier_upgrade_available?
    return true unless user_signed_in?
    current_user_tier != recommended_tier_for_current_user
  end

  def pricing_tier_name(tier)
    tiers = {
      freemium: "Starter",
      individual: "Propriétaire",
      portfolio: "Investisseur",
      premium_mixed: "Premium",
      professional: "Pro",
      enterprise: "Entreprise"
    }
    tiers[tier.to_sym] || tier.to_s.humanize
  end

  def pricing_tier_price(tier)
    prices = {
      freemium: 0,
      individual: 39,
      portfolio: 89,
      premium_mixed: 149,
      professional: 99,
      enterprise: 299
    }
    prices[tier.to_sym] || 0
  end

  def upgrade_badge_text
    if user_signed_in?
      recommended = recommended_tier_for_current_user
      if recommended != current_user_tier
        "→ #{pricing_tier_name(recommended)}"
      else
        "Premium"
      end
    else
      "Pricing"
    end
  end

  def roi_percentage(tier, estimated_savings = nil)
    annual_cost = pricing_tier_price(tier) * 12
    return 0 if annual_cost == 0

    # Estimations conservatives d'économies par tier
    default_savings = {
      individual: 1500,
      portfolio: 5000,
      premium_mixed: 20000,
      professional: 15000,
      enterprise: 50000
    }

    savings = estimated_savings || default_savings[tier.to_sym] || 0
    ((savings.to_f / annual_cost) * 100).round
  end

  def tier_features_count(tier)
    features_count = {
      freemium: 6,
      individual: 9,
      portfolio: 11,
      premium_mixed: 9,
      professional: 10,
      enterprise: 12
    }
    features_count[tier.to_sym] || 0
  end

  def tier_target_description(tier)
    descriptions = {
      freemium: "Découverte",
      individual: "Particuliers 1-3 propriétés",
      portfolio: "Multi-propriétaires 4-10 biens",
      premium_mixed: "Hybride particulier + professionnel",
      professional: "Architectes, entrepreneurs, bureaux d'études",
      enterprise: "Syndic / Promoteur / Grande équipe"
    }
    descriptions[tier.to_sym] || ""
  end

  def pricing_cta_class(tier, current_tier = nil)
    current_tier ||= current_user_tier

    base_class = "btn btn-lg w-100"

    case tier.to_sym
    when current_tier
      "#{base_class} btn-secondary"
    when :freemium
      "#{base_class} btn-outline-secondary"
    when :individual
      "#{base_class} btn-primary"
    when :portfolio
      "#{base_class} btn-warning text-dark"
    when :professional
      "#{base_class} btn-success"
    when :enterprise
      "#{base_class} btn-dark"
    else
      "#{base_class} btn-outline-primary"
    end
  end

  def pricing_card_class(tier, current_tier = nil, recommended_tier = nil)
    current_tier ||= current_user_tier
    recommended_tier ||= recommended_tier_for_current_user

    base_class = "card h-100 pricing-card"

    if tier.to_sym == recommended_tier
      "#{base_class} border-primary shadow-lg"
    elsif tier.to_sym == current_tier
      "#{base_class} border-secondary"
    else
      "#{base_class} border-0 shadow-sm"
    end
  end

  def format_currency(amount, currency = "€")
    "#{amount}#{currency}"
  end

  def format_period(period)
    case period.to_s
    when "month", "mois"
      "/mois"
    when "year", "an", "année"
      "/an"
    when "gratuit", "free"
      ""
    else
      period
    end
  end
end
