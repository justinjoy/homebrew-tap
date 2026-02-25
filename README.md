# homebrew-tap

[![Intel](https://img.shields.io/github/actions/workflow/status/justinjoy/homebrew-tap/tests.yml?branch=main&label=intel&style=flat)](https://github.com/justinjoy/homebrew-tap/actions/workflows/tests.yml?query=branch%3Amain)
[![ARM](https://img.shields.io/github/actions/workflow/status/justinjoy/homebrew-tap/tests.yml?branch=main&label=arm&style=flat)](https://github.com/justinjoy/homebrew-tap/actions/workflows/tests.yml?query=branch%3Amain)
[![Linux](https://img.shields.io/github/actions/workflow/status/justinjoy/homebrew-tap/tests.yml?branch=main&label=linux&style=flat)](https://github.com/justinjoy/homebrew-tap/actions/workflows/tests.yml?query=branch%3Amain)

A custom Homebrew tap providing `differential-dogs3`, a C library for differential-dogs3 join operators.

The `differential-dogs3` library is part of the [TimelyDataflow/differential-dataflow](https://github.com/TimelyDataflow/differential-dataflow) project and enables advanced join patterns in differential dataflow computations.

## Available Formulae

| Formula | Version | Description |
|---------|---------|-------------|
| `differential-dogs3` | 0.19.1 | C library for the differential-dogs3 join operators |

## Requirements

- **macOS** (primary) or **Linux**
- **Homebrew** — see [installation instructions](https://brew.sh)
- **Xcode Command Line Tools** (macOS) — `xcode-select --install`

Note: `rust` is a build dependency handled automatically by Homebrew during installation; it does not need to be installed separately.

## Installation

### Method 1: Direct Install (One-Liner)

```bash
brew install justinjoy/tap/differential-dogs3
```

### Method 2: Tap Then Install (Two-Step)

```bash
brew tap justinjoy/tap
brew install differential-dogs3
```

### Method 3: Brewfile (for `brew bundle` Users)

```ruby
tap "justinjoy/tap"
brew "differential-dogs3"
```

Then run:

```bash
brew bundle
```

**Build Dependencies:** The `rust` and Cargo toolchain are required as build dependencies. Homebrew will install these automatically during the formula installation, so you do not need to install them separately.

## Usage

### Verify Installation

```bash
brew info justinjoy/tap/differential-dogs3
```

### Check Installed Files

```bash
ls $(brew --prefix differential-dogs3)/lib/
```

Expected output (macOS):
```
libdifferential_dogs3.dylib
libdifferential_dogs3.a
```

Expected output (Linux):
```
libdifferential_dogs3.so
libdifferential_dogs3.a
```

### C Compiler Linking Example

To link against the library from C/C++ code:

```bash
cc -L$(brew --prefix differential-dogs3)/lib \
   -ldifferential_dogs3 \
   test.c -o test
```

Or set the library path in environment variables:

```bash
export LIBRARY_PATH="$(brew --prefix differential-dogs3)/lib:$LIBRARY_PATH"
cc -ldifferential_dogs3 test.c -o test
```

### For Rust Projects (Alternative Consumption Path)

This subsection covers consuming `differential-dogs3` as a Rust crate dependency — a fundamentally different approach from the C library installed by Homebrew above. Rust projects typically depend on the crate directly via Cargo rather than linking against the Homebrew-installed C library.

**Add to your `Cargo.toml`:**

```toml
[dependencies]
differential-dogs3 = "0.19.1"
```

If you need a different version or the git repository directly:

```toml
[dependencies]
differential-dogs3 = { git = "https://github.com/TimelyDataflow/differential-dataflow", tag = "differential-dogs3-v0.19.1" }
```

**Note:** This is a Rust crate dependency managed by Cargo, separate from the Homebrew C library installation above. Use this approach if your project is written in Rust and you want to consume the library natively through Cargo rather than via C FFI.

### Update and Uninstall

To upgrade the library:

```bash
brew upgrade differential-dogs3
```

To uninstall:

```bash
brew uninstall differential-dogs3
```

## Troubleshooting

### Rust Not Found

If you see an error about Rust not being found, Homebrew will automatically install it as a build dependency. If you want to install it manually:

```bash
brew install rust
```

### Library Not Found at Link Time

If the compiler cannot find the library, explicitly set the library search path:

```bash
export LIBRARY_PATH="$(brew --prefix differential-dogs3)/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$(brew --prefix differential-dogs3)/include:$C_INCLUDE_PATH"
```

Then recompile your code.

### Formula Outdated

To update to the latest version:

```bash
brew update && brew upgrade differential-dogs3
```

### Empty lib Directory

If after installation `ls $(brew --prefix differential-dogs3)/lib/` shows no `.dylib` or `.so` files, this indicates a silent build failure. Try these solutions:

1. **Reinstall with verbose output** to see where the build fails:

```bash
brew reinstall --build-from-source --verbose --debug differential-dogs3
```

2. **Check the build log directory** for details:

```bash
ls ~/Library/Logs/Homebrew/differential-dogs3/
```

(On Linux, check `~/.cache/Homebrew/Logs/differential-dogs3/` instead.)

3. **Verify Xcode Command Line Tools are installed:**

```bash
xcode-select --install
```

4. If the issue persists, please [file an issue](https://github.com/justinjoy/homebrew-tap/issues).

## Additional Information

- **License:** MIT
- **Upstream Source:** [TimelyDataflow/differential-dataflow](https://github.com/TimelyDataflow/differential-dataflow)
- **Report Issues:** [justinjoy/homebrew-tap issues](https://github.com/justinjoy/homebrew-tap/issues)
- **Homebrew Documentation:** [docs.brew.sh](https://docs.brew.sh)
