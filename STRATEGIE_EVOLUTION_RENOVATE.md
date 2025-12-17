# 🚀 STRATÉGIE D'ÉVOLUTION REN0VATE - ÉCOSYSTÈME COMPLET DE LA RÉNOVATION

*Date de création : 12 décembre 2025*

## 📋 **CONTEXTE STRATÉGIQUE**

Avec l'arrêt programmé du système de primes en Wallonie et à Bruxelles (particuliers), remplacé par des prêts comme le Renopack, Ren0vate doit évoluer vers un écosystème complet de services de rénovation pour maintenir sa pertinence commerciale.

**Zones d'impact :**
- ✅ **FLANDRE** : Système de primes maintenu
- ✅ **BRUXELLES Entreprises** : Aides maintenues
- 🔄 **WALLONIE** : Transition vers prêts (Renopack)
- 🔄 **BRUXELLES Particuliers** : Transition vers prêts

**Atouts stratégiques existants :**
- 📊 **Base de 12.000 prospects** qualifiés (15 ans d'activité)
- 🏆 **Monopole de fait** sur le marché belge multi-régional
- 🤖 **Architecture IA** déjà spécifiée (12 opportunités identifiées)
- 💼 **Modèle SaaS** en cours de déploiement
- 🔗 **Intégration BCE officielle** et APIs régionales

---

## 📊 **ANALYSE DU PARCOURS ACTUEL**

### **Parcours existant (8 étapes)**
1. **Profil utilisateur** → Configuration personnelle
2. **Enregistrement biens** → Gestion des propriétés
3. **Création chantiers** → Définition des projets
4. **Simulation primes** → Calculs financiers (*À ADAPTER*)
5. **Espace technique IA** → Conseils et analyses
6. **Gestion documents** → Classement et organisation
7. **Formulaires miroir** → Préparation administrative
8. **Suivi automatique** → Tracking des demandes

### **Forces actuelles**
- Architecture solide avec `simulations_controller.rb` (1352 lignes)
- Gestion documentaire avancée
- IA intégrée (`decision_hub`)
- API robuste pour calculs régionaux
- Interface utilisateur mature

---

## 🔧 **ÉVOLUTION PAR FONCTIONNALITÉ**

### **À CONSERVER (Flandre + Entreprises Bruxelles)**
- ✅ **Étapes 4, 7, 8** : Simulation primes, formulaires, suivi
- ✅ **Routes API** :
  - `/api/flandre/calculate_prime`
  - `/api/entreprises/bruxelles/aides`
- ✅ **Contrôleurs** : `simulations_controller.rb` (logique primes)

### **À TRANSFORMER (Wallonie + Particuliers Bruxelles)**
- 🔄 **Étape 4** : Intégrer simulateur prêts (Renopack + conditions bancaires)
- 🔄 **Étape 7** : Adapter formulaires pour demandes de prêts
- 🔄 **Étape 8** : Suivi prêts au lieu de primes
- 🔄 **API** : Nouveaux endpoints `/api/wallonie/calculate_loans`

### **À DÉVELOPPER (Architecture déjà spécifiée)**

#### **1. 📋 Gestion documentaire et conformité** *(Base existante à enrichir)*
- Centralisation documents administratifs (permis, attestations, factures)
- Traçabilité certifications (isolation, ventilation, étanchéité)
- Génération automatique dossiers de conformité
- Archivage numérique avec horodatage
- **Intégration** : Extension du système documents existant

#### **2. 👷 Collaboration professionnels** *(Architecture complète disponible)*
```ruby
# Modèles déjà spécifiés dans ARCHITECTURE_COLLABORATION_PROFESSIONNELS.md
class ProjectCollaboration < ApplicationRecord
  belongs_to :property
  belongs_to :collaborator, class_name: 'User'
  enum role: { architect: 'architect', contractor: 'contractor', engineer: 'engineer' }
  jsonb :permissions, default: {}
end
```
- Base de données artisans avec `ProfessionalProfile`
- Système invitations et permissions granulaires
- Comparaison automatisée des devis
- Vérification assurances et certifications

#### **3. 💰 Planificateur budgétaire intelligent**
- Simulation coûts temps réel selon travaux sélectionnés
- Alerte dépassements budgétaires
- Intégration conditions prêts (Renopack, etc.)
- Calcul retours sur investissement énergétiques
- **ROI Calculator** déjà intégré dans pricing strategy

#### **4. 🎯 PEB/Audit Roadmap Generator** *(NOUVELLE FONCTIONNALITÉ)*
```ruby
# Architecture pour import et analyse PEB/Audit énergétique
class EnergyPerformanceImporter
  def import_certificate(pdf_or_xml)
    # OCR + parsing certificats PEB (Wallonie/Bruxelles/Flandre)
    # Extraction données clés : label actuel, consommations, recommandations
    # Génération roadmap personnalisée
  end
end
```

**Fonctionnalités clés :**

**A. Import intelligent certificat PEB/Audit**
- Upload PDF certificat PEB ou rapport audit énergétique
- **OCR automatique** extraction données (label, consommation kWh, superficies)
- **Parsing XML** pour certificats PEB officiels (formats régionaux)
- Détection automatique région et type de bien
- Historique évolution labels (si plusieurs certificats dans le temps)

**B. Double direction stratégique**

**Direction 1 : 📊 Suivi évolution réglementaire**
- **Timeline obligations régionales** :
  - Wallonie : interdiction location label F (2028), E (2033)
  - Bruxelles : label C obligatoire (2030), B (2035)
  - Flandre : objectifs PEB évolutifs
- **Alertes deadlines légales** selon label actuel
- **Calcul impact valeur immobilière** (dépréciation label F/E vs appreciation B/A)
- **Scénarios comparatifs** : coût travaux vs amendes/impossibilité louer
- **Dashboard conformité** : vert si conforme, orange si attention, rouge si urgence

**Direction 2 : 🚀 Planificateur évolution label (F → B)**
- **Roadmap personnalisée par phases** :
  ```
  Exemple F → E → D → C → B
  Phase 1 (F→E) : Isolation toiture + châssis (€15K, gain 80 kWh/m²)
  Phase 2 (E→D) : Isolation murs + ventilation D (€25K, gain 60 kWh/m²)
  Phase 3 (D→C) : Pompe à chaleur + solaire (€35K, gain 45 kWh/m²)
  Phase 4 (C→B) : Optimisation complète (€10K, gain 20 kWh/m²)
  ```
- **Priorisation travaux par impact/coût** (quick wins vs investissements lourds)
- **Simulation économies énergétiques cumulées** (€/an par phase)
- **Calcul ROI global** : coût total vs économies + valorisation bien
- **Intégration recommandations audit** (si disponibles)
- **Adaptation selon budget utilisateur** (étalement sur 2-5-10 ans)

**C. Visualisations interactives**
- **Graphique évolution label** avant/après travaux
- **Courbe consommation énergétique** (kWh/m²/an)
- **Timeline réglementaire superposée** sur planning travaux
- **Comparateur scenarios** : ne rien faire vs roadmap optimale
- **Mapping thermique** (si photos infrarouge disponibles)

**D. Intégration écosystème Ren0vate**
- **Auto-population simulations primes/prêts** selon travaux roadmap
- **Suggestion automatique entrepreneurs** qualifiés par type travaux
- **Génération devis estimatifs** via base de données coûts
- **Checklist documents conformité** par phase
- **Suivi progression réel** vs planning théorique

**Avantages concurrentiels :**
- **Premier outil belge** intégrant réglementation + planning stratégique
- **Approche holistique** : technique + financier + légal
- **Adaptation régionale** automatique (3 systèmes PEB différents)
- **Motivation utilisateur** via visualisation gains concrets
- **Argument commercial fort** : anticiper obligations vs subir

**Technologies requises :**
- OCR : Tesseract ou Google Vision API
- Parsing XML : Nokogiri (certificats PEB officiels)
- ML : Prédiction consommations selon travaux (modèle entraîné)
- Visualisation : Chart.js ou D3.js pour graphiques interactifs
- Calculs énergétiques : Algorithmes PEB officiels (formules régionales)

**💡 Stratégie d'implémentation basée sur l'existant :**

Ren0vate dispose déjà d'une **infrastructure OCR complète** via `EmailDocumentExtractionService` :
- ✅ Tesseract OCR installé (gem `rtesseract`)
- ✅ PDF-reader pour extraction texte PDF natif
- ✅ Système patterns regex pour parsing intelligent
- ✅ Téléchargement et traitement fichiers temporaires

**Approche technique progressive :**

**Niveau 1 : Certificats PEB (2-5 pages)**
```ruby
# app/services/peb_certificate_extraction_service.rb
class PebCertificateExtractionService < EmailDocumentExtractionService

  def extract_peb_data
    temp_file = download_temp_file

    # Extraction texte (PDF natif prioritaire, OCR si scanné)
    extracted_text = extract_text_from_pdf(temp_file.path)
    extracted_text = extract_text_from_image_pages(temp_file.path) if extracted_text.length < 200

    # Parsing données structurées
    {
      label_actuel: extract_label(text),           # "Label: D" → 'D'
      consommation_kwh: extract_consumption(text), # "250 kWh/m²" → 250
      region: detect_region(text),                 # Flandre/Wallonie/Bruxelles
      date_certificat: extract_certificate_date(text),
      surface_habitable: extract_surface(text),
      emissions_co2: extract_emissions(text)
    }
  end

  private

  def extract_label(text)
    # Patterns multi-régionaux
    patterns = [
      /label[:\s]*(A\+\+|A\+|A|B|C|D|E|F|G)/i,      # Wallonie/Bruxelles
      /energielabel[:\s]*(A\+\+|A\+|A|B|C|D|E|F|G)/i # Flandre
    ]
    patterns.each { |p| return text.match(p).captures.first.upcase if text.match(p) }
    nil
  end

  def detect_region(text)
    return 'flandre' if text.match?(/vlaams|energielabel|EPB/i)
    return 'wallonie' if text.match?(/wallon|énergie-wallonie/i)
    return 'bruxelles' if text.match?(/bruxelles|peb-certificaat/i)
    nil
  end
end
```

**Niveau 2 : Audits énergétiques (40 pages) - Traitement par sections**
```ruby
# app/services/energy_audit_extraction_service.rb
class EnergyAuditExtractionService < PebCertificateExtractionService

  def extract_audit_data
    temp_file = download_temp_file

    # Extraction complète (30-60s pour 40 pages)
    full_text = extract_full_audit_text(temp_file.path)

    # Découpage en sections logiques
    sections = split_into_sections(full_text)

    # Parsing structuré
    {
      synthese: extract_synthese(sections[:synthese]),
      recommandations: extract_recommendations(sections[:recommandations]),
      couts_estimes: extract_estimated_costs(sections[:couts]),
      economies_prevues: extract_savings(sections[:economies])
    }
  end

  private

  def extract_recommendations(text)
    recommandations = []

    # Pattern: "1. Isolation toiture - Coût: 15000€ - Économie: 800€/an"
    text.scan(/\d+\.\s*(.+?)(?=\d+\.|$)/m).each do |match|
      reco_text = match.first

      recommandations << {
        travaux: extract_work_type(reco_text),      # 'isolation_toiture'
        cout_estime: extract_cost(reco_text),       # 15000
        economie_annuelle: extract_saving(reco_text), # 800
        impact_label: estimate_label_impact(reco_text) # +2 labels
      }
    end

    recommandations
  end

  def estimate_label_impact(work_description)
    # Estimation impact sur label
    return 2 if work_description.match?(/isolation|pompe.*chaleur/i) # F→D
    return 1 if work_description.match?(/châssis|ventilation/i)      # F→E
    0
  end
end
```

**Niveau 3 : Traitement asynchrone gros fichiers**
```ruby
# app/jobs/process_energy_audit_job.rb
class ProcessEnergyAuditJob < ApplicationJob
  queue_as :documents

  def perform(document_id)
    document = Document.find(document_id)
    service = EnergyAuditExtractionService.new(document.file)

    # Mise à jour progressive du statut
    document.update(processing_status: 'extraction_en_cours')

    data = service.extract_audit_data
    document.update(processing_status: 'termine', extracted_data: data)

    # Génération automatique roadmap
    RoadmapGeneratorService.new(document.property, data).generate
  end
end
```

**Niveau 4 : Fallback IA pour cas complexes**
```ruby
# Si extraction < 60% confiance, utiliser GPT-4 Vision
def extract_with_ai_fallback(file_path)
  images = convert_pdf_to_images(file_path)

  prompt = <<~PROMPT
    Analyse ce certificat PEB belge et extrais au format JSON:
    {
      "label": "A++ à G",
      "consommation_kwh": nombre,
      "region": "Flandre/Wallonie/Bruxelles",
      "surface": nombre,
      "recommandations": ["travaux 1", "travaux 2"]
    }
  PROMPT

  OpenAI::Client.new.chat(
    model: "gpt-4-vision-preview",
    messages: [
      { role: "user", content: [
        { type: "text", text: prompt },
        { type: "image_url", image_url: { url: images.first }}
      ]}
    ]
  )
end
```

**Validation et scoring de confiance**
```ruby
def calculate_confidence_score(extracted_data)
  score = 100
  score -= 20 unless extracted_data[:label_actuel].present?
  score -= 15 unless extracted_data[:consommation_kwh].present?
  score -= 10 unless extracted_data[:region].present?
  score += 10 if label_matches_consumption?(extracted_data)
  score.clamp(0, 100)
end
```

**Avantage : Réutilisation maximale de l'existant** - Pas de nouvelle dépendance, extension naturelle du système de documents actuel.

#### **5. 🤖 IA Smart Property Analyzer** *(12 opportunités IA identifiées)*
```ruby
# Architecture définie dans IA_EXTENSIONS_MULTI_FONCTIONNELLES.md
class AI::PropertyAnalyzerService
  def analyze_property(photos, address, basic_info)
    # GPT-4 Vision pour analyse structure
    # Estimation performance énergétique
    # Calcul potentiel rénovation
end
```
- Guide interactif normes PEB/EPB
- Analyse photos avec Computer Vision
- **Future Energy Score** prédictif
- Interface bases données officielles

---

## 🏗️ **NOUVEAU PARCOURS INTÉGRÉ (12 ÉTAPES)**

### **Phase 1 : Configuration** *(Existant - À maintenir)*
1. **Profil utilisateur**
2. **Enregistrement biens**
3. **Création chantiers**

### **Phase 2 : Simulation énergétique et financement** *(Évolution majeure)*

**4a. 📋 Import & Analyse PEB/Audit** *(NOUVEAU)*
   - **Upload certificat PEB** (2-5 pages) ou **audit énergétique** (40 pages)
   - **Extraction automatique** données clés via OCR :
     - Label actuel (A++ à G)
     - Consommation énergétique (kWh/m²/an)
     - Surface habitable, émissions CO2
     - Recommandations travaux (si audit)
   - **Détection région automatique** (Flandre/Wallonie/Bruxelles)
   - **Génération roadmap évolution label** (ex: F → E → D → C → B)
   - **Priorisation travaux** par impact énergétique et coût
   - **Timeline conformité réglementaire** selon obligations régionales
   - *Base de simulation pour étape suivante*

**4b. 💰 Simulation financière adaptée** *(Enrichi)*
   - **Flandre/Entreprises Brux** → Primes (existant)
   - **Wallonie/Particuliers Brux** → **NOUVEAU** : Prêts + conditions bancaires
   - **Intégration recommandations PEB/Audit** → Calcul automatique aides disponibles
   - **ROI Calculator avancé** : Analyse financière complète (détails ci-dessous)
   - **Comparaison scénarios** : Ne rien faire vs roadmap optimale

**📊 ROI Calculator - Formulation complète**

```ruby
# app/services/roi_calculator_service.rb
class RoiCalculatorService
  def initialize(project, property, renovation_works)
    @project = project
    @property = property
    @works = renovation_works
    @region = property.region
    @current_label = property.current_energy_label
    @target_label = project.target_energy_label
  end

  def calculate_complete_roi
    {
      investment: calculate_total_investment,
      annual_savings: calculate_annual_energy_savings,
      property_value_increase: calculate_property_valorization,
      net_investment: calculate_net_investment,
      simple_payback_period: calculate_payback_period,
      roi_percentage: calculate_roi_percentage,
      cumulative_savings_10y: calculate_cumulative_savings(10),
      cumulative_savings_20y: calculate_cumulative_savings(20),
      break_even_year: find_break_even_point,
      comparison_scenarios: compare_scenarios
    }
  end

  private

  # 1. Investissement total brut
  def calculate_total_investment
    works_cost = @works.sum(&:estimated_cost)
    architect_fees = works_cost * 0.08 if @project.requires_architect?
    permit_fees = calculate_permit_fees

    works_cost + (architect_fees || 0) + permit_fees
  end

  # 2. Économies énergétiques annuelles
  def calculate_annual_energy_savings
    # Consommation actuelle vs future (kWh/m²/an)
    current_consumption = ENERGY_CONSUMPTION_BY_LABEL[@current_label]
    target_consumption = ENERGY_CONSUMPTION_BY_LABEL[@target_label]

    consumption_reduction = current_consumption - target_consumption # kWh/m²/an
    surface = @property.living_area # m²

    # Coûts énergétiques (€/kWh selon source)
    energy_mix = {
      electricity: { share: 0.30, price: 0.35 }, # €/kWh
      gas: { share: 0.50, price: 0.10 },
      fuel: { share: 0.20, price: 0.12 }
    }

    weighted_energy_price = energy_mix.sum { |k, v| v[:share] * v[:price] }

    annual_savings = consumption_reduction * surface * weighted_energy_price

    # Inflation énergétique projetée (+4% par an historique)
    {
      year_1: annual_savings,
      year_5: annual_savings * (1.04 ** 5),
      year_10: annual_savings * (1.04 ** 10),
      year_20: annual_savings * (1.04 ** 20)
    }
  end

  # Référentiel consommation par label (kWh/m²/an)
  ENERGY_CONSUMPTION_BY_LABEL = {
    'A++' => 0,
    'A+' => 45,
    'A' => 85,
    'B' => 150,
    'C' => 230,
    'D' => 310,
    'E' => 390,
    'F' => 470,
    'G' => 550
  }

  # 3. Valorisation immobilière
  def calculate_property_valorization
    # Études de marché : impact label sur prix m²
    # Source : Statbel, notaires.be, études universitaires

    VALORIZATION_BY_LABEL_JUMP = {
      'G->F' => 0.02,   # +2% valeur
      'F->E' => 0.03,   # +3%
      'E->D' => 0.05,   # +5%
      'D->C' => 0.07,   # +7%
      'C->B' => 0.10,   # +10%
      'B->A' => 0.12,   # +12%
      'A->A+' => 0.08   # +8%
    }

    current_value = @property.estimated_market_value
    label_jumps = count_label_jumps(@current_label, @target_label)

    total_valorization_rate = label_jumps.sum do |jump|
      VALORIZATION_BY_LABEL_JUMP[jump] || 0
    end

    valorization = current_value * total_valorization_rate

    {
      absolute: valorization,
      percentage: (total_valorization_rate * 100).round(1),
      new_estimated_value: current_value + valorization
    }
  end

  # 4. Investissement net (après aides)
  def calculate_net_investment
    gross_investment = calculate_total_investment

    # Aides financières
    grants = calculate_grants_by_region # Primes selon région
    loans = calculate_loan_conditions # Prêts à taux réduit (Renopack, etc.)
    tax_deductions = calculate_tax_benefits # Réductions d'impôts

    net_investment = gross_investment - grants[:total_amount]

    # Si prêt : calculer coût réel avec intérêts
    if loans[:activated]
      loan_cost = calculate_loan_real_cost(loans)
      net_investment += loan_cost[:total_interest]
    end

    {
      gross: gross_investment,
      grants: grants[:total_amount],
      tax_deductions: tax_deductions,
      net_cash: net_investment,
      financing: loans
    }
  end

  # 5. Période de retour simple
  def calculate_payback_period
    net_investment = calculate_net_investment[:net_cash]
    annual_savings_y1 = calculate_annual_energy_savings[:year_1]

    # Sans valorisation immobilière (approche conservatrice)
    simple_payback = net_investment / annual_savings_y1

    # Avec valorisation (récupérée à la revente)
    valorization = calculate_property_valorization[:absolute]
    payback_with_valorization = (net_investment - valorization) / annual_savings_y1

    {
      simple: simple_payback.round(1),
      with_valorization: [payback_with_valorization.round(1), 0].max,
      interpretation: interpret_payback(simple_payback)
    }
  end

  def interpret_payback(years)
    case years
    when 0..5 then "🟢 Excellent : retour très rapide"
    when 5..10 then "🟢 Bon : retour sur investissement intéressant"
    when 10..15 then "🟡 Moyen : à considérer selon autres bénéfices"
    when 15..25 then "🟠 Long : valorisation immobilière importante"
    else "🔴 Très long : priorité conformité réglementaire"
    end
  end

  # 6. ROI en pourcentage
  def calculate_roi_percentage
    net_investment = calculate_net_investment[:net_cash]
    annual_savings = calculate_annual_energy_savings[:year_1]
    valorization = calculate_property_valorization[:absolute]

    # ROI annuel moyen sur 10 ans
    total_benefits_10y = (annual_savings * 10 * 1.02) + valorization # +2%/an inflation
    roi_10y = ((total_benefits_10y - net_investment) / net_investment) * 100

    # ROI annualisé
    annual_roi = roi_10y / 10

    {
      annual: annual_roi.round(2),
      ten_year: roi_10y.round(2),
      interpretation: interpret_roi(annual_roi)
    }
  end

  def interpret_roi(annual_roi)
    case annual_roi
    when 10..Float::INFINITY then "🟢 Excellent investissement (>10%/an)"
    when 5..10 then "🟢 Bon investissement (5-10%/an)"
    when 2..5 then "🟡 Investissement correct (2-5%/an)"
    when 0..2 then "🟠 Faible rentabilité (<2%/an)"
    else "🔴 Perte financière nette"
    end
  end

  # 7. Économies cumulées sur N années
  def calculate_cumulative_savings(years)
    annual_savings_y1 = calculate_annual_energy_savings[:year_1]
    valorization = calculate_property_valorization[:absolute]
    net_investment = calculate_net_investment[:net_cash]

    cumulative = []
    total_saved = -net_investment # Investissement initial négatif

    (1..years).each do |year|
      # Inflation énergétique +4%/an
      savings_this_year = annual_savings_y1 * (1.04 ** year)
      total_saved += savings_this_year

      # Valorisation comptée à la revente (année N)
      total_saved += valorization if year == years

      cumulative << {
        year: year,
        annual_savings: savings_this_year.round(0),
        cumulative_savings: total_saved.round(0),
        break_even: total_saved >= 0
      }
    end

    cumulative
  end

  # 8. Année du break-even
  def find_break_even_point
    cumulative_30y = calculate_cumulative_savings(30)
    break_even_data = cumulative_30y.find { |y| y[:break_even] }

    if break_even_data
      break_even_data[:year]
    else
      nil # Jamais rentable sur 30 ans
    end
  end

  # 9. Comparaison scénarios
  def compare_scenarios
    # Scénario A : Ne rien faire
    scenario_nothing = {
      name: "Ne rien faire",
      investment: 0,
      energy_cost_10y: calculate_energy_cost_without_renovation(10),
      energy_cost_20y: calculate_energy_cost_without_renovation(20),
      property_value_evolution: calculate_property_depreciation, # Dépréciation label F/G
      regulatory_risk: assess_regulatory_risk, # Amendes, interdiction location
      total_cost_20y: nil # Calculé ci-dessous
    }

    # Scénario B : Rénovation optimale
    scenario_renovation = {
      name: "Rénovation vers #{@target_label}",
      investment: calculate_net_investment[:net_cash],
      energy_cost_10y: calculate_energy_cost_with_renovation(10),
      energy_cost_20y: calculate_energy_cost_with_renovation(20),
      property_value_evolution: calculate_property_valorization[:absolute],
      regulatory_risk: 0, # Conformité assurée
      total_cost_20y: nil
    }

    # Coûts totaux 20 ans
    scenario_nothing[:total_cost_20y] =
      scenario_nothing[:energy_cost_20y] +
      scenario_nothing[:regulatory_risk] -
      scenario_nothing[:property_value_evolution]

    scenario_renovation[:total_cost_20y] =
      scenario_renovation[:investment] +
      scenario_renovation[:energy_cost_20y] -
      scenario_renovation[:property_value_evolution]

    # Différence nette
    net_benefit = scenario_nothing[:total_cost_20y] - scenario_renovation[:total_cost_20y]

    {
      do_nothing: scenario_nothing,
      renovate: scenario_renovation,
      net_benefit_20y: net_benefit.round(0),
      recommendation: net_benefit > 0 ? "🟢 Rénover est rentable" : "🔴 Coût net supérieur"
    }
  end

  def calculate_energy_cost_without_renovation(years)
    current_consumption = ENERGY_CONSUMPTION_BY_LABEL[@current_label]
    surface = @property.living_area
    energy_price = 0.15 # €/kWh moyen

    (1..years).sum do |year|
      (current_consumption * surface * energy_price) * (1.04 ** year)
    end
  end

  def calculate_property_depreciation
    # Label F/G : dépréciation estimée -15% sur 10 ans (interdiction location)
    return -(@property.estimated_market_value * 0.15) if ['F', 'G'].include?(@current_label)
    -(@property.estimated_market_value * 0.05) # -5% label E
  end

  def assess_regulatory_risk
    # Wallonie : interdiction location label F (2028), E (2033)
    return 50000 if @current_label == 'F' && @region == 'wallonie' # Perte revenus locatifs
    return 30000 if @current_label == 'E' && @region == 'wallonie'
    0
  end
end
```

**Visualisations interactives :**

1. **Graphique courbe économies cumulées** (Chart.js)
   - Axe X : Années (0-30)
   - Axe Y : Économies cumulées (€)
   - Point break-even marqué en vert
   - Zone profitable colorée

2. **Camembert répartition investissement**
   - Travaux (%)
   - Primes/aides (%)
   - Coût net (%)

3. **Barres comparaison scénarios** (20 ans)
   - Scénario A : Ne rien faire (rouge)
   - Scénario B : Rénover (vert)
   - Différence nette affichée

4. **Timeline valorisation immobilière**
   - Valeur actuelle
   - Valeur projetée après travaux
   - Impact label par étape

**Flux utilisateur Phase 2 :**
```
1. Upload PEB/Audit (optionnel mais recommandé)
   ↓
2. Extraction automatique + Roadmap générée
   ↓
3. Sélection travaux souhaités (ou création manuelle si pas de PEB)
   ↓
4. Simulation primes/prêts selon région + ROI global
   ↓
5. Export rapport complet (technique + financier)
```

### **Phase 3 : Préparation chantier** *(NOUVEAU)*

**5. 📋 Gestion documentaire et conformité**
- Centralisation documents administratifs (permis, attestations, factures)
- Traçabilité certifications (isolation, ventilation, étanchéité)
- Génération automatique dossiers de conformité
- Archivage numérique avec horodatage

**6. 🏛️ Permis d'urbanisme - Préparation, Soumission & Obtention** *(NOUVEAU)*

```ruby
# app/models/building_permit.rb
class BuildingPermit < ApplicationRecord
  belongs_to :property
  belongs_to :project

  enum permit_type: {
    not_required: 'not_required',           # Travaux exemptés
    declaration_prealable: 'declaration',   # Déclaration préalable (petits travaux)
    permis_urbanisme: 'permis_urbanisme',   # Permis urbanisme complet
    permis_unique: 'permis_unique'          # Permis unique (+ environnement)
  }

  enum status: {
    assessment: 'assessment',               # Évaluation nécessité
    preparation: 'preparation',             # Préparation dossier
    ready_to_submit: 'ready_to_submit',    # Prêt à soumettre
    submitted: 'submitted',                 # Déposé
    under_review: 'under_review',          # En instruction
    additional_info: 'additional_info',    # Infos complémentaires demandées
    approved: 'approved',                   # Accordé
    refused: 'refused',                     # Refusé
    appeal: 'appeal'                        # Recours en cours
  }

  # Données du permis
  string :reference_number
  string :commune
  datetime :submission_date
  datetime :decision_date
  datetime :permit_expiry_date              # Validité 2-3 ans selon région

  # Documents requis (checklist dynamique)
  jsonb :required_documents, default: {
    plans_architecte: { status: 'missing', document_id: nil },
    photos_existant: { status: 'missing', document_id: nil },
    formulaire_demande: { status: 'missing', document_id: nil },
    note_explicative: { status: 'missing', document_id: nil },
    extrait_cadastral: { status: 'missing', document_id: nil },
    accord_mitoyens: { status: 'missing', document_id: nil }
  }

  # Délais et timeline
  jsonb :timeline, default: {}
  text :notes
  text :conditions_particulieres
end
```

**A. Évaluation nécessité permis (Assistant intelligent)**

**Détection automatique selon travaux :**
- **✅ Permis NON requis** (travaux exemptés selon CoBAT/CoDT/Code flamand) :
  - Isolation intérieure sans modification structure
  - Remplacement châssis (mêmes dimensions et aspect)
  - Installation panneaux solaires (conditions : toiture, non classé)
  - Remplacement chaudière
  - Travaux intérieurs mineurs

- **⚠️ Déclaration préalable** (procédure simplifiée) :
  - Modifications façade limitées
  - Extension < seuil régional
  - Abri jardin < 40m²
  - Délai : 30 jours ouvrables

- **🏛️ Permis d'urbanisme complet** :
  - Extension habitation
  - Modification volume (toiture, véranda)
  - Changement affectation
  - Démolition-reconstruction
  - Zone protégée ou classée
  - Délai : 75-115 jours selon région

- **🏭 Permis unique** (urbanisme + environnement) :
  - Projets avec impact environnemental
  - Installations classées
  - Délai : 90-150 jours

**Quiz intelligent de qualification :**
```
Questions adaptatives selon travaux sélectionnés :
→ "Extension de plus de 15m² ?" → Oui → Permis requis
→ "Bien classé ou en zone protégée ?" → Oui → Procédure renforcée
→ "Modification façade visible rue ?" → Oui → Vérifier règlement communal
```

**B. Préparation du dossier**

**1. Checklist documents par commune**
```ruby
def generate_document_checklist(commune, permit_type)
  # Base commune toutes régions
  base_docs = [
    'Formulaire demande (4 exemplaires)',
    'Plans situation (échelle 1/500)',
    'Plans existant et projeté (échelle 1/50 ou 1/100)',
    'Élévations et coupes',
    'Photos existantes (4 vues minimum)',
    'Note explicative travaux'
  ]

  # Documents spécifiques selon commune
  commune_specific = CommuneRegulation.find_by(commune: commune).additional_requirements

  # Si mitoyens
  if property.has_neighbors?
    base_docs << 'Accord mitoyens (ou preuve notification)'
  end

  # Si zone spéciale
  if property.in_protected_zone?
    base_docs << 'Étude impact patrimonial'
    base_docs << 'Photos contexte urbain élargi'
  end

  base_docs + commune_specific
end
```

**2. Générateur automatique formulaires**
- **Pré-remplissage** avec données property et project
- **Adaptation formulaires** par région :
  - Bruxelles : Formulaire CoBAT
  - Wallonie : Formulaire CoDT
  - Flandre : Omgevingsvergunning
- **Export PDF prêt à imprimer** (4 exemplaires + version numérique)

**3. Assistant plans et documents**
- **Templates notes explicatives** : Modèles pré-rédigés adaptables
- **Checklist photos obligatoires** :
  - Vue ensemble depuis rue
  - Détails façades
  - Mitoyenneté
  - Contexte urbain
- **Upload plans architecte** avec vérification conformité (échelles, cotations)
- **Validation complétude** : Score % documents fournis

**C. Soumission du dossier**

**1. Vérification pré-dépôt**
```ruby
def pre_submission_check
  checks = {
    documents_complete: all_documents_present?,
    forms_filled: formulaire_complete?,
    photos_sufficient: photos.count >= 4,
    plans_valid: plans_at_correct_scale?,
    fees_calculated: calculate_fees > 0
  }

  if checks.values.all?
    status = 'ready_to_submit'
    generate_submission_package # ZIP complet
  else
    missing_items = checks.select { |k, v| !v }.keys
    errors.add(:base, "Documents manquants: #{missing_items.join(', ')}")
  end
end
```

**2. Calcul taxes et redevances**
- **Automatique par commune** : Tarifs variables (100€ - 500€ selon travaux)
- **Alertes montant** : "Taxe urbanisme estimée : 250€"
- **Modes paiement** : Coordonnées bancaires administration

**3. Modes de dépôt**
- **📧 Dépôt électronique** (si commune équipée) :
  - Upload direct plateforme communale
  - Accusé réception automatique
  - Tracking numéro dossier

- **📮 Dépôt physique** :
  - Génération ZIP documents à graver
  - Check-list papier pour dépôt
  - Modèle lettre accompagnement

**D. Suivi instruction**

**1. Timeline automatique**
```ruby
def calculate_instruction_timeline(submission_date, permit_type, commune)
  delays = {
    'declaration' => 30.days,
    'permis_urbanisme' => permit_type_delay(commune), # 75-115j
    'permis_unique' => 120.days
  }

  milestones = {
    completeness_check: submission_date + 15.days,
    public_inquiry_start: submission_date + 20.days,  # Si requis
    public_inquiry_end: submission_date + 50.days,
    decision_expected: submission_date + delays[permit_type],
    implicit_approval: submission_date + delays[permit_type] + 1.day # Silence = accord
  }

  milestones
end
```

**2. Notifications et alertes**
- **J+15** : "Vérification complétude dossier"
- **J+20** : "Début enquête publique potentielle"
- **J+45** : "Mi-parcours instruction"
- **J+75** : "Décision attendue dans 2 semaines"
- **J+116** : "🎉 Permis accordé par défaut (silence administratif)"

**3. Gestion demandes complémentaires**
- Notification si administration demande infos
- Upload documents complémentaires
- Tracking suspension délais

**E. Obtention et exploitation**

**1. Réception décision**
- Upload décision officielle (arrêté collège)
- Extraction automatique :
  - ✅ Accordé / ❌ Refusé / ⚠️ Accordé avec conditions
  - Date validité (2-3 ans)
  - Conditions particulières

**2. Exploitation du permis**
- **Affichage chantier obligatoire** : Génération panneau réglementaire (PDF A3)
- **Notification début travaux** : Formulaire pré-rempli commune (8 jours avant)
- **Rappels validité** :
  - "Permis expire dans 6 mois, démarrer travaux"
  - "Possibilité prolongation 1 an (demande avant expiration)"

**3. Gestion recours tiers**
- Période 20 jours post-décision : Possibilité recours voisins
- Suivi procédure recours si contestation
- Assistance juridique (partenariats avocats)

**F. Archive et historique**

- **Conservation dossier complet** : Documents + échanges administration
- **Export notaire** : En cas de vente (permis valorise bien)
- **Historique modifications** : Si avenants ou modifications ultérieures

**Interface utilisateur :**

**Dashboard permis urbanisme :**
- **Widget évaluation** : "Vos travaux nécessitent : 🏛️ Permis d'urbanisme complet"
- **Timeline visuelle** : Étapes préparation → soumission → instruction → obtention
- **Indicateur avancement** : 🔴 Documents manquants (3/8) | 🟡 En préparation | 🟢 Prêt à soumettre
- **Countdown décision** : "Décision attendue dans 42 jours" avec barre progression
- **Notifications temps réel** : Changements statut, demandes administration

**Valeur ajoutée :**
- **Simplicité** : Démarche administrative guidée pas à pas
- **Conformité** : Assurance documents complets selon commune
- **Gain temps** : Pré-remplissage et génération automatique
- **Transparence** : Visibilité totale sur avancement
- **Sérénité** : Rappels et alertes pour ne rien oublier

**7. 🏗️ Comparateur produits et matériaux énergétiques** *(NOUVEAU)*

```ruby
# app/models/energy_product.rb
class EnergyProduct < ApplicationRecord
  enum category: {
    insulation: 'insulation',           # Isolants
    windows: 'windows',                 # Châssis et vitrages
    heating: 'heating',                 # Chaudières et PAC
    ventilation: 'ventilation',         # Systèmes VMC/VMI
    thermal_regulation: 'thermal_regulation'  # Thermostats et régulation
  }

  enum insulation_type: {
    mineral_wool: 'mineral_wool',       # Laine de roche/verre
    eps: 'eps',                         # Polystyrène expansé
    pur_pir: 'pur_pir',                # Polyuréthane/Polyisocyanurate
    wood_fiber: 'wood_fiber',          # Fibre de bois
    cellulose: 'cellulose',            # Ouate de cellulose
    hemp: 'hemp',                       # Chanvre
    cork: 'cork'                        # Liège
  }

  # Caractéristiques techniques
  string :brand                         # Marque
  string :model                         # Modèle/référence
  decimal :lambda_value                 # λ (W/m·K) pour isolants
  decimal :r_value                      # Résistance thermique
  decimal :u_value                      # Coefficient U pour châssis
  string :fire_rating                   # Classement feu (A1, B, C...)
  boolean :vapor_barrier                # Pare-vapeur intégré
  string :certifications                # EPD, PEFC, natureplus, etc.

  # Performance énergétique
  decimal :efficiency_rating            # COP pour PAC, rendement chaudière
  string :energy_label                  # Label énergétique A+++, A++, etc.
  integer :lifespan_years               # Durée de vie estimée
  boolean :renewable_energy             # Source renouvelable

  # Données commerciales
  decimal :price_per_unit               # Prix/m² ou prix unitaire
  string :unit                          # m², pièce, installation
  text :suppliers                       # Liste fournisseurs/magasins
  text :installation_difficulty         # Facile/Moyen/Expert
  boolean :professional_required        # Installation pro obligatoire

  # Caractéristiques environnementales
  decimal :embodied_carbon              # kg CO2/unité (ACV)
  boolean :recyclable
  boolean :local_production             # Production belge/européenne
  integer :environmental_score          # Score écologique /100

  # Normes et conformité
  jsonb :certifications_details, default: {}
  text :technical_specs
  text :maintenance_requirements
end
```

**Interface comparateur par catégorie :**

**A. ISOLATIONS - Comparateur multicritères**

**Filtres intelligents :**
- **Application** : Toiture, murs, sol, combles
- **Épaisseur souhaitée** : 100mm, 120mm, 140mm, 160mm, 200mm
- **Budget** : €/m²
- **Priorités** : Performance thermique, écologique, économique, phonique
- **Contraintes** : Espace limité, humidité, feu

**Tableau comparatif :**
```
┌────────────────┬──────────┬─────────┬──────────┬────────────┬───────────┐
│ Isolant        │ λ (W/m·K)│ R (20cm)│ Prix/m²  │ Écologique │ Feu       │
├────────────────┼──────────┼─────────┼──────────┼────────────┼───────────┤
│ PUR/PIR        │ 0.022    │ 9.09    │ 45€      │ ⭐⭐       │ B/C       │
│ Laine de roche │ 0.035    │ 5.71    │ 28€      │ ⭐⭐⭐⭐    │ A1        │
│ Fibre de bois  │ 0.038    │ 5.26    │ 52€      │ ⭐⭐⭐⭐⭐  │ E         │
│ EPS Graphite   │ 0.031    │ 6.45    │ 35€      │ ⭐⭐       │ E         │
│ Cellulose      │ 0.038    │ 5.26    │ 22€      │ ⭐⭐⭐⭐⭐  │ B         │
└────────────────┴──────────┴─────────┴──────────┴────────────┴───────────┘
```

**Recommandations contextuelles :**
- "Pour toiture plate : PUR/PIR recommandé (meilleur R en faible épaisseur)"
- "Pour murs avec risque humidité : Laine de roche hydrophobe"
- "Meilleur rapport qualité/prix écologique : Cellulose"

**B. CHÂSSIS - Comparateur profils et vitrages**

**Critères de comparaison :**

**Profils :**
- **Matériaux** : PVC, Aluminium, Bois, Bois-alu, Composite
- **U châssis** : 0.8 - 1.4 W/m²K
- **Durabilité** : 30-50 ans
- **Entretien** : Faible/Moyen/Élevé
- **Esthétique** : Finitions, couleurs RAL
- **Prix indicatif** : €€/m²

**Vitrages :**
- **Types** : Double (4-16-4), Triple (4-12-4-12-4), HR++, HR+++
- **U vitrage** : 0.5 - 1.1 W/m²K
- **Factor solaire g** : 0.50 - 0.70 (gains chaleur)
- **Isolation acoustique** : 28-45 dB
- **Options** : Argon/Krypton, Low-E, verre trempé

**Tableau combinaisons :**
```
Profil PVC + Triple HR+++ (Uw 0.8) : 850€/m² | Primes Flandre : -20%
Profil Alu isolé + Triple (Uw 1.0) : 920€/m² | Excellente durabilité
Profil Bois + Double HR++ (Uw 1.2) : 780€/m² | Écologique mais entretien
```

**Assistant de choix :**
```
Questions :
→ Orientation fenêtres ? (Sud = privilégier g élevé pour gains gratuits)
→ Bruit extérieur ? (Route = recommander 40+ dB)
→ Budget ? (Excellent = Triple, Bon = Double HR++)
→ Style maison ? (Moderne = Alu, Classique = Bois)

Résultat : "Recommandé : PVC blanc + Triple HR+++ (Ug 0.5, Uw 0.8)"
```

**C. CHAUDIÈRES ET POMPES À CHALEUR**

**Filtres :**
- **Type** : Gaz condensation, Mazout condensation, PAC air-eau, PAC air-air, PAC géothermique, Pellets
- **Puissance** : 10-35 kW (calcul auto selon surface + isolation)
- **COP/SCOP** : 3.5 - 5.5
- **Basse température** : Compatible planchers chauffants
- **Connectivité** : Wi-Fi, modulation, smart grid

**Comparatif détaillé :**
```
┌─────────────────┬──────┬──────┬─────────┬──────────┬────────────────┐
│ Système         │ COP  │ Conso│ €/an *  │ CO2/an   │ Investissement │
├─────────────────┼──────┼──────┼─────────┼──────────┼────────────────┤
│ PAC air-eau     │ 4.2  │ 4200│ 1260€   │ 0.8t     │ 12.000€        │
│ Gaz condensation│ 0.98 │15000│ 1800€   │ 3.0t     │ 4.500€         │
│ PAC géothermie  │ 5.0  │ 3500│ 1050€   │ 0.7t     │ 22.000€        │
│ Chaudière pellets│1.05 │ 3.5t │ 1400€   │ 0.2t CO2 │ 15.000€        │
└─────────────────┴──────┴─────────┴──────────┴────────────────┘
* Chauffage + ECS pour 150m² PEB D
```

**ROI intégré :**
- Calcul retour sur investissement vs référence (gaz)
- Intégration primes régionales
- Projection 15 ans avec évolution prix énergie
- "PAC air-eau : Rentabilisée en 7 ans (avec primes)"

**D. VENTILATION - VMC Simple/Double flux**

**Comparatif systèmes :**

**VMC Simple flux hygro :**
- Prix : 1.500 - 3.000€
- Consommation : 50 W
- Installation : Facile (pas de gaines d'insufflation)
- Perte chaleur : Oui (air neuf non réchauffé)
- **Idéal pour** : Rénovation, budget limité

**VMC Double flux avec échangeur :**
- Prix : 4.000 - 8.000€
- Rendement : 85-95% récupération chaleur
- Consommation : 80 W
- Filtres : F7/G4 (allergies)
- Installation : Complexe (gaines aller-retour)
- **Idéal pour** : Maison passive, neuf, confort maximal

**VMI (Ventilation Mécanique par Insufflation) :**
- Prix : 2.000 - 4.000€
- Principe : Surpression (1 seul point d'insufflation)
- Préchauffage air : Option résistance
- **Idéal pour** : Lutte humidité, rénovation simple

**Critères de choix :**
```ruby
def recommend_ventilation_system(property, insulation_level, budget)
  if insulation_level >= 'PEB_B' && budget >= 5000
    'VMC Double flux : Récupération 90%, économies 400€/an'
  elsif property.humidity_issues?
    'VMI : Solution anti-humidité, installation simple'
  else
    'VMC Simple flux hygro : Bon compromis performance/prix'
  end
end
```

**E. RÉGULATION THERMIQUE - Thermostats intelligents**

**Comparatif fonctionnalités :**

**Thermostat classique :**
- Prix : 50-150€
- Programmation : Horaire fixe
- Zones : 1 seule

**Thermostat connecté (Nest, Netatmo, Tado) :**
- Prix : 200-350€
- Fonctions :
  - Auto-apprentissage habitudes
  - Contrôle smartphone (distance)
  - Météo intégrée (anticipation)
  - Zones multiples (vannes thermostatiques)
  - Détection présence
  - Statistiques consommation
- Économies : 15-25% facture chauffage
- ROI : 2-3 ans

**Régulation pièce par pièce :**
- Têtes thermostatiques intelligentes : 50€/pièce
- Configuration idéale : 19°C séjour, 17°C chambres, 22°C SDB
- "Économie estimée : 320€/an pour maison 150m²"

**Fonctionnalités avancées pour entreprises :**
- **Building Management System (BMS)** : Régulation centralisée bâtiments tertiaires
- **Smart Grid** : Pilotage PAC selon prix électricité temps réel
- **Monitoring** : Alertes surconsommation, maintenance prédictive

---

**Valeur ajoutée du comparateur :**

✅ **Éducation client** : Néophytes comprennent différences techniques
✅ **Choix éclairé** : Comparaison objective multicritères
✅ **Optimisation budget** : Rapport performance/prix transparent
✅ **Écologie** : Indicateurs environnementaux (ACV, recyclabilité)
✅ **Conformité** : Produits certifiés normes belges/européennes
✅ **ROI intégré** : Retour investissement selon projet spécifique
✅ **Mise à jour** : Base données actualise (nouveaux produits, prix)

**Monétisation :**
- **Référencement fournisseurs** : Partenariats magasins/négoces (commission)
- **Leads qualifiés** : Transmission coordonnées utilisateurs intéressés
- **Publicité ciblée** : Marques premium visibilité renforcée

**8. 👷 Comparateur entrepreneurs**

**9. 💰 Planificateur budgétaire**

### **Phase 4 : Espace technique** *(Existant - À enrichir)*
9. **🤖 Assistant IA enrichi** *(existant `decision_hub`)*
10. **📁 Documents par phases** *(existant)*

### **Phase 5 : Suivi chantier** *(NOUVEAU)*

**11. 🔧 Assistant technique conformité**
- **Checklist dynamique par type travaux** : Normes obligatoires selon région (PEB, ventilation, électricité)
- **Validation par photos** : Upload photos chantier → IA détecte problèmes potentiels (ponts thermiques, défauts étanchéité)
- **Alertes réglementaires contextuelles** : "Test d'étanchéité obligatoire avant fermeture des murs"
- **Documentation conformité automatique** : Génération PV de réception, checklist validation artisan
- **Support technique IA** : Questions/réponses selon phase travaux en cours

**12. 📊 État d'avancement chantier**

**Version simplifiée (sans architecte) :**
```ruby
# app/models/project_progress.rb
class ProjectProgress < ApplicationRecord
  belongs_to :property
  belongs_to :project

  enum status: {
    not_started: 'not_started',
    in_progress: 'in_progress',
    completed: 'completed',
    blocked: 'blocked'
  }

  # Phases standards par type de travaux
  jsonb :phases, default: [
    { name: 'Préparation chantier', status: 'not_started', progress: 0 },
    { name: 'Démolition/Dépose', status: 'not_started', progress: 0 },
    { name: 'Gros œuvre', status: 'not_started', progress: 0 },
    { name: 'Finitions', status: 'not_started', progress: 0 },
    { name: 'Réception', status: 'not_started', progress: 0 }
  ]
end
```

**Fonctionnalités :**
- **Timeline visuelle** : Dates prévues vs dates réalisées (style Gantt simplifié)
- **% Avancement global** : Calculé automatiquement selon phases complétées
- **Statuts visuels** : 🔴 Pas démarré | 🟡 En cours (avec %) | 🟢 Terminé | ⚠️ Bloqué
- **Validation jalons** : Photos obligatoires + signature numérique entrepreneur pour passer à phase suivante
- **Budget temps réel** : Suivi dépenses vs budget initial par phase
- **Historique modifications** : Qui a changé quoi et quand

**Version avancée (avec architecte/coordinateur) :**
```ruby
class ConstructionPhase < ApplicationRecord
  belongs_to :project_progress
  belongs_to :responsible_user, class_name: 'User' # Architecte, entrepreneur, etc.

  enum phase_type: {
    preliminary: 'preliminary',      # 0% - Préparation
    foundation: 'foundation',         # 10% - Fondations
    structure: 'structure',           # 40% - Gros œuvre fermé
    technical: 'technical',           # 60% - Techniques spéciales
    finishing: 'finishing',           # 80% - Finitions
    reception: 'reception'            # 100% - Réception provisoire
  }

  datetime :planned_start
  datetime :planned_end
  datetime :actual_start
  datetime :actual_end

  # PV réunions chantier
  has_many :site_meeting_reports
end
```

**Fonctionnalités avancées :**
- **Collaboration multi-acteurs** : Propriétaire, architecte, entrepreneurs peuvent mettre à jour
- **États d'avancement officiels** : Conformes phases chantier professionnelles (10%, 40%, 60%, 80%, 100%)
- **PV numériques réunions chantier** : Enregistrement décisions, photos, validations
- **Validation architecte requise** : Déblocage paiements selon validation phases par architecte
- **Gestion retards automatique** : Alertes drift planning + impact cascade autres corps métier
- **Chemin critique** : Identification tâches bloquantes pour la suite
- **Exports officiels** : Rapports pour banques, assurances, contrôle urbanisme

**Interface utilisateur :**
- Dashboard avec timeline horizontale interactive
- Cartes par phase avec indicateurs visuels (progression, délais, budget)
- Vue calendrier pour planification
- Notifications push sur mobile pour changements statut
- Export PDF rapport avancement pour banque/assurances

### **Phase 6 : Administration & Clôture** *(Existant - À enrichir)*

**13. 📋 Formulaires/Suivi primes et prêts** *(adapter selon région)*
- Génération formulaires miroir pré-remplis (existant)
- Suivi statut demandes (existant)
- Adaptation prêts Wallonie/Bruxelles particuliers (nouveau)

**14. ✅ Checklist clôture chantier** *(NOUVEAU)*

```ruby
# app/models/project_closure.rb
class ProjectClosure < ApplicationRecord
  belongs_to :project
  belongs_to :property

  enum closure_status: {
    in_progress: 'in_progress',
    documents_incomplete: 'documents_incomplete',
    pending_validation: 'pending_validation',
    closed: 'closed'
  }

  # Checklist documents administratifs
  jsonb :administrative_documents, default: {
    reception_provisoire: { status: 'missing', date: nil, document_id: nil },
    reception_definitive: { status: 'missing', date: nil, document_id: nil },
    attestations_conformite: { status: 'missing', date: nil, document_id: nil },
    factures_soldees: { status: 'missing', date: nil, document_id: nil }
  }

  # Checklist garanties et assurances
  jsonb :warranties_insurance, default: {
    garantie_decennale: { status: 'missing', expiry_date: nil, document_id: nil },
    garantie_biennale: { status: 'missing', expiry_date: nil, document_id: nil },
    assurance_trc: { status: 'missing', expiry_date: nil, document_id: nil },
    polices_assurance: { status: 'missing', expiry_date: nil, document_id: nil }
  }

  # Checklist certifications techniques
  jsonb :technical_certifications, default: {
    certificat_peb: { status: 'missing', label: nil, date: nil, document_id: nil },
    attestation_electricite: { status: 'missing', date: nil, document_id: nil },
    attestation_gaz: { status: 'missing', date: nil, document_id: nil },
    test_etancheite: { status: 'missing', result: nil, document_id: nil },
    certificat_ventilation: { status: 'missing', date: nil, document_id: nil }
  }

  datetime :closure_date
  text :closure_notes
end
```

**Checklist complète de clôture :**

**A. Documents administratifs obligatoires**
- ✅ **Procès-verbal réception provisoire** (PV réception avec réserves éventuelles)
- ✅ **Procès-verbal réception définitive** (après levée réserves, 1 an après provisoire)
- ✅ **Attestations de conformité** (urbanisme si permis, normes techniques)
- ✅ **Factures acquittées** (preuve paiements complets entrepreneurs)
- ✅ **Décompte final travaux** (avec détail modifications vs devis initial)
- ✅ **Attestation fin de chantier** (pour assurances et administration)

**B. Garanties et assurances (conservation 10 ans minimum)**
- ✅ **Garantie décennale** : Responsabilité entrepreneurs pour vices graves (10 ans)
  - Numéros polices assurance
  - Coordonnées assureurs
  - Période de couverture
- ✅ **Garantie biennale** : Petits éléments d'équipement (2 ans)
  - Attestations par corps métier
- ✅ **Assurance TRC** (Tous Risques Chantier) : Conservation documents
- ✅ **Polices d'assurance RC professionnelle** : Copie par entrepreneur
- ✅ **Garanties fabricants** : Matériaux et équipements (chaudière, châssis, etc.)

**C. Certifications techniques obligatoires**
- ✅ **Certificat PEB/EPB** : Obligatoire pour vente/location
  - Label énergétique final
  - Amélioration vs situation initiale
- ✅ **Attestation électricité** : Si modification installation (< 25 ans)
- ✅ **Attestation gaz** : Si modification installation (< 25 ans)
- ✅ **Test d'étanchéité à l'air** : Si exigé par région (isolation importante)
- ✅ **Certificat ventilation** : Conformité système ventilation (D50-001)
- ✅ **Plans as-built** : Plans finaux conformes à l'exécution réelle

**D. Documents financiers**
- ✅ **Tableau récapitulatif coûts finaux** : Ventilation par poste
- ✅ **Preuves paiements primes/prêts** : Si aides obtenues
- ✅ **Attestations fiscales** : Pour déductions d'impôts éventuelles
- ✅ **Bordereaux garantie financière** : Si montants retenus

**E. Informations techniques de maintenance**
- ✅ **Notices techniques équipements** : Chaudière, VMC, panneaux solaires, etc.
- ✅ **Plans de maintenance** : Fréquence entretien par équipement
- ✅ **Coordonnées installateurs** : Pour SAV et entretiens futurs
- ✅ **Garanties matériaux** : Durée et conditions par produit
- ✅ **Photos avant/après** : Documentation état final

**Fonctionnalités automatiques :**

**1. Checklist interactive intelligente**
- **Adaptation automatique** selon type travaux (isolation seule ≠ rénovation complète)
- **Rappels contextuels** : "Attention : certificat PEB obligatoire avant location"
- **Scoring complétude** : % documents obtenus / documents requis
- **Alertes dates** : "Réception définitive à planifier dans 2 mois"

**2. Assistant validation**
```ruby
# Exemple validation automatique
def validate_closure_readiness
  checks = {
    pv_reception: reception_documents_present?,
    warranties: all_warranties_registered?,
    certifications: technical_certs_complete?,
    payments: all_invoices_paid?,
    compliance: regulatory_compliance_ok?
  }

  completion_rate = (checks.values.count(true) / checks.size.to_f) * 100

  if completion_rate >= 95
    'ready_to_close'
  elsif completion_rate >= 70
    'minor_issues'
  else
    'major_issues'
  end
end
```

**3. Génération dossier complet**
- **Export ZIP** : Tous documents en un seul fichier
- **Rapport de clôture PDF** : Synthèse complète avec checklist
- **Timeline projet** : De la simulation initiale à la clôture
- **Bilan énergétique** : Avant/après avec économies réalisées
- **Bilan financier** : Budget prévisionnel vs réalisé

**4. Calendrier post-clôture**
- **Rappels automatiques** :
  - J+11 mois : "Planifier réception définitive"
  - J+23 mois : "Fin garantie biennale, vérifier équipements"
  - J+9 ans : "Fin proche garantie décennale"
- **Suivi entretiens** : Rappels entretien chaudière, VMC, etc.
- **Renouvellements** : Alertes expiration certifications (électricité 25 ans)

**5. Archivage légal sécurisé**
- **Conservation 10 ans minimum** : Conformité obligations légales
- **Horodatage blockchain** : Preuve date archivage
- **Accès sécurisé** : Cryptage documents sensibles
- **Export notaire** : En cas de vente bien immobilier

**Interface utilisateur :**
- Dashboard clôture avec indicateur global (🔴 Incomplet | 🟡 En cours | 🟢 Prêt)
- Vue par catégorie (Admin / Garanties / Certifications / Financier)
- Upload drag & drop avec détection automatique type document
- Timeline post-clôture avec rappels futurs
- Bouton "Générer dossier complet" pour export final

**Valeur ajoutée :**
- **Sécurité juridique** : Tous documents en un seul endroit
- **Tranquillité** : Rappels automatiques pour ne rien oublier
- **Valorisation** : Dossier complet augmente valeur revente
- **Conformité** : Garantie respect obligations légales

---

## 🎯 **PLAN DE DÉVELOPPEMENT TECHNIQUE**

### **Phase 0 : Audit & Nettoyage de la codebase (1-2 semaines)** ⚠️ **PRIORITAIRE**

**Objectif** : Nettoyer le code obsolète avant d'ajouter de nouvelles fonctionnalités pour éviter la dette technique.

#### **0.1 Audit des simulateurs de primes obsolètes**

**À identifier et retirer :**

**A. Contrôleurs à nettoyer/supprimer**
```ruby
# Simulateurs Wallonie/Bruxelles particuliers (devenus obsolètes avec prêts)
# À VÉRIFIER :
- app/controllers/wallonie_simulations_controller.rb # Si existe
- app/controllers/bruxelles_particuliers_controller.rb # Si existe
- Routes obsolètes dans routes.rb (/simulations/wallonie/particuliers)

# Méthode :
# 1. Grep recherche utilisation dans vues
# 2. Vérifier logs production (endpoints jamais appelés)
# 3. Marquer @deprecated avant suppression
# 4. Supprimer après tests passage
```

**B. Modèles et tables DB à auditer**
```bash
# Audit complet base de données
rails db:schema:dump # Analyser schema.rb

# Tables potentiellement obsolètes :
# - old_simulations (si migration faite)
# - legacy_primes_calculators
# - deprecated_user_preferences
# - unused_tracking_tables

# Commandes audit :
# 1. Lister toutes les tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;

# 2. Détecter tables jamais utilisées (pas de records récents)
SELECT tablename, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
WHERE n_tup_ins = 0 AND n_tup_upd = 0;

# 3. Détecter colonnes jamais peuplées
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'votre_table';

# Puis :
SELECT COUNT(*) FROM votre_table WHERE column_name IS NOT NULL;
```

**Checklist tables à vérifier :**
- [ ] `primes` : Garder seulement Flandre + Entreprises Bruxelles
- [ ] `simulations` : Ajouter champ `simulation_type` (prime/prêt)
- [ ] Tables temporaires de tests/dev à supprimer
- [ ] Indexes inutilisés (ralentissent writes)
- [ ] Foreign keys orphelines

#### **0.2 Nettoyage JavaScript & Assets**

**A. Fichiers JS obsolètes**
```bash
# app/javascript/
# À auditer :

# 1. Trouver fichiers JS jamais importés
find app/javascript -name "*.js" | while read file; do
  name=$(basename "$file" .js)
  if ! grep -r "import.*$name" app/javascript; then
    echo "❌ Potentiellement inutilisé : $file"
  fi
done

# 2. Librairies obsolètes dans package.json
npm list --depth=0 # Lister dépendances
npm outdated # Versions obsolètes
npx depcheck # Dépendances non utilisées

# Exemples potentiels à retirer :
- Old calculators JS (wallonie_calculator.js, bruxelles_calculator.js)
- Librairies dupliquées (2 versions jQuery?)
- Polyfills inutiles (si navigateurs modernes uniquement)
```

**B. Stylesheets non utilisées**
```bash
# app/assets/stylesheets/
# À auditer :

# 1. CSS non référencées
grep -r "stylesheet_link_tag" app/views

# 2. Classes CSS jamais utilisées (outil : PurgeCSS)
npx purgecss --css app/assets/stylesheets/**/*.css \
             --content app/views/**/*.erb \
             --output public/purged/

# Nettoyer :
- Anciennes pages marketing (si refonte design)
- Styles primes obsolètes (formulaires Wallonie/Bruxelles particuliers)
- Vendor CSS jamais chargés
```

#### **0.3 Services et Helpers obsolètes**

**A. Services à auditer**
```bash
# app/services/
# Identifier services jamais appelés :

# 1. Grep usage dans app/
for service in app/services/*.rb; do
  class_name=$(grep "class.*Service" "$service" | awk '{print $2}')
  echo "Recherche usage de : $class_name"
  grep -r "$class_name.new\|$class_name.call" app/ --exclude-dir=services
done

# Services potentiellement obsolètes :
- old_prime_calculator_service.rb
- legacy_pdf_generator_service.rb (si nouveau existe)
- unused_email_services.rb
- deprecated_api_clients.rb
```

**B. Helpers redondants**
```bash
# app/helpers/
# Méthodes jamais utilisées dans vues

# Script détection :
for helper in app/helpers/*.rb; do
  grep "def " "$helper" | while read line; do
    method=$(echo "$line" | awk '{print $2}' | cut -d'(' -f1)
    if ! grep -r "$method" app/views/; then
      echo "❌ Helper non utilisé : $method dans $helper"
    fi
  done
done
```

#### **0.4 Tests obsolètes et documentation**

**A. Tests à nettoyer**
```bash
# test/
# Supprimer tests pour code supprimé

# 1. Tests de fonctionnalités obsolètes
rm test/controllers/wallonie_simulations_controller_test.rb
rm test/services/old_calculator_service_test.rb

# 2. Fixtures inutilisées
# Identifier fixtures jamais chargées dans tests
```

**B. Documentation à jour**
```bash
# docs/
# Retirer docs features obsolètes

- docs/old_prime_simulator.md → SUPPRIMER
- docs/wallonie_particuliers_guide.md → ARCHIVER
- README.md → Mettre à jour nouvelles features
```

#### **0.5 Migrations et données orphelines**

**A. Migrations à consolider**
```ruby
# db/migrate/
# Si > 100 migrations, envisager squash

# Script consolidation (production stable uniquement) :
rails db:schema:dump
# Puis créer nouvelle migration from scratch

# Attention : Garder historique Git
```

**B. Données orphelines en DB**
```sql
-- Identifier records sans relations valides

-- Simulations sans propriété
SELECT COUNT(*) FROM simulations
WHERE property_id NOT IN (SELECT id FROM properties);

-- Documents sans attachement
SELECT COUNT(*) FROM documents
WHERE active_storage_blob_id IS NULL;

-- Users inactifs depuis 5 ans (RGPD)
SELECT COUNT(*) FROM users
WHERE last_sign_in_at < NOW() - INTERVAL '5 years';

-- Nettoyage avec prudence (backup avant!)
```

#### **0.6 Outils automatisés**

**A. Linters et analyseurs**
```bash
# Rubocop : Détecter code mort
bundle exec rubocop --only Lint/UselessAssignment

# Reek : Code smells
gem install reek
reek app/

# Rails Best Practices
gem install rails_best_practices
rails_best_practices .

# Brakeman : Sécurité
bundle exec brakeman -q

# Bundle Audit : Vulnérabilités gems
bundle audit
```

**B. Coverage et métriques**
```bash
# SimpleCov : Code coverage
# Identifier code jamais testé = potentiellement inutilisé

# Dans test_helper.rb :
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
end

# Générer rapport :
rails test
open coverage/index.html
```

**C. Analyse performance**
```bash
# Bullet : Requêtes N+1
gem 'bullet', group: :development

# Rack Mini Profiler : Temps chargement
gem 'rack-mini-profiler'

# Identifier pages lentes avec vieux code
```

#### **0.7 Plan d'exécution nettoyage**

**Semaine 1 : Audit et identification**
```
Jour 1-2 :
- Audit complet DB (tables, colonnes, indexes)
- Liste fichiers JS/CSS/Services suspects
- Génération rapports automatiques

Jour 3-4 :
- Validation avec tests (ne rien casser)
- Marquage @deprecated dans code
- Documentation éléments à supprimer

Jour 5 :
- Backup complet DB et code
- Premier pass suppression (safe items)
```

**Semaine 2 : Nettoyage progressif**
```
Jour 1-2 :
- Suppression services obsolètes
- Nettoyage JS/CSS
- Update package.json et Gemfile

Jour 3-4 :
- Migrations DB (colonnes inutilisées)
- Suppression tables obsolètes
- Optimisation indexes

Jour 5 :
- Tests complets (toute la suite)
- Performance benchmarks (avant/après)
- Validation en staging
```

**Métriques succès :**
- ✅ **-30% lignes code** inutiles
- ✅ **-20% taille DB** (tables/colonnes)
- ✅ **-40% assets JS/CSS** non utilisés
- ✅ **+50% couverture tests** (code mort retiré)
- ✅ **+30% vitesse build** (moins de dépendances)

**Risques et mitigation :**
- ⚠️ **Backup complet avant toute suppression**
- ⚠️ **Tests systématiques après chaque modification**
- ⚠️ **Feature flags** pour tester en prod sans déployer
- ⚠️ **Rollback plan** si problème détecté
- ⚠️ **Code review** obligatoire pour suppressions majeures

---

### **Phase 1 : Adaptation immédiate (4-6 semaines)**

#### **1.1 Modification `simulations_controller.rb`**
```ruby
# Ligne ~46 : Ajouter logique conditionnelle
def show
  if @simulation.region&.downcase == 'wallonie' ||
     (@simulation.region&.downcase == 'bruxelles' && @simulation.type_demandeur == 'particulier')
    # Calculateur prêts Renopack
    @loan_calculator = true
    @grant_calculator = false
    @loan_conditions = calculate_loan_conditions(@simulation)
  else
    # Calculateur primes existant
    @grant_calculator = true
    @primes = Prime.where(region: normalized_region).order(:ordre_affichage)
  end
end
```

#### **1.2 Nouvelles routes (routes.rb)**
```ruby
# API Prêts
namespace :api do
  namespace :wallonie do
    post 'calculate_loans', to: 'loan_calculations#calculate'
    get 'loan_conditions', to: 'loan_calculations#conditions'
  end

  namespace :bruxelles do
    post 'calculate_loans_particuliers', to: 'loan_calculations#calculate_brussels'
  end
end

# Nouvelles fonctionnalités
resources :contractors do
  collection do
    get :search
    post :compare_quotes
    get :ratings
  end
end

resources :budget_planners do
  member do
    get :dashboard
    post :calculate_costs
    get :roi_analysis
  end
end
```

### **Phase 2 : Nouveaux contrôleurs (6-8 semaines)**

#### **2.1 Contrôleurs principaux à créer**
- `app/controllers/loan_calculations_controller.rb`
- `app/controllers/contractors_controller.rb`
- `app/controllers/budget_planners_controller.rb`
- `app/controllers/project_progress_controller.rb`
- `app/controllers/technical_compliance_controller.rb`

#### **2.2 Modèles associés**
- `app/models/loan_calculation.rb`
- `app/models/contractor.rb`
- `app/models/contractor_rating.rb`
- `app/models/budget_plan.rb`
- `app/models/project_progress.rb`
- `app/models/construction_phase.rb`

### **Phase 3 : Interface utilisateur (4-6 semaines)**

#### **3.1 Adaptation dashboard (`app/views/dashboard/index.html.erb`)**
- Ajout phases 3 et 5 (préparation + suivi chantier)
- Adaptation phase 2 selon région
- Nouvelles cartes fonctionnalités

#### **3.2 Nouvelles vues**
- `app/views/contractors/` (recherche, comparaison)
- `app/views/budget_planners/` (simulateur, ROI)
- `app/views/project_progress/` (timeline, état avancement)

---

## 💰 **MODÈLE ÉCONOMIQUE CONSOLIDÉ**

### **Pricing Tiers validés** *(Base 12K prospects)*
```
🏠 INDIVIDUAL (39€/mois) : 1-3 propriétés
├── Target : 80% prospects (9.600 users potentiels)
├── Simulations illimitées + exports PDF
└── Support email standard (48h)

🏢 PORTFOLIO (89€/mois) : 4-10 propriétés
├── Target : 15% prospects (1.800 users potentiels)
├── Dashboard avancé + analytics ROI
├── Collaboration professionnels
└── Support prioritaire (24h)

🏛️ ENTERPRISE (299€/mois) : 10+ propriétés
├── Target : 5% prospects (600 users potentiels)
├── API access + white-label
├── Account manager dédié
└── SLA garantie + formations
```

### **Projections revenus conservatrices**
- **🎯 2026** : **1,3M€ ARR** (2.000 users actifs)
- **🚀 2027** : **4,3M€ ARR** (5.000 users + services)
- **💎 2028** : **10M€+ ARR** (expansion internationale)

### **Mix revenue diversifié**
- **85% SaaS récurrent** (abonnements mensuels)
- **15% services premium** (consulting, formations)
- **Expansion revenue** : upsell naturel multi-propriétés

### **Nouvelles sources de revenus**
- 🏗️ **Commissions entrepreneurs** : 3-5% sur projets conclus
- 🤖 **Services IA premium** : Analyse photos, prédictions énergétiques
- 📊 **API Business** : Licence pour syndics, promoteurs
- 📱 **Applications mobiles** : Freemium pour artisans
- 👷 **Forfaits coordination chantier** : Suivi avancement premium

---

## 🎯 **AVANTAGES CONCURRENTIELS**

### **1. Monopole de fait marché belge**
- **Seule plateforme** couvrant les 3 régions (Flandre/Bruxelles/Wallonie)
- **18 mois d'avance** technologique sur concurrence
- **Base réglementaire propriétaire** mise à jour continue
- **Intégration BCE officielle** validée

### **2. Transition douce préservant l'acquis**
- **Flandre/Entreprises** → Continuité service total
- **Wallonie/Particuliers** → Évolution naturelle vers prêts
- **Architecture évolutive** sans rupture utilisateur
- **Migration progressive** par région

### **3. Écosystème technologique mature**
- **Stack technique moderne** : Rails 8, PostgreSQL, Stripe
- **API architecture** prête pour intégrations B2B
- **IA spécialisée** réglementation énergétique
- **PWA ready** pour expérience mobile optimale

### **4. Intelligence artificielle différenciante**
- **12 opportunités IA** déjà architecturées
- **Computer Vision** pour analyse propriétés
- **Prédictions énergétiques** avec Machine Learning
- **Ren0Chat** contextuel 9h-17h

### **5. Réseau professionnel intégré**
- **Architecture collaboration** complètement spécifiée
- **Permissions granulaires** par rôle professionnel
- **Système invitations** sécurisé
- **Validation certifications** automatique

---

## 📅 **PLANNING DE MISE EN ŒUVRE - JANVIER-MARS 2026**

### **🛠️ JANVIER 2026 : Développement Core (4 semaines)**
```
📅 SEMAINE 1-2 : Adaptation simulateur régional
├── [ ] Logique conditionnelle prêts Wallonie/Bruxelles particuliers
├── [ ] Interface dashboard adaptée par région
├── [ ] API loan_calculations_controller.rb
├── [ ] Routes /api/wallonie/calculate_loans
└── [ ] Tests intégration Renopack

📅 SEMAINE 3-4 : Collaboration professionnels
├── [ ] Implémentation ProjectCollaboration & ProfessionalProfile
├── [ ] Interface recherche/invitation entrepreneurs
├── [ ] Système permissions granulaires
├── [ ] contractors_controller.rb + vues
└── [ ] MVP base entrepreneurs (50 profils test)
```

### **🔧 FÉVRIER 2026 : Fonctionnalités Avancées (4 semaines)**
```
📅 SEMAINE 1-2 : IA & Analytics intelligentes
├── [ ] AI Smart Property Analyzer (Computer Vision)
├── [ ] Planificateur budgétaire avec ROI Calculator
├── [ ] Dashboard analytics multi-propriétés
├── [ ] Future Energy Score prédictif
└── [ ] Intégration GPT-4 Vision pour analyse photos

📅 SEMAINE 3-4 : Marketplace & Mobile Excellence
├── [ ] Interface fournisseurs matériaux (materials_marketplace_controller.rb)
├── [ ] Optimisation Progressive Web App (PWA)
├── [ ] Ren0Chat IA contextuel 9h-17h
├── [ ] Mobile responsiveness avancée
└── [ ] API Business pour syndics/promoteurs
```

### **🚀 MARS 2026 : Polish & Launch Commercial (4 semaines)**
```
📅 SEMAINE 1-2 : Tests & Optimisation Performance
├── [ ] Tests A/B avec 100 prospects HOT
├── [ ] Load testing & optimisation base de données
├── [ ] Debugging approfondi & monitoring
├── [ ] Formation équipe support client
└── [ ] Documentation utilisateur complète

📅 SEMAINE 3-4 : Go-to-Market & Lancement
├── [ ] Campagne email marketing 12K prospects (séquencée)
├── [ ] Onboarding automatisé nouveaux utilisateurs
├── [ ] Monitoring métriques temps réel (conversion, churn, LTV)
├── [ ] Support client réactif
└── [ ] 🎯 LANCEMENT OFFICIEL FIN MARS 2026
```

### **📈 OBJECTIFS QUANTIFIÉS LAUNCH**
- **👥 Users actifs** : 500+ (conversion 4% prospects HOT+WARM)
- **💰 ARR initial** : 50K€ (mix pricing tiers)
- **📊 Metrics** : <5% churn, >20% feature adoption
- **🔄 Pipeline** : 1000+ prospects en nurturing actif

---

## 🚨 **RISQUES ET MITIGATION**

### **Risques identifiés**
1. **Complexité technique** → Développement agile par sprints
2. **Résistance utilisateurs** → Formation et support renforcé
3. **Concurrence** → Différenciation par IA et intégration
4. **Réglementation** → Veille juridique continue

### **Mesures de protection**
- **Tests A/B** pour nouvelles fonctionnalités
- **Rollback** possible vers ancien système
- **Formation équipe** sur nouvelles technologies
- **Partenariats stratégiques** avec acteurs établis

---

## 📊 **SEGMENTATION PROSPECTS EXISTANTS (12K Base)**

### **Priorités de conversion**
```
🔥 HOT (500 prospects) : Contactés 6 derniers mois
├── Projets actifs ou récents
├── Engagement récent prouvé
├── Probabilité conversion : 20% (100 users)
└── Priority 1 pour launch

🌡️ WARM (2.000 prospects) : Contactés derniers 18 mois
├── Projets planifiés ou en réflexion
├── Engagement modéré historique
├── Probabilité conversion : 10% (200 users)
└── Priority 2 pour nurturing

❄️ COLD (4.500 prospects) : 18 mois - 5 ans
├── Projets anciens ou dormants
├── Engagement faible historique
├── Probabilité conversion : 3% (135 users)
└── Priority 3 pour re-activation

📧 DORMANT (5.000 prospects) : +5 ans
├── Base historique à réactiver
├── Campagnes spécifiques nécessaires
├── Probabilité conversion : 1% (50 users)
└── Campagne "Renaissance Ren0vate"
```

### **Stratégie email marketing séquencée**
- **Phase 1** (J+0-30) : HOT prospects → Conversion immédiate
- **Phase 2** (J+30-60) : WARM prospects → Nurturing + démonstrations
- **Phase 3** (J+60-120) : COLD prospects → Réactivation progressive
- **Phase 4** (J+120+) : DORMANT → Campagnes spécialisées

---

## 🎯 **CONCLUSION**

Cette évolution transforme Ren0vate d'un **calculateur de primes** en **plateforme complète de la rénovation**, créant un avantage concurrentiel durable dans un marché en mutation.

**L'approche graduelle** préserve l'existant tout en développant de nouveaux marchés, assurant une transition en douceur pour les utilisateurs et une croissance soutenue des revenus.

**Next steps :** Validation technique des APIs prêts et développement du MVP comparateur entrepreneurs.

---

## 📈 **VALORISATION & POTENTIEL DE SORTIE**

### **Positionnement PropTech/GovTech européen**
- **Valorisation cible** : 10-50M€ d'ici 2027
- **Segment** : Intersection PropTech (immobilier) × GovTech (régulations)
- **Comparables** : Plateformes réglementaires spécialisées
- **Différenciation** : Seule solution multi-régionale intégrée

### **Métriques d'attractivité investisseurs**
```
📊 METRIQUES CLES :
├── ARR Growth : 200%+ YoY projeté
├── Churn Rate : <5% (sticky B2B)
├── CAC Payback : <6 mois (base prospects)
├── LTV/CAC : >5x (recurring revenue)
└── Market Size : 3M+ propriétés Belgique
```

### **Stratégies de sortie potentielles**
1. **Acquisition stratégique** : Grands acteurs immobilier/construction
2. **Expansion européenne** : Franchising du modèle
3. **API-first** : Plateforme pour écosystème PropTech
4. **Spin-offs spécialisés** : IA énergie, Collaboration BTP

---

## 🎯 **NEXT STEPS IMMÉDIATS - DÉCEMBRE 2025**

### **🔍 Phase de Validation (Semaines 51-52 2025)**
- [ ] **Architecture Review** : Audit complet collaboration professionnels
- [ ] **Technical Specs** : Estimation effort APIs prêts Wallonie/Bruxelles
- [ ] **AI Integration** : Tests compatibilité extensions IA existantes
- [ ] **Database Design** : Schémas loan_calculations & contractor_profiles
- [ ] **API Planning** : Endpoints prioritaires et authentification

### **🛠️ Préparation Développement (Semaine 1-2 Janvier 2026)**
- [ ] **Environment Setup** : Branches développement + staging
- [ ] **Team Alignment** : Répartition tâches et responsabilités
- [ ] **Tools & Monitoring** : Analytics, error tracking, performance monitoring
- [ ] **Testing Strategy** : Test suite automatisée + manuel QA process
- [ ] **Communication Plan** : Updates réguliers stakeholders

### **📊 Success Metrics à Tracker**
```
🎯 JANVIER (Développement) :
├── Code Coverage : >85%
├── Performance : <2s load time
├── Bug Rate : <10 bugs/semaine
└── Feature Completion : 100% core features

🚀 FÉVRIER (Features Avancées) :
├── User Testing : 20+ beta testers actifs
├── Feature Adoption : >60% nouvelles fonctionnalités
├── Mobile Performance : >95% mobile score
└── AI Response Time : <3s analyses

📈 MARS (Launch) :
├── Conversion Rate : >4% prospects contactés
├── User Onboarding : >80% completion rate
├── Support Tickets : <5% users avec problèmes
└── Revenue Target : 50K€ ARR atteint
```

### **⚠️ Risk Mitigation Strategy**
- **Plan B** : Rollback vers version stable si problèmes majeurs
- **Progressive Rollout** : 10% users → 50% users → 100% users
- **Support Renforcé** : Équipe dédiée pour période launch
- **Performance Monitoring** : Alertes temps réel sur métriques critiques

---

*Document stratégique consolidé - Version 1.2 - Timeline Janvier-Mars 2026 validée*
*Dernière mise à jour : 12 décembre 2025 - Planning exécution immédiate*

---

## 🚀 **ENGAGEMENT MUTUEL - OBJECTIF MARS 2026**

**Vision :** Transformer Ren0vate d'un calculateur de primes en écosystème complet de la rénovation avec lancement commercial fin mars 2026.

**Commitment :**
- 📈 **Développement agile** avec feedback hebdomadaire
- 🔧 **Support technique continu** pour implémentation
- 📊 **Validation marché permanente** avec base 12K prospects
- 🎯 **Focus résultat** : 50K€ ARR + 500 users actifs au launch

**Ready to Code !** 💪
