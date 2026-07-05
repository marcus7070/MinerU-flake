# MinerU-flake/process-pdf.nix
#
# Build a single PDF through MinerU. Inputs:
#   - stdenv:        the standard Nix build environment (from
#                    nixpkgs via the MinerU-flake's overlay)
#   - mineru:        the MinerU Python package (from
#                    MinerU-flake/packages/mineru/)
#   - mineru-models: the bundled PDF-Extract-Kit-1.0 model
#                    weights (from MinerU-flake/packages/mineru-models/)
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
# The mineru.json config is written inside the build sandbox
# from the Nix inputs. The ${mineru-models} interpolation
# gives the sandbox-time absolute path of the model store
# path; the build never sees `~/.cache/`.
#
# This file was moved from nix/process-pdf.nix in the pprtrnt
# repo as part of the slice 020 restructure. The body is
# unchanged.

{ stdenv, mineru, mineru-models }:

{ pdf }:

let
  modelsDir = "${mineru-models}";
in
stdenv.mkDerivation {
  name = "mineru-output";
  system = builtins.currentSystem;

  buildInputs = [ mineru ];

  buildCommand = ''
    export HOME="$NIX_BUILD_TOP"
    mkdir -p "$HOME"

    export MINERU_MODEL_SOURCE=local

    cat > "$HOME/mineru.json" <<'EOF'
{
  "models-dir": {
    "pipeline": "${modelsDir}",
    "vlm": ""
  },
  "latex-delimiter-config": {
    "display": {"left": "$$", "right": "$$"},
    "inline": {"left": "$", "right": "$"}
  },
  "llm-aided-config": {
    "title_aided": {"enable": false}
  }
}
EOF

    mkdir -p "$out"
    mineru -p ${pdf} -o "$out" --backend pipeline 2>&1

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
