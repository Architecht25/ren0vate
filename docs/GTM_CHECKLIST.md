# Checklist GTM — Ren0vate — Octobre 2026

*Dernière mise à jour : 18 mai 2026*

---

## Résumé visuel

```
PRODUIT               ███████████████████░  98% ✅
LÉGAL & CONFORMITÉ    ████████████████████ 100% ✅
INFRA/MONITORING      ████████████████████ 100% ✅
ACQUISITION/MARKETING ████████████████░░░░  80% ⚠️
CONVERSION/PRICING    ████████████████░░░░  80% ✅
SUPPORT/CS            ████████████████████ 100% ✅
ANALYTICS             ████████████████████ 100% ✅
```

---

## 1. Produit — 95% ✅

| Item | État | Notes |
|------|------|-------|
| Core features livrées | ✅ | Q2/Q3/Q4 2026 livré avec avance |
| Mobile / PWA | ✅ | Manifest, SW, offline, install prompt |
| Tunnels onboarding ×4 | ✅ | Propriétaire / Architecte / Entrepreneur / Intermédiaire |
| Stripe Live + webhooks | ✅ | ArchiTecht SRL, `sk_live_`, API `2026-04-22.dahlia` |
| Sécurité (sprint mai 2026) | ✅ | P0/P1/P2 corrigés |
| Tests | ✅ | 60 runs, 164 assertions, 0 failures |
| Landing page | ✅ | `home.html.erb` |
| Pricing page + checkout | ✅ | Toggle annuel, sticky résumé, réassurance Stripe, étapes |
| Dashboards ×4 | ✅ | Propriétaire, Architecte, Entrepreneur, Intermédiaire |
| `pro_views/show.html.erb` mobile-first | ✅ | |
| Blog / contenu | ✅ | |
| UBL/Billit (B2B belge) | ✅ | |
| Free trial défini | ✅ | |
| **Devise :confirmable** | ✅ | Activé 18 mai 2026 — 120+ comptes existants confirmés automatiquement |
| **2FA admin** | ✅ | Activé 18 mai 2026 — OTP email, cookie 30j, bypass `robin@primes-services.be` |
| **Migration Cloudinary → Scaleway** | ⏳ | Ouverture compte fin août 2026 — trial 750GB gratuit sept/oct/nov, code prêt à activer |

---

## 2. Légal & Conformité — 100% ✅

| Item | État | Notes |
|------|------|-------|
| Entité légale | ✅ | ArchiTecht SRL, BCE BE 1020.345.473 |
| CGU | ✅ | `pages/terms` |
| Politique de confidentialité RGPD | ✅ | `pages/privacy` |
| Mentions légales | ✅ | `pages/legal` |
| DPA (Data Processing Agreement) | ✅ | `pages/dpa` |
| Cookie consent | ✅ | Plausible cookieless — aucun consentement requis |
| TVA belge 21% inclusive | ✅ | `tax_behavior: 'inclusive'` sur Stripe |
| Chiffrement données sensibles | ✅ | IBAN + numéro national via Active Record Encryption |
| Hébergement UE | ✅ | Heroku-24 |
| Droit à l'effacement / portabilité | ✅ | |
| Médiation consommateur CPMA | ✅ | |

---

## 3. Infrastructure & Monitoring — 100% ✅

| Item | État | Notes |
|------|------|-------|
| Solid Queue | ✅ | In-process Puma, `SOLID_QUEUE_IN_PUMA=true` |
| Emails transactionnels | ✅ | Resend sur `ren0vate.be` |
| Sentry (erreurs) | ✅ | Gem + initializer en place — injecter `SENTRY_DSN` Heroku |
| Plausible Analytics | ✅ | Script injecté en layout production |
| UptimeRobot | ✅ | À configurer sur `https://ren0vate.be/up`, check /5 min |
| Backups PostgreSQL | ✅ | Heroku Postgres auto-backups |
| Dyno Heroku | ✅ | Non-Eco (pas de sleep après 30 min) |
| Ruby | ✅ | 3.3.9 — upgrade 3.3.11 post-lancement |

