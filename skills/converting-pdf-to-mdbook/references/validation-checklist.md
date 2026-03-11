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

## Content Validation

- [ ] All chapters contain meaningful content (not empty or stub files)
- [ ] Page metadata comments (`<!-- pdf-page: N -->`) are present in every chapter
- [ ] Page numbers are sequential within each file
- [ ] Page numbers don't have gaps across files (unless pages were intentionally skipped)
- [ ] First page number in each chapter follows last page number of previous chapter

## Typography and Formatting

- [ ] Headings use proper hierarchy (H2 for chapters, H3 for sections, etc.)
- [ ] No raw OCR artifacts (random characters, broken words mid-line)
- [ ] Special characters properly encoded (accented letters, symbols)
- [ ] Paragraphs separated by single blank lines
- [ ] No excessive whitespace or empty lines
- [ ] Block quotes used appropriately for quoted text

## Cross-Reference Validation

- [ ] Internal markdown links use correct relative paths
- [ ] Internal links point to existing headings (anchor targets exist)
- [ ] Footnotes are numbered sequentially within each chapter
- [ ] Every footnote reference has a corresponding definition
- [ ] Every footnote definition has at least one reference

## OCR Quality Indicators

- [ ] `<!-- ocr-uncertain: "word" -->` markers placed for uncertain readings
- [ ] Review uncertain markers - are they genuine uncertainties or false positives?
- [ ] Common OCR confusions checked: l/1, O/0, rn/m, cl/d
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

The agent should:

1. Run `validate-mdbook.sh` for automated checks (build, lint, links)
2. Manually verify content checks by sampling 3-5 chapters
3. Verify completeness by comparing SUMMARY.md against original book's table of contents
4. Report any `<!-- ocr-uncertain -->` markers for human review
5. If any check fails, fix the issue and re-validate

**Automated checks** (run via validate-mdbook.sh): Build, Lint, Structure, Page metadata

**Agent-verified checks** (require reading/comparison): Content, Typography, Cross-references, OCR quality, Completeness
