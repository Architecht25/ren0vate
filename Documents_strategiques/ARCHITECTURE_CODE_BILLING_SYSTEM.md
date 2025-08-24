# Architecture Code pour Modèle Économique Ren0vate

**Date :** 20 août 2025
**Objectif :** Architecture technique pour modèle freemium + usage + subscription + success fee
**Stack :** Rails 8.0 + moderne billing system

## 🏗️ **ARCHITECTURE GLOBALE RECOMMANDÉE**

### **📊 Vue d'Ensemble du Système**
```
┌─────────────────────────────────────────────────────────────┐
│                    BILLING CORE SYSTEM                     │
├─────────────────────────────────────────────────────────────┤
│  🆓 Freemium    💳 Usage-Based   📅 Subscriptions  💰 Fees │
│     Logic         Billing         Management      Tracking │
├─────────────────────────────────────────────────────────────┤
│           🎯 USER TIER MANAGEMENT SYSTEM                    │
├─────────────────────────────────────────────────────────────┤
│     🤖 AI Services    🏠 Properties    📊 Analytics        │
│      Gating          Scaling          Tracking             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ **MODÈLES DE DONNÉES CORE**

### **1. User Extensions pour Billing**
```ruby
# app/models/user.rb (extensions)
class User < ApplicationRecord
  # Existing code...

  # === BILLING RELATIONSHIPS ===
  has_one :billing_profile, dependent: :destroy
  has_many :usage_credits, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :success_fee_agreements, dependent: :destroy
  has_many :billing_transactions, dependent: :destroy

  # === TIER MANAGEMENT ===
  enum tier: {
    free: 0,
    occasional: 1,
    portfolio_builder: 2,
    power_investor: 3,
    elite_member: 4
  }

  # === DELEGATIONS ===
  delegate :simulation_credits, :property_slots_used, :property_slots_available,
           :has_active_chat_subscription?, :has_active_bot_subscription?,
           to: :billing_profile

  # === CORE BUSINESS LOGIC ===
  def can_create_simulation?
    simulation_credits > 0 || has_unlimited_simulations?
  end

  def can_add_property?
    property_slots_available > 0 || has_unlimited_properties?
  end

  def can_access_chat?
    has_active_chat_subscription? || elite_member?
  end

  def can_access_bot?
    has_active_bot_subscription? || elite_member?
  end

  private

  def has_unlimited_simulations?
    has_active_bot_subscription? || elite_member?
  end

  def has_unlimited_properties?
    elite_member?
  end
end
```

### **2. Billing Profile - Hub Central**
```ruby
# app/models/billing_profile.rb
class BillingProfile < ApplicationRecord
  belongs_to :user
  has_many :usage_credits
  has_many :subscriptions
  has_many :property_billings

  # === SIMULATION CREDITS ===
  def simulation_credits
    usage_credits.simulation_type.unexpired.sum(:quantity)
  end

  def deduct_simulation_credit!
    credit = usage_credits.simulation_type.unexpired.first
    return false unless credit&.quantity&.positive?

    credit.update!(quantity: credit.quantity - 1)
    true
  end

  def add_simulation_credits!(quantity, expires_at = 1.year.from_now)
    usage_credits.create!(
      credit_type: 'simulation',
      quantity: quantity,
      expires_at: expires_at
    )
  end

  # === PROPERTY SLOTS ===
  def property_slots_used
    user.properties.count
  end

  def property_slots_available
    return Float::INFINITY if user.elite_member?

    purchased_slots = property_billings.sum(:slots_purchased)
    base_slots = 1 # Premier bien gratuit
    total_slots = base_slots + purchased_slots

    [total_slots - property_slots_used, 0].max
  end

  # === SUBSCRIPTIONS STATUS ===
  def has_active_chat_subscription?
    subscriptions.chat_type.active.exists?
  end

  def has_active_bot_subscription?
    subscriptions.bot_type.active.exists? ||
    subscriptions.bundle_type.active.exists?
  end

  # === TIER CALCULATION ===
  def calculate_tier
    return :elite_member if elite_conditions_met?
    return :power_investor if power_investor_conditions_met?
    return :portfolio_builder if portfolio_builder_conditions_met?
    return :occasional if occasional_conditions_met?
    :free
  end

  private

  def elite_conditions_met?
    user.simulations.count >= 10 && user.properties.count >= 5
  end

  def power_investor_conditions_met?
    user.properties.count >= 3 || has_active_subscriptions?
  end

  def portfolio_builder_conditions_met?
    user.properties.count >= 2
  end

  def occasional_conditions_met?
    user.simulations.count >= 2
  end

  def has_active_subscriptions?
    has_active_chat_subscription? || has_active_bot_subscription?
  end
