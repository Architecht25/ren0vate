# Agents IA — Ren0vate
*Mis à jour le 30 mai 2026*

Trois agents IA. Deux types distincts :

- **Agent expert réactif** : répond à la demande avec une expertise encodée (Agent Primes)
- **Agents proactifs** : agissent selon un schedule ou un trigger sans intervention humaine (Agent Veille, Agent Marketing)

> **Note — chatbot Expert IA :** `ContextualBotService` est un assistant contextuel générique — il agrège du contexte utilisateur mais n'a pas d'expertise propre encodée. Ce n'est pas un agent — il n'est pas documenté ici.

---

## Vue d'ensemble

| | Agent Primes | Agent Veille | Agent Marketing |
|---|---|---|---|
| **Service** | `SubsidyBotService` | `IntelligenceReportJob` + `IntelligenceScraperService` + `IntelligenceAnalysisService` | `~/agents-hub/Ren0vate/acquisition/` |
| **Modèle** | Sonnet 4.5 | Sonnet 4.5 | Sonnet 4.5 |
| **Type** | Expert réactif | Proactif | Proactif |
| **Déclenchement** | À la demande (user) | Cron — chaque lundi 7h | Manuel après rapport veille |
| **Statut** | ✅ En fonction | ✅ En fonction (1er rapport 26/05) | ✅ Livré 30/05 |
| **Prompt caching** | ✅ | ✅ | ✅ prévu |

---

## Positionnement

```
app/ (Rails — en prod)
  services/
    subsidy_bot_service.rb           ← Agent Primes
    intelligence_scraper_service.rb  ← Agent Veille (scraping)
    intelligence_analysis_service.rb ← Agent Veille (analyse Claude)
  jobs/
    intelligence_report_job.rb       ← Agent Veille (orchestration, cron lundi 7h)
  models/
    intelligence_report.rb           ← Agent Veille (stockage DB)
  controllers/admin/
    intelligence_reports_controller.rb ← Agent Veille (interface admin)

~/agents-hub/ (à construire)
  Ren0vate/
    acquisition/
      marketing_agent.rb             ← Agent Marketing/Commercialisation
  brief.rb                           ← Agrégateur 7h (toutes apps)
```

---

## Agent Primes — `SubsidyBotService`

### Rôle

Expert subsides disponible pre-login et post-login. Base de connaissances terrain de 15 ans encodée dans le prompt. Répond aux questions sur l'éligibilité, les montants, les délais, les documents requis et les recours pour les 3 régions belges.

### Base de connaissances encodée (`EXPERT_KNOWLEDGE`)

La constante `EXPERT_KNOWLEDGE` (~500 lignes) est mise en cache Anthropic à chaque conversation. Elle contient :

**Philosophie générale**
- Conseil universel : analyse préalable des primes AVANT de lancer les travaux
- 7 erreurs récurrentes à prévenir (audit PAE manquant, codes NACE non vérifiés, facture de solde après dépôt, délais dépassés…)
- Idée reçue à corriger : l'éligibilité n'est pas le résultat, c'est la condition d'entrée

**Statuts juridiques et éligibilité**
- Personnes physiques vs morales par région (SRL exclues Wallonie depuis 01/07/2025, ASBL éligibles Flandre)
- Règle BCE entrepreneur : codes NACE à vérifier AVANT de signer le devis

**Valeurs thermiques de référence** (seuils minimaux pour déclencher les primes)
- Isolation toit : R ≥ 4,5–5 m²K/W
- Murs extérieurs : R ≥ 3,5–4 m²K/W
- Châssis : Ug ≤ 1,0 W/m²K

**Checklists terrain**
- 8 éléments obligatoires sur un devis d'isolation (marque, modèle, type, surface, épaisseur, λ, R, prix)
- 4 éléments souvent manquants sur un bordereau châssis (prix/unité, Ug, Uw, grilles de ventilation)
- Règle photos châssis Flandre : 4 critères cumulatifs (une par fenêtre, intérieur, pièce identifiable, grilles visibles)

**Région Flandre**
- 4 catégories de revenus basées sur l'avertissement-extrait de rôle SPF Finances
- ⚠️ Catégories 1 et 2 : seules PAC et boiler thermodynamique disponibles
- ⚠️ Prime PEB **disparaît le 30/06/2026**
- Portail Mijn Verbouwpremie — irréversible une fois soumis

**Région Wallonie**
- ⚠️ Système de primes **s'arrête le 30/09/2026**
- Audit PAE obligatoire avant les travaux depuis le 01/03/2025
- ~31 catégories de travaux couverts
- Successeur annoncé : prêt à taux 0%

**Région Bruxelles**
- Primes Renolution supprimées
- ✅ Primes Petit Patrimoine : méconnues, jusqu'à 50 000€, process en 2 temps obligatoires
- Orienter vers prêts à taux 0% Bruxelles Environnement

### Alertes régionales automatiques

| Région | Alerte injectée dans le prompt |
|---|---|
| Wallonie | Deadline 30/09/2026 rappelée systématiquement |
| Flandre | Deadline Prime PEB 30/06/2026 si pertinent |
| Bruxelles | Plus de Renolution → Petit Patrimoine mis en avant |
| Non connecté | Mode découverte, invitation à créer un compte |

### Fichier source

[app/services/subsidy_bot_service.rb](../app/services/subsidy_bot_service.rb)

---

## Agent Veille — embarqué dans l'app Rails

### Rôle

Rapport de veille hebdomadaire produit chaque lundi à 7h. Scrape 5 sources belges, analyse avec Claude, stocke en base et envoie par email à l'admin.

### Fichiers source

