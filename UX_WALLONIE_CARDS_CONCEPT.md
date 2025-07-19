# Concept UX - Cartes Primes Wallonie

## Vision Générale
Organiser les 46 primes Wallonie en **10 cartes métier** pour une expérience utilisateur optimisée.

## Structure des Cartes

### 1. Audit énergétique (1 prime)
- Audit complet → [forfait] → [résultat €]

### 2. Toiture (4 primes)
- Isolation toiture inclinée → [m²] → [résultat €]
- Isolation toiture plate → [m²] → [résultat €]
- Membrane d'étanchéité → [m²] → [résultat €]
- Charpente → [forfait] → [résultat €]
- **TOTAL TOITURE** → [somme automatique] €

### 3. Murs (3 primes)
- Isolation murs par l'extérieur → [m²] → [résultat €]
- Isolation murs par l'intérieur → [m²] → [résultat €]
- Doublage murs → [m²] → [résultat €]
- **TOTAL MURS** → [somme automatique] €

### 4. Sols (2 primes)
- Isolation sol sur cave/vide → [m²] → [résultat €]
- Isolation sol sur terre-plein → [m²] → [résultat €]
- **TOTAL SOLS** → [somme automatique] €

### 5. Menuiseries (4 primes)
- Fenêtres → [nombre] → [résultat €]
- Portes extérieures → [nombre] → [résultat €]
- Châssis → [m²] → [résultat €]
- Volets → [m²] → [résultat €]
- **TOTAL MENUISERIES** → [somme automatique] €

### 6. Installations techniques (8 primes)
- Ventilation mécanique → [forfait] → [résultat €]
- VMC double flux → [forfait] → [résultat €]
- Système de chauffage → [forfait] → [résultat €]
- Etc...
- **TOTAL INSTALLATIONS** → [somme automatique] €

### 7. Systèmes de chauffage (8 primes)
- Chaudière gaz condensation → [forfait] → [résultat €]
- Pompe à chaleur → [forfait] → [résultat €]
- Chaudière biomasse → [forfait] → [résultat €]
- Etc...
- **TOTAL CHAUFFAGE** → [somme automatique] €

### 8. Ventilation (4 primes)
- VMC hygro → [forfait] → [résultat €]
- Extracteur d'air → [nombre] → [résultat €]
- Etc...
- **TOTAL VENTILATION** → [somme automatique] €

### 9. Amélioration chauffage (6 primes)
- Isolation conduites → [ml] → [résultat €]
- Isolation ballon → [forfait] → [résultat €]
- Circulateur → [forfait] → [résultat €]
- Vannes thermostatiques → [nombre] → [résultat €]
- Thermostat → [forfait] → [résultat €]
- **TOTAL AMÉLIORATION** → [somme automatique] €

### 10. ECS - Eau Chaude Sanitaire (6 primes)
- Ballon ≤500l → [forfait] → [résultat €]
- Ballon >500l → [forfait] → [résultat €]
- Isolation conduites → [ml] → [résultat €]
- Échangeur → [forfait] → [résultat €]
- Isolation ballon ≤500l → [forfait] → [résultat €]
- Isolation ballon >500l → [forfait] → [résultat €]
- **TOTAL ECS** → [somme automatique] €

## Avantages UX

### Réduction de la complexité
- **Avant** : 46 primes individuelles à naviguer
- **Après** : 10 cartes métier logiques

### Workflow naturel
- L'utilisateur pense "travaux par zone"
- Calculs contextualisés par métier
- Vision d'ensemble par domaine

### Expérience optimisée
- **Calculs en temps réel** JavaScript
- **Totaux automatiques** par carte
- **Validation progressive** par métier
- **Sauvegarde état** par carte
- **Export PDF** structuré

### Layout suggéré
- **Grid 2x5** ou **3x4** selon l'écran
- **Icônes distinctes** par catégorie
- **Badge nombre de primes** sur chaque carte
- **Couleurs thématiques** par section
- **Filtrage par catégorie**

## Flow utilisateur type
```
👤 "Je veux rénover ma maison"
├── 🏠 Carte Toiture → Calculs multiples → Total toiture
├── 🧱 Carte Murs → Calculs multiples → Total murs
├── 🪟 Carte Menuiseries → Calculs multiples → Total menuiseries
├── ... autres cartes selon besoins
└── 📊 TOTAL GÉNÉRAL automatique
```

## Implémentation technique
- **Grouping par catégorie** dans le controller
- **Calculs front-end** temps réel
- **State management** par carte
- **API endpoints** par catégorie
- **Validation** granulaire par input

---
*Concept validé le 19/07/2025 - À implémenter en phase UI/UX*
