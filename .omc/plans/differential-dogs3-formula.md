# Work Plan: differential-dogs3 Homebrew Formula

**Date:** 2026-02-24
**Status:** Draft (Revision 1 -- addressing Architect/Critic feedback)
**Scope:** Rewrite the existing formula skeleton into a working Homebrew formula that builds the `differential-dogs3` Rust crate as a C-compatible shared library accessible via FFI.
**Platform assumption:** This tap targets **macOS** as the primary platform. Linux compatibility (`.so` vs `.dylib`) is noted where relevant but is not a blocking requirement for v1.

---

## 1. Requirements Summary

### What We Are Building

A Homebrew formula at `/opt/homebrew/Library/Taps/justinjoy/homebrew-tap/Formula/differential-dogs3.rb` that:

1. Downloads the `differential-dogs3` v0.19.1 source from the TimelyDataflow/differential-dataflow monorepo
2. Builds the `dogsdogsdogs` Rust crate as a C-compatible shared library (`.dylib` on macOS, `.so` on Linux)
3. Generates a C header file via `cbindgen` for FFI consumers
4. Installs headers, static library (`.a`), shared library, and a `pkg-config` `.pc` file
5. Enables other C programs/libraries to link against the library via standard C toolchain patterns

### Critical Context

- **The upstream project is pure Rust** with zero existing C FFI bindings. The `dogsdogsdogs` crate exports Rust traits and generics (`PrefixExtender<G, R>`, `CollectionIndex<K, V, T, R>`) that are NOT directly C-compatible.
- **This means a C FFI shim layer must be authored.** The Rust generics and trait-based API cannot be directly exported to C. A `capi` module with `extern "C"` functions wrapping concrete instantiations of the Rust API must be created.
- The existing formula file is a **generated template** with a non-functional `./configure` call. It must be completely rewritten.
- The monorepo uses a Cargo workspace; the build must target the `dogsdogsdogs` subdirectory.
- **The upstream `dogsdogsdogs` package version is `0.19.1`** (confirmed from `Cargo.toml`), matching the tag `differential-dogs3-v0.19.1`.

---

## 2. Formula Structure

### File Path

```
/opt/homebrew/Library/Taps/justinjoy/homebrew-tap/Formula/differential-dogs3.rb
```

### Ruby Class Structure (Target Pattern)

Based on the proven `rustls-ffi` and `zlib-rs` patterns from homebrew-core:

```ruby
class DifferentialDogs3 < Formula
  desc "C library for the differential-dogs3 join operators"
  homepage "https://github.com/TimelyDataflow/differential-dataflow"
  url "https://github.com/TimelyDataflow/differential-dataflow/archive/refs/tags/differential-dogs3-v0.19.1.tar.gz"
  sha256 "f8ded99eada449a1de19773597b9bd4fdf0995fb3185b293c80b9b6396b686ba"
  license "MIT"

  livecheck do
    url :stable
    regex(/differential-dogs3-v(\d+(?:\.\d+)+)/i)
  end

  depends_on "cargo-c" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  patch :DATA

  def install
    cd "dogsdogsdogs" do
      system "cargo", "cinstall", "--jobs", ENV.make_jobs.to_s,
             "--prefix", prefix, "--libdir", lib, "--release"
    end
  end

  test do
    (testpath/"test_dogs3.c").write <<~C
      #include "differential_dogs3.h"
      #include <stdio.h>
      #include <string.h>
      int main(void) {
        const char *ver = dd3_version();
        printf("differential-dogs3 version: %s\\n", ver);
        if (strcmp(ver, "0.19.1") != 0) return 1;
        int status = dd3_init();
        if (status != 0) return 1;
        printf("OK\\n");
        return 0;
      }
    C

    ENV.append_to_cflags "-I#{include}"
    ENV.append "LDFLAGS", "-L#{lib}"
    ENV.append "LDLIBS", "-ldifferential_dogs3"

    system "make", "test_dogs3"
    assert_match "0.19.1", shell_output("./test_dogs3")
  end
end

__END__
<< unified diff patch content -- see Step 1 for the literal patch >>
```

### Dependencies

