# MinerU-flake/process-pdf.nix
#
# Build a single PDF through MinerU. Inputs:
#   - stdenv:          the standard Nix build environment (from
#                      nixpkgs via the MinerU-flake's overlay)
#   - lib:             nixpkgs library (for escapeShellArg/escapeShellArgs)
#   - mineruPipeline:  the MinerU pipeline wrapper package
#                      configured with Nix-store model paths
#   - extraMineruArgs: extra CLI arguments to pass to mineru
#                      (e.g. GPU tuning flags)
#   - pdf:             a /nix/store path containing the PDF
#                      (supplied at function-call time by the
#                      consumer; brought into the store by the
#                      flake's builtins.path content-addressing
#                      call).
#
# Output: a directory containing `full.md` and
# `content_list.json` at the top level. (MinerU normally writes
# these under `<output>/<pdfstem>/auto/`; the derivation
# promotes them to the top level so downstream consumers don't
# need to know the MinerU layout.)
#
# The MinerU wrapper provides MINERU_TOOLS_CONFIG_JSON and
# points MinerU at Nix-store model paths; the build never
# sees `~/.cache/`.

{ stdenv, lib, mineruPipeline, extraMineruArgs ? [] }:

{ pdf }:

stdenv.mkDerivation {
  name = "mineru-output";

  buildInputs = [ mineruPipeline ];

  buildCommand = ''
    export HOME="$NIX_BUILD_TOP"
    mkdir -p "$HOME"

    mkdir -p "$out"
    mineru -p ${lib.escapeShellArg pdf} -o "$out" ${lib.escapeShellArgs extraMineruArgs} 2>&1

    # Debug: show what mineru left behind
    echo "=== mineru output tree ===" >&2
    find "$out" -type f -o -type d | head -30 >&2

    # Flatten any subdirectories: move all files up to $out, then
    # remove the (now empty) subdirectories.
    find "$out" -mindepth 2 -type f -exec mv -t "$out" {} +
    find "$out" -mindepth 1 -type d -depth -exec rmdir {} \; 2>/dev/null || true

    # Promote markdown
    for f in "$out"/*.md; do
      [ -f "$f" ] || continue
      mv "$f" "$out/full.md"
      break
    done
    # Promote content_list (prefer non-v2)
    for f in "$out"/*_content_list.json; do
      [ -f "$f" ] || continue
      case "$f" in
        *_v2*) ;;
        *) mv "$f" "$out/content_list.json"; break ;;
      esac
    done
  '';

  pdf = pdf;
}
