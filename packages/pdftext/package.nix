{ lib, buildPythonPackage, fetchurl, pythonRelaxDepsHook, pypdfium2, pydantic, pydantic-settings, click }:

buildPythonPackage rec {
  pname = "pdftext";
  version = "0.6.3";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/bc/b9/4437bb89f04e57f48c96492a50d6168da5e201940de6620730d390449991/pdftext-0.6.3-py3-none-any.whl";
    hash = "sha256-UoQx7Yvc4510NyzT0n6FRK+BLx8a3IHbIpz5+0jayss=";
  };

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  # pdftext requires pypdfium2==4.30.0 (exact pin) but nixpkgs ships 5.x
  pythonRelaxDeps = [ "pypdfium2" ];

  dependencies = [ pypdfium2 pydantic pydantic-settings click ];

  pythonImportsCheck = [ "pdftext" ];

  meta = {
    description = "PDF text extraction using pypdfium2";
    homepage = "https://github.com/VikParuchuri/pdftext";
    license = lib.licenses.asl20;
  };
}
