# Vision IA pour l'extraction des devis et factures

**Date :** 14 avril 2026
**Contexte :** Remplacement du pipeline OCR + Regex par un pipeline Vision/IA unifié

---

## Problème actuel

Le pipeline OCR classique (`FactureOcrService`, `DevisOcrService`) repose sur :
1. `pdftotext` / `PDF::Reader` pour les PDF vectoriels
2. Tesseract (RTesseract) pour les PDF scannés et images
3. 40+ patterns regex pour parser montant, date, n° facture, BCE, TVA, etc.

**Limites identifiées :**
- Les devis artisanaux belges n'ont aucune standardisation de mise en page → regex cassées
- Tesseract dégrade sur les scans de mauvaise qualité
- ~50% des devis arrivent sous format **Excel** (`.xlsx`/`.xls`), parfois plusieurs centaines de lignes — non supporté

---

## Architecture cible : `DevisVisionService` unifié

```
┌─────────────────────────────────────────────────────────────┐
│                   DevisVisionService (nouveau)               │
├───────────────┬──────────────────────┬──────────────────────┤
│  PDF vectoriel│  PDF scanné / image  │  Excel (.xlsx/.xls)  │
│       ↓       │          ↓           │          ↓           │
│  pdftotext    │  Claude Vision       │  roo gem (Ruby)      │
│  (texte pur)  │  (image → IA)        │  → texte structuré   │
│       ↓       │          ↓           │          ↓           │
│         Claude Text API — extraction JSON structuré          │
└─────────────────────────────────────────────────────────────┘
```

---

## Méthode par format

| Format | Méthode d'extraction | API Claude | Fiabilité estimée |
|---|---|---|---|
| PDF vectoriel | `pdftotext` → texte brut | Text API | ✅ Excellent |
| PDF scanné / photo | Base64 ou URL → Vision | Vision API | ✅ Excellent |
| Image JPEG / PNG | Base64 ou URL → Vision | Vision API | ✅ Excellent |
| Excel `.xlsx` / `.xls` | gem `roo` → CSV/texte | Text API | ✅ Excellent |

---

## Gestion des Excel longs (200+ lignes)

Pour les devis Excel volumineux, stratification avant envoi à Claude :

1. **Header (lignes 1–20)** → infos entreprise, date, numéro devis
2. **Lignes de postes** → description + quantité + prix unitaire + total
3. **Footer (dernières lignes)** → HTVA, TVA, TVAC, conditions de paiement
4. **Tronqué intelligemment** à ~150 lignes si fichier géant, Claude est informé

Avantage vs Vision : **100% fidèle aux chiffres** (pas de risque d'hallucination sur valeurs numériques d'un tableau).

---

## Comparaison Vision vs OCR+Regex

| Critère | OCR + Regex | Vision / IA |
|---|---|---|
| PDF vectoriel | ✅ Fiable | ✅ Fiable |
| PDF scanné / photo | ⚠️ Tesseract dégradé | ✅ Natif |
| Mise en page atypique | ❌ Regex cassées | ✅ Comprend le sens |
| Excel multi-lignes | ❌ Non supporté | ✅ Via `roo` + Text API |
| Multilangue FR/NL/EN | ⚠️ Patterns limités | ✅ Natif |
| Coût par document | Gratuit (infra locale) | ~€0.01–0.03/doc |

---

## Dépendances à ajouter (Gemfile)

```ruby
gem "roo"      # Lecture Excel .xlsx et .xls
gem "rubyzip"  # Dépendance roo pour les .xlsx modernes
```

---

## Données extraites (JSON structuré cible)

```json
{
  "type_document": "devis | facture | acompte | solde",
  "numero": "DEV-2025-042",
  "date_emission": "2025-04-01",
  "date_validite": "2025-07-01",
  "entreprise": {
    "nom": "Plafonds Dubois SPRL",
    "numero_bce": "0478.123.456",
    "email": "info@dubois.be",
    "telephone": "+32 ...",
    "adresse": "..."
  },
  "client": { "nom": "...", "adresse": "..." },
  "lignes_travaux": [
    { "description": "Isolation toiture 120mm", "quantite": 85, "unite": "m²", "prix_unitaire": 38.5, "total_htva": 3272.5 }
  ],
  "types_travaux_detectes": ["isolation_toit", "chassis_vitrage"],
  "montant_htva": 3272.5,
  "taux_tva": 6,
  "montant_tva": 196.35,
  "montant_tvac": 3468.85,
  "conditions_paiement": "30% acompte, solde à réception",
  "confiance": 95
}
```

---

## Référence : service vision existant

Le pattern est déjà éprouvé dans `ChantierVisionService` (suivi photos de chantier) :
- Appel direct à l'API Anthropic (`claude-sonnet-4-5-20250929`)
- Images envoyées en base64 ou URL HTTPS (Cloudinary en production)
- Réponse JSON parsée, avec fallback si parse échoue

`DevisVisionService` et `FactureVisionService` reprendront exactement cette architecture.

---

## Statut

- [ ] Créer `DevisVisionService` (PDF vectoriel + PDF scanné + Excel + image)
- [ ] Créer `FactureVisionService` (PDF vectoriel + PDF scanné + image)
- [ ] Ajouter `gem "roo"` et `gem "rubyzip"` au Gemfile
- [ ] Brancher sur les controllers existants (remplacer les appels OCR)
- [ ] Tests de non-régression sur corpus de devis/factures réels
