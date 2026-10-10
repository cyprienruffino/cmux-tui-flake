{
  description = "Nix flake for cmux-tui (from manaflow-ai/cmux)";

  inputs = {
    # nixos-unstable (gcc 16 / binutils 2.46) fails to link the Zig-built
    # libghostty-vt.a; 26.05 links it.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Upstream monorepo; cmux-tui needs the ghostty submodule.
    # Bump with: nix flake update cmux
    cmux = {
      url = "git+https://github.com/manaflow-ai/cmux?submodules=1&shallow=1";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, cmux }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      rev = cmux.rev or "unknown";
      version = "0.1.0-unstable-${builtins.substring 0 8 (cmux.lastModifiedDate or "19700101")}";
    in
    {
      packages = forAllSystems (pkgs: rec {
        cmux-tui = pkgs.callPackage ./package.nix { src = cmux; inherit version rev; };
        default = cmux-tui;
      });

      overlays.default = final: _prev: {
        cmux-tui = final.callPackage ./package.nix { src = cmux; inherit version rev; };
      };

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${pkgs.system}.cmux-tui;
        };
      });
    };
}
