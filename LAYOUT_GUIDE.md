# STREAM Dashboard Refactor - Visual Layout Guide

## Before vs After Layout Structure

### BEFORE (Scrolling Layout)
```
┌─────────────────────────────────────────────────────────┐
│ BODY (scrolls if content > viewport)                   │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Sidebar (fixed, 260px)                              │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ TopBar (fixed, 64px)                                │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Main Content (ml-[260px], mt-16)                    │ │
│ │ Greeting (variable height)                          │ │
│ │ Stats (100px+)                                      │ │
│ │ Table (full height, no scroll)                      │ │
│ │ Widgets (full height, no scroll)                    │ │
│ │ ... MORE CONTENT ...                                │ │
│ │ ... SCROLLS BEYOND VIEWPORT ...                     │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
      ↑ SCROLLBAR HERE (main container scrolls)
```

### AFTER (No-Scroll Layout) ✅
```
┌─────────────────────────────────────────────────────────┐ ← 900px (h-screen)
│ ┌────┬──────────────────────────────────────────────┐  │
│ │ S  │ TopBar (56px) - FIXED                        │  │
│ │ I  ├──────────────────────────────────────────────┤  │
│ │ D  │ ┌──────────────────────────────────────────┐ │  │
│ │ E  │ │ Greeting Row (48px) - FIXED              │ │  │
│ │ B  │ ├──────────────────────────────────────────┤ │  │
│ │ A  │ │ Stat Cards (88px) - FIXED                │ │  │
│ │ R  │ ├──────────────────────────────────────────┤ │  │
│ │    │ │ ┌──────────────┬────────────┐            │ │  │
│ │ 2  │ │ │ Table        │ Widgets    │            │ │  │
│ │ 6  │ │ │ ┌──────────┐ │ ┌────────┐ │            │ │  │
│ │ 0  │ │ │ │ Header   │ │ │ Quick  │ │ FIXED      │ │  │
│ │ p  │ │ │ ├──────────┤ │ ├────────┤ │            │ │  │
│ │ x  │ │ │ │ Columns  │ │ │ Alerts │ │ SCROLLS ↕  │ │  │
│ │    │ │ │ ├──────────┤ │ ├────────┤ │            │ │  │
│ │ S  │ │ │ │          │ │ │ Today  │ │ SCROLLS ↕  │ │  │
│ │ C  │ │ │ │   ROWS   │ │ ├────────┤ │            │ │  │
│ │ R  │ │ │ │ SCROLLS↕ │ │ │ Stats  │ │ FIXED      │ │  │
│ │ O  │ │ │ │          │ │ └────────┘ │            │ │  │
│ │ L  │ │ │ │          │ │   300px    │            │ │  │
│ │ L  │ │ │ └──────────┘ └────────────┘            │ │  │
│ │ S  │ │ │ ├──────────┐                           │ │  │
│ │    │ │ │ │ Paginate │ FIXED                     │ │  │
│ │ ↕  │ │ └──┴──────────┴───────────────────────────┘ │  │
│ └────┴──┴──────────────────────────────────────────┴──┘  │
└─────────────────────────────────────────────────────────┘
   NO SCROLLBAR ON BODY/MAIN ✅
   Only internal areas scroll ✅
```

## Height Breakdown at 1440×900px

```
┌─────────────────────────────────────────┐
│ Total Viewport: 900px                   │
├─────────────────────────────────────────┤
│ TopBar:          56px                   │
│ Padding Top:     20px                   │
│ Greeting:        48px                   │
│ Gap:              8px                   │
│ Stat Cards:      88px                   │
│ Gap:             12px                   │
│ Bottom Grid:    648px (fills remaining) │
│ Padding Bottom:  20px                   │
├─────────────────────────────────────────┤
│ TOTAL:          900px ✅                │
└─────────────────────────────────────────┘
```

## Component Height Specifications

### Dashboard Components
```
Greeting Row           48px  (h-12)    flex-shrink-0
Stat Cards             88px  (h-[88px]) flex-shrink-0
Table Header           48px  (h-12)    flex-shrink-0
Column Headers         36px  (h-9)     flex-shrink-0
Table Body          flex-1  (auto)    overflow-y-auto min-h-0
Pagination             40px  (h-10)    flex-shrink-0

Quick Actions      ~210px  (auto)    flex-shrink-0
Recent Alerts     flex-1  (auto)    overflow-hidden min-h-0
Today's Sessions  flex-1  (auto)    overflow-hidden min-h-0
Adherence Stats   ~140px  (auto)    flex-shrink-0
```

### Layout Components
```
TopBar                 56px  (h-14)    flex-shrink-0
Sidebar Logo           56px  (h-14)    flex-shrink-0
Sidebar Nav         flex-1  (auto)    overflow-y-auto min-h-0
Sidebar User Card      56px  (h-14)    flex-shrink-0
```

## Flexbox Hierarchy

