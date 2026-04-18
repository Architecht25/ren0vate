# Analyse de cybersécurité Ren0vate
**Date de l'analyse : 18 avril 2026**
**Rédigée par : GitHub Copilot (IA) — à valider par un auditeur sécurité humain**
**Société : ArchiTecht SRL — BCE BE 1020.345.473**
**Outil principal : Brakeman 7.0.2 + revue manuelle OWASP Top 10**

---

## 1. Résumé exécutif

| Indicateur | Résultat |
|---|---|
| **Warnings Brakeman actifs** | ✅ 0 (zéro) |
| **Warnings ignorés** | 6 (tous justifiés — voir §3) |
| **Erreurs de parsing** | ⚠️ 1 fichier template non analysé |
| **Headers de sécurité HTTP** | ✅ Bonne couverture |
| **CSP (Content Security Policy)** | 🟠 Présente mais affaiblie (`unsafe-inline`, `unsafe-eval`) |
| **Authentification** | ✅ Devise + `authenticate_user!` global |
| **CSRF** | ✅ `protect_from_forgery with: :exception` |
| **Dépendances outdated critiques** | 🟠 3 à surveiller (Devise, loofah, Rails) |
| **Pseudonymisation Anthropic** | ✅ Implémentée |

---

## 2. Brakeman — Rapport complet (scan du 18 avril 2026)

**Version Brakeman :** 7.0.2
**Version Rails :** 8.0.2
**Durée du scan :** 8,2 secondes
**Contrôleurs analysés :** 50 | **Modèles :** 38 | **Templates :** 401

### 2.1 Résultat

```
Security Warnings: 0
Ignored Warnings:  6
Errors:            1
```

✅ **Aucun warning de sécurité actif.** Le code ne présente pas de vulnérabilité détectable par analyse statique.

### 2.2 Erreur de parsing — action requise

```
Error: app/views/pv_signatures/show.html.erb:228
Parse error on value "elsif" (kELSIF)
Could not parse app/views/pv_signatures/show.html.erb
```

⚠️ **Ce template n'est PAS analysé par Brakeman.** Une erreur de syntaxe ERB à la ligne 228 empêche l'analyse. Si ce template contient des interpolations de données utilisateur non échappées, elles passeraient inaperçues.

**Action requise :** Corriger la syntaxe ERB dans `app/views/pv_signatures/show.html.erb` ligne 228 pour s'assurer que ce fichier est inclus dans les futurs scans.

---

## 3. Warnings Brakeman ignorés — revue de justification

| # | Type | Fichier | Justification |
|---|---|---|---|
| 1 | XSS | `simulations/show_components/_meta_scripts.html.erb:15` | `wallonie_primes_json(...)` — helper dédié, données admin-only, faux positif confirmé |
| 2 | XSS | `simulations/show_components/_meta_scripts.html.erb:21` | `generate_category_script(...)` — idem, données non utilisateur |
| 3 | XSS | `simulations/show_components/_meta_scripts.html.erb:30` | `generate_saved_inputs_script(...)` — idem |
| 4 | Redirect | `documents_controller.rb:293` | `redirect_to file_url` avec `allow_other_host: true` — admin-only, URL Cloudinary vérifiée par `safe_external_url?` |
| 5 | Redirect | `documents_controller.rb:405` | Idem — action `view` |
| 6 | Mass Assignment | `admin/users_controller.rb:146` | `:role` permis par params — contrôleur admin protégé par `ensure_admin_or_moderator` |

**Statut :** Toutes les justifications sont valides. La présence de `safe_external_url?` dans `ApplicationController` (whitelist Cloudinary) confirme la mitigation des redirects.

> **Rappel annuel :** ces 6 warnings doivent être revus à chaque audit pour s'assurer que les contrôles de runtime restent en place.

---

## 4. OWASP Top 10 (2021) — Checklist

### A01 — Broken Access Control
| Point | Statut | Détail |
|---|---|---|
| Authentification globale | ✅ | `before_action :authenticate_user!` dans `ApplicationController` |
| Vérification admin | ✅ | `ensure_admin_or_moderator` sur les routes admin |
| Autorisation au niveau ressource | ✅ | IDOR corrigés le 18 avril 2026 — `requests#show/edit/update` et `factures#validate_facture` scopés à `current_user` |
| Mass assignment | ✅ | Strong parameters partout, `:role` protégé admin-only |

