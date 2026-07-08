{
  pkgs,
  examplePdf,
}:

{
  name,
  runtimeSetup,
  python,
  mineruPackage,
  smokeOutput,
}:

let
  script = pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      set -euo pipefail

      ${runtimeSetup}

      if [ -z "''${MINERU_CUDA_DRIVER_DIR:-}" ]; then
        echo "No CUDA driver library found. Checked LD_LIBRARY_PATH, /run/opengl-driver/lib, /usr/lib/wsl/lib, /usr/lib/x86_64-linux-gnu, /usr/lib64, and /usr/lib." >&2
        exit 1
      fi
      echo "CUDA driver directory: $MINERU_CUDA_DRIVER_DIR"

      if command -v nvidia-smi >/dev/null 2>&1; then
        if ! nvidia-smi; then
          echo "nvidia-smi failed; continuing with Python CUDA checks." >&2
        fi
      else
        echo "nvidia-smi not found on PATH; continuing with Python CUDA checks."
      fi

      ${python}/bin/python - <<'PY'
      import torch
      import vllm

      print("torch", torch.__version__)
      print("vllm", vllm.__version__)
      print("cuda_available", torch.cuda.is_available())
      print("cuda_device_count", torch.cuda.device_count())
      if not torch.cuda.is_available():
          raise SystemExit("torch does not report CUDA availability")
      PY

      rm -rf ${smokeOutput}
      ${mineruPackage}/bin/mineru \
        -p ${examplePdf} \
        -o ${smokeOutput} \
        -s 0 \
        -e 0 \
        --gpu-memory-utilization "''${MINERU_TEST_GPU_MEMORY_UTILIZATION:-0.5}"

      if [ -z "$(find ${smokeOutput} -type f -name '*.md' -print -quit)" ]; then
        echo "Expected Markdown output under ${smokeOutput}, but none was found." >&2
        exit 1
      fi
      if [ -z "$(find ${smokeOutput} -type f -name '*content_list.json' -print -quit)" ]; then
        echo "Expected content JSON output under ${smokeOutput}, but none was found." >&2
        exit 1
      fi
    '';
  };
in {
  type = "app";
  program = "${script}/bin/${name}";
}
