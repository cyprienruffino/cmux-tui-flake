# Zig package set for building ghostty (and libghostty-vt) offline: the
# zon2nix lockfile shipped in the ghostty submodule, plus entries manaflow's
# fork added to build.zig.zon without regenerating build.zig.zon.nix.
{
  lib,
  src,
  callPackage,
  fetchzip,
  runCommand,
}:
let
  ghosttyZigDeps = callPackage "${src}/ghostty/build.zig.zon.nix" {
    name = "cmux-ghostty-zig-deps";
  };

  # Drop these once upstream regenerates build.zig.zon.nix.
  extraZigDeps = [
    {
      name = "itijah-0.2.1-keFZYUG4AwDBukws7ED5UquPdSOnzvHuvMnJWQdnycQ5";
      path = fetchzip {
        url = "https://github.com/manaflow-ai/itijah/archive/48572f235d2005b9bfb88c622ce8268f15c7c491.tar.gz";
        hash = "sha256-8qw6sxDHZftndqKpnBhHJloCfUQXk5hJ8ZQ4sa44EXs=";
      };
    }
    {
      # itijah's lazy Unicode Character Database dependency.
      name = "N-V-__8AALTJcQJ3hosujokSgxYTsa3q1mDZ2dasYhuJwaOV";
      path = fetchzip {
        url = "https://www.unicode.org/Public/zipped/16.0.0/UCD.zip";
        stripRoot = false;
        hash = "sha256-GgEYjOLrxxfTAQsc2bpi7ShoAr3up8z7GXXpe+txFuw=";
      };
    }
  ];
in
# Real directories, not symlinks: Zig's build runner computes relative paths
# lexically and breaks on symlinked package dirs (ziglang/zig#32121).
runCommand "cmux-zig-deps" { } ''
  mkdir $out
  cp -rL ${ghosttyZigDeps}/* $out/
  ${lib.concatMapStrings (d: ''
    [ -e $out/${d.name} ] || cp -rL ${d.path} $out/${d.name}
  '') extraZigDeps}
''
