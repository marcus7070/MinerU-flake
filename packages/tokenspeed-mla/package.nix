{ lib, buildPythonPackage, fetchurl, autoPatchelfHook }:

buildPythonPackage rec {
  pname = "tokenspeed-mla";
  version = "0.1.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/84/01/4bf8b74ead3e8e7c1c809435396254c067a33fde48acc20f602aae622d97/tokenspeed_mla-0.1.2-py3-none-manylinux_2_28_x86_64.whl";
    hash = "sha256-yUZqNR/gOXkuVs9J8+eXRMHcKMevEDBqAuYrjpL6WYU=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  autoPatchelfIgnoreMissingDeps = [
    "libcute_dsl_runtime.so"
    "libtvm_ffi.so"
  ];
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "TokenSpeed MLA kernels";
    homepage = "https://github.com/lightseekorg/tokenspeed";
    license = lib.licenses.mit;
  };
}
