class SaasMetricsService
  # Calcule toutes les métriques SaaS clés en un appel
  def self.call
    new.call
  end

  def call
    active_subs = Subscription.active
    active_count = active_subs.count

    mrr = active_subs.sum { |s| s.monthly_price }
    arr = mrr * 12

    # Nouvelles subscriptions ce mois-ci
    new_this_month = Subscription.where(
      "created_at >= ?", Time.current.beginning_of_month
    ).count

    # Annulations ce mois-ci (status = canceled, updated this month)
    canceled_this_month = Subscription.where(status: "canceled")
                                      .where("updated_at >= ?", Time.current.beginning_of_month)
                                      .count

    # Churn mensuel = annulations / (actifs + annulations ce mois)
    base = active_count + canceled_this_month
    churn_rate = base > 0 ? (canceled_this_month.to_f / base * 100).round(1) : 0.0

    # ARPU = MRR / actifs
    arpu = active_count > 0 ? (mrr.to_f / active_count).round(2) : 0.0

    # LTV = ARPU / churn_rate (en mois). Churn 0 → LTV indéfini, on cap à 999
    ltv = if churn_rate > 0
      (arpu / (churn_rate / 100.0)).round(0).to_i
    else
      active_count > 0 ? 999 : 0
    end

    # Nouveaux utilisateurs ce mois (proxy CAC)
    new_users_this_month = User.where("created_at >= ?", Time.current.beginning_of_month).count

    # Taux de conversion inscription → abonnement (30 derniers jours)
    users_last_30 = User.where("created_at >= ?", 30.days.ago).count
    subs_last_30  = Subscription.where("created_at >= ?", 30.days.ago).count
    conversion_rate = users_last_30 > 0 ? (subs_last_30.to_f / users_last_30 * 100).round(1) : 0.0

    # Croissance MRR vs mois précédent
    prev_month_start = 1.month.ago.beginning_of_month
    prev_month_end   = 1.month.ago.end_of_month
    prev_active = Subscription.where(status: "active")
                               .where("created_at <= ?", prev_month_end)
                               .where("updated_at <= ? OR status = 'active'", prev_month_end)
    prev_mrr = prev_active.sum { |s| s.monthly_price }
    mrr_growth = prev_mrr > 0 ? (((mrr - prev_mrr).to_f / prev_mrr) * 100).round(1) : nil

    {
      mrr:                  mrr,
      arr:                  arr,
      active_subscriptions: active_count,
      churn_rate:           churn_rate,
      arpu:                 arpu,
      ltv:                  ltv,
      new_this_month:       new_this_month,
      canceled_this_month:  canceled_this_month,
      new_users_this_month: new_users_this_month,
      conversion_rate:      conversion_rate,
      mrr_growth:           mrr_growth,
    }
  end
end