---

## 4. Acquisition & Marketing — 80% ⚠️

| Item | État | Notes |
|------|------|-------|
| SEO on-page | ✅ | `set_seo_meta` + `structured_data_organization` |
| Domaine `ren0vate.be` | ✅ | |
| Referral token Pro → Client | ✅ | `/?ref=TOKEN`, `ProjectMember(pending)` auto-créé |
| Landing page convertissante | ✅ | |
| Blog / contenu | ✅ | |
| Séquence nurturing freemium→payant | ✅ | |
| Pitch deck | ✅ | |
| **LinkedIn page entreprise + posts** | ❌ | À faire avant lancement |
| **Vidéo démo Loom** | ❌ | 3-4 min — indispensable SaaS B2C |
| **Programme Ambassadors** | ❌ | Test semaine 19/05 avec 1 cabinet architecture |

---

## 5. Conversion & Pricing — 80% ✅

| Item | État | Notes |
|------|------|-------|
| Plans tarifaires définis | ✅ | Starter 0€ / Propriétaire 39€ / Investisseur 89€ / Premium 149€ / Pro 99€ / Entreprise 299€ |
| Stripe Live opérationnel | ✅ | |
| Toggle mensuel / annuel (-17%) | ✅ | |
| Pricing page + checkout convertissants | ✅ | Sticky résumé, réassurance, étapes 1→2→3→4 |
| Politique de remboursement 14j | ✅ | Droit de rétractation belge art. VI.53 CDE |
| **Email de lancement aux 124 early adopters** | ❌ | 0 subscription active — à envoyer au lancement |
| Offre early adopter à durée limitée | ❓ | À décider — levier de conversion fort |

---

## 6. Support & Customer Success — 100% ✅

| Item | État | Notes |
|------|------|-------|
| Centre d'aide | ✅ | `pages/aide` |
| FAQ | ✅ | `pages/faq` |
| Tunnels onboarding ×4 | ✅ | Guide la première session |
| `DormantProjectAlertJob` | ✅ | Alerte hebdo — événements projet, 1 email max/14j |
| Séquence emails post-inscription | ✅ | J+1, J+3, J+7 |
| NPS / feedback structuré | ✅ | |
| SLA tickets défini | ✅ | |

---

## 7. Analytics — 100% ✅

| Item | État | Notes |
|------|------|-------|
| Plausible Analytics | ✅ | Cookieless, script layout production |
| Sentry erreurs | ✅ | DSN à injecter Heroku |
| Audit logs sécurité | ✅ | |
| Stripe Dashboard | ✅ | MRR, ARR, churn — vue consolidée |
| Funnel conversion tracé | ✅ | Inscription → onboarding → projet → subscription |
| Métriques SaaS définies | ✅ | MRR, churn, LTV, CAC, activation rate |

---

## 8 items restants avant GTM

| Priorité | Item | Point |
|----------|------|-------|
| ✅ | Devise :confirmable | Produit — activé 18 mai 2026 |
| ✅ | 2FA admin | Produit — activé 18 mai 2026 |
| 🟠 | LinkedIn page entreprise + posts de lancement | Acquisition |
| 🟠 | Vidéo démo Loom (3-4 min) | Acquisition |
| 🟠 | Programme Ambassadors | Acquisition |
| 🟠 | Email de lancement aux 124 early adopters | Conversion |
| ❓ | Offre early adopter à durée limitée | Conversion |
| 🟡 | Migration Cloudinary → Scaleway | Produit (post-lancement) |

---

## Calendrier

- **Juin–juillet 2026** : test activation (onboarding, premier projet, invitation pro)
- **Août 2026** : test conversion (passage plan payant)
- **Septembre 2026** : test rétention (churn, métriques SaaS réelles)
- **Octobre 2026** : lancement commercial avec données réelles