| Fichier | Rôle |
|---|---|
| [app/services/intelligence_scraper_service.rb](../app/services/intelligence_scraper_service.rb) | Scraping 5 sources (RSS + HTML) |
| [app/services/intelligence_analysis_service.rb](../app/services/intelligence_analysis_service.rb) | Analyse Claude Sonnet 4.5 avec prompt caching |
| [app/jobs/intelligence_report_job.rb](../app/jobs/intelligence_report_job.rb) | Orchestration : scrape → analyse → email admin |
| [app/models/intelligence_report.rb](../app/models/intelligence_report.rb) | Stockage DB (`week_of`, `status`, `raw_content`, `analysis`) |
| [app/controllers/admin/intelligence_reports_controller.rb](../app/controllers/admin/intelligence_reports_controller.rb) | Interface admin — consultation + déclenchement manuel |
| [config/recurring.yml](../config/recurring.yml) | Schedule Solid Queue : `at 7am every monday` |

### Sources surveillées

| Source | Type | Ce qu'on y cherche |
|---|---|---|
| ABEX — Indice de reconstruction | RSS | Évolution des coûts de construction belges |
| Google News — Rénovation & Énergie Belgique | RSS | Actualités secteur, signaux réglementaires |
| Embuild — Construction Belgique | HTML | Annonces fédération, tendances marché |
| Urban.brussels — Permis & Urbanisme | HTML | Nouvelles réglementations permis Bruxelles |
| Bruxelles Environnement — Communiqués | HTML | Prêts taux 0%, Petit Patrimoine, PEB |

### Format du rapport (output Claude)

```
## Résumé exécutif
2-3 phrases sur ce qui s'est passé cette semaine dans le secteur.

## Signaux importants pour Ren0vate
**[PRIORITÉ: HAUTE/MOYENNE/FAIBLE]** — description + impact concret sur la plateforme.

## 3 suggestions d'évolution produit
**Suggestion** — Justification (basée sur telle news) — Effort estimé (S/M/L).

## À surveiller la semaine prochaine
1-2 sujets à garder en radar.
```

### Schedule

`config/recurring.yml` → `at 7am every monday` via Solid Queue (in-process Puma).
Idempotent : si le rapport de la semaine existe déjà en `completed`, le job skip.

**Statut :** ✅ En fonction — premier rapport remis le lundi 26 mai 2026.

---

## Agent Marketing/Commercialisation

### Rôle

Produit du contenu marketing et des supports commerciaux de façon autonome. S'exécute après le rapport de veille du lundi, dépose ses livrables, attend la validation humaine. Zéro publication sans relecture.

### Pipeline

```
Rapport veille (Agent Veille, lundi 7h)
          ↓
Rédaction contenu (blog / LinkedIn / social)
          ↓
Briefs visuels
          ↓
Brief matin agrégateur
          ↓
Validation humaine → publication manuelle
```

### Contenus produits

| Format | Fréquence | Canal |
|--------|-----------|-------|
| Article blog SEO | 2/mois | Blog + LinkedIn |
| Post LinkedIn B2B | 1/semaine | LinkedIn |
| Post Instagram/Facebook B2C | 2/semaine | Social |
| Newsletter | 1/mois | Email |

### 5 piliers éditoriaux

| # | Thème | Canal prioritaire |
|---|-------|------------------|
| 1 | Urgence financière (matériaux +40%, taux) | Blog SEO + LinkedIn |
| 2 | Primes — ne pas laisser expirer ses droits | Blog SEO + social |
| 3 | Automatisation — récupérer 40h par projet | Blog + email |
| 4 | Expert IA contextuel — différence vs ChatGPT | Social + vidéo |
| 5 | B2B pros — clients mieux préparés | LinkedIn |

### Contraintes rédactionnelles (à encoder dans le prompt)

- Ton belge — ni trop formel, ni startup américaine
- Terminologie : "entrepreneur agréé", "avertissement-extrait de rôle", "primes énergétiques"
- Toujours chiffrer : montants de primes, heures récupérées, ROI abonnement
- Urgences : deadline Wallonie 30/09/2026, Prime PEB Flandre 30/06/2026
- Un seul CTA par contenu

### Règle absolue

Le pipeline s'arrête au brief matin. La validation et la publication sont toujours manuelles. L'agent prépare, l'humain décide.

### Fichiers source

| Fichier | Rôle |
|---------|------|
| [~/agents-hub/Ren0vate/acquisition/marketing_agent.rb](~/agents-hub/Ren0vate/acquisition/marketing_agent.rb) | Script principal — 4 appels Claude, prompt caching, écriture drafts |
| [~/agents-hub/Ren0vate/acquisition/prompts/system_marketing.md](~/agents-hub/Ren0vate/acquisition/prompts/system_marketing.md) | `MARKETING_KNOWLEDGE` — messages, piliers, ton, segments, KPIs |
| [app/jobs/intelligence_report_job.rb](../app/jobs/intelligence_report_job.rb) | `export_for_marketing_agent` — écrit le JSON veille après analyse |

### Structure outputs

```
~/agents-hub/Ren0vate/acquisition/
  outputs/
    veille/
      2026-W22.json    ← écrit par IntelligenceReportJob après chaque rapport
    drafts/
      2026-W22/
        BRIEF.md           ← récap actions humaines requises
        article_blog.md
        linkedin_post.md
        instagram_post.md
        facebook_post.md
```

### Utilisation

```bash
cd ~/agents-hub/Ren0vate/acquisition
ANTHROPIC_API_KEY=sk-ant-... ruby marketing_agent.rb
```

Prérequis : un fichier JSON dans `outputs/veille/` (écrit automatiquement par le job Rails le lundi 7h).

### Prochain livrable

`~/agents-hub/brief.rb` — agrégateur matin : lit les BRIEF.md de tous les agents et produit un résumé quotidien.
