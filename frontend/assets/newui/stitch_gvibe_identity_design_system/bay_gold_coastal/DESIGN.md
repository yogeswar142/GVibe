---
name: Bay & Gold Coastal
colors:
  surface: '#101413'
  surface-dim: '#101413'
  surface-bright: '#363a39'
  surface-container-lowest: '#0b0f0e'
  surface-container-low: '#181c1b'
  surface-container: '#1c201f'
  surface-container-high: '#272b2a'
  surface-container-highest: '#313634'
  on-surface: '#e0e3e1'
  on-surface-variant: '#bcc9c6'
  inverse-surface: '#e0e3e1'
  inverse-on-surface: '#2d3130'
  outline: '#879391'
  outline-variant: '#3d4947'
  surface-tint: '#6bd8cb'
  primary: '#6bd8cb'
  on-primary: '#003732'
  primary-container: '#29a195'
  on-primary-container: '#00302b'
  inverse-primary: '#006a61'
  secondary: '#ffb77d'
  on-secondary: '#4d2600'
  secondary-container: '#d97707'
  on-secondary-container: '#432100'
  tertiary: '#4fdbc8'
  on-tertiary: '#003731'
  tertiary-container: '#00a392'
  on-tertiary-container: '#00302a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#89f5e7'
  primary-fixed-dim: '#6bd8cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#005049'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#71f8e4'
  tertiary-fixed-dim: '#4fdbc8'
  on-tertiary-fixed: '#00201c'
  on-tertiary-fixed-variant: '#005048'
  background: '#101413'
  on-background: '#e0e3e1'
  surface-variant: '#313634'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system reflects the vibrant coastal identity of Visakhapatnam (Vizag) merged with high-octane collegiate spirit. The visual personality balances seaside composure—evoked by the deep oceanic teal of the Bay of Bengal—with the celebratory warmth of Andhra turmeric gold. The aesthetic is tactile, modern, and dark-mode first, built to mirror the night-life energy of campus fests, late-night hackathons, and seafront walks.

The design movement is **Refined Cyber-Coastal**: combining deep obsidian-teal surfaces, glowing neon-teal structural borders, and targeted amber sparks. Interface elements feel luminous yet grounded, avoiding sterile corporate patterns in favor of dynamic campus social interaction. The tone is culturally anchored, confident, and energetic without becoming chaotic.

## Colors

The palette operates under a strict **60-30-10 hierarchy rule**:
- **60% Base & Neutral Surfaces:** Dominated by deep mineral tones (`#080C0B` down through surface steps `#0D1412`, `#131C1A`, and `#182220`).
- **30% Structure & Text Hierarchy:** High-legibility pale seafoam white (`#E8F4F2`), muted sage (`#7A9E9A`), dim seafoam (`#3D5C58`), and translucent structural borders (`rgba(13, 148, 136, 0.14)`).
- **10% Bay Teal Accents:** Interactive triggers, tab selections, active rings, and floating action indicators powered by Deep Bay Teal (`#0D9488`) and light teal glow states.

**Gold (`#D97706` / `#F59E0B`) is an intentional micro-accent.** It must never cover large surface cards or standard buttons; its use is reserved strictly for high-value rewards, event badges, story halos, gems, achievement milestones, and the brandmark focal point.

### Light Mode Mapping
When switching to light mode:
- Canvas base shifts to `#F5FAF9`, and primary surfaces adopt clean stark `#FFFFFF` and pale aqua `#EDF7F5`.
- Primary teal steps down to the deeper `#0F766E` to ensure contrast compliance against light fields.
- Gold deepens to `#B45309`, anchoring titles and achievement items legibly.
- Body typography converts to `#0C1F1D` (primary) and `#3D6B66` (secondary).

## Typography

The typographic tension pairs the electric, technical geometry of **Space Grotesk** with the humanistic, legible warmth of **Plus Jakarta Sans**. 

- **Space Grotesk** commands attention across headers, scores, event countdowns, and navigational hero tags. Letter-spacing for Space Grotesk should be slightly tracked out on uppercase display (`+0.02em`) and tight on large headings (`-0.02em`).
- **Plus Jakarta Sans** grounds the application with balanced line-heights and open letterforms, facilitating seamless reading in chat feeds, announcements, and profile details on compact smartphone displays.
- **Brand Wordmark:** The signature logo combines a 700-weight 'G' filled with a linear gradient spanning from deep teal (`#0D9488`) to turmeric gold (`#D97706`), placed flush against 'Vibe' rendered in warm white (`#E8F4F2`).

## Layout & Spacing

This mobile-first system is built around a flexible **4-column mobile layout** (expanding to 8 columns on foldables and tablets). Layout values adhere strictly to an 8-point base scale with a 4-point sub-grid for icons, micro-tags, and badges.