| Dependency | Type    | Purpose                                            |
|------------|---------|-----------------------------------------------------|
| `rust`     | `:build` | Rust compiler toolchain                            |
| `cargo-c`  | `:build` | Provides `cargo cinstall` for C lib output         |
| `pkgconf`  | `:build` | Required by cargo-c for `.pc` file generation      |

---

## 3. Build Configuration

### The cargo-c Pipeline

`cargo cinstall` performs these steps automatically:

1. Compiles the Rust crate with `crate-type = ["cdylib", "staticlib"]`
2. Runs `cbindgen` to generate a C header from `extern "C"` functions
3. Installs to `--prefix`:
   - `include/differential_dogs3.h` (generated header)
   - `lib/libdifferential_dogs3.dylib` (shared library, macOS) or `lib/libdifferential_dogs3.so` (Linux)
   - `lib/libdifferential_dogs3.a` (static library)
   - `lib/pkgconfig/differential_dogs3.pc` (pkg-config metadata)

### Required Upstream Modifications (Patch or Resource)

Since the upstream `dogsdogsdogs` crate has **no C FFI layer**, the formula must either:

**Option A (Recommended): Patch-based approach**
- Include an inline `__END__` / `DATA` patch or use Homebrew's `patch` DSL to add:
  1. A `capi.rs` module with `extern "C"` wrapper functions
  2. A `cbindgen.toml` configuration file
  3. Modifications to `Cargo.toml` to add `crate-type = ["cdylib", "staticlib"]` and `[package.metadata.capi]`

**Option B: Fork-based approach**
- Maintain a fork at `github.com/justinjoy/differential-dataflow` with the FFI shim layer added
- Point the formula URL at the fork's tagged release

**Option C: Resource overlay approach**
- Use Homebrew's `resource` blocks to download additional files (the FFI shim) that get overlaid onto the source tree during build

### Cargo.toml Additions Needed (in dogsdogsdogs/)

```toml
[lib]
crate-type = ["cdylib", "staticlib", "lib"]

[package.metadata.capi.header]
name = "differential_dogs3"
subdirectory = ""

[package.metadata.capi.library]
name = "differential_dogs3"

[package.metadata.capi.pkg_config]
name = "differential_dogs3"
```

### cbindgen.toml Needed (in dogsdogsdogs/)

```toml
language = "C"
include_guard = "DIFFERENTIAL_DOGS3_H"
autogen_warning = "/* Auto-generated by cbindgen. Do not edit. */"

[export]
prefix = "dd3_"
```

### C FFI Shim (capi.rs) -- Concrete Wrapper Functions

Because the upstream Rust API uses generics (`PrefixExtender<G, R>`, `CollectionIndex<K, V, T, R>`), the FFI shim must export concrete instantiations. A minimal viable FFI surface would include:

```rust
// dogsdogsdogs/src/capi.rs
use std::os::raw::c_int;

/// Returns the library version as a static string pointer.
#[no_mangle]
pub extern "C" fn dd3_version() -> *const std::os::raw::c_char {
    concat!(env!("CARGO_PKG_VERSION"), "\0").as_ptr() as *const _
}

/// Returns 0 to indicate the library is operational.
#[no_mangle]
pub extern "C" fn dd3_init() -> c_int {
    0
}
```

A more complete FFI surface exposing `CollectionIndex` operations with opaque pointers would be a follow-up task. The initial formula should prove the build pipeline works with a minimal FFI surface.

---

## 4. Installation Layout

After `brew install justinjoy/tap/differential-dogs3`, the following files are installed:

```
#{prefix}/
  include/
    differential_dogs3.h          # C header with FFI declarations
  lib/
    libdifferential_dogs3.dylib   # Shared library (macOS)
    libdifferential_dogs3.a       # Static library
    pkgconfig/
      differential_dogs3.pc       # pkg-config metadata
```

On the Homebrew cellar path, this resolves to:
```
/opt/homebrew/Cellar/differential-dogs3/0.19.1/include/differential_dogs3.h
/opt/homebrew/Cellar/differential-dogs3/0.19.1/lib/libdifferential_dogs3.dylib
/opt/homebrew/Cellar/differential-dogs3/0.19.1/lib/libdifferential_dogs3.a
/opt/homebrew/Cellar/differential-dogs3/0.19.1/lib/pkgconfig/differential_dogs3.pc
```

