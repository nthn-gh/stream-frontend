// Resolves a main.css CSS custom property to its current literal value, for
// call sites that can't consume var(--...) directly -- e.g. Chart.js
// dataset colors and html2canvas options, which are read by a Canvas 2D
// context rather than the CSS cascade, so raw var() strings there are
// silently invalid instead of resolving.
//
// document.documentElement is the right element to read from because
// useTheme.ts toggles dark mode by adding/removing the `.dark` class on
// documentElement itself, and both `:root` and `.dark` in main.css target
// that same element -- so this automatically picks up the active theme.
export function resolveToken(varName: string, fallback = ''): string {
  if (typeof window === 'undefined') return fallback
  const value = getComputedStyle(document.documentElement).getPropertyValue(varName).trim()
  return value || fallback
}