end
```

### **3. Usage Credits System**
```ruby
# app/models/usage_credit.rb
class UsageCredit < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :source, polymorphic: true, optional: true # Purchase, Bundle, Promo

  enum credit_type: {
    simulation: 0,
    property_slot: 1,
    document_generation: 2,
    ai_analysis: 3
  }

  scope :unexpired, -> { where('expires_at > ? OR expires_at IS NULL', Time.current) }
  scope :simulation_type, -> { where(credit_type: :simulation) }

  # Auto-expire old credits
  def self.cleanup_expired!
    where('expires_at <= ?', Time.current).delete_all
  end
end

# app/models/property_billing.rb
class PropertyBilling < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :property

  validates :slots_purchased, presence: true, numericality: { greater_than: 0 }
  validates :price_paid, presence: true, numericality: { greater_than: 0 }
  validates :tier_at_purchase, presence: true

  # Tier pricing logic
  def self.calculate_price_for_property(billing_profile)
    properties_count = billing_profile.user.properties.count

    case properties_count + 1 # +1 car on calcule pour le suivant
    when 2..3
      199 # 2-3 biens
    when 4..10
      149 # 4-10 biens
    when 11..25
      99  # 11-25 biens
    else
      79  # 25+ biens
    end
  end
end
```

### **4. Subscriptions System**
```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :plan

  enum status: { active: 0, paused: 1, cancelled: 2, expired: 3 }
  enum subscription_type: { chat: 0, bot: 1, bundle: 2 }

  scope :active, -> { where(status: :active, ends_at: Time.current..) }
  scope :chat_type, -> { where(subscription_type: :chat) }
  scope :bot_type, -> { where(subscription_type: :bot) }
  scope :bundle_type, -> { where(subscription_type: :bundle) }

  # Auto-renewal logic
  def should_renew?
    active? && auto_renew? && ends_at <= 7.days.from_now
  end

  def renew!
    return false unless should_renew?

    transaction do
      # Process payment
      payment = process_renewal_payment
      return false unless payment.succeeded?

      # Extend subscription
      update!(
        ends_at: ends_at + 1.month,
        last_renewed_at: Time.current
      )

      # Log transaction
      billing_profile.billing_transactions.create!(
        transaction_type: 'subscription_renewal',
        amount: plan.price,
        payment_reference: payment.id
      )
    end

    true
  end
end

# app/models/plan.rb
class Plan < ApplicationRecord
  enum plan_type: { chat: 0, bot: 1, bundle: 2 }

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :billing_cycle, inclusion: { in: %w[monthly yearly] }

  # Predefined plans
  def self.ren0chat_plan
    find_by(plan_type: :chat, billing_cycle: 'monthly') ||
    create!(
      name: 'Ren0Chat',
      plan_type: :chat,
      price: 49.00,
      billing_cycle: 'monthly',
      features: ['Questions processus', 'Conseils rénovation', 'Heures ouvrables']
    )
  end

  def self.ren0bot_plan
    find_by(plan_type: :bot, billing_cycle: 'monthly') ||
    create!(
      name: 'Ren0Bot',
      plan_type: :bot,
      price: 79.00,
      billing_cycle: 'monthly',
      features: ['IA avancée 24/7', 'Prompts illimités', 'Analyse prédictive']
    )
  end

  def self.bundle_plan
    find_by(plan_type: :bundle, billing_cycle: 'monthly') ||
    create!(
      name: 'Chat + Bot Bundle',
      plan_type: :bundle,
      price: 119.00,
      billing_cycle: 'monthly',
      features: ['Tout Ren0Chat + Ren0Bot', 'Économies 9€/mois']
    )
  end
