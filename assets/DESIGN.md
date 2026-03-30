# Design System Document: Neo-Campus Brutalism

## 1. Overview & Creative North Star

### Creative North Star: "The Kinetic Zine"
This design system rejects the polished, sanitized aesthetic of modern SaaS in favor of "The Kinetic Zine." It is a digital manifestation of campus underground culture—raw, high-contrast, and unapologetically loud. We move beyond standard UI by embracing **visual friction**. Instead of guiding the user through soft transitions, we use intentional asymmetry, "stark" typography scales, and a monochromatic base punctuated by "acid" hits of color.

The goal is to make the interface feel like it was assembled, not rendered. By utilizing a 4% noise texture over deep blacks and sharp-edged containers, we create a tactile, physical depth that feels premium through its refusal to follow "safe" design trends.

---

## 2. Colors

The palette is built on a foundation of high-contrast "Void" tones and "Toxic" accents.

- **Primary Background (`#0A0A0F`):** The "ink" of our zine. Everything lives within this void.
- **Surface (`#111118`):** Used for primary containers to create a subtle lift from the background.
- **Accent Electric (`#C8FF00`):** Our primary "Acid Yellow." Use this for critical actions and "illegal" borders.
- **Accent Secondary (`#FF3CAC`):** "Hot Pink." Use for secondary highlights, notifications, or to break the yellow dominance.
- **Text Primary (`#F0EDE6`):** A warm off-white. This provides better readability than pure white against dark backgrounds, feeling like weathered paper.

### The "No-Line" Rule
Prohibit the use of 1px solid grey borders for general sectioning. Sectioning must be achieved through **Surface Hierarchy**:
- Place a `surface-container-high` (`#1F1F26`) element directly against a `surface` (`#111118`) background.
- Boundary definition comes from the shift in tonal value, not a structural wire.

### Signature Textures
Apply a global **4% Opacity Noise Texture** (grain) overlay across the entire UI. This eliminates the "flat digital" feel and provides a "printed" editorial quality.

---

## 3. Typography

Typography is the primary engine of this design system’s personality. We use a three-tier system to balance raw energy with high-utility readability.

- **Display (Clash Display - Bold/Black):** Used for all-caps headings. Tracking must be set to `-2%` or `-5%` to create a "blocky," monolithic feel. This is the "voice" of the app.
- **Body (Syne - Regular/Medium):** A modern, wide-reaching sans-serif. It maintains an editorial edge while ensuring long-form content is digestible. Never go below 16px for body text to maintain the "Zine" scale.
- **Mono (Space Mono):** Used for usernames, metadata, labels, and timestamps. This introduces a "technical/data" layer that contrasts against the bold Display type.

**Hierarchy as Identity:**
Use extreme scale shifts. A `display-lg` headline should feel massive compared to the `body-md` content below it, creating an intentional typographic "collision."

---

## 4. Elevation & Depth

Standard shadows are strictly forbidden. We communicate hierarchy through **Tonal Layering** and **Hard Offsets**.

### The Layering Principle
Depth is achieved by "stacking" surface-container tiers. To lift a card:
1. Use `surface-container-low` for the section background.
2. Use `surface-container-highest` for the card itself.
3. If an element is "active," wrap it in a **1px Accent Border** using the `primary` (`#C8FF00`) token.

### Asymmetry & Floating Elements
Instead of centered alignment, offset elements by `1.75rem` (8 on the spacing scale) to create a sense of movement. Floating elements (like FABs or Tooltips) should use a high-contrast background with no shadow, appearing to "clip" onto the layout rather than hover over it.

### Corner Rules
- **Radius:** Strictly 0px (Sharp) to 4px (Softened Sharp). 
- **The Cut-Corner:** All avatars and profile imagery must use a `clip-path` to create a 12px diagonal "clipped" corner at the top-right, mimicking a physical photo tucked into a folder.

---

## 5. Components

### Buttons
- **Primary:** Background `primary` (`#C8FF00`), Text `on-primary` (`#4F6700`), 0px radius. Use all-caps `Space Mono`.
- **Secondary:** Transparent background, 1px `primary` border, Text `primary`.
- **States:** On hover, shift the entire button `2px` up and to the left, and add a "hard shadow" (an opaque block of `secondary` pink) behind it.

### Cards & Lists
- **No Dividers:** Forbid the use of divider lines. Separate list items using `0.9rem` (4) vertical whitespace or by alternating background colors between `surface-container` and `surface-container-low`.
- **Editorial Layout:** Cards should be asymmetric. For example, the image might take up 40% of the left side, but bleed over the top border by `0.4rem`.

### Input Fields
- **Styling:** No "pill" shapes. Use a 1px border of `outline-variant` on three sides, with the bottom border using the `primary` (`#C8FF00`) accent to indicate focus. 
- **Helper Text:** Use `Space Mono` at `label-sm` scale.

### Avatars
- **Primitive:** Square.
- **Treatment:** Always use the "Cut-Corner" clip-path. Images should have a subtle desaturation or high-contrast filter applied via CSS to match the Neo-Brutalist tone.

---

## 6. Do's and Don'ts

### Do:
- **Embrace whitespace:** Use the spacing scale (specifically `12` and `16` tokens) to let the typography breathe.
- **Use "Illegal" Colors:** Pair the Acid Yellow (`#C8FF00`) and Hot Pink (`#FF3CAC`) in high-tension areas like error states or notifications.
- **Stick to the Grid... then break it:** Align 90% of the UI to a rigid grid, then allow one key image or headline to break the alignment entirely.

### Don't:
- **No Rounded Pills:** Never use `border-radius: 999px`. Even buttons must be rectangles.
- **No Soft Shadows:** If you need depth, use a solid-color 1:1 offset block.
- **No Gradients:** Colors must be flat and punchy. Depth comes from texture and layering, not color interpolation.
- **No Standard Icons:** Avoid generic thin-line icon sets. Use thick, bold icons (2pt stroke minimum) or custom "pixel-perfect" mono icons.

### Accessibility Note:
While the aesthetic is "raw," ensure that all text against the `background` (`#0A0A0F`) maintains a contrast ratio of at least 4.5:1. Use `Text Primary` (`#F0EDE6`) for all essential data.