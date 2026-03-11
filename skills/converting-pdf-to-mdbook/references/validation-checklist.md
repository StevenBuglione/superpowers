# Validation Checklist

A concrete, verifiable checklist the agent follows to verify conversion quality.
Run automated checks first, then agent-verified checks, and report results.

---

## Build Validation

- [ ] `mdbook build` completes with exit code 0
- [ ] No warnings in build output
- [ ] Generated `book/` directory contains index.html
- [ ] All chapter HTML files generated in book/

## Markdown Lint Validation

- [ ] `markdownlint-cli2` passes with skill config (`.markdownlint-cli2.yaml`)
- [ ] No heading level skips (MD001)
- [ ] Consistent list markers (MD004)
- [ ] No reversed or empty links (MD011, MD042)

## Structure Validation

- [ ] SUMMARY.md exists and is well-formed
- [ ] Every link in SUMMARY.md resolves to an existing .md file
- [ ] Every .md file in src/ (except SUMMARY.md) is referenced in SUMMARY.md
- [ ] Chapter files are named following convention: `chapter-NN-slug.md`
- [ ] Chapter ordering in SUMMARY.md matches original book order
- [ ] book.toml contains title, authors, and language

## Page Accountability Validation

- [ ] Every source page in the assigned range is represented exactly
  once with a page marker before chapter assembly begins
- [ ] Every page marker uses the required contract:
  `<!-- pdf-page: physical=42 printed=iii -->`
- [ ] Every page marker includes `physical=<number>`
- [ ] `printed=<label>` appears only when a visible printed page label
  exists on the source page
- [ ] `printed` values match the source exactly when present (including Roman
  numerals, prefixes, and punctuation)
- [ ] Physical page numbers are unique across the whole assigned range
- [ ] Physical page numbers are in strict ascending order across the whole assigned
  range
- [ ] Missing pages, duplicate markers, and out-of-order markers are explicitly
  detected and reconciled against the PDF before chapter boundaries are finalized
- [ ] Start page and end page for every assembled chapter reconcile
  cleanly with the verified whole-range page sequence

## Content Validation

- [ ] All chapters contain meaningful content (not empty or stub files)
- [ ] No text, headings, or illustrations from the assigned page range are missing
  after reconciliation
- [ ] Running headers/footers and other excluded artifacts are not
  mistaken for body content
- [ ] Chapter boundaries match the source book structure rather than arbitrary page
  slices

## Typography and Formatting

- [ ] Headings use proper hierarchy (H2 for chapters, H3 for sections, etc.)
- [ ] No raw vision-transcription artifacts (random characters, broken words mid-line)
- [ ] Special characters properly encoded (accented letters, symbols)
- [ ] Paragraphs separated by single blank lines
- [ ] No excessive whitespace or empty lines
- [ ] Block quotes used appropriately for quoted text

## Table and Structured Content Validation

- [ ] Pipe tables are used only for simple rectangular tables with unambiguous row
  and column structure
- [ ] HTML tables are used for complex, merged, multi-level, continued, or otherwise
  ambiguous table layouts
- [ ] No table headers, captions, legends, summaries, row groups, or notes were
  invented during transcription
- [ ] Continuation labels, repeated headers, legends, row groups, and notes are
  preserved exactly where the source shows them
- [ ] Pages containing structured content received a table-specialist re-read pass
  before chapter assembly

## Cross-Reference Validation

- [ ] Internal markdown links use correct relative paths
- [ ] Internal links point to existing headings (anchor targets exist)
- [ ] Footnotes are numbered sequentially within each chapter
- [ ] Every footnote reference has a corresponding definition
- [ ] Every footnote definition has at least one reference

## Vision Review Indicators

- [ ] `<!-- vision-uncertain: "word" -->` markers placed for uncertain readings
- [ ] Review uncertain markers - are they genuine uncertainties or false positives?
- [ ] Common vision-transcription confusions checked: l/1, O/0, rn/m, cl/d
- [ ] Foreign language text preserved accurately
- [ ] Numbers and dates verified against original where possible

## Completeness Check

- [ ] Total page count in metadata matches original PDF page count
- [ ] Table of Contents from original book matches SUMMARY.md structure
- [ ] No chapters or major sections missing compared to original ToC
- [ ] Front matter included (title, preface, introduction)
- [ ] Back matter included if present (appendix, index, bibliography)

---

## How to Use This Checklist

Copilot should:

1. Run `validate-mdbook.sh` for automated checks (build, lint, links)
2. Verify page accountability across the **entire assigned range**, not a sample
3. Detect and reconcile missing pages, duplicate markers, and out-of-order markers
   before assembling or reordering chapters
4. Re-read every page with structured content using the table rules above before
   final chapter assembly
5. Verify completeness by comparing SUMMARY.md against the original
   book's table of contents after page reconciliation is complete
6. Report any `<!-- vision-uncertain -->` markers for human review
7. If any check fails, fix the issue and re-validate the full affected range

**Automated checks** (run via validate-mdbook.sh): Build, Lint,
Structure, basic page metadata

**Agent-verified checks** (require reading/comparison): Whole-range
page accountability, Content, Typography, Tables, Cross-references, vision
quality, Completeness
