# mdBook Formatting Guide for Scanned PDF Conversion

> **Purpose:** This is the definitive formatting reference for converting scanned PDF books into mdBook-compatible Markdown. Follow every rule exactly — do not improvise formatting conventions.

---

## Heading Hierarchy

- **`#` (H1)** = Book parts (e.g., `# Part I: Morning Prayers`). Use **only** if the original book is divided into named parts. If the book has no parts, never use H1 inside chapter files.
- **`##` (H2)** = Chapter titles. Every chapter file begins with exactly one H2.
- **`###` (H3)** = Sections within a chapter.
- **`####` (H4)** = Subsections within a section.
- **Never skip heading levels.** Do not jump from H2 to H4. If the original book's visual hierarchy implies a skip, insert the intermediate level with an appropriate title.

---

## Page Metadata Convention

Mark every page boundary with an HTML comment so page coverage is explicit, auditable,
and recoverable from the Markdown source.

- Use this exact contract: `<!-- pdf-page: physical=42 printed=iii -->`
- `physical` is **required**. It records the PDF's physical page number and must
  appear on every page marker.
- `printed` is **optional**. Include it only when a printed page label
  is visible on the page, and preserve that label exactly as shown
  (`iii`, `42`, `A-12`, etc.).
- If no printed page label is visible, omit `printed` entirely:
  `<!-- pdf-page: physical=42 -->`
- Place the comment **before** the first content that appears on that physical page.
- If a paragraph spans a page break, place the comment at the closest natural break
  point between sentences or blocks. Never split a sentence with a page marker.
- Every physical page in scope must have exactly one corresponding page
  marker. These comments are the accountability contract used for
  validation and reconciliation.

**Example:**

```markdown
<!-- pdf-page: physical=7 printed=iii -->

Preface text from the printed front matter.

<!-- pdf-page: physical=42 -->

This is the content from physical PDF page 42, which has no visible printed number.

<!-- pdf-page: physical=43 printed=1 -->

Chapter 1 begins on the first printed page of the main text.
```

---

## Typography Rules

| Original                          | Markdown Output                        |
|-----------------------------------|----------------------------------------|
| Double hyphens (`--`)             | Em-dash (`—`)                          |
| Straight quotes (`"` `'`)        | Keep straight quotes (`"` `'`) for mdBook compatibility |
| Three dots (`...`)                | Ellipsis character (`…`)               |
| Accented characters (é, ñ, ü)    | Preserve faithfully — never strip diacritics |
| Small caps in original            | Regular case (no CSS hacks)            |
| ALL CAPS headers in original      | Title Case                             |

**Additional rules:**

- Never introduce typographic characters that mdBook cannot render. Straight quotes are the safe default.
- Preserve all ligatures, accented characters, and non-ASCII glyphs from the source text exactly as they appear.
- If the original uses a special character you cannot reproduce in UTF-8, insert `<!-- vision-uncertain: "description" -->` and use the closest equivalent.

---

## Front Matter Handling

| Original Element       | mdBook Treatment                                                                 |
|------------------------|----------------------------------------------------------------------------------|
| Title page             | Extract into `book.toml` metadata (`title`, `authors`). Optionally create a short `front-00-title.md` intro chapter. |
| Copyright page         | Include as a chapter (`front-01-copyright.md`) or embed in `book.toml` `description`. |
| Dedication             | Short separate chapter file (`front-02-dedication.md`).                          |
| Table of Contents      | Becomes `SUMMARY.md`. **Do NOT** include the TOC as a rendered chapter.          |
| Preface                | Separate chapter file (`front-03-preface.md`), listed in `SUMMARY.md` before main content. |
| Foreword               | Separate chapter file (`front-04-foreword.md`), listed in `SUMMARY.md` before main content. |
| Introduction           | Separate chapter file (`front-05-introduction.md`), listed in `SUMMARY.md` before main content. |

- Number front matter files in the order they appear in the original book.
- Adjust the numbering scheme (`front-NN-slug.md`) to match the actual front matter present — not every book has all of these.

---

## Back Matter Handling

| Original Element | mdBook Treatment                                                                 |
|------------------|----------------------------------------------------------------------------------|
| Appendices       | Separate chapter files (`back-01-appendix-a.md`, etc.), listed in `SUMMARY.md` after main content. |
| Bibliography     | Separate chapter file (`back-NN-bibliography.md`) with properly formatted citations. |
| Index            | Convert to a searchable chapter (`back-NN-index.md`). mdBook has built-in search, but a dedicated index chapter preserves the original structure and adds browsing value. |
| Glossary         | Separate chapter file (`back-NN-glossary.md`) using definition list formatting or bold-term paragraphs. |

