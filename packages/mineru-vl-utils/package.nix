{ lib, buildPythonPackage, fetchurl, httpx, httpx-retries, aiofiles, pillow, pydantic, loguru }:

buildPythonPackage rec {
  pname = "mineru-vl-utils";
  version = "0.2.8";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/7a/cd/bd5f56ee9da7ff8c0f43daa34ee38f2affdf653d6c533c86e531f9160ea2/mineru_vl_utils-0.2.8-py3-none-any.whl";
    hash = "sha256-MDUNyS7ZiAfCN/6AW6Nu1llQpOmOQ211NiJzynuv2ek=";
  };

  dependencies = [ httpx httpx-retries aiofiles pillow pydantic loguru ];

  pythonImportsCheck = [ "mineru_vl_utils" ];

  meta = {
    description = "MinerU vision-language model utilities";
    homepage = "https://github.com/opendatalab/MinerU";
    license = lib.licenses.asl20;
  };
}
