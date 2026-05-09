/**
 * i18n style linter for translated docs.
 *
 * Detects content-level anti-patterns (not structural drift — see i18n-drift.ts
 * for that) that violate the oma-translator skill's mechanical-checks rules.
 *
 * Currently checks:
 * - cjk-em-dash: em-dash (—) usage in CJK targets (ko/ja/zh) outside code
 *   blocks. Per oma-translator/SKILL.md § Stage 4-A, em-dashes in CJK should
 *   be structurally restructured into separate clauses, parentheses, or
 *   coordinated noun phrases — never used as direct substitution from English.
 *
 * The CLI never auto-fixes; it only reports. The host LLM (oma-translator
 * runtime) consumes the issue list and applies restructuring.
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";

export type I18nStyleRule = "cjk-em-dash";

export interface I18nStyleIssue {
  file: string;
  lang: string;
  line: number;
  rule: I18nStyleRule;
  match: string;
}

export interface LintI18nOptions {
  repoRoot: string;
  i18nDir?: string;
  i18nDocsSubpath?: string;
  cjkLocales?: string[];
  rules?: I18nStyleRule[];
}

const DEFAULT_CJK_LOCALES = ["ko", "ja", "zh"];
const DEFAULT_RULES: I18nStyleRule[] = ["cjk-em-dash"];
const EM_DASH = "—";

function findMarkdownFiles(
  root: string,
  results: string[] = [],
  base = root,
): string[] {
  if (!existsSync(root)) return results;
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const full = join(root, entry.name);
    if (entry.isDirectory()) {
      findMarkdownFiles(full, results, base);
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      results.push(relative(base, full));
    }
  }
  return results;
}

/**
 * Strip fenced code blocks from text so em-dash inside code (e.g., flag
 * descriptions, regex examples) doesn't trigger the rule.
 *
 * Returns the stripped text with the same line count (code-block lines
 * become empty), so reported line numbers remain accurate.
 */
function stripCodeBlocks(text: string): string {
  const lines = text.split("\n");
  let inFence = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
      lines[i] = "";
      continue;
    }
    if (inFence) {
      lines[i] = "";
      continue;
    }
    // Strip inline code spans (`...`) on the line
    lines[i] = line.replace(/`[^`\n]+`/g, "");
  }
  return lines.join("\n");
}

function checkCjkEmDash(
  fileRel: string,
  lang: string,
  text: string,
): I18nStyleIssue[] {
  const issues: I18nStyleIssue[] = [];
  const stripped = stripCodeBlocks(text);
  const lines = stripped.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (!line.includes(EM_DASH)) continue;
    issues.push({
      file: fileRel,
      lang,
      line: i + 1,
      rule: "cjk-em-dash",
      match: line.trim().slice(0, 120),
    });
  }
  return issues;
}

export function lintI18nStyle(opts: LintI18nOptions): I18nStyleIssue[] {
  const i18nDir = opts.i18nDir ?? "web/i18n";
  const subpath =
    opts.i18nDocsSubpath ?? "docusaurus-plugin-content-docs/current";
  const cjk = opts.cjkLocales ?? DEFAULT_CJK_LOCALES;
  const rules = opts.rules ?? DEFAULT_RULES;

  const issues: I18nStyleIssue[] = [];
  for (const lang of cjk) {
    const langRoot = join(opts.repoRoot, i18nDir, lang, subpath);
    if (!existsSync(langRoot)) continue;
    const files = findMarkdownFiles(langRoot);
    for (const rel of files) {
      const abs = join(langRoot, rel);
      const text = readFileSync(abs, "utf-8");
      const fileRel = join(i18nDir, lang, subpath, rel);
      if (rules.includes("cjk-em-dash")) {
        issues.push(...checkCjkEmDash(fileRel, lang, text));
      }
    }
  }
  return issues;
}

export function summarizeStyleIssues(issues: I18nStyleIssue[]): {
  total: number;
  byRule: Record<I18nStyleRule, number>;
  byLang: Record<string, number>;
  byFile: Array<{ file: string; lang: string; count: number }>;
} {
  const byRule: Record<I18nStyleRule, number> = { "cjk-em-dash": 0 };
  const byLang: Record<string, number> = {};
  const fileCounts = new Map<string, { lang: string; count: number }>();
  for (const i of issues) {
    byRule[i.rule]++;
    byLang[i.lang] = (byLang[i.lang] ?? 0) + 1;
    const cur = fileCounts.get(i.file);
    if (cur) {
      cur.count++;
    } else {
      fileCounts.set(i.file, { lang: i.lang, count: 1 });
    }
  }
  const byFile = Array.from(fileCounts.entries())
    .map(([file, { lang, count }]) => ({ file, lang, count }))
    .sort((a, b) => b.count - a.count);
  return { total: issues.length, byRule, byLang, byFile };
}
