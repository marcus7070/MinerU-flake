{ lib, buildPythonPackage, fetchurl }:

buildPythonPackage rec {
  pname = "flashinfer-cubin";
  version = "0.6.8.post1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/11/b7/5e3b1a8c67031b421a8bd29c2bc29b900a550bb3392e8bda18bb15b5e476/flashinfer_cubin-0.6.8.post1-py3-none-any.whl";
    hash = "sha256-Q2NtTNOeaUqD12qJ+H/vzfTOy0xPfdItrCXsNowekB8=";
  };

  pythonImportsCheck = [ "flashinfer_cubin" ];

  meta = {
    description = "Pre-compiled CUDA kernels for FlashInfer";
    homepage = "https://github.com/flashinfer-ai/flashinfer";
    license = lib.licenses.asl20;
  };
}
