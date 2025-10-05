import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["b2cTiers", "b2bTiers", "hybridTiers", "segmentB2c", "segmentB2b", "segmentHybrid"]
  static values = {
    selectedTier: String,
    userContext: Object
  }

  connect() {
    console.log("💰 Pricing controller connected")
    console.log("🎯 Available targets:", {
      b2cTiers: this.hasB2cTiersTarget,
      b2bTiers: this.hasB2bTiersTarget,
      hybridTiers: this.hasHybridTiersTarget,
      segmentB2c: this.hasSegmentB2cTarget,
      segmentB2b: this.hasSegmentB2bTarget,
      segmentHybrid: this.hasSegmentHybridTarget
    })

    this.setupSegmentToggle()
    this.setupTierRecommendations()
    this.trackAnalytics()
  }

  setupSegmentToggle() {
    // Initialiser l'affichage selon la sélection par défaut
    this.toggleSegment()

    // Ajouter des listeners explicites pour chaque segment
    if (this.hasSegmentB2cTarget) {
      this.segmentB2cTarget.addEventListener('change', () => this.toggleSegment())
    }
    if (this.hasSegmentB2bTarget) {
      this.segmentB2bTarget.addEventListener('change', () => this.toggleSegment())
    }
    if (this.hasSegmentHybridTarget) {
      this.segmentHybridTarget.addEventListener('change', () => this.toggleSegment())
    }
  }

  toggleSegment() {
    const isB2C = this.segmentB2cTarget.checked
    const isB2B = this.segmentB2bTarget.checked
    const isHybrid = this.hasSegmentHybridTarget && this.segmentHybridTarget.checked

    console.log("🔄 Toggle segment - B2C:", isB2C, "B2B:", isB2B, "Hybrid:", isHybrid)

    // Masquer toutes les sections d'abord en retirant la classe active
    this.b2cTiersTarget.classList.remove('active')
    this.b2bTiersTarget.classList.remove('active')

    if (this.hasHybridTiersTarget) {
      this.hybridTiersTarget.classList.remove('active')
    }

    if (isB2C) {
      this.b2cTiersTarget.classList.add('active')
      console.log("📊 Segment B2C activé")
      this.trackSegmentChange('B2C')
    } else if (isB2B) {
      this.b2bTiersTarget.classList.add('active')
      console.log("🏢 Segment B2B activé")
      this.trackSegmentChange('B2B')
    } else if (isHybrid && this.hasHybridTiersTarget) {
      this.hybridTiersTarget.classList.add('active')
      console.log("🔄 Segment Hybride activé")
      this.trackSegmentChange('Hybrid')
    }
  }

  setupTierRecommendations() {
    // Highlight du tier recommandé basé sur le contexte utilisateur
    if (this.hasUserContextValue && this.userContextValue) {
      try {
        const context = this.userContextValue
        console.log("👤 Contexte utilisateur:", context)

        // Logique de recommandation dynamique
        this.highlightRecommendedTier(context)
      } catch (error) {
        console.log("⚠️ Erreur lors du parsing du contexte utilisateur:", error)
        // Continuer sans recommandations
      }
    } else {
      console.log("ℹ️ Pas de contexte utilisateur disponible")
    }
  }

  highlightRecommendedTier(context) {
    const propertiesCount = context.properties_count || 0
    let recommendedTier = 'individual'

    if (propertiesCount === 0) {
      recommendedTier = 'freemium'
    } else if (propertiesCount <= 3) {
      recommendedTier = 'individual'
    } else if (propertiesCount <= 10) {
      recommendedTier = 'portfolio'
    } else {
      recommendedTier = 'professional'
    }

    console.log(`🎯 Tier recommandé: ${recommendedTier} (${propertiesCount} propriétés)`)

    // Ajouter classe CSS pour highlight
    const recommendedCard = document.querySelector(`[data-tier="${recommendedTier}"]`)
    if (recommendedCard) {
      recommendedCard.classList.add('recommended-tier')
    }
  }

  // Actions utilisateur
  selectTier(event) {
    const tier = event.currentTarget.dataset.tier
    const price = event.currentTarget.dataset.price

    console.log(`💳 Tier sélectionné: ${tier} à ${price}€`)

    // Visual feedback
    this.highlightSelectedTier(event.currentTarget)

    // Analytics
    this.trackTierSelection(tier, price)

    // Confirm action
    if (tier !== 'freemium') {
      this.showUpgradeConfirmation(tier, price)
    }
  }

  highlightSelectedTier(selectedCard) {
    // Retirer highlight des autres cards
    document.querySelectorAll('.pricing-card').forEach(card => {
      card.classList.remove('selected-tier')
    })

    // Ajouter highlight à la card sélectionnée
    selectedCard.classList.add('selected-tier')
  }

  showUpgradeConfirmation(tier, price) {
    const confirmation = confirm(
      `Confirmer l'upgrade vers ${tier} à ${price}€/mois ?\n\n` +
      `✅ Activation immédiate\n` +
      `✅ Garantie 30 jours\n` +
      `✅ Changement de formule possible à tout moment`
    )

    if (confirmation) {
      console.log(`✅ Upgrade confirmé vers ${tier}`)
      // Le formulaire sera soumis par Rails
    } else {
      console.log(`❌ Upgrade annulé`)
    }
  }

  // Analytics tracking
  trackAnalytics() {
    // Track page view
    this.trackEvent('pricing_page_viewed', {
      user_signed_in: document.body.dataset.userSignedIn === 'true',
      timestamp: new Date().toISOString()
    })
  }

  trackSegmentChange(segment) {
    this.trackEvent('pricing_segment_changed', {
      segment: segment,
      timestamp: new Date().toISOString()
    })
  }

  trackTierSelection(tier, price) {
    this.trackEvent('pricing_tier_selected', {
      tier: tier,
      price: price,
      user_context: this.userContextValue,
      timestamp: new Date().toISOString()
    })
  }

  trackEvent(eventName, data) {
    // Placeholder pour analytics (Google Analytics, Mixpanel, etc.)
    console.log(`📊 Analytics: ${eventName}`, data)

    // À implémenter avec votre solution d'analytics
    // gtag('event', eventName, data)
    // mixpanel.track(eventName, data)
  }

  // Helper methods
  calculateROI(tier, userContext) {
    // Calcul ROI dynamique basé sur le contexte utilisateur
    const savings = {
      individual: 1500, // Économies estimées par an
      portfolio: 5000,
      professional: 15000,
      enterprise: 50000
    }

    const costs = {
      individual: 468, // Coût annuel
      portfolio: 1068,
      professional: 1788,
      enterprise: 3588
    }

    const saving = savings[tier] || 0
    const cost = costs[tier] || 1

    return Math.round((saving / cost) * 100)
  }

  // Méthodes pour les animations et UX
  animateCardHover(event) {
    const card = event.currentTarget
    card.style.transform = 'translateY(-8px)'
    card.style.boxShadow = '0 12px 30px rgba(0,0,0,0.2)'
  }

  animateCardLeave(event) {
    const card = event.currentTarget
    card.style.transform = 'translateY(0)'
    card.style.boxShadow = '0 4px 15px rgba(0,0,0,0.1)'
  }

  // Méthode pour smooth scroll vers les tiers
  scrollToTiers() {
    const tiersSection = document.querySelector('.pricing-tiers')
    if (tiersSection) {
      tiersSection.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }
  }
}