```
App.vue
└─ div (h-screen overflow-hidden flex)
   ├─ AppSidebar (flex-shrink-0 h-screen overflow-hidden)
   │  ├─ Logo (h-14 flex-shrink-0)
   │  ├─ Nav (flex-1 overflow-y-auto min-h-0) ← SCROLLS
   │  └─ User Card (h-14 flex-shrink-0)
   │
   └─ div (flex-1 flex flex-col h-screen overflow-hidden)
      ├─ AppTopBar (h-14 flex-shrink-0)
      └─ main (flex-1 overflow-hidden flex flex-col p-5)
         └─ RouterView
            └─ DashboardView (flex flex-col h-full overflow-hidden)
               ├─ Greeting (h-12 flex-shrink-0)
               ├─ Stats (h-[88px] flex-shrink-0)
               └─ Grid (flex-1 min-h-0)
                  ├─ Table (flex flex-col overflow-hidden)
                  │  ├─ Header (h-12 flex-shrink-0)
                  │  ├─ Columns (h-9 flex-shrink-0)
                  │  ├─ Body (flex-1 overflow-y-auto min-h-0) ← SCROLLS
                  │  └─ Pagination (h-10 flex-shrink-0)
                  │
                  └─ Widgets (flex flex-col gap-3 overflow-hidden)
                     ├─ Quick Actions (flex-shrink-0)
                     ├─ Alerts (flex-1 min-h-0 overflow-hidden)
                     │  ├─ Header (flex-shrink-0)
                     │  └─ List (flex-1 overflow-y-auto min-h-0) ← SCROLLS
                     ├─ Sessions (flex-1 min-h-0 overflow-hidden)
                     │  ├─ Header (flex-shrink-0)
                     │  └─ List (flex-1 overflow-y-auto min-h-0) ← SCROLLS
                     └─ Adherence (flex-shrink-0)
```

## Key CSS Properties

### Root Container (App.vue)
```css
.h-screen         /* height: 100vh */
.overflow-hidden  /* overflow: hidden */
.flex             /* display: flex */
```

### Main Content Area
```css
.flex-1           /* flex: 1 1 0% */
.overflow-hidden  /* overflow: hidden */
.flex             /* display: flex */
.flex-col         /* flex-direction: column */
.p-5              /* padding: 1.25rem (20px) */
```

### Scrollable Areas
```css
.flex-1           /* flex: 1 1 0% */
.min-h-0          /* min-height: 0 (CRITICAL!) */
.overflow-y-auto  /* overflow-y: auto */
```

### Fixed Height Elements
```css
.h-12             /* height: 3rem (48px) */
.h-14             /* height: 3.5rem (56px) */
.h-[88px]         /* height: 88px */
.flex-shrink-0    /* flex-shrink: 0 */
```

## Why min-h-0 is Critical

Without `min-h-0`:
```
┌────────────────────┐
│ Flex Parent        │
│ ┌────────────────┐ │
│ │ flex-1 Child   │ │← Wants to grow
│ │ (content: 1000px) │← But content determines size
│ └────────────────┘ │
│ Exceeds parent! ❌ │
└────────────────────┘
    Parent scrolls
```

With `min-h-0`:
```
┌────────────────────┐
│ Flex Parent        │
│ ┌────────────────┐ │
│ │ flex-1 min-h-0 │ │← Constrained by parent
│ │ overflow-y-auto│ │← Internal scroll
│ │ ↕ scrolls      │ │← Perfect! ✅
│ └────────────────┘ │
└────────────────────┘
    No parent scroll
```

## Typography Scale

```
Page Title       20px  (--text-page-title)
Page Subtitle    13px  (--text-page-subtitle)
Section Title    14px  (--text-section-title)
Card Title       13px  (--text-card-title)
Body Text        13px  (--text-body)
Small Text       12px  (--text-small)
Extra Small      11px  (--text-xs)
Stat Numbers     26px  (--text-stat-number)
Badge            10px  (inline)
```

## Viewport Size Reference

```
1440×900px (Target)
├─ Width:  1440px
│  ├─ Sidebar:       260px
│  ├─ Content:      1180px
│  │  ├─ Padding:     40px (20px × 2)
│  │  ├─ Available: 1140px
│  │  │  ├─ Table:   ~820px
│  │  │  └─ Widgets:  300px
│  │  │  └─ Gap:       16px
│
└─ Height: 900px
   ├─ TopBar:          56px
   ├─ Padding:         40px (20px × 2)
   └─ Content:        804px
      ├─ Greeting:     48px
      ├─ Gap:           8px
      ├─ Stats:        88px
      ├─ Gap:          12px
      └─ Grid:        648px (fills remaining)
```

## Success Indicators

✅ Body scrollbar: GONE
✅ Main scrollbar: GONE
✅ Table body: SCROLLS INTERNALLY
✅ Widget lists: SCROLL INTERNALLY
✅ All content: VISIBLE WITHOUT SCROLLING
✅ Layout: FITS PERFECTLY IN 900PX HEIGHT

---

**Remember:** The golden rule is `min-h-0` on ALL flex children that need internal scrolling!
