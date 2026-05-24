{ lib, buildPythonPackage, fetchurl, av, packaging, pillow, requests }:

buildPythonPackage rec {
  pname = "qwen-vl-utils";
  version = "0.0.14";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/c4/43/80f67e0336cb2fc725f8e06f7fe35c1d0fe946f4d2b8b2175e797e07349e/qwen_vl_utils-0.0.14-py3-none-any.whl";
    hash = "sha256-Xihle/0DHla9RHxZAbWN38ODUoXtEA9MVlgOCt4FTpY=";
  };

  dependencies = [ av packaging pillow requests ];

  # qwen_vl_utils imports torch at module load; torch is provided at runtime by mineru
  pythonImportsCheck = [];

  meta = {
    description = "Utility functions for Qwen-VL models";
    homepage = "https://github.com/QwenLM/Qwen-VL";
    license = lib.licenses.asl20;
  };
}