end
```

### **5. Success Fee System**
```ruby
# app/models/success_fee_agreement.rb
class SuccessFeeAgreement < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :project

  enum status: { pending: 0, active: 1, completed: 2, cancelled: 3 }

  validates :fee_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :estimated_project_value, presence: true,
            numericality: { greater_than: 0 }

  # Calculate fee based on tier
  def self.fee_percentage_for_user(user)
    case user.tier
    when 'power_investor', 'elite_member'
      7.0 # Reduced fee for premium users
    else
      10.0 # Standard fee
    end
  end

  def calculate_fee_amount(actual_grant_amount)
    (actual_grant_amount * fee_percentage / 100).round(2)
  end

  def process_success_fee!(actual_grant_amount)
    return false unless active?

    fee_amount = calculate_fee_amount(actual_grant_amount)

    transaction do
      # Create billing transaction
      billing_profile.billing_transactions.create!(
        transaction_type: 'success_fee',
        amount: fee_amount,
        description: "Success fee for project #{project.id}",
        metadata: {
          project_id: project.id,
          grant_amount: actual_grant_amount,
          fee_percentage: fee_percentage
        }
      )

      # Update agreement
      update!(
        status: :completed,
        actual_grant_amount: actual_grant_amount,
        fee_amount: fee_amount,
        completed_at: Time.current
      )
    end

    true
  end
end

# app/models/billing_transaction.rb
class BillingTransaction < ApplicationRecord
  belongs_to :billing_profile
  belongs_to :source, polymorphic: true, optional: true

  enum transaction_type: {
    simulation_purchase: 0,
    property_slot_purchase: 1,
    subscription_payment: 2,
    subscription_renewal: 3,
    success_fee: 4,
    bundle_purchase: 5,
    refund: 6
  }

  enum status: { pending: 0, completed: 1, failed: 2, refunded: 3 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true

  scope :revenue, -> { where.not(transaction_type: :refund) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..) }
end
```

---

## 🛠️ **SERVICES MÉTIER**

### **6. Billing Service - Orchestrateur**
```ruby
# app/services/billing_service.rb
class BillingService
  def initialize(user)
    @user = user
    @billing_profile = user.billing_profile || user.create_billing_profile!
  end

  # === SIMULATION BILLING ===
  def purchase_simulations(quantity, payment_method)
    price = calculate_simulation_price(quantity)

    payment = process_payment(price, payment_method, 'simulation_purchase')
    return { success: false, error: payment.error } unless payment.succeeded?

    @billing_profile.add_simulation_credits!(quantity)

    # Create transaction record
    @billing_profile.billing_transactions.create!(
      transaction_type: 'simulation_purchase',
      amount: price,
      payment_reference: payment.id,
      metadata: { quantity: quantity }
    )

    { success: true, credits_added: quantity }
  end

  def use_simulation_credit!
    return false unless @user.can_create_simulation?

    if @billing_profile.simulation_credits > 0
      @billing_profile.deduct_simulation_credit!
    else
      true # Unlimited subscription
    end
  end

  # === PROPERTY BILLING ===
  def purchase_property_slot(payment_method)
    price = PropertyBilling.calculate_price_for_property(@billing_profile)

    payment = process_payment(price, payment_method, 'property_slot_purchase')
    return { success: false, error: payment.error } unless payment.succeeded?

    # Create property billing record
    @billing_profile.property_billings.create!(
      slots_purchased: 1,
      price_paid: price,
      tier_at_purchase: current_tier_name,
      purchased_at: Time.current
    )

    { success: true, price_paid: price }
  end

  # === SUBSCRIPTION BILLING ===
  def subscribe_to_plan(plan_type, payment_method)
    plan = Plan.public_send("#{plan_type}_plan")

    payment = process_payment(plan.price, payment_method, 'subscription_payment')
    return { success: false, error: payment.error } unless payment.succeeded?

    # Cancel existing subscriptions if bundle
    if plan_type == 'bundle'
      @billing_profile.subscriptions.active.update_all(status: :cancelled)
    end

    # Create new subscription
    subscription = @billing_profile.subscriptions.create!(
      plan: plan,
      subscription_type: plan.plan_type,
      starts_at: Time.current,
      ends_at: 1.month.from_now,
      auto_renew: true,
      status: :active
    )

    { success: true, subscription: subscription }
  end

  # === SUCCESS FEE ===
  def create_success_fee_agreement(project, estimated_value)
    fee_percentage = SuccessFeeAgreement.fee_percentage_for_user(@user)

    @billing_profile.success_fee_agreements.create!(
      project: project,
      fee_percentage: fee_percentage,
      estimated_project_value: estimated_value,
      status: :active
    )
  end

  private

  def calculate_simulation_price(quantity)
    base_price = 9.00 # Optimized psychological pricing

    # Volume discounts
    discount = case quantity
    when 5..9 then 0.05   # 5% discount
    when 10..19 then 0.10 # 10% discount
    when 20.. then 0.15   # 15% discount
    else 0
    end

    (base_price * quantity * (1 - discount)).round(2)
  end

  def process_payment(amount, payment_method, type)
    # Integration with Stripe/Mollie
    PaymentService.new.process_payment(
      amount: amount,
      payment_method: payment_method,
      customer: @user,
      description: "Ren0vate #{type}"
    )
  end

  def current_tier_name
    @billing_profile.calculate_tier.to_s
  end
