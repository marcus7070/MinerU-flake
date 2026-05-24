{ lib, buildPythonPackage, fetchFromGitHub, cmake, ninja, pkg-config
, torch, libjpeg, libpng, python }:

buildPythonPackage rec {
  pname = "torchvision";
  version = "0.26.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "pytorch";
    repo = "vision";
    rev = "v${version}";
    hash = "sha256-FOdDGY3v8yWBhtNo9tZP79/xwrc7AoIY5Y1ZABzWe6g=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config ];

  dontUseCmakeConfigure = true;
  buildInputs = [ torch.lib libjpeg libpng ];

  env = {
    FORCE_CUDA = "0";
    USE_CUDA = "0";
    TORCH_CUDA_ARCH_LIST = "";
    Torch_DIR = "${torch.dev}/share/cmake/Torch";
    CMAKE_PREFIX_PATH = "${torch.dev}/share/cmake";
  };

  dependencies = [ torch ];

  pythonImportsCheck = [ "torchvision" ];

  meta = {
    description = "Image and video datasets and models for torch deep learning";
    homepage = "https://github.com/pytorch/vision";
    license = lib.licenses.bsd3;
  };
}