Homebrew symlinks these into `/opt/homebrew/include/` and `/opt/homebrew/lib/` automatically.

---

## 5. FFI Integration Points

### For C Consumers

```c
#include "differential_dogs3.h"

int main(void) {
    const char *ver = dd3_version();
    int status = dd3_init();
    return status;
}
```

Compile with:
```bash
cc -I$(brew --prefix differential-dogs3)/include \
   -L$(brew --prefix differential-dogs3)/lib \
   -ldifferential_dogs3 \
   test.c -o test
```

### For pkg-config Users

```bash
cc $(pkg-config --cflags --libs differential_dogs3) test.c -o test
```

### For Other Homebrew Formulas

```ruby
depends_on "justinjoy/tap/differential-dogs3"

# In install:
ENV.append_to_cflags "-I#{Formula["differential-dogs3"].opt_include}"
ENV.append "LDFLAGS", "-L#{Formula["differential-dogs3"].opt_lib}"
```

---

## 6. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC1 | `brew install justinjoy/tap/differential-dogs3` completes without error | Run install command |
| AC2 | Header file exists at `#{prefix}/include/differential_dogs3.h` | `test -f` check |
| AC3 | Shared library exists at `#{prefix}/lib/libdifferential_dogs3.{dylib,so}` (platform-dependent: `.dylib` on macOS, `.so` on Linux) | `ls #{lib}/libdifferential_dogs3.*` confirms shared lib present |
| AC4 | Static library exists at `#{prefix}/lib/libdifferential_dogs3.a` | `test -f` check |
| AC5 | pkg-config file exists and resolves correctly | `pkg-config --libs differential_dogs3` |
| AC6 | A C test program can compile and link against the library | `brew test differential-dogs3` |
| AC7 | The test program calls `dd3_version()` and gets "0.19.1" | Output assertion in test block |
| AC8 | `brew audit --strict differential-dogs3` passes | Run audit command |
| AC9 | Version string in header matches upstream tag version (0.19.1) | `grep "0.19.1"` on generated header or `dd3_version()` return value |

---

## 7. Implementation Steps

### Step 1: Create the C FFI Shim Layer (as inline patch)

**What:** Author the minimal FFI wrapper files as a unified diff patch that will be placed in the formula's `__END__` section. This patch is applied by Homebrew's `patch :DATA` mechanism against the extracted source tarball.

**Context:** The tarball extracts to `differential-dataflow-differential-dogs3-v0.19.1/`. Homebrew strips one leading path component by default (`-p1`), so paths in the diff should be `a/dogsdogsdogs/...` and `b/dogsdogsdogs/...`.

**The literal unified diff patch content:**

```diff
diff --git a/dogsdogsdogs/Cargo.toml b/dogsdogsdogs/Cargo.toml
--- a/dogsdogsdogs/Cargo.toml
+++ b/dogsdogsdogs/Cargo.toml
@@ -14,6 +14,22 @@
 timely = { workspace = true }
 differential-dataflow = { workspace = true }
 serde = { version = "1.0", features = ["derive"]}
+cbindgen = "0.28"
+
+[lib]
+crate-type = ["cdylib", "staticlib", "lib"]
+
+[package.metadata.capi.header]
+name = "differential_dogs3"
+subdirectory = ""
+generation = false
+
+[package.metadata.capi.library]
+name = "differential_dogs3"
+
+[package.metadata.capi.pkg_config]
+name = "differential_dogs3"

 [dev-dependencies]
 graph_map = "0.1"
diff --git a/dogsdogsdogs/cbindgen.toml b/dogsdogsdogs/cbindgen.toml
new file mode 100644
--- /dev/null
+++ b/dogsdogsdogs/cbindgen.toml
@@ -0,0 +1,7 @@
+language = "C"
+include_guard = "DIFFERENTIAL_DOGS3_H"
+autogen_warning = "/* Auto-generated by cbindgen. Do not edit. */"
+tab_width = 4
+
+[export]
+prefix = "dd3_"
diff --git a/dogsdogsdogs/src/capi.rs b/dogsdogsdogs/src/capi.rs
new file mode 100644
--- /dev/null
+++ b/dogsdogsdogs/src/capi.rs
@@ -0,0 +1,14 @@
+//! Minimal C FFI surface for differential-dogs3.
+//! Provides version and init functions for downstream C consumers.
+
+use std::os::raw::c_int;
+
+/// Returns the library version as a NUL-terminated string pointer.
+#[no_mangle]
+pub extern "C" fn dd3_version() -> *const std::os::raw::c_char {
+    concat!(env!("CARGO_PKG_VERSION"), "\0").as_ptr() as *const _
+}
+
+/// Returns 0 to indicate the library is initialised and operational.
+#[no_mangle]
+pub extern "C" fn dd3_init() -> c_int {
+    0
+}
diff --git a/dogsdogsdogs/src/lib.rs b/dogsdogsdogs/src/lib.rs
--- a/dogsdogsdogs/src/lib.rs
+++ b/dogsdogsdogs/src/lib.rs
@@ -8,6 +8,7 @@
 pub mod altneu;
 pub mod calculus;
 pub mod operators;
+pub mod capi;

 /// A type capable of extending a stream of prefixes.
 ///
```

