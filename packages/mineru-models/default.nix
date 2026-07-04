{ fetchurl
, lib
, stdenvNoCC
}:

let
  baseUrl = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0/resolve/main";

  files = {
    "config.json"                                = lib.fakeSha256;
    "Layout/YOLO@v8_ft/model.pt"                = lib.fakeSha256;
    "MFD/YOLO@v8_ft/model.pt"                   = lib.fakeSha256;
    "MFR/unimernet_hf_small/config.json"         = lib.fakeSha256;
    "MFR/unimernet_hf_small/model.safetensors"   = lib.fakeSha256;
    "MFR/unimernet_hf_small/tokenizer.json"      = lib.fakeSha256;
    "MFR/unimernet_hf_small/tokenizer_config.json" = lib.fakeSha256;
    "MFR/unimernet_hf_small/special_tokens_map.json" = lib.fakeSha256;
    "MFR/unimernet_hf_small/vocab.json"          = lib.fakeSha256;
    "MFR/unimernet_hf_small/merges.txt"          = lib.fakeSha256;
    "TabRec/StructEqTable/config.json"          = lib.fakeSha256;
    "TabRec/StructEqTable/model.safetensors"    = lib.fakeSha256;
    "TabRec/TableMaster/config.json"            = lib.fakeSha256;
    "TabRec/TableMaster/model.pth"              = lib.fakeSha256;
    "README.md"                                  = lib.fakeSha256;
  };
in
stdenvNoCC.mkDerivation {
  pname = "mineru-models";
  version = "1.0.0";

  srcs = lib.mapAttrsToList
    (relpath: hash:
      fetchurl {
        url = "${baseUrl}/${relpath}";
        sha256 = hash;
      })
    files;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    for src in $srcs; do
      cp -L "$src" "$out/$(basename "$src")"
    done
    runHook postInstall
  '';

  meta = {
    description = "PDF-Extract-Kit-1.0 model weights for MinerU";
    longDescription = ''
      Bundles the model weights used by MinerU's pipeline
      backend. Sourced from
      https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0.
      Each file is fetched by `fetchurl` with a content
      hash; the resulting store path is reproducible.
    '';
    homepage = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
