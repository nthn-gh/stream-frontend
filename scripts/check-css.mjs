#!/usr/bin/env node
// Guards the deploy against silently broken CSS. Dependency-free.
//
// Why: a "*/" inside a CSS comment (for example "p-*/m-*") ends the comment early and the rest of the
// text becomes garbage CSS. Twice that silently broke the production body rule; type-check does not see
// it and `vite build` still exits 0. This script fails on:
//   (a) source: every src/**/*.css, every <style> block in src/**/*.vue and in index.html is scanned for
//       a "*/" outside a comment, a "/*" inside a comment, an unterminated comment, a "/*" vs "*/" count
//       mismatch, and non-CSS text left on the line after a comment closes;
//   (b) build: `vite build` is run into a temporary directory and the script fails if the build exits
//       non-zero or prints a CSS warning line.
//
// Usage: node scripts/check-css.mjs [--root <dir>] [--skip-build]
//   --root        project to check (default: the current directory)
//   --skip-build  source scan only (no vite build)

import { spawnSync } from 'node:child_process'
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, relative, resolve } from 'node:path'

const args = process.argv.slice(2)
const rootIndex = args.indexOf('--root')
const root = resolve(rootIndex >= 0 ? args[rootIndex + 1] : process.cwd())
const skipBuild = args.includes('--skip-build')

// ---------------------------------------------------------------- (a) source scan

/** Returns { problems: [{ line, message }], opens, closes } for one piece of CSS; line numbers start at `firstLine`. */
function scanCss(text, firstLine = 1) {
  const problems = []
  let line = firstLine
  let inComment = false
  let commentLine = firstLine
  let opens = 0
  let closes = 0
  let i = 0

  while (i < text.length) {
    const c = text[i]
    const next = text[i + 1]

    if (inComment) {
      if (c === '*' && next === '/') {
        inComment = false
        closes++
        i += 2
        const eol = text.indexOf('\n', i)
        const trailing = text.slice(i, eol === -1 ? text.length : eol).trim()
        if (trailing !== '' && !trailing.startsWith('/*') && !/[{};,]$/.test(trailing) && !/[{}]/.test(trailing)) {
          problems.push({
            line,
            message: `text after the end of a comment that does not look like CSS: "${trailing.slice(0, 60)}" (a "*/" inside the comment ended it early?)`,
          })
        }
        continue
      }
      if (c === '/' && next === '*') {
        opens++
        problems.push({ line, message: 'a "/*" inside a comment (CSS comments do not nest)' })
        i += 2
        continue
      }
      if (c === '\n') line++
      i++
      continue
    }

    if (c === '\n') {
      line++
      i++
    } else if (c === '"' || c === "'") {
      i++
      while (i < text.length && text[i] !== c && text[i] !== '\n') i += text[i] === '\\' ? 2 : 1
      i++
    } else if (c === '/' && next === '*') {
      inComment = true
      commentLine = line
      opens++
      i += 2
    } else if (c === '*' && next === '/') {
      closes++
      problems.push({ line, message: 'a "*/" outside a comment (an earlier "*/" closed the comment early)' })
      i += 2
    } else {
      i++
    }
  }

  if (inComment) problems.push({ line: commentLine, message: 'a comment that is never closed' })
  if (opens !== closes) problems.push({ line: firstLine, message: `${opens} "/*" but ${closes} "*/" in this block` })
  return { problems, opens, closes }
}

function walk(dir, found = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name)
    if (statSync(path).isDirectory()) walk(path, found)
    else found.push(path)
  }
  return found
}

/** Every CSS source in the project as { file, text, firstLine }. */
function cssSources() {
  const sources = []
  const srcDir = join(root, 'src')
  const files = existsSync(srcDir) ? walk(srcDir) : []
  const indexHtml = join(root, 'index.html')
  if (existsSync(indexHtml)) files.push(indexHtml)

  for (const file of files) {
    if (file.endsWith('.css')) {
      sources.push({ file, text: readFileSync(file, 'utf8'), firstLine: 1 })
    } else if (file.endsWith('.vue') || file.endsWith('.html')) {
      const text = readFileSync(file, 'utf8')
      for (const match of text.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi)) {
        const bodyStart = match.index + match[0].indexOf('>') + 1
        const firstLine = text.slice(0, bodyStart).split('\n').length
        sources.push({ file, text: match[1], firstLine })
      }
    }
  }
  return sources
}

function checkSources() {
  const failures = []
  const sources = cssSources()
  for (const { file, text, firstLine } of sources) {
    for (const p of scanCss(text, firstLine).problems) {
      failures.push(`${relative(root, file).replaceAll('\\', '/')}:${p.line}: ${p.message}`)
    }
  }
  console.log(`check:css source scan: ${sources.length} CSS block(s) in ${new Set(sources.map((s) => s.file)).size} file(s)`)
  return failures
}

// ---------------------------------------------------------------- (b) build output

const CSS_WARNING = [
  /minifying css/i,
  /css-syntax-error/i,
  /\[vite:css/i,
  /\[postcss\]/i,
  /CssSyntaxError/,
  /\[WARNING\].*\bcss\b/i,
  /\.css\b.*\b(warn|warning|error)\b/i,
  /\b(warn|warning|error)\b.*\.css\b/i,
]

function checkBuild() {
  const failures = []
  const viteBin = join(root, 'node_modules', 'vite', 'bin', 'vite.js')
  if (!existsSync(viteBin)) return [`cannot find ${relative(root, viteBin)}; run npm ci first`]

  const outDir = mkdtempSync(join(tmpdir(), 'check-css-'))
  try {
    const result = spawnSync(process.execPath, [viteBin, 'build', '--outDir', outDir, '--emptyOutDir'], {
      cwd: root,
      encoding: 'utf8',
      maxBuffer: 64 * 1024 * 1024,
    })
    const output = `${result.stdout ?? ''}\n${result.stderr ?? ''}`
    const cssLines = output.split(/\r?\n/).filter((l) => CSS_WARNING.some((re) => re.test(l)))
    console.log(`check:css build: vite build exited ${result.status}, ${cssLines.length} CSS warning line(s)`)
    if (result.status !== 0) failures.push(`vite build failed (exit ${result.status}):\n${output.split(/\r?\n/).slice(-15).join('\n')}`)
    for (const l of cssLines) failures.push(`build output: ${l.trim()}`)
  } finally {
    rmSync(outDir, { recursive: true, force: true })
  }
  return failures
}

// ---------------------------------------------------------------- run

const failures = [...checkSources(), ...(skipBuild ? [] : checkBuild())]
if (failures.length > 0) {
  console.error(`\ncheck:css FAILED (${failures.length}):`)
  for (const f of failures) console.error(`  - ${f}`)
  process.exit(1)
}
console.log('check:css passed')
