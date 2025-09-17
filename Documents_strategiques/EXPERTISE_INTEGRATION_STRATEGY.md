# Exemple d'intégration expertise analystes dans Decision Hub IA

## 1. Structure de données enrichies

```ruby
# Dans simulation.parameters (exemple enrichi)
{
  "user_inputs": {
    "isolation_toiture": "250",
    "ventilation_simple": "1"
  },
  "expertise_insights": {
    "analyst_id": 12,
    "confidence_score": 85,
    "recommendations": [
      {
        "type": "timing",
        "rule_id": 156,
        "message": "D'expérience, déposer en septembre pour éviter l'engorgement",
        "impact": "high",
        "success_rate": 0.92
      },
      {
        "type": "optimization",
        "rule_id": 203,
        "message": "Combiner avec audit PAE pour majoration 15%",
        "potential_gain": 800,
        "complexity": "medium"
      }
    ],
    "risk_factors": [
      {
        "type": "administrative",
        "severity": "medium",
        "description": "Délai traitement commune rallongé cette année",
        "mitigation": "Prévoir +6 semaines"
      }
    ]
  },
  "historical_patterns": {
    "similar_cases_count": 47,
    "average_success_rate": 0.89,
    "common_issues": ["missing_factures", "norme_isolation_changed"],
    "best_practices": ["contact_commune_early", "use_certified_contractor"]
  }
}
```

## 2. Service d'expertise intelligent

```ruby
class ExpertiseService
  def self.analyze_simulation(simulation)
    # Analyse contextuelle
    context = {
      region: simulation.region,
      category: simulation.category,
      property_type: simulation.property.property_type,
      project_scope: extract_project_scope(simulation),
      amount_range: categorize_amount(simulation.total_simule)
    }

    # Récupération expertise applicable
    rules = ExpertiseRule.applicable_for(context)

    # Génération insights
    {
      timing_insights: extract_timing_insights(rules, context),
      optimization_opportunities: find_optimizations(rules, simulation),
      risk_assessment: assess_risks(rules, context),
      success_predictors: calculate_success_probability(rules, simulation)
    }
  end
end
```

## 3. Migration progressive

```ruby
# Phase 1: Enrichir simulations existantes
class EnrichExistingSimulationsJob
  def perform
    Simulation.includes(:primes, :property, :project).find_in_batches do |batch|
      batch.each do |simulation|
        expertise = ExpertiseService.analyze_simulation(simulation)

        params = JSON.parse(simulation.parameters || '{}')
        params['expertise_insights'] = expertise

        simulation.update(parameters: params.to_json)
      end
    end
  end
end

# Phase 2: Intégrer dans Decision Hub
class DecisionHub::DataService
  def build_ai_context
    base_context = super

    # Ajouter expertise
    if @simulation.parameters.present?
      parsed_params = JSON.parse(@simulation.parameters)
      expertise = parsed_params['expertise_insights']

      base_context.merge!({
        analyst_recommendations: expertise&.dig('recommendations') || [],
        risk_factors: expertise&.dig('risk_factors') || [],
        success_patterns: expertise&.dig('historical_patterns') || {}
      })
    end

    base_context
  end
end
```

## 4. Interface Decision Hub enrichie

L'IA du Decision Hub peut maintenant répondre avec l'expertise :

**Utilisateur:** "Quand déposer ma demande ?"

**IA avec expertise:** "Selon l'expérience de nos analystes sur 47 cas similaires au vôtre, le timing optimal est septembre.
Voici pourquoi :
- ✅ 92% de succès en septembre vs 76% en décembre
- ⚠️ Cette année, délais commune rallongés (+6 semaines)
- 💡 Astuce experte : Contactez la commune dès maintenant pour préparer le dossier"

## 5. Apprentissage continu

```ruby
class ExpertiseLearningService
  def learn_from_success(simulation, outcome)
    # Analyser ce qui a fonctionné
    success_factors = extract_success_factors(simulation, outcome)

    # Mettre à jour les règles d'expertise
    applicable_rules = find_applicable_rules(simulation)
    applicable_rules.each do |rule|
      rule.update_success_rate(outcome)
      rule.refine_conditions(success_factors)
    end

    # Créer nouvelles règles si pattern émergent
    if novel_pattern_detected?(success_factors)
      ExpertiseRule.create_from_success_case(simulation, outcome)
    end
  end
end
```