### A02 — Cryptographic Failures
| Point | Statut | Détail |
|---|---|---|
| HTTPS / HSTS | ✅ | `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` (production) |
| Mots de passe | ✅ | bcrypt 3.1.20 via Devise |
| Credentials Rails | ✅ | `credentials.yml.enc` — clés non exposées en repo |
| Données sensibles en clair en BDD | ✅ | `users.national_number` + `iban` et `rib_donnees.iban` + `nom_titulaire` chiffrés via AR Encryption. Migration appliquée en production le 18 avril 2026. Revenus (`decimal`) et OCR brut : Priorité 3 |
| Données en transit vers Anthropic | ✅ | HTTPS TLS, pseudonymisation activée |

### A03 — Injection
| Point | Statut | Détail |
|---|---|---|
| SQL Injection | ✅ | ActiveRecord ORM — pas de requête SQL brute détectée par Brakeman |
| XSS | ✅ | ERB auto-escape + 3 cas ignorés justifiés |
| Template Injection | ✅ | Aucun warning Brakeman |
| Command Injection | ✅ | Aucun `system()` / `exec()` détecté |

### A04 — Insecure Design
| Point | Statut | Détail |
|---|---|---|
| Pseudonymisation IA | ✅ | Revenus → tranches, IBAN → boolean, adresse → CP + commune |
| Consentement chatbot | ✅ | Checkbox RGPD avant activation, stockage localStorage |
| Séparation des rôles | ✅ | `freemium / owner / investor / expert / platform / admin / moderator` |

### A05 — Security Misconfiguration
| Point | Statut | Détail |
|---|---|---|
| Headers HTTP | ✅ | X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy |
| Erreurs détaillées | ✅ | `config.consider_all_requests_local = false` en production (standard Rails) |
| Cache pages authentifiées | ✅ | `Cache-Control: private, no-store` sur toutes les réponses |
| Turbo/Thruster cache | ✅ | `Turbo-Cache-Control: no-store`, `Vary: Cookie` |
| CSP | 🟠 | Voir §5 |

### A06 — Vulnerable and Outdated Components
| Point | Statut | Détail |
|---|---|---|
| Rails 8.0.2 → 8.1.3 disponible | 🟠 | Mise à jour mineure recommandée (pas de CVE critique connue à ce jour) |
| Devise 4.9.4 → 5.0.3 | 🟠 | Version majeure disponible — lire changelog avant mise à jour |
| loofah 2.24.1 → 2.25.1 | 🟠 | Librairie HTML sanitization — mise à jour conseillée |
| Brakeman 7.0.2 → 8.0.4 | 🟡 | Outil d'audit — mettre à jour pour de meilleures détections |
| nokogiri 1.18.8 → 1.19.2 | 🟡 | XML parsing — surveiller CVEs |
| rubyzip 2.4.1 → 3.2.2 | 🟠 | Version majeure — CVE potentielles sur extraction ZIP |
| stripe gem 15.5.0 → 19.0.0 | 🔴 | 4 versions majeures de retard — API Stripe évolue, risque de dépréciation |

### A07 — Identification and Authentication Failures
| Point | Statut | Détail |
|---|---|---|
| Authentification | ✅ | Devise 4.9.4 — sessions sécurisées |
| CSRF | ✅ | `protect_from_forgery with: :exception` |
| Brute force | 🟠 | Vérifier si `devise-security` ou Lockable est activé |
| 2FA | 🔴 | Non implémentée — recommandée pour les comptes admin et clients payants |

### A08 — Software and Data Integrity Failures
| Point | Statut | Détail |
|---|---|---|
| Webhooks Stripe | ✅ | `Stripe::Webhook.construct_event` + `Stripe::SignatureVerificationError` — implémenté dans `webhooks_controller.rb` |
| Import map | ✅ | `importmap-rails` — pas de bundler npm, surface d'attaque réduite |
| Dépendances signées | ✅ | Bundler avec Gemfile.lock versionné |

