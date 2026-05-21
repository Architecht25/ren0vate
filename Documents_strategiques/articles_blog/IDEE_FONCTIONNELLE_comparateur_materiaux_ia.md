# 💡 Idée fonctionnelle — Comparateur de matériaux & IA économies chantier

*Capturée le 21 mai 2026 — à creuser pour la préparation de chantier*

---

## Contexte déclencheur

Article Trends Tendances (mai 2026) confirme la tendance haussière sur :
- Matériaux de construction (+34% à +62% selon le type)
- Main d'œuvre qualifiée (+18% depuis 2022)
- Produits à base de pétrole (isolants synthétiques, PVC, colles, mousses PU)
- Taux d'intérêt (hausse attendue sur les prochains trimestres)

**Observation** : le propriétaire n'a aujourd'hui aucun outil pour l'aider à identifier des alternatives moins chères à performance équivalente.

---

## Idée : "IA Économies Chantier" dans la section Préparation de projet

### Concept

Dans la section **Préparation de chantier** (existante), ajouter un module IA qui analyse le devis reçu et propose :

1. **Des alternatives matériaux** à performance équivalente ou supérieure, à coût inférieur
   - Ex : *"L'isolant laine de verre proposé coûte 28€/m². De la ouate de cellulose offre R identique à 19€/m² chez des fournisseurs belges. Économie estimée : 840€ sur votre surface."*

2. **Des pistes d'optimisation des lots**
   - Regrouper certains postes pour négocier un forfait global
   - Identifier les travaux qui peuvent être phasés sans impact sur les primes

3. **Des alertes sur les postes à risque de hausse**
   - *"Le cuivre est sous tension — ce lot plomberie est sensible à une révision de prix dans 3 mois. Suggéré : clause de révision de prix dans le contrat."*

4. **Un score d'optimisation** du devis (0-100)
   - Calcul : qualité/prix des matériaux proposés + cohérence des quantités + risques de dérive

---

## Bénéfice utilisateur

- Propriétaire : économiser 5% à 15% sur le coût matériaux sans sacrifier la qualité
- Architecte : avoir un outil pour conseiller son client sur les alternatives
- Entrepreneur : pouvoir proposer des variantes avec l'appui de données

---

## Stack technique envisagée

- Prompt Claude Anthropic avec contexte du devis (OCR déjà en place)
- Base de données de matériaux belges (à construire ou via API fournisseurs)
- Intégration dans `PreparationChantierController` ou section devis existante
- Pas de comparateur temps réel obligatoire pour la V1 — des fourchettes de prix par catégorie suffisent

---

## Positionnement article

Cette fonctionnalité alimenterait naturellement **l'article #3** (coût rénovation + ROI) comme proof point concret :
> *"Ren0vate propose même des pistes pour réduire le coût des matériaux via son module IA Économies — une fonctionnalité en cours de développement."*

---

## Priorité suggérée

**Phase 2** (septembre–décembre 2026) — après la stabilisation du lancement organique.
Valeur commerciale forte : différenciant clair vs tous les outils concurrents.
