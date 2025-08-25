# Documentation Sécurité - Ren0vate

## Configuration de Sécurité Mise en Place

### 1. Content Security Policy (CSP)

La CSP a été configurée pour prévenir les attaques XSS et l'injection de code malveillant.

#### Configuration Actuelle

**Mode :** 
- Développement/Test : Report-only (analyse des violations sans blocage)
- Production : Enforcement actif

**Directives Principales :**
- `default-src 'self'` : Par défaut, seules les ressources du même domaine
- `script-src` : Scripts autorisés depuis notre domaine + CDNs de confiance
- `style-src` : Styles autorisés + inline nécessaire pour Bootstrap/SweetAlert2
- `img-src` : Images depuis notre domaine + Cloudinary + data URLs
- `connect-src` : APIs externes autorisées (monuments Flandre, primes communales)

**CDNs Autorisés :**
- `cdn.jsdelivr.net` (Bootstrap, SweetAlert2)
- `cdnjs.cloudflare.com` (FontAwesome)
- `fonts.googleapis.com` / `fonts.gstatic.com` (Google Fonts si utilisées)

#### Rapports de Violation

- Endpoint : `/csp-violation-report-endpoint`
- Contrôleur : `SecurityController#csp_violation_report`
- Logging automatique des violations
- Détection des violations critiques (tentatives XSS)

### 2. Headers de Sécurité Additionnels

Configurés dans `ApplicationController#set_security_headers` :

#### Headers Appliqués
- `X-Frame-Options: SAMEORIGIN` - Protection clickjacking
- `X-Content-Type-Options: nosniff` - Prévention MIME sniffing
- `X-XSS-Protection: 1; mode=block` - Protection XSS navigateurs anciens
- `Referrer-Policy: strict-origin-when-cross-origin` - Contrôle référent
- `Permissions-Policy` - Restriction APIs navigateur

#### Headers Production Uniquement
- `Strict-Transport-Security` - Force HTTPS avec HSTS
- `Expect-CT` - Certificate Transparency

### 3. Configuration HTTPS

- Production : `config.force_ssl = true`
- HSTS activé avec preload
- Durée : 1 an (31536000 secondes)

## Violations CSP Communes et Solutions

### 1. SweetAlert2 / Bootstrap Inline Styles
**Problème :** Génération dynamique de styles inline
**Solution :** `'unsafe-inline'` autorisé pour `style-src`

### 2. Onclick Handlers
**Problème :** Handlers JavaScript inline dans les templates
**Solution :** Migration vers Stimulus controllers (recommandé)
**Temporaire :** `'unsafe-inline'` pour `script-src`

### 3. Styles Dynamiques
**Problème :** Attributs `style=""` pour composants interactifs
**Solution :** `style-src-attr 'unsafe-inline'`

## API Externes Autorisées

### Flandre
- `geo.onroerenderfgoed.be` - API monuments et sites classés

### Primes Communales
- `www.premiezoeker.be` - API primes communales

### Cloudinary
- `res.cloudinary.com` - Hébergement images/médias

## Monitoring et Alertes

### Logs CSP
```ruby
# Violations normales
Rails.logger.warn "[CSP VIOLATION] #{report.inspect}"

# Violations critiques (potentielles attaques)
Rails.logger.error "[CSP CRITICAL VIOLATION] Possible security threat"
```

### Métriques à Surveiller
- Nombre de violations par heure
- Types de violations fréquentes
- Tentatives d'injection de code
- Violations depuis IPs suspectes

## Actions de Maintenance

### Révision Périodique
1. **Mensuel :** Analyser les rapports de violation
2. **Trimestriel :** Réviser la liste des CDNs autorisés
3. **Semestriel :** Audit complet de sécurité

### Migration Progressive
1. **Phase 1 ✅ :** CSP Report-only + Headers sécurité
2. **Phase 2 :** Migration onclick → Stimulus
3. **Phase 3 :** Durcissement CSP (retrait 'unsafe-inline')

### Tests de Sécurité
```bash
# Test headers sécurité
curl -I https://ren0vate-630b5136c442.herokuapp.com/

# Test CSP
# Ouvrir DevTools → Console → Observer violations CSP
```

## Bonnes Pratiques Développement

### Scripts
- ❌ `onclick="..."` inline
- ✅ Stimulus controllers
- ✅ Event listeners dans JS séparés

### Styles
- ❌ `style="..."` inline quand possible
- ✅ Classes CSS
- ✅ Variables CSS pour styles dynamiques

### Ressources Externes
- Toujours vérifier l'intégrité (SRI)
- Préférer les CDNs reconnus
- Documenter les nouvelles sources autorisées

## Conformité et Audits

### Standards Respectés
- OWASP Top 10 - A7 (XSS)
- RGPD - Sécurité des données
- Mozilla Security Guidelines

### Outils d'Audit Recommandés
- OWASP ZAP
- Mozilla Observatory
- SSL Labs
- SecurityHeaders.com

---

**Dernière mise à jour :** 25 août 2025
**Responsable :** Équipe développement
**Révision suivante :** Novembre 2025
