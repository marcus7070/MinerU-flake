{
  lib,
  stdenv,
  buildPythonPackage,
  fetchurl,
  autoPatchelfHook,
  flatbuffers,
  numpy,
  packaging,
  protobuf,
}:

buildPythonPackage rec {
  pname = "onnxruntime";
  version = "1.26.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/3d/26/4d09ddc755a84fc8d5e192991626b0e0680e8f6c5d58f4f1d05c42bc48cf/onnxruntime-1.26.0-cp313-cp313-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-wHr2/G1VV4NfK27nqW2LMjXQxXqOIw797a7hBqijy8Y=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dependencies = [
    flatbuffers
    numpy
    packaging
    protobuf
  ];

  pythonImportsCheck = [ "onnxruntime" ];

  meta = {
    description = "ONNX Runtime is a runtime accelerator for Machine Learning models";
    homepage = "https://onnxruntime.ai";
    license = lib.licenses.mit;
  };
}