---

## Chapter File Naming

Use this exact pattern: `chapter-NN-slug.md`

- `NN` = zero-padded chapter number (two digits minimum).
- `slug` = lowercase, hyphen-separated title derived from the chapter name.
- Keep slugs short but recognizable.

**Examples:**

| Chapter Title             | Filename                              |
|---------------------------|---------------------------------------|
| Morning Prayers           | `chapter-01-morning-prayers.md`       |
| Evening Devotions         | `chapter-02-evening-devotions.md`     |
| The Litany of the Saints  | `chapter-14-litany-of-the-saints.md`  |

**Front matter:** `front-NN-slug.md` (e.g., `front-01-preface.md`, `front-02-introduction.md`)

**Back matter:** `back-NN-slug.md` (e.g., `back-01-appendix-a.md`, `back-02-index.md`)

---

## SUMMARY.md Structure

The `SUMMARY.md` file defines the mdBook sidebar navigation. Follow this exact structure:

```markdown
# Summary

[Title Page](./front-00-title.md)
[Preface](./front-01-preface.md)

---

# Part I: Title

- [Chapter 1: Title](./chapter-01-slug.md)
  - [Section 1.1](./chapter-01-slug.md#section-slug)
- [Chapter 2: Title](./chapter-02-slug.md)

---

# Part II: Title

- [Chapter 3: Title](./chapter-03-slug.md)
- [Chapter 4: Title](./chapter-04-slug.md)

---

# Appendices

- [Appendix A: Title](./back-01-appendix-a.md)
- [Index](./back-02-index.md)
```

**Rules:**

- Items before the first `---` are prefix chapters (no numbering in sidebar).
- `---` creates a visual separator in the mdBook sidebar.
- `# Part Title` lines create named section headers in the sidebar.
- Use `- [Title](path)` for numbered sidebar entries.
- Indent with 2 spaces for sub-items (sections within chapters).
- If the book has no parts, omit the `# Part` headers and list chapters directly.

---

## Paragraph Formatting