end
```

### **7. AI Services Gating**
```ruby
# app/services/ai_gating_service.rb
class AiGatingService
  def initialize(user)
    @user = user
  end

  def can_use_chat?
    @user.can_access_chat?
  end

  def can_use_bot?
    @user.can_access_bot?
  end

  def can_use_unlimited_prompts?
    @user.has_active_bot_subscription? || @user.elite_member?
  end

  def chat_limits
    return { unlimited: true } if can_use_chat?

    {
      unlimited: false,
      upgrade_required: true,
      suggested_plan: 'ren0chat',
      price: '49€/mois'
    }
  end

  def bot_limits
    return { unlimited: true } if can_use_bot?

    {
      unlimited: false,
      upgrade_required: true,
      suggested_plan: 'ren0bot',
      price: '79€/mois',
      bundle_option: {
        name: 'Chat + Bot Bundle',
        price: '119€/mois',
        savings: '9€/mois'
      }
    }
  end
end

# app/services/tier_management_service.rb
class TierManagementService
  def initialize(user)
    @user = user
    @billing_profile = user.billing_profile
  end

  def update_user_tier!
    new_tier = @billing_profile.calculate_tier

    if @user.tier != new_tier.to_s
      @user.update!(tier: new_tier)

      # Trigger tier-specific actions
      handle_tier_upgrade(new_tier) if tier_upgraded?(new_tier)
    end

    new_tier
  end

  def tier_benefits(tier = @user.tier)
    case tier.to_sym
    when :free
      {
        simulations: '1 gratuite',
        properties: '1 bien gratuit',
        chat: 'Non inclus',
        bot: 'Non inclus',
        success_fee: '10%'
      }
    when :occasional
      {
        simulations: 'À la carte (9€)',
        properties: 'Tiereds pricing',
        chat: 'Upgrade disponible',
        bot: 'Upgrade disponible',
        success_fee: '10%',
        bonus: 'Simulation -50% offerte'
      }
    when :portfolio_builder
      {
        simulations: 'À la carte (9€)',
        properties: 'Pricing dégressif',
        chat: 'Recommandé',
        bot: 'Recommandé',
        success_fee: '10%',
        bonus: 'Bundle Chat+Bot -20%'
      }
    when :power_investor
      {
        simulations: 'À la carte ou illimité',
        properties: 'Pricing optimal',
        chat: 'Accès premium',
        bot: 'Accès premium',
        success_fee: '7%',
        bonus: 'Success fee réduit'
      }
    when :elite_member
      {
        simulations: 'Illimité',
        properties: 'Illimité',
        chat: 'Inclus',
        bot: 'Inclus',
        success_fee: '5%',
        bonus: 'Account manager + betas'
      }
    end
  end

  private

  def tier_upgraded?(new_tier)
    tier_levels = { free: 0, occasional: 1, portfolio_builder: 2, power_investor: 3, elite_member: 4 }
    tier_levels[new_tier] > tier_levels[@user.tier.to_sym]
  end

  def handle_tier_upgrade(new_tier)
    # Send congratulations email
    TierUpgradeMailer.congratulations(@user, new_tier).deliver_later

    # Grant tier-specific bonuses
    grant_tier_bonuses(new_tier)
  end

  def grant_tier_bonuses(tier)
    case tier
    when :occasional
      # Grant discounted simulation
      @billing_profile.add_simulation_credits!(1, 30.days.from_now)
    when :portfolio_builder
      # Offer bundle discount
      create_discount_coupon('BUNDLE20', 20, 'bundle_discount')
    when :power_investor
      # Reduce success fee
      update_success_fee_agreements(7.0)
    when :elite_member
      # Grant premium access
      grant_elite_benefits
    end
  end
