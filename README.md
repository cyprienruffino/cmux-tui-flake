# cmux-tui-flake

Nix flake for [cmux-tui](https://github.com/manaflow-ai/cmux/tree/main/cmux-tui), the Rust terminal multiplexer from manaflow-ai/cmux.

```sh
nix run github:cyprienruffino/cmux-tui-flake
```

As an input:

```nix
inputs.cmux-tui.url = "github:cyprienruffino/cmux-tui-flake";
# packages: cmux-tui.packages.${system}.default   overlay: cmux-tui.overlays.default
```

## Updates

`flake.lock` pins upstream cmux. A weekly GitHub Action (`update-cmux`) runs `nix flake update cmux`, builds, and pushes to `main` only if the build passes. Manual: `nix flake update cmux && nix build`.

## Known quirks

- Pinned to `nixos-26.05`: unstable's gcc 16 / binutils 2.46 fails to link the Zig-built `libghostty-vt.a`.
- `extraZigDeps` in `package.nix` patches Zig deps missing from manaflow's ghostty `build.zig.zon.nix`. If an update fails with `lazy dependency package not found: <name>`, add that entry there.