**Upstream source reference for context accuracy:**

- `dogsdogsdogs/Cargo.toml` line 14-16: the `[dependencies]` entries `timely`, `differential-dataflow`, `serde` are the last 3 lines before `[dev-dependencies]`. The patch inserts `cbindgen` as a build dependency and appends the `[lib]` and `[package.metadata.capi.*]` sections between `[dependencies]` and `[dev-dependencies]`.
- `dogsdogsdogs/src/lib.rs` lines 8-10: `pub mod altneu;`, `pub mod calculus;`, `pub mod operators;` -- the patch adds `pub mod capi;` after line 10.
- `dogsdogsdogs/cbindgen.toml` and `dogsdogsdogs/src/capi.rs` are entirely new files.

**Important note on `cbindgen` dependency:** The `cbindgen` crate is listed in `[dependencies]` in the patch above. However, `cargo-c` bundles its own `cbindgen` invocation, so the `cbindgen` dependency line may be unnecessary. The executor should test with and without it:
- If `cargo cinstall` works without `cbindgen` in `[dependencies]`, remove that line from the patch.
- The `[package.metadata.capi.header] generation = false` line tells cargo-c to use `cbindgen.toml` directly rather than auto-generating headers. If `generation = false` causes issues, try removing it (cargo-c defaults to using cbindgen.toml when present).

**Acceptance:** The patch applies cleanly to the v0.19.1 tarball with `patch -p1` and the resulting source compiles with `cargo cinstall`.

### Step 2: Rewrite the Formula File

**What:** Replace the template formula at `/opt/homebrew/Library/Taps/justinjoy/homebrew-tap/Formula/differential-dogs3.rb` with a working formula.

**Key elements:**
- `desc "C library for the differential-dogs3 join operators"` (accurate, concise -- does not overstate FFI surface)
- `depends_on "cargo-c" => :build`, `depends_on "pkgconf" => :build`, and `depends_on "rust" => :build`
- `livecheck` block with regex `/differential-dogs3-v(\d+(?:\.\d+)+)/i`
- `patch :DATA` before `def install` to apply the FFI shim from `__END__`
- `def install` using `cargo cinstall` in the `dogsdogsdogs` subdirectory
- `test do` block with a C program that includes the header, calls `dd3_version()`, and asserts the version string
- `__END__` section containing the literal unified diff from Step 1

**Acceptance:** The formula file is syntactically valid Ruby, follows the `rustls-ffi` pattern from homebrew-core, and contains the complete patch in `__END__`.

### Step 3: Validate the Build

**What:** Run `brew install --build-from-source justinjoy/tap/differential-dogs3` and verify all artifacts are installed.

**Acceptance:**
- Install completes without error
- All four artifact types exist (header, shared lib, static lib, .pc file)
- `brew test differential-dogs3` passes (C test program compiles, links, runs, outputs correct version)

### Step 4: Run Homebrew Quality Checks

**What:** Execute the Homebrew quality toolchain per AGENTS.md guidelines.

**Commands:**
- `brew audit --strict --online differential-dogs3` -- formula lint
- `brew style Formula/differential-dogs3.rb` -- RuboCop style check
- `brew test-bot --only-tap-syntax` -- tap-level syntax validation (matches CI at `.github/workflows/tests.yml:38`)

