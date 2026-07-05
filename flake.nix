{
  description = "MinerU document parser";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      overlay = final: prev: {
        python3Packages = prev.python3Packages.override {
          overrides = pyFinal: pyPrev: {
            fasttext-predict   = pyPrev.fasttext.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                sed -i 's/np\.array(probs, copy=False)/np.asarray(probs)/g' \
                  "$out/${pyFinal.python.sitePackages}/fasttext/FastText.py"
              '';
            });
            robust-downloader  = pyFinal.callPackage ./packages/robust-downloader/package.nix {};
            fast-langdetect    = pyFinal.callPackage ./packages/fast-langdetect/package.nix {};
            pdftext            = pyFinal.callPackage ./packages/pdftext/package.nix {};
            mineru-vl-utils    = pyFinal.callPackage ./packages/mineru-vl-utils/package.nix {};
            qwen-vl-utils      = pyFinal.callPackage ./packages/qwen-vl-utils/package.nix {};
            pypptx-with-oxml   = pyFinal.callPackage ./packages/pypptx-with-oxml/package.nix {};
            torchvision        = pyFinal.callPackage ./packages/torchvision/package.nix {};
            transformers       = pyFinal.callPackage ./packages/transformers/package.nix {};
            mineru             = pyFinal.callPackage ./packages/mineru/package.nix {};
            mineru-models      = pyFinal.callPackage ./packages/mineru-models/default.nix {};
          };
        };
      };
      pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
    in {
      inherit overlay;
      packages.${system} = {
        default = pkgs.python3Packages.mineru;
        mineru-models = pkgs.python3Packages.mineru-models;
      };

      # Curried function output. Takes per-invocation
      # { pdf, pdfHash } and returns a derivation. The fixed
      # dependencies are bound once per system at flake-eval
      # time; only the inner closure is evaluated per call,
      # with `pdf` and `pdfHash` substituted.
      #
      # Consumers call
      # `flake.functions.x86_64-linux.process-pdf
      #   { pdf = "..."; pdfHash = "..."; }`
      # via `nix build --expr '<expr>'` with a locked
      # `builtins.getFlake` reference (see the
      # pprtrnt architecture doc §3.1.5 for the full
      # expression).
      functions.${system}.process-pdf = { pdf, pdfHash }:
        let
          pdfInput = builtins.path {
            path = pdf;
            sha256 = pdfHash;
            recursive = false;
            name = "input.pdf";
          };
        in
        (import ./process-pdf.nix {
          stdenv = pkgs.stdenv;
          mineru = pkgs.python3Packages.mineru;
          mineru-models = pkgs.python3Packages.mineru-models;
        }) { pdf = pdfInput; };
    };
}
