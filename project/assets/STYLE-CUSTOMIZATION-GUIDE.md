# Guide de Personnalisation du Template

Ce template utilise un système complet de variables CSS pour permettre une personnalisation facile et rapide pour différents sites.

## 🎨 Personnalisations Rapides

### Exemples de Styles Différents

#### 1. Style Moderne avec Ombres
```css
:root {
    --card-shadow: var(--shadow-lg);
    --card-hover-shadow: var(--shadow-xl);
    --card-hover-transform: translateY(-4px);
    --card-border-radius: var(--border-radius-xl);
}
```

#### 2. Style Minimaliste avec Bordures
```css
:root {
    --card-shadow: var(--shadow-none);
    --card-border: var(--border-width) var(--border-style) var(--card-border-color);
    --card-border-radius: var(--border-radius-sm);
    --card-hover-transform: none;
}
```

#### 3. Style Coloré
```css
:root {
    --background-color: #f8f9fa;
    --card-bg: #ffffff;
    --accent-color: #e74c3c;
    --nav-hover-color: #e74c3c;
    --nav-active-color: #e74c3c;
    --card-shadow: var(--shadow-md);
}
```

#### 4. Style Sombre
```css
:root {
    --background-color: #1a1a1a;
    --font-color: #ffffff;
    --header-bg: #2d2d2d;
    --card-bg: #2d2d2d;
    --card-text-color: #ffffff;
    --nav-text-color: #ffffff;
    --footer-bg: #2d2d2d;
    --footer-text-color: #ffffff;
    --border-color: #404040;
}
```

### Navigation Styles

#### Menu avec Fond au Hover
```css
:root {
    --nav-bg-hover: var(--accent-color);
    --nav-hover-color: #ffffff;
    --nav-border-hover: var(--accent-color);
    --nav-padding: 0.75rem 1.5rem;
    --nav-border-radius: var(--border-radius-md);
}
```

#### Menu sans Soulignement
```css
:root {
    --nav-border-bottom-width: 0px;
    --nav-hover-color: var(--accent-color);
    --nav-active-color: var(--accent-color);
}
```

#### Menu Vertical (Mobile Style)
```css
:root {
    --nav-layout: block;
    --nav-gap: var(--spacing-sm);
}
```

### Cards/Articles Styles

#### Cards avec Animation Scale
```css
:root {
    --card-hover-transform: scale(1.02);
    --card-transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
```

#### Cards avec Bordure Colorée
```css
:root {
    --card-border: 3px var(--border-style) var(--accent-color);
    --card-shadow: var(--shadow-sm);
}
```

#### Cards sans Espacement
```css
:root {
    --card-margin: 0;
    --card-padding: var(--spacing-sm);
    --card-border-radius: 0;
}
```

## 📱 Variables par Catégorie

### Couleurs
- `--background-color` : Couleur de fond principale
- `--font-color` : Couleur du texte principal
- `--accent-color` : Couleur d'accent principale
- `--nav-hover-color` : Couleur du menu au survol
- `--card-bg` : Couleur de fond des cartes

### Espacements
- `--spacing-xs` à `--spacing-3xl` : Échelle d'espacements
- `--article-padding-*` : Padding des articles par device
- `--article-margin-*` : Marges par device
ose 
### Ombres
- `--shadow-none` à `--shadow-2xl` : Échelle d'ombres
- `--card-shadow` : Ombre des cartes
- `--card-hover-shadow` : Ombre au survol

### Bordures
- `--border-radius-sm` à `--border-radius-xl` : Rayons de bordure
- `--card-border` : Bordure des cartes
- `--card-border-radius` : Rayon des cartes

### Typographie
- `--font-size-*` : Tailles de police
- `--font-weight-*` : Poids des polices
- `--line-height-*` : Hauteurs de ligne

## 🚀 Comment Personnaliser

### Méthode 1: Modification Directe
Modifiez directement les variables dans `style.css` dans la section `:root`.

### Méthode 2: Fichier de Surcharge
Créez un fichier `custom-variables.css` et chargez-le après `style.css`:

```css
/* custom-variables.css */
:root {
    --accent-color: #your-color;
    --card-shadow: var(--shadow-lg);
    /* ... autres variables ... */
}
```

### Méthode 3: Variables par Site
Utilisez des classes conditionnelles:

```css
.site-corporate {
    --accent-color: #003366;
    --card-shadow: var(--shadow-sm);
}

.site-creative {
    --accent-color: #ff6b35;
    --card-shadow: var(--shadow-xl);
    --card-hover-transform: rotate(1deg);
}
```

## 🎯 Presets Prêts à l'Emploi

### Preset "Corporate"
```css
:root {
    --accent-color: #003366;
    --card-shadow: var(--shadow-sm);
    --card-border-radius: var(--border-radius-sm);
    --nav-font-weight: var(--font-weight-normal);
}
```

### Preset "Creative"
```css
:root {
    --accent-color: #ff6b35;
    --card-shadow: var(--shadow-xl);
    --card-hover-transform: translateY(-8px) rotate(1deg);
    --card-border-radius: var(--border-radius-xl);
}
```

### Preset "Minimal"
```css
:root {
    --card-shadow: var(--shadow-none);
    --card-border: 1px solid var(--border-color);
    --card-border-radius: 0;
    --nav-border-bottom-width: 1px;
}
```

## 📋 Checklist de Personnalisation

- [ ] Définir la palette de couleurs
- [ ] Choisir le style des cartes (ombre, bordure, ou minimal)
- [ ] Configurer la navigation (style des liens, hover)
- [ ] Ajuster les espacements
- [ ] Tester sur mobile/tablette
- [ ] Vérifier l'accessibilité des couleurs

Ce système permet de créer facilement des designs très différents en modifiant simplement quelques variables !