**Acceptance:** All three commands pass with zero errors (warnings acceptable for tap formulas).

### Step 5: Final Cleanup and Documentation

**What:** Remove all generated template comments from the formula. Update the tap README if needed. Ensure the formula is commit-ready.

**Acceptance:**
- No `# PLEASE REMOVE ALL GENERATED COMMENTS` or placeholder comments remain
- Formula is clean, minimal, and follows homebrew-core conventions

---

## 8. Risks and Mitigations

### Risk 1: Upstream has no C FFI surface (HIGH)

**Impact:** The entire cargo-c / cbindgen pipeline depends on `extern "C"` functions existing in the crate.

**Mitigation:** Author a minimal FFI shim (`capi.rs`) injected via Homebrew's patch mechanism. Start with a trivially small FFI surface (`dd3_version`, `dd3_init`) to prove the pipeline, then expand.

### Risk 2: Cargo workspace complicates cargo-c (MEDIUM)

**Impact:** `cargo cinstall` may struggle with workspace-level dependencies or feature resolution.

**Mitigation:** Use `cd "dogsdogsdogs"` in the install block (same pattern as `zlib-rs`). If workspace resolution fails, the patch can also modify the root `Cargo.toml` to adjust workspace settings.

### Risk 3: Generic Rust types cannot be exported to C (MEDIUM)

**Impact:** The core API (`PrefixExtender<G, R>`, `CollectionIndex<K, V, T, R>`) uses Rust generics that have no C representation.

**Mitigation:** The FFI shim exports only concrete instantiations or opaque pointer types. The initial minimal shim avoids this entirely by only exposing version/init functions. A richer FFI surface is a separate follow-up plan.

### Risk 4: Patch drift on upstream updates (LOW)

**Impact:** When upstream releases a new version, the inline patch may fail to apply.

**Mitigation:** Keep the patch minimal and isolated (new files + small Cargo.toml edits). Consider contributing the FFI layer upstream or maintaining a fork long-term.

### Risk 5: timely dependency resolution during build (LOW)

**Impact:** The `dogsdogsdogs` crate depends on `timely` and `differential-dataflow` from the workspace. Build may fail if workspace-level dependency resolution is incomplete.

**Mitigation:** The tarball includes the full workspace. `cargo cinstall` from within `dogsdogsdogs/` should resolve workspace deps from `../Cargo.toml`. Test this in Step 3.

### Risk 6: cbindgen dependency in Cargo.toml may conflict with cargo-c (LOW)

**Impact:** Adding `cbindgen` as a `[dependencies]` entry may conflict with the version bundled by `cargo-c`, or may be entirely unnecessary since `cargo-c` manages `cbindgen` invocation itself.

**Mitigation:** The executor should test the build with and without the `cbindgen = "0.28"` line in the patch. Remove it if cargo-c handles cbindgen invocation without it.

---

## 9. Verification Steps

### Manual Verification Sequence

**Note:** These steps are written for macOS. On Linux, the shared library extension is `.so` instead of `.dylib`. The `file` command is used where possible to be platform-aware.

```bash
# 1. Install from source
brew install --build-from-source justinjoy/tap/differential-dogs3

# 2. Check artifacts exist
test -f "$(brew --prefix differential-dogs3)/include/differential_dogs3.h"
test -f "$(brew --prefix differential-dogs3)/lib/libdifferential_dogs3.a"
test -f "$(brew --prefix differential-dogs3)/lib/pkgconfig/differential_dogs3.pc"

# 3. Verify shared library exists (platform-aware)
# On macOS:
test -f "$(brew --prefix differential-dogs3)/lib/libdifferential_dogs3.dylib"
# On Linux:
# test -f "$(brew --prefix differential-dogs3)/lib/libdifferential_dogs3.so"
# Platform-agnostic alternative:
ls "$(brew --prefix differential-dogs3)/lib/libdifferential_dogs3".{dylib,so} 2>/dev/null | head -1

# 4. Verify shared library type with file command
file "$(brew --prefix differential-dogs3)/lib/libdifferential_dogs3".*

# 5. Verify version string in header or via dd3_version()
grep -q "dd3_version\|dd3_init" "$(brew --prefix differential-dogs3)/include/differential_dogs3.h"

# 6. Verify pkg-config works
pkg-config --cflags --libs differential_dogs3

# 7. Run formula test (compiles and runs a C program)
brew test differential-dogs3

# 8. Run Homebrew quality checks
brew audit --strict differential-dogs3
brew style Formula/differential-dogs3.rb
brew test-bot --only-tap-syntax

# 9. Verify livecheck works
brew livecheck differential-dogs3

# 10. Test uninstall/reinstall cycle
brew uninstall differential-dogs3
brew install justinjoy/tap/differential-dogs3
brew test differential-dogs3
```

