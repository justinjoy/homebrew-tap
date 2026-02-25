# Open Questions

## differential-dogs3-formula - 2026-02-24

### Resolved in Revision 1

- [x] **Should a `livecheck` block be added for automatic version tracking?** -- RESOLVED: Yes. Added `livecheck` block with regex `/differential-dogs3-v(\d+(?:\.\d+)+)/i` to the formula structure in the plan.

- [x] **Linux compatibility: should the formula include `on_linux` blocks?** -- RESOLVED: The plan now explicitly states macOS as the primary platform. Verification steps note the `.dylib` vs `.so` difference. No `on_linux` blocks are needed for v1; the tap CI already tests on `ubuntu-22.04` so Linux issues will surface naturally.

### Deferred (still open)

- [ ] **Option A (patch) vs Option B (fork) vs Option C (resource overlay)?** -- The plan proceeds with Option A (inline patch via `patch :DATA`). If the patch grows beyond ~100 lines in future versions or if upstream updates break the patch frequently, reconsider Option B (fork). This is a maintenance decision, not a v1 blocker.

- [ ] **What FFI surface should be exposed beyond the minimal `dd3_version` / `dd3_init`?** -- The upstream Rust API is heavily generic (`PrefixExtender<G, R>`, `CollectionIndex<K, V, T, R>`). Exposing meaningful operations to C requires choosing concrete type instantiations (e.g., `CollectionIndex<u64, u64, ...>`). This is deferred to a follow-up plan after the v1 build pipeline is proven.

- [ ] **Should the formula also install a CLI binary?** -- The `rav1e` formula installs both a binary (`cargo install`) and a C library (`cargo cinstall`). The `dogsdogsdogs` crate has examples but no binary target. Confirm no binary is needed. Deferred -- not relevant for v1.

- [ ] **Is the `cbindgen` crate dependency in `[dependencies]` needed?** -- Added in Revision 1 patch as `cbindgen = "0.28"`. However, `cargo-c` bundles its own cbindgen invocation, so this line may be unnecessary or cause version conflicts. The executor should test with and without it. If cargo-c works without it, remove from patch.

## readme-documentation - 2026-02-25

### From Critic Revision 2

- [ ] **Execution order: README before or after formula rewrite?** -- The README plan now declares an explicit dependency on the formula rewrite plan (`differential-dogs3-formula.md`). Step 3 includes two variants (future/current) so the executor can adapt. However, the preferred path is to complete the formula rewrite first. If execution order is reversed, the executor must use the "Current Formula" fallback variant and revisit the README after the formula is updated.

- [ ] **Should the Cargo.toml dependency example be included in the README?** -- Step 3 now includes a dedicated "For Rust Projects (Alternative Consumption Path)" subsection with both crate version and git dependency fallback variants. The executor MUST verify crates.io availability (https://crates.io/crates/differential-dogs3) before choosing which variant to include. If not published, use the git dependency with tag. This question remains open until the executor performs the check at execution time.

- [ ] **How should the formula table version be maintained?** -- Step 1 adds a formula table with a hardcoded version `0.19.1`. When the formula is updated to a new version, the README must also be updated. Consider whether the version should be omitted or if there is a way to keep it in sync automatically.
