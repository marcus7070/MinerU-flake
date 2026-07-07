{ lib, buildPythonPackage, fetchurl, httpx, httpx-retries, aiofiles, pillow, pydantic, loguru }:

buildPythonPackage rec {
  pname = "mineru-vl-utils";
  version = "1.0.5";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/a0/e6/71556a212ab86c8845f5bec220952e08ba288342593161da41076c678627/mineru_vl_utils-1.0.5-py3-none-any.whl";
    hash = "sha256-z5EOaPBgdjTmG2E7f1mS2vYEv4C0ANgee58PEXt8PBU=";
  };

  dependencies = [ httpx httpx-retries aiofiles pillow pydantic loguru ];

  pythonImportsCheck = [ "mineru_vl_utils" ];

  meta = {
    description = "MinerU vision-language model utilities";
    homepage = "https://github.com/opendatalab/MinerU";
    license = lib.licenses.asl20;
  };
}