### A09 — Security Logging and Monitoring Failures
| Point | Statut | Détail |
|---|---|---|
| Filter parameter logging | ✅ | `filter_parameter_logging.rb` présent |
| Logs applicatifs | 🟠 | Vérifier que les revenus et données AER ne sont pas loggés en clair |
| Monitoring intrusion | 🔴 | Pas de solution SIEM/alerting identifiée (ex. : Logentries, Papertrail, Datadog) |
| Endpoint violation CSP | 🟡 | `/csp-violation-report-endpoint` configuré — vérifier qu'il existe en production |

### A10 — Server-Side Request Forgery (SSRF)
| Point | Statut | Détail |
|---|---|---|
| Requêtes HTTP sortantes | 🟠 | HTTParty et Faraday utilisés — vérifier que les URLs sont validées avant appel |
| Anthropic API | ✅ | URL fixe définie dans le service, pas d'URL utilisateur |
| Mapbox / APIs externes | ✅ | URLs fixes dans le CSP `connect_src` |

---

## 5. Content Security Policy — Analyse détaillée

La CSP est configurée dans `config/initializers/content_security_policy.rb` et appliquée globalement.

### Points forts
- ✅ `object-src: none` — bloque Flash et plugins
- ✅ `base-uri: self` — empêche les attaques de base URI
- ✅ `form-action: self` — restreint les cibles de formulaires
- ✅ `worker-src: self, blob` — pour Mapbox GL JS
- ✅ Rapport de violations via `/csp-violation-report-endpoint`
- ✅ Mode `report-only` en développement, mode strict en production

### Points d'amélioration
| Directive | Problème | Recommandation |
|---|---|---|
| `script-src 'unsafe-inline'` | 🟠 Neutralise la protection XSS de la CSP | Migrer vers des nonces (infrastructure déjà en place avec `content_security_policy_nonce_generator`) |
| `script-src 'unsafe-eval'` | 🟠 Risque d'injection via `eval()` | Nécessaire pour Turbo — surveiller les montées de version (Turbo 2.x supprime ce besoin) |
| `style-src 'unsafe-inline'` | 🟡 Standard pour Bootstrap | Acceptable, bas risque |
| `script-src :https` | 🟠 Trop large — autorise tout script HTTPS | Lister explicitement les CDNs (déjà partiellement fait) et supprimer `:https` générique |

**Priorité :** Implémenter les nonces pour `script-src` est la mesure à plus fort impact. L'infrastructure de nonces est déjà en place côté Rails.

---

## 6. Dépendances — Actions prioritaires

### 🔴 Critique
| Gem | Version actuelle | Version disponible | Action |
|---|---|---|---|
| `stripe` | ~~15.5.0~~ **19.0.0** | 19.0.0 | ✅ Mis à jour le 18 avril 2026 |

### 🟠 Haute priorité
| Gem | Version actuelle | Version disponible | Action |
|---|---|---|---|
| `rubyzip` | 2.4.1 | 3.2.2 | Mettre à jour — CVE potentielles sur extraction d'archives ZIP |
| `devise` | 4.9.4 | 5.0.3 | Planifier migration — lire guide de migration Devise 5 |
| `loofah` | 2.24.1 | 2.25.1 | Mettre à jour dès que possible (sanitization HTML) |
| `rails-html-sanitizer` | 1.6.2 | 1.7.0 | Lié à loofah — mettre à jour ensemble |

### 🟡 Maintenance normale
| Gem | Version actuelle | Version disponible | Action |
|---|---|---|---|
| `rails` | 8.0.2 | 8.1.3 | Mise à jour mineure recommandée dans le prochain cycle |
| `nokogiri` | 1.18.8 | 1.19.2 | Surveiller CVEs — mettre à jour prochainement |
| `brakeman` | 7.0.2 | 8.0.4 | Mettre à jour pour de meilleures détections |

---

## 7. Architecture de sécurité — Synthèse des flux