- **One blank line** between every paragraph. No exceptions.
- **No indentation** on the first line of any paragraph. Markdown does not use first-line indentation.
- Preserve paragraph breaks exactly as they appear in the original. Do not merge or split paragraphs.
- Very short lines (poetry, prayers, litanies, responsive readings) → use a trailing backslash (`\`) at end of line or `<br>` for hard line breaks within a single block:

```markdown
Our Father, who art in heaven,\
hallowed be thy name;\
thy kingdom come,\
thy will be done\
on earth as it is in heaven.
```

- Alternatively, use blockquote syntax for set-apart poetic or liturgical text:

```markdown
> Our Father, who art in heaven,
> hallowed be thy name;
> thy kingdom come,
> thy will be done
> on earth as it is in heaven.
```

---

## Lists

- Use **`-`** (hyphen) for all unordered lists. Do not mix `-`, `*`, and `+`.
- Use **`1.`** for all ordered list items. Let Markdown auto-number — do not manually number (`1.`, `2.`, `3.`). Just use `1.` repeatedly.
- Indent nested lists by **2 spaces**.
- Preserve the original list structure. If the source uses numbered items, use an ordered list. If the source uses bullets or dashes, use an unordered list.

**Example:**

```markdown
- First item
  - Nested item
  - Another nested item
- Second item

1. First step
1. Second step
   1. Sub-step
1. Third step
```

---

## Tables

- Use Markdown pipe tables **only** for simple rectangular tables with
  clearly bounded rows and columns, no merged cells, no ambiguous
  header structure, and no continuation notes or layout dependencies.
- Use HTML `<table>` markup as the default for complex or ambiguous
  tables, including multi-row headers, merged cells, row groups,
  legends, continuation tables, notes, side labels, or any layout that
  cannot be represented faithfully in pipe-table syntax.
- Never invent headers, captions, column names, summaries, legends, notes, or row
  labels. Encode only what is present in the source.
- Preserve captions, continuation labels, repeated headers, legends, row
  groups, and table notes exactly as they appear in the source. If the
  table continues across pages, preserve that continuation explicitly
  rather than silently merging or normalizing it away.
- Keep page metadata comments at the true page boundaries even when a table spans
  pages.
- Any page with structured content that behaves like a table, matrix,
  calendar, ledger, or parallel-column form requires a dedicated
  table-specialist re-read pass before chapter assembly.

**Simple rectangular table → pipe table:**

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| data     | data     | data     |
```

**Complex table → HTML table:**

```markdown
<table>
  <caption>Table 2. Daily Offices</caption>
  <thead>
    <tr>
      <th rowspan="2">Season</th>
      <th colspan="2">Office</th>
    </tr>
    <tr>
      <th>Morning</th>
      <th>Evening</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Advent</th>
      <td>Matins</td>
      <td>Vespers</td>
    </tr>
  </tbody>
</table>
```

---

## Footnotes

- Use Markdown footnote syntax: `text[^1]` in the body, with `[^1]: Footnote content.` collected at the **end of the chapter file**.
- Number footnotes **sequentially within each chapter**, restarting at `[^1]` for every new chapter file.
- Convert original footnote markers (*, †, ‡, §) to numbered footnotes.
- If a footnote spans multiple paragraphs, indent continuation lines by 4 spaces:

```markdown
[^1]: First paragraph of the footnote.

    Second paragraph of the footnote, indented by 4 spaces.
```

---

## Cross-References

- **Internal chapter links:** `[Chapter Title](./chapter-NN-slug.md)`
- **Internal section links:** `[Section Title](./chapter-NN-slug.md#heading-slug)` where `heading-slug` is the lowercase, hyphenated heading text.
- **"See page X" references:** Convert to `[relevant text](./chapter-NN-slug.md#closest-heading)`. Find the nearest heading to the referenced page and link to that.
- **Dead references** (pointing to content not included in the conversion): Leave as plain text and append a comment: `<!-- reference-unresolved: "original reference text" -->`.

---

## Block Quotes and Special Text

- **Quoted passages** → Standard blockquote syntax:

  ```markdown
  > This is a quoted passage from another source.
  ```

- **Prayers, verses, poetry** → Use blockquote or trailing backslash line breaks. Choose one style per book and be consistent.

- **Latin or foreign language text** → Preserve the original text exactly. Wrap in *italic* emphasis to visually distinguish it:

  ```markdown
  *Pater noster, qui es in caelis, sanctificetur nomen tuum.*
  ```

- **Rubrics and liturgical instructions** → Use *italic* to distinguish from the main text:

  ```markdown
  *The priest then says:*

  The Lord be with you.
  ```

- **Bold emphasis** → Use only where the original uses bold or where a rubric heading requires strong distinction.

---

## Vision Uncertainty Markers

When the AI vision model is uncertain about a word or passage, mark it immediately after the uncertain text:

```markdown
The rubrical<!-- vision-uncertain: "rubrical" --> directions indicate…
```

**Rules:**

- Place `<!-- vision-uncertain: "word" -->` directly after the uncertain word with no space before the comment.
- These comments are invisible in rendered output but flagged for human review.
- Use liberally — it is better to over-flag than to silently introduce errors.

**Common vision-transcription confusion pairs to watch for:**

| Often Confused | With    |
|----------------|---------|
| `l` (ell)      | `1` (one) |
| `O` (letter)   | `0` (zero) |
| `rn`           | `m`     |
| `cl`           | `d`     |
| `fi` / `fl`    | ligature misreads |
| `é`            | `e` (stripped accent) |
| `ff`           | `fl` or single `f` |

---

## What NOT to Include

Strip all of the following from the converted output:

- **Running headers/footers** — page titles repeated at the top or bottom of every page.
- **Page numbers in text** — these are captured by `<!-- pdf-page: physical=42 printed=iii -->`
  comments instead.
- **Decorative horizontal rules** — ornamental dividers that carry no structural meaning.
- **Publisher advertisements** — promotional pages for other books.
- **Library stamps or markings** — "Property of…", barcodes, catalog numbers.
- **Scanning artifacts** — bleed-through text, skewed margins, dust specks.
- **Blank pages** — "This page intentionally left blank" or truly empty pages.

---

## General Principles

1. **Faithfulness over aesthetics.** The goal is an accurate transcription, not a redesign. Preserve the author's structure, wording, and intent.
2. **Consistency over local optimization.** Pick one convention and apply it everywhere. Do not switch styles mid-book.
3. **Machine-readability matters.** The page comments, uncertainty markers, and clean heading hierarchy exist so tooling can process this output programmatically.
4. **When in doubt, preserve.** If you are unsure whether to include or exclude something, include it and flag it with a comment.
