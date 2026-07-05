{ fetchurl
, lib
, stdenvNoCC
}:

let
  baseUrl = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0/resolve/main";

  files = {
    # Layout detection
    "models/Layout/PP-DocLayoutV2/config.json"                     = "sha256-GKaWtUxkxPpYKvzTpBQHxLZamdx6sYetL+2K+OQSitg=";
    "models/Layout/PP-DocLayoutV2/model.safetensors"               = "sha256-5g83Ja7tyI/TGUFu8Wa9p5FxpBUWowHCfKuRMtwnOdI=";
    "models/Layout/PP-DocLayoutV2/preprocessor_config.json"        = "sha256-VigacMkxopHcr2U2BftN9xP9gj9l6TmuzWAFwmNGoQM=";

    # Formula recognition (UniMERNet small 2503)
    "models/MFR/unimernet_hf_small_2503/config.json"              = "sha256-ZMAumJdBBlj3ZoxqM0qLMGJ25Gl2Vsvgb4bYxPAfwEA=";
    "models/MFR/unimernet_hf_small_2503/generation_config.json"   = "sha256-1Wyp1cXvpCg6JWWuQncbr9ApELVu+cU+m0QcnEyJbQk=";
    "models/MFR/unimernet_hf_small_2503/model.safetensors"        = "sha256-kkTiVlWFwPibw6bu7qCA7zxYg3X8DVNgdP6I6AuRfNo=";
    "models/MFR/unimernet_hf_small_2503/special_tokens_map.json"  = "sha256-NYwkni+ykGDGtzFX1CiFOwxIcQ3v/I7mcKsQE4gJRsk=";
    "models/MFR/unimernet_hf_small_2503/tokenizer.json"           = "sha256-+OKePDqAF/Bntio9LZIRu0zrwIolr+WNOmBpmB42hNY=";
    "models/MFR/unimernet_hf_small_2503/tokenizer_config.json"    = "sha256-KLmeM4leBjicJsE5sTM7grf12O1fT9FJmKz9fCCYkzg=";
    "models/MFR/unimernet_hf_small_2503/README.md"                = "sha256-lldPOFfpGTUwJO3EI7kWXb9G6QLP6XtbfsVSKDvXRPY=";

    # OCR (shared det + ch rec models only — others trivial to add)
    "models/OCR/paddleocr_torch/ch_PP-OCRv5_det_infer.pth"        = "sha256-34SO1QYLrE0PblhXKuqX2S6QmoqHzykoSSN7DoT2/9s=";
    "models/OCR/paddleocr_torch/ch_PP-OCRv5_rec_infer.pth"        = "sha256-0g7o2sLKY+LRmJsC7MQllccdYb+N2Mjdxa0u5o57W+I=";
    "models/OCR/paddleocr_torch/ch_PP-OCRv4_rec_server_doc_infer.pth" = "sha256-9l5pn0ynkvvODpLR30ybve/j4hu9sBwwdcxJRwubwcw=";
    "models/OCR/paddleocr_torch/ch_PP-OCRv5_rec_server_infer.pth" = "sha256-R2fdyQwVMuwB2IGpgNrgoLkmefT4L4jE6fklY95p50A=";

    # Table recognition
    "models/TabRec/SlanetPlus/slanet-plus.onnx"                   = "sha256-1XqUKvai9X1qSgNyVzxpaiN5v1hXxF4qxpmT87M0UUs=";
    "models/TabRec/UnetStructure/unet.onnx"                       = "sha256-DqSNOhfjXvXC5Jil55lWYHMjTTmxB5yiHZ9Pr+c8bSA=";
    "models/TabCls/paddle_table_cls/PP-LCNet_x1_0_table_cls.onnx" = "sha256-yEvx15wcdNU0tbEq2xTdEhUcQveuPkvk8QQrgw+AuUk=";

    # Repo documentation
    "README.md"                                                    = "sha256-ltpd3ec8P1eLnqsjWsWcu19RJ1UJB3mhRGGGN2e3DzQ=";
  };

  # Each file gets its own fetchurl call with a unique name, so the store
  # path is deterministic (once the hash is fixed) and available as a
  # build-time input.
  fetchers = lib.mapAttrs (relpath: hash:
    fetchurl {
      url = "${baseUrl}/${relpath}";
      sha256 = hash;
      name = lib.strings.replaceStrings [ "/" ] [ "-" ] relpath;
    }
  ) files;
in
stdenvNoCC.mkDerivation {
  pname = "mineru-models";
  version = "1.0.0";

  srcs = builtins.attrValues fetchers;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
  '' + lib.concatStringsSep "\n" (lib.mapAttrsToList
    (relpath: _:
      let dir = builtins.dirOf relpath;
      in ''
        mkdir -p "$out/${dir}"
        cp -L "${fetchers.${relpath}}" "$out/${relpath}"
      ''
    )
    files)
  + ''
    runHook postInstall
  '';

  meta = {
    description = "PDF-Extract-Kit-1.0 model weights for MinerU";
    longDescription = ''
      Bundles the model weights used by MinerU 3.1.15's pipeline
      backend. Sourced from
      https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0.
      Each file is fetched by `fetchurl` with a content
      hash; the resulting store path is reproducible. Files are
      placed in the subdirectory layout that MinerU expects at
      runtime.
    '';
    homepage = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