```
Internet
    │
    ├─ Thruster (proxy HTTP/2) ─────── HSTS + headers sécurité
    │
    ├─ Rails ApplicationController ─── authenticate_user!, CSRF, headers, CSP
    │       │
    │       ├─ Pages publiques ──────── before_action skip explicite requis
    │       │
    │       └─ Pages authentifiées ─── Devise session + cache no-store
    │
    ├─ Anthropic API ────────────────── HTTPS + pseudonymisation ✅
    │   (Claude Haiku / Sonnet)         DPA ArchiTecht SRL requis
    │
    ├─ Stripe API ───────────────────── HTTPS + signature webhook (à vérifier)
    │
    ├─ Cloudinary ───────────────────── URLs whitelistées TRUSTED_REDIRECT_HOSTS
    │
    └─ Mapbox ───────────────────────── API key côté client — à sécuriser via domaine restriction
```

---

## 8. Recommandations priorisées

### Priorité 1 — Avant lancement commercial (bloquant)

- [ ] **Corriger `pv_signatures/show.html.erb:228`** — template non analysé par Brakeman, risque de XSS non détecté
- [x] **`stripe` gem mise à jour 15.5.0 → 19.0.0** ✅ *(fait le 18 avril 2026)*
- [x] **Signature webhook Stripe** ✅ — `Stripe::Webhook.construct_event` + `Stripe::SignatureVerificationError` déjà implémenté dans `webhooks_controller.rb`
- [ ] **Activer Devise Lockable ou rate limiting** — protéger les formulaires d'authentification contre le brute force

### Priorité 2 — Dans le mois suivant le lancement

- [ ] **Mettre à jour `rubyzip` 2.4.1 → 3.2.2** — risque CVE sur extraction ZIP
- [ ] **Mettre à jour `loofah` + `rails-html-sanitizer`** — librairies de sanitization HTML critiques
- [ ] **Migrer `script-src` vers nonces** — infrastructure déjà en place, impact sécurité maximal
- [ ] **Restreindre `script-src :https`** vers une liste explicite de CDNs
- [ ] **Mettre à jour `brakeman` 7.0.2 → 8.0.4** — meilleures détections pour Rails 8.1
- [x] **Corriger les IDOR `find(params[:id])`** ✅ *(fait le 18 avril 2026)* — `requests#show/edit/update` → `current_user.requests.find(params[:id])` ; `factures#validate_facture` → vérification `@facture.project_id == @project.id`

### Priorité 3 — Dans les 3 mois

- [ ] **Chiffrer les revenus et OCR brut** — `aer_donnees.revenu_*` (decimal → string/text + migration données), `aer_donnees.texte_ocr_brut`, `rib_donnees.texte_ocr_brut` — nécessite migration des données existantes
- [ ] **2FA pour les comptes admin et Expert/Platform** — via `devise-two-factor` ou OTP par email
- [ ] **Monitoring des logs** — intégrer Papertrail ou Datadog pour alerting sur erreurs 5xx et patterns suspects
- [ ] **Planifier migration Devise 4 → 5** — lire le guide de migration avant la mise à jour
- [x] **Chiffrement at-rest national_number + IBAN** ✅ *(fait le 18 avril 2026, migration production appliquée)* — AR Encryption sur `users.national_number`, `users.iban`, `rib_donnees.iban`, `rib_donnees.nom_titulaire`. Clés `AR_ENCRYPTION_*` actives sur Heroku
- [ ] **Chiffrement at-rest revenus + OCR brut** — déplacé en Priorité 3 (migration données nécessaire)
- [ ] **Restreindre la clé Mapbox par domaine** — dans la console Mapbox, limiter l'usage aux domaines ren0vate.be
- [ ] **Vérifier la validation des URLs** dans HTTParty/Faraday — prévention SSRF
- [ ] **Audit annuel complet** — Brakeman + revue manuelle OWASP + test de pénétration

---

## 9. Références

- **OWASP Top 10 (2021)** — https://owasp.org/Top10/
- **Brakeman scanner** — https://brakemanscanner.org
- **Rails Security Guide** — https://guides.rubyonrails.org/security.html
- **Devise Security** — https://github.com/devise-security/devise-security
- **CSP avec nonces Rails** — https://guides.rubyonrails.org/security.html#content-security-policy-header
- **Stripe webhook signatures** — https://docs.stripe.com/webhooks/signature

---

*Ce document est généré par analyse statique (Brakeman) et revue manuelle. Il ne remplace pas un test de pénétration professionnel.*
*À renouveler après chaque évolution majeure de l'architecture ou mise à jour de dépendances critiques.*
