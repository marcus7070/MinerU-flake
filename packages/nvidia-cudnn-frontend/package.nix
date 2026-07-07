{ lib, buildPythonPackage, fetchurl, autoPatchelfHook }:

buildPythonPackage rec {
  pname = "nvidia-cudnn-frontend";
  version = "1.18.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/19/74/3038cf496d5de7cfdff730f5202e438c17d9123de507059340e02ddff9d7/nvidia_cudnn_frontend-1.18.0-cp313-cp313-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-wFRCBrAsrp2k8ETKP+dBa5ngyKgFIoXdPlqPxEXTT5w=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "cuDNN FrontEnd Python library";
    homepage = "https://github.com/NVIDIA/cudnn-frontend";
    license = lib.licenses.unfree;
  };
}
