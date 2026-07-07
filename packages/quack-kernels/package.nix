{ lib, buildPythonPackage, fetchurl }:

buildPythonPackage rec {
  pname = "quack-kernels";
  version = "0.3.3";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/10/8d/3c3858c5415e76baab6f17a1325eda2d649d3895728dc2d1d6d551cb9fea/quack_kernels-0.3.3-py3-none-any.whl";
    hash = "sha256-h6Upov7ecrP2OQXkaaFubpmItazreT1hb7mtxBWUGhs=";
  };

  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "QuACK kernels";
    homepage = "https://pypi.org/project/quack-kernels/";
    license = lib.licenses.asl20;
  };
}