end
```

---

## 🎮 **CONTROLLERS & API**

### **8. Billing Controller**
```ruby
# app/controllers/billing_controller.rb
class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_billing_profile

  def dashboard
    @billing_summary = BillingSummaryService.new(current_user).generate_summary
    @tier_benefits = TierManagementService.new(current_user).tier_benefits
    @upgrade_suggestions = UpgradeRecommendationService.new(current_user).suggestions
  end

  # === SIMULATIONS ===
  def purchase_simulations
    quantity = params[:quantity].to_i
    payment_method = params[:payment_method]

    result = BillingService.new(current_user).purchase_simulations(quantity, payment_method)

    if result[:success]
      redirect_to billing_dashboard_path, notice: "#{quantity} simulations ajoutées !"
    else
      redirect_to billing_dashboard_path, alert: "Erreur: #{result[:error]}"
    end
  end

  # === PROPERTIES ===
  def purchase_property_slot
    result = BillingService.new(current_user).purchase_property_slot(params[:payment_method])

    if result[:success]
      redirect_to new_property_path, notice: "Nouvel emplacement bien acheté !"
    else
      redirect_to billing_dashboard_path, alert: "Erreur: #{result[:error]}"
    end
  end

  # === SUBSCRIPTIONS ===
  def subscribe
    plan_type = params[:plan_type]
    result = BillingService.new(current_user).subscribe_to_plan(plan_type, params[:payment_method])

    if result[:success]
      redirect_to billing_dashboard_path, notice: "Abonnement #{plan_type} activé !"
    else
      redirect_to billing_dashboard_path, alert: "Erreur: #{result[:error]}"
    end
  end

  private

  def ensure_billing_profile
    current_user.create_billing_profile! unless current_user.billing_profile
  end
end

# app/controllers/api/billing_controller.rb
class Api::BillingController < ApplicationController
  before_action :authenticate_user!

  def check_simulation_access
    service = AiGatingService.new(current_user)

    render json: {
      can_create: current_user.can_create_simulation?,
      credits_remaining: current_user.simulation_credits,
      upgrade_info: service.chat_limits
    }
  end

  def check_ai_access
    service = AiGatingService.new(current_user)

    render json: {
      chat_access: service.can_use_chat?,
      bot_access: service.can_use_bot?,
      chat_limits: service.chat_limits,
      bot_limits: service.bot_limits
    }
  end

  def pricing_info
    render json: {
      simulation_price: 9.00,
      property_price: PropertyBilling.calculate_price_for_property(current_user.billing_profile),
      plans: {
        chat: Plan.ren0chat_plan.price,
        bot: Plan.ren0bot_plan.price,
        bundle: Plan.bundle_plan.price
      },
      tier_benefits: TierManagementService.new(current_user).tier_benefits
    }
  end
end
```

---

## 🎯 **HOOKS & AUTOMATION**

### **9. Application Hooks**
```ruby
# app/models/concerns/billable.rb
module Billable
  extend ActiveSupport::Concern

  included do
    after_create :check_billing_requirements
    after_update :update_tier_if_needed
  end

  private

  def check_billing_requirements
    case self.class.name
    when 'Simulation'
      handle_simulation_billing
    when 'Property'
      handle_property_billing
    end
  end

  def handle_simulation_billing
    return if user.simulation_credits > 0 || user.has_unlimited_simulations?

    # Block creation if no credits
    errors.add(:base, 'Crédits simulation insuffisants')
    throw :abort
  end

  def handle_property_billing
    return if user.can_add_property?

    errors.add(:base, 'Emplacements propriétés insuffisants')
    throw :abort
  end

  def update_tier_if_needed
    TierManagementService.new(user).update_user_tier!
  end
end

# Include in models
class Simulation < ApplicationRecord
  include Billable
  # existing code...
end

class Property < ApplicationRecord
  include Billable
  # existing code...
end
```

### **10. Background Jobs**
```ruby
# app/jobs/billing_jobs.rb
class SubscriptionRenewalJob < ApplicationJob
  queue_as :billing

  def perform
    Subscription.includes(:billing_profile).each do |subscription|
      next unless subscription.should_renew?

      begin
        subscription.renew!
      rescue => e
        Rails.logger.error "Failed to renew subscription #{subscription.id}: #{e.message}"
        # Send notification to user about failed renewal
        SubscriptionFailureMailer.failed_renewal(subscription).deliver_later
      end
    end
  end
