{ lib
, buildPythonPackage
, fetchurl
, python
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
, safetensors
, torch
, torchvision
}:

buildPythonPackage rec {
  pname = "mineru";
  version = "3.4.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/78/5e/6b28b36c0f4d3a9051317c7660323043851d7db68b06ec7a16cba1f179a7/mineru-3.4.2-py3-none-any.whl";
    hash = "sha256-iXtwx7rAY31DLecyvO5Y17qsnrEHWIHLWNspgAGF+H0=";
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
    safetensors
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
    substituteInPlace "$out/${python.sitePackages}/mineru/backend/vlm/vlm_analyze.py" \
      --replace-fail \
        "AsyncEngineArgs(**kwargs)" \
        "AsyncEngineArgs(**{k: v for k, v in kwargs.items() if k != 'engine'})"

    substituteInPlace "$out/${python.sitePackages}/mineru/utils/cli_parser.py" \
      --replace-fail \
        "    except ValueError:
            return raw_value" \
        "    except ValueError:
            import json
            try:
                return json.loads(raw_value)
            except ValueError:
                return raw_value"

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
