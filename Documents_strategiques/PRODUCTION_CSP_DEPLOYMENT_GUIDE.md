# Guide de Déploiement Production - CSP et Dashboard Admin

## ✅ Vérifications Pre-Déploiement

### 1. Configuration CSP ✅
- `/config/initializers/content_security_policy.rb` est configuré
- Nonces activés en production seulement
- Script inline avec nonce dans `admin/dashboard.html.erb`

### 2. Assets ✅
- JavaScript corrigé (tous les `` \` `` remplacés par `` ` ``)
- Assets précompilés pour production

### 3. Checklist de Déploiement

#### Avant le déploiement :
```bash
# 1. Précompiler les assets
RAILS_ENV=production bin/rails assets:precompile

# 2. Vérifier la syntaxe JavaScript
grep -n "\\\\`" app/views/admin/dashboard.html.erb
# ⚠️ Doit retourner aucun résultat !

# 3. Vérifier le nonce CSP
grep -n "content_security_policy_nonce" app/views/admin/dashboard.html.erb
# ✅ Doit trouver la ligne avec nonce="<%= content_security_policy_nonce %>"
```

#### Après le déploiement :
```bash
# 1. Tester les headers CSP
curl -I https://votre-domaine.com/admin/dashboard | grep -i content-security

# 2. Vérifier les nonces dans le HTML
curl -s https://votre-domaine.com/admin/dashboard | grep -o 'nonce="[^"]*"' | head -3

# 3. Test des boutons de sécurité
# ➡️ Accéder au dashboard et cliquer sur les 6 boutons de la section "Actions de Sécurité"
```

## 🔧 Configuration Production

### Content Security Policy
- **Script-src** : `nonce-{GENERATED}` au lieu de `'unsafe-inline'`
- **Nonce Generator** : Utilise l'ID de session
- **Report Only** : `false` en production (enforcement activé)

### Assets Pipeline
- Assets précompilés obligatoires
- JavaScript inline nécessite des nonces valides
- CDNs autorisés : Bootstrap, SweetAlert2, FontAwesome

## 🐛 Résolution de Problèmes

### Si les boutons ne fonctionnent pas en production :

1. **Vérifier les headers CSP** :
   ```bash
   curl -I https://votre-domaine.com | grep -i content-security
   ```

2. **Vérifier les nonces** :
   ```bash
   curl -s https://votre-domaine.com/admin/dashboard | grep 'nonce="'
   ```

3. **Console du navigateur** :
   - Ouvrir DevTools > Console
   - Chercher des erreurs CSP : "Refused to execute inline script"
   - Vérifier : "🚀 Dashboard JavaScript loading..."

4. **Si CSP bloque** :
   - Vérifier que le nonce est identique dans CSP header et script tag
   - S'assurer que `config.content_security_policy_nonce_generator` fonctionne

### Erreurs communes :

- ❌ **"Refused to execute inline script"** → Nonce manquant ou incorrect
- ❌ **"SweetAlert2 not defined"** → CDN bloqué par CSP
- ❌ **"Uncaught SyntaxError"** → Caractères échappés dans JavaScript

## ✅ État Actuel

- [x] CSP configuré avec nonces pour production
- [x] JavaScript corrigé (backticks non échappés)
- [x] Nonce ajouté au script tag du dashboard
- [x] Assets précompilés
- [x] CDNs autorisés dans CSP
- [x] Tests validés en développement

**Prêt pour le déploiement !** 🚀
