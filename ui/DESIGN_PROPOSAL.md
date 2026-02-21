# Mole — macOS Desktop App Design Proposal

## Overview

**Mole** is an open-source macOS system maintenance tool (think CleanMyMac, but open-source). We're building a **Flutter desktop GUI** to replace the current terminal-only interface.

**Target platform:** macOS only
**Framework:** Flutter (desktop)
**Design direction:** Dark, premium, CleanMyMac-inspired

---

## Design Inspiration

- **CleanMyMac X** — sidebar navigation, scan/clean flow, category cards
- **DaisyDisk** — disk visualization, color-coded bars
- **iStat Menus** — live system metrics, sparkline charts, health gauges
- **Apple System Settings (Ventura+)** — sidebar layout, macOS-native feel

---

## Screens Needed (7 total)

### 1. Clean (Home/Default)
- **Purpose:** Scan and remove caches, logs, browser leftovers
- **Elements:** 6 category cards (User Cache, Browser, Dev Tools, Logs, App Cache, Trash), each showing scanned size. Two action buttons: "Scan" (preview) and "Clean" (execute). Live output log panel.
- **Feel:** The hero screen — should feel powerful and satisfying

### 2. Uninstall
- **Purpose:** Remove apps + hidden remnants (preferences, caches, launch agents)
- **Elements:** Searchable app list from /Applications, checkboxes for selection, app icons, "Uninstall" action button
- **Feel:** Clean, organized list view

### 3. Optimize
- **Purpose:** Refresh system databases, caches, services
- **Elements:** Task list with checkmarks (Rebuild Spotlight, Reset Network, Clear Swap, etc.), single "Run" button, progress indicators per task
- **Feel:** Satisfying checklist completion

### 4. Analyze (Disk Explorer)
- **Purpose:** Visualize disk usage, browse large files/folders
- **Elements:** Directory listing with size bars (proportional), breadcrumb path navigation, back button, color-coded by size fraction (blue → orange → red)
- **Feel:** DaisyDisk-like exploration

### 5. Status (Live Dashboard)
- **Purpose:** Real-time system health monitoring
- **Elements:**
  - Health score ring (0-100, animated, color-coded)
  - CPU card with usage %, sparkline chart
  - Memory card with used/total GB, progress bar
  - Disk card with used/free, progress bar
  - Battery card with %, charging status
- **Feel:** iStat Menus dashboard, data-rich but clean

### 6. Purge (Project Cleanup)
- **Purpose:** Remove old build artifacts (node_modules, target, build, venv)
- **Elements:** Artifact type chips showing what will be scanned, project list with sizes after scan, "Scan Projects" button
- **Feel:** Developer-focused, utilitarian

### 7. Installers
- **Purpose:** Find and remove .dmg, .pkg, .zip files
- **Elements:** 3 source cards (Downloads, Desktop, Homebrew), found files list with sizes, "Find Installers" button
- **Feel:** Simple, focused cleanup

---

## Persistent Layout

### Sidebar (Left, ~220px)
- Mole logo + "System Cleaner" tagline at top
- 7 nav items with icons (filled when active, outlined when inactive)
- Hover effect: subtle background highlight
- Active state: green accent background + left indicator
- Version number at bottom

### Top Area
- Frameless/hidden title bar (draggable area)
- Screen title + subtitle on each page

---

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#0E0E12` | Main app background |
| Sidebar | `#16161C` | Sidebar panel |
| Surface | `#1C1C22` | Cards, panels |
| Surface Light | `#26262E` | Hover states |
| Border | `#2A2A35` | Card borders |
| Green Accent | `#34C759` | Primary action, health good |
| Blue Accent | `#0A84FF` | Secondary, analyze |
| Purple Accent | `#BF5AF2` | Status, installers |
| Orange Accent | `#FF9F0A` | Optimize, warnings |
| Red Accent | `#FF453A` | Danger, uninstall, critical |
| Teal Accent | `#64D2FF` | Purge, disk info |
| Text Primary | `#FFFFFF` | Headings, labels |
| Text Secondary | `#8E8E93` | Body text |
| Text Tertiary | `#636366` | Hints, disabled |

## Typography

- **Font:** Inter (Google Fonts) or SF Pro (system)
- **Headings:** 24px / bold
- **Body:** 14px / regular
- **Caption:** 11-12px / regular
- **Monospace:** Menlo (for terminal output)

---

## Key UI Patterns

1. **Action buttons** — gradient background matching screen accent, subtle glow on hover
2. **Cards** — 16px border radius, 0.5px border, subtle shadow, hover glow effect
3. **Progress bars** — 6px height, rounded, gradient fill
4. **Health ring** — circular gauge, animated sweep, glow effect behind foreground arc
5. **Sparklines** — smooth curved line chart with translucent fill below
6. **Terminal output** — monospace font panel, dark surface background, scrollable
7. **Micro-animations** — 200ms ease transitions on hover/active states

---

## Deliverables Requested

1. **Figma file** with all 7 screens + sidebar in both idle and active states
2. **Component library:** buttons, cards, nav items, progress bars, health ring, sparkline
3. **Interaction specs:** hover states, active states, loading states
4. **Icon set recommendation** (Material Icons are used currently, open to alternatives)
5. **Optional:** Light theme variant

---

## Reference Screenshots

The app is already functional (code-first approach). We need design refinement to make it **premium-grade**. Current implementation uses Material Icons and basic Flutter widgets — the design should push it to feel like a polished indie Mac app.
