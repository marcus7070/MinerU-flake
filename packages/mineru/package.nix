{ lib
, buildPythonPackage
, fetchurl
, pythonRelaxDepsHook
# core deps from nixpkgs
, boto3
, click
, loguru
, numpy
, pdfminer-six
, tqdm
, requests
, httpx
, pillow
, pypdfium2
, pypdf
, reportlab
, modelscope
, huggingface-hub
, json-repair
, opencv4
, scikit-image
, openai
, beautifulsoup4
, magika
, python-docx
, mammoth
, pylatexenc
, lxml
, pandas
, openpyxl
, fastapi
, python-multipart
, uvicorn
# custom packages
, pdftext
, fast-langdetect
, mineru-vl-utils
, qwen-vl-utils
, pypptx-with-oxml
, transformers
, albumentations
, shapely
, pyclipper
, omegaconf
, onnxruntime
, dill
, pyyaml
, ftfy
, torch
, torchvision
}:

buildPythonPackage rec {
  pname = "mineru";
  version = "3.1.15";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/da/05/9b88b06f9dfd4057e4fc32ffd68a19a4fed171a9f60b4d521173e3ab4c6e/mineru-3.1.15-py3-none-any.whl";
    hash = "sha256-xWq+SK8sIVCaPNtpMN6OagFW2f9/Fq+fVLZm4Zdbl8w=";
  };

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  dontBuild = true;
  dontCheckRuntimeDeps = true;

  # opencv-python is provided by nixpkgs opencv4 (pname="opencv")
  pythonRemoveDeps = [ "opencv-python" ];

  dependencies = [
    boto3
    click
    loguru
    numpy
    pdfminer-six
    tqdm
    requests
    httpx
    pillow
    pypdfium2
    pypdf
    reportlab
    pdftext
    modelscope
    huggingface-hub
    json-repair
    opencv4
    fast-langdetect
    scikit-image
    openai
    beautifulsoup4
    magika
    mineru-vl-utils
    qwen-vl-utils
    python-docx
    pypptx-with-oxml
    transformers
    albumentations
    shapely
    pyclipper
    omegaconf
    onnxruntime
    dill
    pyyaml
    ftfy
    torch
    torchvision
    mammoth
    pylatexenc
    lxml
    pandas
    openpyxl
    fastapi
    python-multipart
    uvicorn
  ];

  pythonImportsCheck = [ "mineru" ];

  # wrapPythonPrograms sets up site-packages via site.addsitedir() inside the
  # .mineru-wrapped Python script.  That is in-process only — child processes
  # launched with subprocess/exec (e.g. `python3 -m mineru.cli.fast_api`) do
  # not inherit those paths.  Re-export as PYTHONPATH in the bash wrappers so
  # the entire subprocess chain can locate the mineru package.
  postFixup = ''
    wrapped="$out/bin/.mineru-wrapped"
    if [ -f "$wrapped" ]; then
      # The wrapped script stores paths as a list literal inside functools.reduce().
      # Extract only the /nix/store/.../site-packages entries.
      pythonpath=$(grep -oE "'/nix/store/[^']+'" "$wrapped" \
        | grep "/site-packages'" \
        | tr -d "'" \
        | paste -sd ':')
      for prog in mineru mineru-api; do
        wrapper="$out/bin/$prog"
        if [ -f "$wrapper" ]; then
          chmod +w "$wrapper"
          tmpfile=$(mktemp)
          {
            IFS= read -r shebang
            printf '%s\n' "$shebang"
            printf 'export PYTHONPATH="%s"\n' "$pythonpath"
            cat
          } < "$wrapper" > "$tmpfile"
          chmod +x "$tmpfile"
          mv "$tmpfile" "$wrapper"
        fi
      done
    fi
  '';

  meta = {
    description = "An efficient open-source tool for converting PDFs to Markdown";
    homepage = "https://github.com/opendatalab/MinerU";
    license = lib.licenses.asl20;
    mainProgram = "mineru";
  };
}
