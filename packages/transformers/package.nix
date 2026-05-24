{ lib, buildPythonPackage, fetchurl, pythonRelaxDepsHook, python
, filelock, huggingface-hub, numpy, packaging, pyyaml, regex, requests
, tokenizers, safetensors, tqdm }:

buildPythonPackage rec {
  pname = "transformers";
  version = "4.57.6";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/03/b8/e484ef633af3887baeeb4b6ad12743363af7cce68ae51e938e00aaa0529d/transformers-4.57.6-py3-none-any.whl";
    hash = "sha256-TJ6d4RMz3f5RFLyHLJ83BQkZis8Lh6gyoKuUWOK9BVA=";
  };

  nativeBuildInputs = [ pythonRelaxDepsHook ];
  dontBuild = true;
  dontCheckRuntimeDeps = true;

  # nixpkgs huggingface-hub is 1.x; wheel metadata and runtime check require <1.0
  pythonRelaxDeps = [ "huggingface-hub" "tokenizers" ];

  postInstall = ''
    sed -i 's|"huggingface-hub>=0.34.0,<1.0"|"huggingface-hub>=0.34.0"|' \
      "$out/${python.sitePackages}/transformers/dependency_versions_table.py"
  '';

  dependencies = [
    filelock
    huggingface-hub
    numpy
    packaging
    pyyaml
    regex
    requests
    tokenizers
    safetensors
    tqdm
  ];

  pythonImportsCheck = [ "transformers" ];

  meta = {
    description = "State-of-the-art Machine Learning for JAX, PyTorch and TensorFlow";
    homepage = "https://github.com/huggingface/transformers";
    license = lib.licenses.asl20;
  };
}
