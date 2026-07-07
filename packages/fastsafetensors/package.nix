{ lib, buildPythonPackage, fetchurl, typer, autoPatchelfHook }:

buildPythonPackage rec {
  pname = "fastsafetensors";
  version = "0.2.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/f1/c0/13dec18b8a9ec0e5f84c140add9b43261fcc495fbd96c868ac7d647824b0/fastsafetensors-0.2.2-cp313-cp313-manylinux_2_34_x86_64.whl";
    hash = "sha256-lZapEVXfKAZKkhS6Pi3LZUbdl6HfSUZA+Grh5dIga3E=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  dependencies = [ typer ];

  pythonImportsCheck = [ ];

  meta = {
    description = "High-performance safetensors model loader";
    homepage = "https://github.com/foundation-model-stack/fastsafetensors";
    license = lib.licenses.asl20;
  };
}
