{
  lib,
  src,
  version,
  rev,
  rustPlatform,
  callPackage,
  fetchzip,
  runCommandLocal,
  writeShellScript,
  zig_0_16,
  pkg-config,
}:
let
  # Ghostty's Zig dependencies, prefetched from the zon2nix lockfile that the
  # ghostty submodule ships, so `zig build` runs without network access.
  ghosttyZigDeps = callPackage "${src}/ghostty/build.zig.zon.nix" {
    name = "cmux-tui-ghostty-zig-deps";
  };

  # Entries manaflow's ghostty fork added to build.zig.zon without
  # regenerating build.zig.zon.nix. Drop them once upstream catches up.
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

  zigDeps = runCommandLocal "cmux-tui-zig-deps" { } ''
    mkdir $out
    ln -s ${ghosttyZigDeps}/* $out/
    ${lib.concatMapStrings (d: ''
      [ -e $out/${d.name} ] || ln -s ${d.path} $out/${d.name}
    '') extraZigDeps}
  '';

  # ghostty-vt-sys/build.rs runs `$ZIG build ...`; point it at the prefetched
  # packages instead of letting Zig fetch them.
  zigWrapper = writeShellScript "zig-offline" ''
    if [ "$1" = build ]; then
      exec ${lib.getExe zig_0_16} "$@" --system ${zigDeps}
    fi
    exec ${lib.getExe zig_0_16} "$@"
  '';
in
rustPlatform.buildRustPackage {
  pname = "cmux-tui";
  inherit version src;

  sourceRoot = "source/cmux-tui";
  cargoLock.lockFile = "${src}/cmux-tui/Cargo.lock";

  # build.rs resolves ghostty at ../../../ghostty relative to the crate, which
  # lands outside sourceRoot once unpacked. Pass it explicitly.
  postUnpack = ''
    chmod -R u+w source/ghostty
  '';
  preBuild = ''
    export CMUX_GHOSTTY_SRC=$NIX_BUILD_TOP/source/ghostty
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-local-cache
    # ghostty's build.zig shells out to `zig env` via PATH.
    export PATH=${zig_0_16}/bin:$PATH
  '';

  # zig_0_16 is reached through zigWrapper only: listing it here would pull in
  # its setup hook, which replaces the cargo build phase with `zig build`.
  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  env = {
    # cmux-remote/build.rs otherwise reads it from `git rev-parse`.
    CMUX_TUI_BUILD_COMMIT = rev;
    ZIG = "${zigWrapper}";
    # Portable binary: don't tune libghostty-vt for the build machine's CPU.
    CMUX_GHOSTTY_VT_ZIG_CPU = "baseline";
  };

  cargoBuildFlags = [ "-p" "cmux-tui" ];
  # The workspace test suite needs PTYs, sockets and network; not sandbox-safe.
  doCheck = false;

  meta = {
    description = "cmux terminal multiplexer (TUI) built on libghostty-vt";
    homepage = "https://github.com/manaflow-ai/cmux/tree/main/cmux-tui";
    license = lib.licenses.mit;
    mainProgram = "cmux-tui";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
