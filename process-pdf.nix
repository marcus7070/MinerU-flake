# MinerU-flake/process-pdf.nix
#
# Build a single PDF through MinerU. Inputs:
#   - stdenv:        the standard Nix build environment (from
#                    nixpkgs via the MinerU-flake's overlay)
#   - mineruPipeline: the MinerU pipeline wrapper package
#                    configured with Nix-store model paths
#   - pdf:           a /nix/store path containing the PDF
#                    (supplied at function-call time by the
#                    consumer; brought into the store by the
#                    flake's builtins.path content-addressing
#                    call).
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
#
# This file was moved from nix/process-pdf.nix in the pprtrnt
# repo as part of the slice 020 restructure. The body is
# unchanged.

{ stdenv, mineruPipeline }:

{ pdf }:

stdenv.mkDerivation {
  name = "mineru-output";
  system = builtins.currentSystem;

  buildInputs = [ mineruPipeline ];

  buildCommand = ''
    export HOME="$NIX_BUILD_TOP"
    mkdir -p "$HOME"

    mkdir -p "$out"
    mineru -p ${pdf} -o "$out" 2>&1

    for subdir in "$out"/*/; do
      [ -d "$subdir" ] || continue
      auto="$subdir/auto"
      if [ -d "$auto" ]; then
        for item in "$auto"/*; do
          [ -e "$item" ] || continue
          mv "$item" "$out/"
        done
        rmdir "$auto"
      fi
      for item in "$subdir"/*; do
        [ -e "$item" ] || continue
        mv "$item" "$out/"
      done
      rmdir "$subdir"
      break
    done
    for f in "$out"/*.md; do
      [ -f "$f" ] || continue
      mv "$f" "$out/full.md"
      break
    done
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