### Automated Test Block (in formula)

```ruby
test do
  (testpath/"test_dogs3.c").write <<~C
    #include "differential_dogs3.h"
    #include <stdio.h>
    #include <string.h>
    int main(void) {
      const char *ver = dd3_version();
      printf("differential-dogs3 version: %s\\n", ver);
      if (strcmp(ver, "0.19.1") != 0) return 1;
      int status = dd3_init();
      if (status != 0) return 1;
      printf("OK\\n");
      return 0;
    }
  C

  ENV.append_to_cflags "-I#{include}"
  ENV.append "LDFLAGS", "-L#{lib}"
  ENV.append "LDLIBS", "-ldifferential_dogs3"

  system "make", "test_dogs3"
  assert_match "0.19.1", shell_output("./test_dogs3")
end
```

---

## 10. Guardrails

### Must Have
- Working `cargo cinstall` build from the `dogsdogsdogs` subdirectory
- C header, shared library, static library, and pkg-config file installed
- A test block that compiles and runs a C program against the library
- All Homebrew template comments removed
- Clean `brew audit` and `brew style` output
- `livecheck` block for automated version tracking
- `pkgconf` build dependency

### Must NOT Have
- No `./configure` or `cmake` calls (this is a Rust project)
- No hardcoded absolute paths in the formula
- No modifications to files outside `Formula/differential-dogs3.rb` in the tap
- No implementation of a full-featured FFI surface in the initial version (keep it minimal)
- No fork dependency -- use inline patch against upstream tarball

---

## Appendix: Reference Formulas

These homebrew-core formulas were used as proven patterns:

| Formula | Path | Pattern Used |
|---------|------|-------------|
| `rustls-ffi` | `/opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/r/rustls-ffi.rb` | cargo-c with C test, FFI header validation, `pkgconf` dependency |
| `rav1e` | `/opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/r/rav1e.rb` | cargo cinstall + cargo install pattern, `livecheck` block |
| `zlib-rs` | `/opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/z/zlib-rs.rb` | Subdirectory build (`cd "subdir"`), C test compilation |
| `xclogparser` | `/opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/x/xclogparser.rb` | `patch :DATA` / `__END__` inline patch mechanism |

## Appendix: Revision Changelog

### Revision 1 (2026-02-24) -- Architect/Critic feedback

| # | Gap | Resolution |
|---|-----|------------|
| 1 | Missing `depends_on "pkgconf" => :build` | Added to Section 2 formula structure and dependencies table |
| 2 | Missing `livecheck` block | Added with regex `/differential-dogs3-v(\d+(?:\.\d+)+)/i` in Section 2 |
| 3 | No literal unified diff patch in Step 1 | **Full patch provided** in Step 1 with 4 files, context lines referencing exact upstream source |
| 4 | Inaccurate `desc` field ("C FFI bindings" overpromises) | Changed to `"C library for the differential-dogs3 join operators"` |
| 5 | Hardcoded `.dylib` in AC3 and verification steps | AC3 now lists both extensions; verification steps include platform-aware checks and `file` command |
| 6 | Missing `brew test-bot --only-tap-syntax` in Step 4 | Added as third quality check command, referencing CI workflow line 38 |
| + | Critic: verify `dogsdogsdogs` crate version matches tag | Confirmed: upstream `Cargo.toml` has `version = "0.19.1"`, matching tag `differential-dogs3-v0.19.1` |
| + | Critic: state platform assumption explicitly | Added platform assumption statement in plan header and Section 9 |
| + | Added AC9 | "Version string in header matches upstream tag version (0.19.1)" |
| + | Added Risk 6 | cbindgen dependency in Cargo.toml may conflict with cargo-c |
