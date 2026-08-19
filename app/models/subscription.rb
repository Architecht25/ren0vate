class Subscription < ApplicationRecord
  belongs_to :user

  # Status constants
  STATUSES = %w[active canceled incomplete_expired trialing unpaid past_due].freeze

  # Tier constants
  TIERS = %w[freemium individual portfolio premium_mixed professional enterprise].freeze

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :tier, presence: true, inclusion: { in: TIERS }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :by_tier, ->(tier) { where(tier: tier) }

  def active?
    status == 'active'
  end

  def canceled?
    status == 'canceled'
  end

  def trial?
    status == 'trialing'
  end

  def current_period_days_remaining
    return 0 unless current_period_end

    days = (current_period_end.to_date - Date.current).to_i
    [days, 0].max
  end

  def tier_name
    case tier
    when 'freemium' then 'Starter'
    when 'individual' then 'Propriétaire'
    when 'portfolio' then 'Investisseur'
    when 'premium_mixed' then 'Premium'
    when 'professional' then 'Pro'
    when 'enterprise' then 'Entreprise'
    else tier.humanize
    end
  end

  def monthly_price
    case tier
    when 'freemium' then 0
    when 'individual' then 39
    when 'portfolio' then 89
    when 'premium_mixed' then 149
    when 'professional' then 99
    when 'enterprise' then 299
    else 0
    end
  end

  # Sync with Stripe
  def sync_with_stripe!
    return unless stripe_subscription_id

    stripe_subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
    subscription = JSON.parse(stripe_subscription.to_json)

    # API 2024-09-30+ : current_period_start/end sont dans les items
    period_start = subscription['current_period_start'] ||
                   subscription.dig('items', 'data', 0, 'current_period', 'start')
    period_end   = subscription['current_period_end'] ||
                   subscription.dig('items', 'data', 0, 'current_period', 'end')

    update!(
      status: stripe_subscription.status,
      current_period_start: period_start ? Time.at(period_start) : nil,
      current_period_end: period_end ? Time.at(period_end) : nil
    )

    stripe_subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to sync subscription #{id} with Stripe: #{e.message}"
    false
  end

  def cancel!
    return false unless stripe_subscription_id && active?

    Stripe::Subscription.update(
      stripe_subscription_id,
      { cancel_at_period_end: true }
    )

    sync_with_stripe!
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to cancel subscription #{id}: #{e.message}"
    false
  end
end