- **Screen Padding:** Standard outer canvas margin is `1rem` (16px), expanding to `1.25rem` (20px) on viewport widths above 400px.
- **Card Padding:** Default card and container interior padding is `1rem` (16px) for standard cards and `0.75rem` (12px) for compact listings.
- **Stack Spacing:** Stacked content sections separate cleanly at `1.5rem` (24px). Interactive component groupings (action rows, segmented controls) utilize `0.5rem` (8px) gaps.
- **Safe Area Insets:** The interface enforces hard boundaries for bottom navigation and floating action buttons: bottom bar components reserve `2rem` safe-area clearance above device chin gesture zones.

## Elevation & Depth

Visual hierarchy uses a layered **tonal step architecture** supported by translucent teal edge lighting, rather than traditional muddy drop shadows:

1. **Canvas Base (`#080C0B`):** The foundational substrate behind all content screens.
2. **Level 1 Surface (`#0D1412`):** Primary background for feeds, list backdrops, and static panels. Outlined with `border-default` (`rgba(13, 148, 136, 0.14)`).
3. **Level 2 Interactive Cards (`#131C1A`):** Touchable feed cards, media units, and actionable panels. Outlined with a 1px border of `rgba(13, 148, 136, 0.18)` that brightens on press or hover.
4. **Level 3 Dialogs & Sheets (`#182220`):** Bottom sheets, modal overlays, and pinned navigation menus. Bordered with `border-elevated` (`rgba(13, 148, 136, 0.28)`) and backed by a soft ambient shadow (`0 12px 32px -4px rgba(0, 0, 0, 0.65)`).
5. **Accent Bloom:** Floating controls and primary action anchors generate a diffuse teal halo (`0 0 20px rgba(13, 148, 136, 0.25)`) to signal interactivity without breaking the dark oceanic aesthetic.

## Shapes

The design system employs a **Rounded (Level 2)** geometry to evoke approachable warmth while maintaining crisp structural integrity.

- **Base Radius (0.5rem / 8px):** Inputs, tooltips, list row highlights, status pills, and compact buttons.
- **Container Radius (1rem / 16px):** Campus feed cards, event banners, popovers, and segmented tab tracks.
- **Large Surface Radius (1.5rem / 24px):** Bottom sheets (top corners), expanded modal panels, and spotlight profile headers.
- **Pill Radius (9999px):** Category filters, tags, story rings, active presence counters, and icon action bubbles.

## Components

### Buttons
- **Primary Action:** Solid Deep Bay Teal (`#0D9488`) background, `#FFFFFF` Space Grotesk text, 12px vertical and 20px horizontal padding, rounded to `0.5rem`. Hover/pressed state shifts to `#0F766E` accompanied by `primary-accent-glow` (`rgba(13, 148, 136, 0.25)`).
- **Secondary / Outlined:** Transparent surface with a 1px border of `border-elevated` (`rgba(13, 148, 136, 0.28)`), typography rendered in `#E8F4F2`.
- **Gold Reward Trigger:** Exclusively reserved for campus coin redemption, festive alerts, and VIP ticketing: Turmeric Gold (`#D97706`) background, dark text `#080C0B`, bold weight.

### Chips & Filter Tags
- **Inactive:** Surface `#131C1A`, border `rgba(13, 148, 136, 0.14)`, text `#7A9E9A`. Rounded to full pill (`9999px`).
- **Active:** Surface `#182220`, border `#0D9488`, text `#E8F4F2` with a 4px Deep Bay Teal glowing dot preceding the label.

### Cards & Feed Items
- Constructed with `#0D1412` or `#131C1A` backgrounds, framed with a 1px stroke of `border-default`. Corner radius is fixed to `1rem`. Headers use Space Grotesk medium bold; subtext uses Plus Jakarta Sans in `#7A9E9A`.

### Input Fields
- Enclosed with `#0D1412` background and a 1px stroke of `border-default`. Text value renders in `#E8F4F2`; placeholder text settles into `#3D5C58`. Upon focus, the border transitions smoothly to `#0D9488` with a matching `0 0 0 3px rgba(13, 148, 136, 0.15)` focus ring.

### Checkboxes & Radios
- Square checkbox elements (`0.25rem` radius) and circular radio buttons carry a 1.5px frame in `#3D5C58`. When checked, the fill transitions into `#0D9488` featuring a sharp white checkmark or inner core.

### Campus Badges & Story Halos
- **Active Student / Club Stories:** 2px circular avatar border featuring a gradient halo shifting from `#0D9488` (Teal) to `#D97706` (Turmeric Gold).
- **Festival / Academic Badges:** Pill-shaped, tinted with `gold-muted` (`rgba(217, 119, 6, 0.15)`), bordered with a 1px line of `gold-accent` (`#D97706`), with text displayed in `#F59E0B`.