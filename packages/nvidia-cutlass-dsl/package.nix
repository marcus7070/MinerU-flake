{ lib, buildPythonPackage, fetchurl }:

buildPythonPackage rec {
  pname = "nvidia-cutlass-dsl";
  version = "4.4.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/a9/03/678dab0383db1ddfc449da216220f40404189eb36eeed9d87a4fa4bdb0e6/nvidia_cutlass_dsl-4.4.2-py3-none-any.whl";
    hash = "sha256-fPue8ZBisFW5Nyx6YnAEck4nVeTIsWw8yIgH1kUBpK4=";
  };

  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "NVIDIA CUTLASS Python DSL";
    homepage = "https://github.com/NVIDIA/cutlass";
    license = lib.licenses.unfree;
  };
}
