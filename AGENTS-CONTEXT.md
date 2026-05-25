# Contexte — Développement des agents IA (session 2026-05-24)

## Décisions stratégiques actées

### Architecture générale
- **Hub unique** : `~/agents-hub/` centralise tous les agents des 3 apps
- **Brief matin à 7h** : agrégateur qui synthétise les rapports de nuit, lu par l'utilisateur
- **Budget estimé** : ~$35-55/mois avec prompt caching activé
- **HQ** : 4ème app (dashboard web) pour visualiser les résultats — arrive après les agents

### Philosophie
Construire la base, l'utiliser au quotidien, puis ajouter des agents complémentaires selon les besoins réels. Pas de sur-planification.

---

## Agents Ren0vate — Ce qui a été décidé

### Deux missions
1. **Acquisition** : traction, contenus marketing, pipeline commercial
2. **Rétention** : agents qui s'occupent des clients existants

### Deux agents experts embarqués dans Ren0vate

**Agent Rénovation**
- Conseille les utilisateurs sur leurs projets de rénovation
- Choix des matériaux, approche des travaux, estimation des coûts
- Recommandation de professionnels
- Nourri par l'expertise terrain de l'utilisateur

**Agent Subsides (lite)**
- Répond aux questions sur les primes belges (tant qu'elles existent)
- Expertise personnelle de l'utilisateur encodée dans le prompt
- Se connecte à l'Agent Rénovation : quand un projet est identifié, vérifie automatiquement les primes éligibles

### Pipeline acquisition (contenu marketing)
```
Veille concurrents → Rédaction → Visuels → Brief matin → Validation utilisateur
```

### Pipeline clients existants
```
Question client → Agent Rénovation (+ Agent Subsides si pertinent) → Réponse → Suivi
```

---

## Prochaine étape : l'interview

Avant tout codage, une session d'interview (~1h) pour extraire l'expertise de l'utilisateur dans deux domaines :
- Rénovation belge (matériaux, approches, coûts, professionnels)
- Subsides belges (primes par région, éligibilité, démarches)

Ce document d'expertise devient le prompt de base des deux agents.

---

## Ce qui est hors scope

- **Primes-Services** : déprioritisé, le marché belge sait que les primes se terminent
- **Borbolla** : outil interne personnel, agents DIY/ROI pour l'utilisateur uniquement
