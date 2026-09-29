module PricingTierCatalog
  TIERS = {
    freemium: { name: "Starter", price: 0, annual_total: 0, chat_limit: 5 },
    individual: { name: "Propriétaire", price: 39, annual_total: 390, chat_limit: 50 },
    portfolio: { name: "Investisseur", price: 89, annual_total: 890, chat_limit: 150 },
    premium_mixed: { name: "Premium", price: 149, annual_total: 1490, chat_limit: Float::INFINITY },
    professional: { name: "Pro", price: 99, annual_total: 990, chat_limit: Float::INFINITY },
    enterprise: { name: "Entreprise", price: 299, annual_total: 2990, chat_limit: Float::INFINITY }
  }.freeze

  def self.name(tier)
    TIERS.dig(tier.to_sym, :name) || tier.to_s.humanize
  end

  def self.price(tier)
    TIERS.dig(tier.to_sym, :price) || 0
  end

  def self.annual_total(tier)
    TIERS.dig(tier.to_sym, :annual_total) || 0
  end

  def self.chat_limit(tier)
    TIERS.dig(tier.to_sym, :chat_limit) || Float::INFINITY
  end
end