end

class UsageCreditCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    UsageCredit.cleanup_expired!
  end
end

class TierUpdateJob < ApplicationJob
  queue_as :billing

  def perform(user_id)
    user = User.find(user_id)
    TierManagementService.new(user).update_user_tier!
  end
end
```

---

## 📊 **MIGRATIONS**

### **11. Database Schema**
```ruby
# Migration examples
class CreateBillingTables < ActiveRecord::Migration[8.0]
  def change
    # Billing Profiles
    create_table :billing_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.integer :tier, default: 0
      t.decimal :total_spent, precision: 10, scale: 2, default: 0
      t.integer :total_simulations_purchased, default: 0
      t.integer :total_properties_purchased, default: 0
      t.timestamps
    end

    # Usage Credits
    create_table :usage_credits do |t|
      t.references :billing_profile, null: false, foreign_key: true
      t.references :source, polymorphic: true, null: true
      t.integer :credit_type, null: false
      t.integer :quantity, default: 1
      t.datetime :expires_at
      t.timestamps

      t.index [:billing_profile_id, :credit_type]
      t.index :expires_at
    end

    # Property Billings
    create_table :property_billings do |t|
      t.references :billing_profile, null: false, foreign_key: true
      t.references :property, null: true, foreign_key: true
      t.integer :slots_purchased, null: false
      t.decimal :price_paid, precision: 8, scale: 2, null: false
      t.string :tier_at_purchase, null: false
      t.datetime :purchased_at, null: false
      t.timestamps
    end

    # Plans
    create_table :plans do |t|
      t.string :name, null: false
      t.integer :plan_type, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.string :billing_cycle, default: 'monthly'
      t.json :features, default: []
      t.boolean :active, default: true
      t.timestamps

      t.index [:plan_type, :billing_cycle]
    end

    # Subscriptions
    create_table :subscriptions do |t|
      t.references :billing_profile, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.integer :subscription_type, null: false
      t.integer :status, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :auto_renew, default: true
      t.datetime :last_renewed_at
      t.timestamps

      t.index [:billing_profile_id, :status]
      t.index [:subscription_type, :status]
    end

    # Success Fee Agreements
    create_table :success_fee_agreements do |t|
      t.references :billing_profile, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.integer :status, default: 0
      t.decimal :fee_percentage, precision: 4, scale: 2, null: false
      t.decimal :estimated_project_value, precision: 10, scale: 2
      t.decimal :actual_grant_amount, precision: 10, scale: 2
      t.decimal :fee_amount, precision: 8, scale: 2
      t.datetime :completed_at
      t.timestamps
    end

    # Billing Transactions
    create_table :billing_transactions do |t|
      t.references :billing_profile, null: false, foreign_key: true
      t.references :source, polymorphic: true, null: true
      t.integer :transaction_type, null: false
      t.integer :status, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :payment_reference
      t.text :description
      t.json :metadata, default: {}
      t.timestamps

      t.index [:billing_profile_id, :transaction_type]
      t.index [:transaction_type, :status]
      t.index :created_at
    end

    # Add tier to users
    add_column :users, :tier, :integer, default: 0
    add_index :users, :tier
  end
end
```

---

## 🎯 **CONCLUSION ARCHITECTURE**

### **✅ Points Forts de Cette Architecture**

1. **🏗️ Modulaire** : Chaque composant billing séparé et testable
2. **📈 Scalable** : Support multi-tier avec calculs automatiques
3. **💰 Revenue Diversifié** : 4 streams revenue intégrés
4. **🔒 Sécurisé** : Gating approprié et validations
5. **📊 Analytics Ready** : Tracking complet pour métriques business
6. **🤖 AI-Friendly** : Gating IA intégré naturellement
7. **🎮 Gamification Ready** : Tier system avec progression

### **🚀 Prochaines Étapes**

1. **Migration DB** : Créer les tables billing core
2. **Services Métier** : Implémenter BillingService step by step
3. **Payment Integration** : Stripe/Mollie pour EU
4. **UI/UX** : Dashboard billing utilisateur
5. **Background Jobs** : Automation renouvellements
6. **Analytics** : Métriques business et revenue tracking

**Cette architecture supporte parfaitement votre modèle économique hybride ! 🎯💰**
