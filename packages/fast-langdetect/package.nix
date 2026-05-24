{ lib, buildPythonPackage, fetchurl, pythonRelaxDepsHook, robust-downloader, requests, fasttext-predict }:

buildPythonPackage rec {
  pname = "fast-langdetect";
  version = "0.2.5";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/27/da/c621e64d4bc23f485468295bb7d4a5f2290ebb4d342c8dc448ab66808071/fast_langdetect-0.2.5-py3-none-any.whl";
    hash = "sha256-jV/2QNlNXzC7dlPHYa27kSK2F7A/ofFmt8wWw15ITQ4=";
  };

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  # fasttext-predict is provided by nixpkgs fasttext (same library, prediction-compatible)
  pythonRemoveDeps = [ "fasttext-predict" ];

  dependencies = [ robust-downloader requests fasttext-predict ];

  pythonImportsCheck = [ "fast_langdetect" ];

  meta = {
    description = "Fast language detection using fasttext models";
    homepage = "https://github.com/opendatalab/fast-langdetect";
    license = lib.licenses.asl20;
  };
}
