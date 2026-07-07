{ lib, buildPythonPackage, fetchurl, autoPatchelfHook }:

buildPythonPackage rec {
  pname = "tilelang";
  version = "0.1.9";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/f7/8a/1cbeee79d62abaa02441c2d00621554e41aa62dbf3b94a4feb3867184b01/tilelang-0.1.9-cp38-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-S7zP6QNa7Xdf+vttwlpZlFBLJOLF2V0POWQ+36+nvxI=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  autoPatchelfIgnoreMissingDeps = [
    "libtvm_ffi.so"
    "libz3.so"
  ];
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];

  meta = {
    description = "Tile-level programming language for high-performance GPU and CPU kernels";
    homepage = "https://github.com/tile-ai/tilelang";
    license = lib.licenses.mit;
  };
}
