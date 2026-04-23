# Stratégie design go-to-market — Ren0vate

## Contexte

416 vues existantes. Base Bootstrap 5 + SCSS bien structurée. Palette distinctive déjà en place.
Objectif : se démarquer visuellement de la déferlante d'apps Lovable/shadcn pour le lancement commercial.

---

## Avantage concurrentiel actuel

Les apps Lovable/shadcn génèrent toutes du Tailwind + composants identiques → elles se ressemblent toutes.

Ren0vate a déjà :
- Palette thématique distinctive (ardoise `#334155` / terracotta `#D97706` / sauge `#84A98C`)
- Identité matériaux de construction — pas le bleu tech générique
- Variables CSS propres dans `_variables.scss`
- Bootstrap 5 structuré avec composants SCSS séparés

**À ne pas changer** : migrer vers Tailwind serait 2 semaines de travail pour zéro valeur utilisateur.

---

## Pages prioritaires (les 5 qui drivent le go-to-market)

| # | Page | Fichier | Rôle | Priorité |
|---|------|---------|------|---------|
| 1 | Landing | `app/views/pages/home.html.erb` | Première impression, acquisition | 🔴 Critique |
| 2 | Pricing | `app/views/pricing/index.html.erb` | Conversion | 🔴 Critique |
| 3 | Checkout | `app/views/pricing/select.html.erb` | Conversion | 🔴 Critique |
| 4 | Dashboard | `app/views/dashboard/index.html.erb` | Screenshots marketing + rétention | 🟠 Important |
| 5 | Wizard simulation | `app/views/simulations/` | Demo produit | 🟠 Important |

Les 411 autres vues (formulaires CRUD, admin) : ne pas toucher sauf blocage commercial.

---

## Workflow recommandé : Claude Code en direct

Le plus efficace pour une app Rails existante — pas besoin de passer par Figma ou un outil externe.

### Prompt type (à adapter par page)

```
Rewrite [NOM_PAGE].html.erb. 
Keep the Bootstrap 5 + ERB structure.
Keep all existing CSS variables (--ren0vate-primary, --ren0vate-accent, --ren0vate-success...).
Goal: modern SaaS landing that converts.
Needs: [voir détails par page ci-dessous]
Do NOT change the Rails/ERB logic, only the HTML structure and classes.
```

---

## Détails par page

### 1. `home.html.erb` — Landing page

**Needs à ajouter au prompt :**
- Stronger hero with clear value proposition (1 phrase, pas de jargon)
- Social proof section (chiffres, témoignages, logos partenaires)
- Feature grid with Bootstrap Icons
- One primary CTA above the fold
- Belgian market, construction/renovation sector tone

**Éléments à conserver impérativement :**
- `set_seo_meta(...)` en tête de fichier
- `structured_data_organization` dans le head
- Links ERB (`new_user_registration_path`, `root_path`, etc.)
- L'image `arcliine.jpg` en hero background si elle est bonne

---

### 2. `pricing/index.html.erb` — Page tarifs (521 lignes)

**Needs à ajouter au prompt :**
- Highlighted plan (anneau coloré `--ren0vate-accent` sur le plan recommandé)
- Toggle switch mensuel / annuel avec réduction affichée
- Bullet points iconifiés par tier (pas de tableaux)
- CTA distinct par plan
- FAQ section courte en bas (3-4 questions)

---

### 3. `pricing/select.html.erb` — Checkout (481 lignes)

**Needs à ajouter au prompt :**
- Résumé du plan choisi visible à droite (sticky)
- Réassurance visuelle (sécurité Stripe, pas d'engagement)
- Étapes claires (1 → 2 → 3)
- Pas de distractions — supprimer tout ce qui n'est pas lié au paiement

---

### 4. `dashboard/index.html.erb` — Tableau de bord

**Needs à ajouter au prompt :**
- Stat cards avec icônes et couleurs par type (projets, budget, primes)
- Progress bars sur les chantiers actifs
- Section "prochaine action" prominente
- Tone: professionnel mais chaleureux — pas un cockpit de banque

---

## 3 changements structurels à fort impact visuel

Ces 3 ajouts transforment la perception sans toucher aux vues CRUD.

### A. Micro-animations AOS.js

**Fichier :** `app/views/layouts/application.html.erb`
**Effort :** 30 minutes

```html
<!-- Dans <head> -->
<link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">

<!-- Avant </body> -->
<script src="https://unpkg.com/aos@2.3.1/dist/aos.js"></script>
<script>AOS.init({ duration: 600, once: true });</script>
```

Ensuite sur les sections de la landing : `data-aos="fade-up"` / `data-aos="fade-right"`.

---

### B. Navbar glassmorphism au scroll

**Fichier :** `app/assets/stylesheets/layout/_navbar.scss`
**Effort :** 20 minutes

```scss
.navbar.scrolled {
  background: rgba(255, 255, 255, 0.85) !important;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--ren0vate-shadow);
  transition: var(--ren0vate-transition-slow);
}
```

JS dans le layout :
```javascript
window.addEventListener('scroll', () => {
  document.querySelector('.navbar')?.classList.toggle('scrolled', window.scrollY > 50);
});
```

---

### C. Pricing highlighted plan

**Fichier :** `app/views/pricing/index.html.erb`
**Effort :** 15 minutes

Sur la card du plan recommandé :
```html
<div class="pricing-card position-relative" style="
  border: 2px solid var(--ren0vate-accent);
  transform: scale(1.03);
  box-shadow: var(--ren0vate-shadow-lg);
">
  <div class="position-absolute top-0 start-50 translate-middle">
    <span class="badge px-3 py-2" style="background: var(--ren0vate-accent); border-radius: 20px;">
      ⭐ Recommandé
    </span>
  </div>
  ...
</div>
```

---

## Option B : prototypage avec Claude.ai web (artifacts)

Pour valider visuellement avant de coder — utile si tu veux voir le rendu avant de modifier le code.

1. **Claude.ai** → générer un artifact HTML/CSS statique de la page cible
2. Valider le look dans le browser (artifact s'affiche en live)
3. **Claude Code** → convertir l'HTML en ERB avec les helpers Rails

Prompt pour l'artifact :
```
Generate a modern SaaS landing page for "Ren0vate" — Belgian renovation management platform.
Color palette: primary #334155 (slate blue), accent #D97706 (terracotta), success #84A98C (sage green), background #E6DDD3 (sand).
Stack: Bootstrap 5 + vanilla CSS variables. No Tailwind.
Include: hero, 3-feature grid, social proof, pricing teaser, footer.
Target: Belgian homeowners managing renovation projects.
```

---

## Ce qu'on ne fait PAS

- ❌ Migrer vers Tailwind CSS
- ❌ Exporter depuis Figma (CSS non maintenable en contexte ERB)
- ❌ Redesigner les vues CRUD (formulaires, listes, admin)
- ❌ Tester des vues (`test/views/`) — zéro valeur

---

## Ordre d'exécution

```
Jour 1 : home.html.erb  (landing — acquisition)
Jour 2 : pricing/index.html.erb  (conversion)
Jour 3 : AOS.js + navbar scroll + pricing highlight  (polish rapide)
Jour 4 : dashboard/index.html.erb  (screenshots marketing)
Jour 5 : pricing/select.html.erb  (checkout)
```
