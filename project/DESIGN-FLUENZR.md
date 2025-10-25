# FLUENZR - Design Moderne & Brut

## 🎨 Proposition de Design

Un design **minimaliste** et **épuré** inspiré de tendances modernes, avec la couleur violette principale (#6840de) comme accent.

### Caractéristiques principales:

#### 1. **Header**
- Logo plus grand (280px au lieu de 200px)
- Navigation minimale et épurée
- Underline animé au hover
- Border subtle en bas

#### 2. **Mosaïque Accueil (home-mosaic)**
```
Grid 3 colonnes avec cartes flexibles:
- Cartes standards (1x1)
- Cartes larges (2x1)
- Cartes full-width (3x1) avec image à gauche, contenu à droite
```

**Styling:**
- Bordures minimalistes (1px)
- Pas d'ombres par défaut, ombre violette au hover
- Images avec zoom léger au hover (1.05x)
- Background blanc/gris clair
- Animations de slide-in cascadées

#### 3. **Cartes Individuelles**
```
┌─────────────────────┐
│                     │
│   Image (16:9)      │  ← Zone image avec gradient subtle
│                     │
├─────────────────────┤
│ Titre Article       │  ← Grand texte, gras
│ 15 oct 2025         │  ← Date subtle
│                     │
│ Excerpt du contenu  │  ← Gris clair
│ continue ici...     │
│                     │
│ [Catégorie badge]   │  ← Violet, bold, uppercase
└─────────────────────┘
```

#### 4. **Couleurs**
- **Primaire**: #6840de (Violet)
- **Secondaire**: #5629c2 (Violet sombre au hover)
- **Texte**: #000 (noir) / #666 (gris)
- **Fond**: #fff (blanc) / #fafafa (gris clair)
- **Borders**: #e8e8e8 (gris très clair)

#### 5. **Typographie**
- Font: Lato (déjà importée)
- Headings: Gras (700)
- Navigation: Semi-bold (600)
- Body: Regular (400)

#### 6. **Interactions**
- Links color: Violet (#6840de)
- Hover: Underline + color change
- Cards: Border color change + subtle shadow
- Buttons: Violet background, darker au hover

#### 7. **Responsive**
- Desktop (1400px): Grid 3 colonnes
- Tablet (1024px): Grid 2 colonnes
- Mobile (768px): Grid 1 colonne, full-width becomes flex

---

## 📁 Fichiers créés/modifiés

### Nouveaux:
- **`fluenzr-design.css`** - Tout le design personnalisé Fluenzr

### Modifiés:
- **`functions.php`** - Logo 280px + chargement du CSS fluenzr-design
- **`style.css`** - Couleurs mises à jour (#6840de)

---

## 🚀 Activation

Le design est **automatiquement activé** et chargé dans l'ordre:
1. `style.css` (variables CSS)
2. `shared.css` (depuis static.le-meon.com)
3. **`fluenzr-design.css`** ← Notre nouveau design ✨
4. Autres CSS spécifiques

---

## 💡 Points clés du design

✅ **Minimaliste** - Peu d'ombres, borders fines, espace blanc
✅ **Moderne** - Grid layout, animations smooth, hover effects
✅ **Brut** - Bordures carrées, pas de arrondis
✅ **Violet-first** - La couleur primaire en point focal
✅ **Responsive** - Fonctionne sur mobile, tablet, desktop
✅ **Performant** - Animations optimisées (GPU)

---

## 🔄 Variations possibles

Si tu veux ajuster:
- **Bordures arrondies**: Modifier `border-radius: 0` → `border-radius: 8px`
- **Couleurs**: Remplacer `#6840de` et `#5629c2`
- **Spacing**: Modifier `gap` et `padding` dans `.home-mosaic`
- **Animations**: Modifier `@keyframes slideInUp`

---

## ✅ À vérifier

- [x] Logo 280px en desktop
- [x] Mosaïque 3 colonnes
- [x] Cartes larges (2x1)
- [x] Cartes full-width (3x1)
- [x] Hover effects violets
- [x] Responsive mobile/tablet
- [x] Animations cascadées
- [x] Footer noir (#000)

