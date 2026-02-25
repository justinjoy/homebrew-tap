# Work Plan: README.md Documentation for homebrew-tap

**Date:** 2026-02-25
**Status:** Revision 3 -- addressing Critic CONDITIONAL APPROVE feedback (Issues #1, #2)
**Scope:** Single file (`README.md`) update
**Complexity:** LOW
**Repository:** https://github.com/justinjoy/homebrew-tap.git

**Dependency:** This plan MUST be executed AFTER the `differential-dogs3-formula` plan is complete. The Usage section (Step 3) references C header files and pkg-config integration that only exist after the formula is rewritten to use `cargo-c`. If the formula rewrite is not yet done, the executor must use the "Current Formula" variant of Step 3 instead.

---

## Context

The `justinjoy/homebrew-tap` repository contains one formula: `differential-dogs3` (a C library for differential-dogs3 join operators, built with Rust/Cargo, version 0.19.1, MIT license). The current `README.md` is a generic Homebrew tap template with `<formula>` placeholders and no formula-specific information. It needs to be replaced with concrete, user-friendly documentation.

**Current README.md contents (345 bytes):**
- Generic title "Justinjoy Tap"
- Placeholder install commands with `<formula>`
- Link to Homebrew docs

**Target audience:** Homebrew users who want to install and use `differential-dogs3`.

**Two formula states to account for:**

| State | Build Tool | Installs Headers | Installs pkg-config | C Linking |
|-------|-----------|-----------------|--------------------|-----------|
| Current formula (`cargo build`) | `cargo build --release` | No | No | Not directly supported |
| Future formula (`cargo-c`) | `cargo cinstall` | Yes (`differential_dogs3.h`) | Yes (`.pc` file) | Fully supported via `-I`/`-L`/`-l` flags |

The README should be written for the **future formula** state, since the formula rewrite plan (`differential-dogs3-formula.md`) is a prerequisite. However, see Guardrails for handling the case where execution order is reversed.

---

## Work Objectives

1. Replace the generic template README with documentation specific to `differential-dogs3`
2. Provide clear, copy-pasteable install commands
3. Include a Requirements section for prerequisites
4. Include a formula table for discoverability and future extensibility
5. Cover usage scenarios with **verified** C compiler examples (not untested rustc examples)
6. Help users troubleshoot common issues, including "empty lib directory"

---

## Guardrails

### Must Have
- All install commands must be tested/valid Homebrew syntax
- Markdown must render correctly on GitHub
- Include the formula description, version, and license info from the formula file
- Preserve the `brew bundle` / `Brewfile` usage pattern from the original template
- Use fenced code blocks with language identifiers (`bash`, `ruby`, `c`) for syntax highlighting
- Linking examples must use C compiler (`cc`) not `rustc` -- referencing the verified pattern from `differential-dogs3-formula.md` Section 5

### Must NOT Have
- Broken or untested commands
- References to formulas that do not exist in the tap
- Generic `<formula>` placeholders (replace all with actual formula name)
- Implementation details about the formula internals (keep it user-focused)
- Untested `rustc` linking examples (the previous plan had a `rustc -L ... -l` example that was never validated)
- Inline code (backtick) where fenced code blocks (triple backtick) are more appropriate for multi-line commands

---

## Task Flow

```
[Step 1: Header, Introduction & Formula Table]
       |
       v
[Step 1.5: Requirements Section]
       |
       v
[Step 2: Installation Section]
       |
       v
[Step 3: Usage Examples (C compiler based)]
       |
       v
[Step 4: Troubleshooting & Additional Info]
```

---

## Detailed TODOs

### Step 1: Header, Introduction, and Formula Table

Replace the generic "Justinjoy Tap" header with a descriptive project header and add a formula table.

**Content to include:**
- Repository title: `homebrew-tap`
- One-line description: custom Homebrew tap for `differential-dogs3`
- Brief description of what `differential-dogs3` is (C library for differential-dogs3 join operators, from TimelyDataflow/differential-dataflow)
- Badge or link to the upstream project: https://github.com/TimelyDataflow/differential-dataflow

**Formula table (new -- Critic item #4):**

```markdown
## Available Formulae

| Formula | Version | Description |
|---------|---------|-------------|
| `differential-dogs3` | 0.19.1 | C library for the differential-dogs3 join operators |
```

This table provides discoverability and is structured to accommodate future additions to the tap without restructuring the README.

**Acceptance Criteria:**
- [ ] Title clearly identifies the repository purpose
- [ ] Description explains what `differential-dogs3` is in 1-2 sentences
- [ ] Link to upstream project is present and correct
- [ ] Formula table lists `differential-dogs3` with version and description
- [ ] Table structure allows easy addition of future formulas

---

### Step 1.5: Requirements Section (NEW -- Critic item #5)

Add a Requirements section between the introduction and installation instructions.

**Content to include:**

```markdown
## Requirements

- **macOS** (primary) or **Linux**
- **Homebrew** -- see [installation instructions](https://brew.sh)
- **Xcode Command Line Tools** (macOS) -- `xcode-select --install`
```

**Notes:**
- `rust` is a build dependency handled automatically by Homebrew during installation; it does not need to be listed as a user-facing requirement
- Xcode CLT is required on macOS for the C toolchain (needed both for building and for linking against the installed library)

**Acceptance Criteria:**
- [ ] Requirements section is present between introduction and installation
- [ ] Lists macOS/Linux, Homebrew, and Xcode CLT
- [ ] Does not list `rust` as a user requirement (it is a build dep managed by Homebrew)
- [ ] Xcode CLT entry includes the install command

---

### Step 2: Installation Section with Multiple Methods

Provide three installation methods, all using the actual formula name `differential-dogs3`.

**Content to include:**

**Method 1 -- Direct install (one-liner):**
```bash
brew install justinjoy/tap/differential-dogs3
```

**Method 2 -- Tap then install (two-step):**
```bash
brew tap justinjoy/tap
brew install differential-dogs3
```

**Method 3 -- Brewfile (for `brew bundle` users):**
```ruby
tap "justinjoy/tap"
brew "differential-dogs3"
```

**Build dependency note:** Mention that `rust` and `cargo-c` are required as build dependencies and Homebrew will handle this automatically.

**Markdown formatting note (Critic item #2e):** All multi-line command blocks must use fenced code blocks with language identifiers (` ```bash `, ` ```ruby `) rather than inline backticks. Single inline commands within prose (e.g., "run `brew update`") may use backticks.

**Acceptance Criteria:**
- [ ] All three installation methods are present with correct syntax
- [ ] No `<formula>` placeholders remain
- [ ] Build dependencies (rust, cargo-c) are mentioned as automatically handled
- [ ] Each method has a brief explanation of when to use it
- [ ] All code blocks use fenced syntax with language identifiers

---

### Step 3: Usage Examples (Revised -- Critic items #2a, #3)

Provide practical examples of how to use the installed library. The linking examples must use the **C compiler pattern verified in the formula plan** (Section 5 of `differential-dogs3-formula.md`), not the untested `rustc` example from the previous plan revision.

**IMPORTANT -- Formula dependency gate:**
- If the formula rewrite (cargo-c) is complete: use the "Future Formula" variant below (headers + pkg-config)
- If the formula rewrite is NOT yet complete: use the "Current Formula" variant (library files only)
- The executor should check which variant applies at execution time

**Future Formula variant (post cargo-c rewrite -- preferred):**

- Verify installation:
  ```bash
  brew info justinjoy/tap/differential-dogs3
  ```

- Installed files overview:
  ```bash
  ls $(brew --prefix differential-dogs3)/include/
  # Expected: differential_dogs3.h
  ls $(brew --prefix differential-dogs3)/lib/
  # Expected: libdifferential_dogs3.dylib (macOS) or .so (Linux), plus .a (static)
  ls $(brew --prefix differential-dogs3)/lib/pkgconfig/
  # Expected: differential_dogs3.pc
  ```

- C compiler linking example (from formula plan Section 5 -- verified):
  ```bash
  cc -I$(brew --prefix differential-dogs3)/include \
     -L$(brew --prefix differential-dogs3)/lib \
     -ldifferential_dogs3 \
     test.c -o test
  ```

- pkg-config alternative:
  ```bash
  cc $(pkg-config --cflags --libs differential_dogs3) test.c -o test
  ```

**For Rust Projects (Alternative Consumption Path):**

  This subsection covers consuming `differential-dogs3` as a Rust crate dependency -- a fundamentally different path from the C library installed by Homebrew above. Rust projects typically depend on the crate directly via Cargo rather than linking the Homebrew-installed C library.

  **Executor prerequisite:** Before including this section in the README, verify whether `differential-dogs3` is published on crates.io by checking https://crates.io/crates/differential-dogs3. This is flagged in `open-questions.md`.

  - **If published on crates.io:**
    ```toml
    [dependencies]
    differential-dogs3 = "0.19.1"
    ```

  - **If NOT published on crates.io (git dependency fallback):**
    ```toml
    [dependencies]
    differential-dogs3 = { git = "https://github.com/TimelyDataflow/differential-dataflow", tag = "differential-dogs3-v0.19.1" }
    ```

  Include a note in the README clarifying: "This is a Rust crate dependency managed by Cargo, separate from the Homebrew C library installation above. Use this if your project is written in Rust and you want to consume the library natively through Cargo rather than via C FFI."

- Upgrade command:
  ```bash
  brew upgrade differential-dogs3
  ```

- Uninstall command:
  ```bash
  brew uninstall differential-dogs3
  ```

**Current Formula variant (pre cargo-c rewrite -- fallback):**

If the formula rewrite has not been completed yet, omit the header and pkg-config examples. Replace the linking section with:

- Library file location:
  ```bash
  ls $(brew --prefix differential-dogs3)/lib/
  # Expected: libdifferential_dogs3.dylib (macOS) or .so (Linux), plus .a (static)
  ```

- Note that headers are not yet available; direct C FFI usage requires the formula to be updated to the cargo-c build.

**Acceptance Criteria:**
- [ ] At least 4 usage examples are provided
- [ ] Library path discovery command is included
- [ ] Both macOS (.dylib) and Linux (.so) library extensions are mentioned
- [ ] C compiler linking example uses `cc` (not `rustc`) with `-I`, `-L`, `-l` flags
- [ ] pkg-config example is included (future variant only)
- [ ] Header file location is documented (future variant only)
- [ ] All code blocks use fenced syntax with language identifiers (`bash`, `toml`)
- [ ] Cargo.toml example is in a clearly separated "For Rust Projects (Alternative)" subsection
- [ ] Cargo.toml subsection explicitly states this is a different consumption path from the Homebrew C library
- [ ] Executor has verified crates.io availability before choosing the crate version or git dependency variant

---

### Step 4: Troubleshooting and Additional Information (Revised -- Critic item #2d)

Add a troubleshooting section and footer with helpful links.

**Content to include:**

**Troubleshooting items:**

1. "Rust not found" -- explain that `brew install rust` resolves this, or that Homebrew installs it automatically as a dependency

2. "Library not found at link time" -- show how to find the correct lib path with `brew --prefix`:
   ```bash
   export LIBRARY_PATH="$(brew --prefix differential-dogs3)/lib:$LIBRARY_PATH"
   export C_INCLUDE_PATH="$(brew --prefix differential-dogs3)/include:$C_INCLUDE_PATH"
   ```

3. "Formula outdated" -- `brew update && brew upgrade differential-dogs3`

4. **"Empty lib directory" (NEW -- Critic item #2d):** After installation, if `ls $(brew --prefix differential-dogs3)/lib/` shows no `.dylib` or `.so` files, this indicates a build failure that was silently ignored. Solutions:
   - Reinstall from source with verbose output to see where it fails:
     ```bash
     brew reinstall --build-from-source --verbose --debug differential-dogs3
     ```
   - Check the build log directory for details:
     ```bash
     ls ~/Library/Logs/Homebrew/differential-dogs3/
     ```
     (On Linux, check `~/.cache/Homebrew/Logs/differential-dogs3/` instead.)
   - Ensure Xcode CLT is installed: `xcode-select --install`
   - If the issue persists, file an issue (link below)

**Additional info:**
- License: MIT
- Upstream source: link to TimelyDataflow/differential-dataflow
- How to report issues: link to https://github.com/justinjoy/homebrew-tap/issues
- Link to Homebrew documentation: https://docs.brew.sh

**Acceptance Criteria:**
- [ ] At least 3 troubleshooting items with solutions (minimum: Rust not found, Library not found, Empty lib directory)
- [ ] "Empty lib directory" troubleshooting case is present with actionable steps
- [ ] License is stated
- [ ] Issue reporting link is present
- [ ] Homebrew docs link is preserved from original README

---

## Success Criteria

1. README.md contains zero `<formula>` placeholders
2. All `brew` commands in the README are syntactically correct and use `differential-dogs3`
3. A new user can follow the README from top to bottom and successfully install the library
4. The document renders correctly as GitHub-flavored Markdown
5. The README covers: introduction, formula table, requirements, installation (3 methods), usage examples, and troubleshooting
6. All fenced code blocks have language identifiers for syntax highlighting
7. Linking examples use `cc` (C compiler), not `rustc`, matching the verified pattern from the formula plan
8. The formula table is structured for future extensibility

---

## Revision Changelog

### Revision 2 (2026-02-25) -- Critic REJECT response

| # | Critic Item | Resolution |
|---|-------------|------------|
| 1 | README plan depends on formula rewrite but does not declare it | Added explicit **Dependency** statement in plan header. Added "formula dependency gate" in Step 3 with two variants (future/current). Added formula state comparison table in Context. |
| 2a | Usage section linking example needs verification | Replaced untested `rustc` example with verified C compiler (`cc`) example from formula plan Section 5. |
| 2b | Requirements section missing | Added **Step 1.5: Requirements Section** with macOS/Linux, Homebrew, and Xcode CLT. |
| 2c | Formula table missing for discoverability | Added formula table to **Step 1** with version and description columns. |
| 2d | Troubleshooting missing "Empty lib directory" case | Added as item #4 in **Step 4** with reinstall, log check, and Xcode CLT solutions. |
| 2e | Markdown syntax: fenced code blocks with language identifiers | Added formatting note in Step 2 guardrail. Updated all examples to use ` ```bash ` / ` ```ruby ` / ` ```toml ` / ` ```c `. Added Success Criterion #6. |
| 3 | Linking example used untested rustc pattern | C compiler example (`cc -I... -L... -l...`) now references formula plan Section 5 verified pattern. Added pkg-config alternative. Added Cargo.toml dependency example for Rust consumers. |
| 4 | No formula table for tap discoverability | Formula table added in Step 1 with extensible structure (version + description columns). |
| 5 | No Requirements section | Step 1.5 added between introduction and installation. Lists OS, Homebrew, Xcode CLT. Explicitly notes `rust` is NOT a user requirement. |

### Revision 3 (2026-02-25) -- Critic CONDITIONAL APPROVE response

| # | Critic Issue | Resolution |
|---|-------------|------------|
| 1 (mandatory) | `brew log differential-dogs3` is incorrect -- shows git history, not build logs | Replaced with two correct commands: `brew reinstall --build-from-source --verbose --debug differential-dogs3` for verbose rebuild, and `ls ~/Library/Logs/Homebrew/differential-dogs3/` for checking build log directory. Added Linux path variant. |
| 2 (mandatory) | Cargo.toml example is ambiguous -- crates.io status unknown, not clearly framed as alternative to Homebrew C library | Restructured into a dedicated "For Rust Projects (Alternative Consumption Path)" subsection. Added executor prerequisite to verify crates.io availability. Provided both crate version and git dependency fallback variants. Added explicit note distinguishing this from the Homebrew C library path. Added 3 new acceptance criteria to Step 3. |
| 3 (recommended) | Formula table version maintenance note | Acknowledged; no change required per Critic (optional). Already tracked in `open-questions.md`. |
