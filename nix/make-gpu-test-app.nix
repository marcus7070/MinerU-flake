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

      if [ -z "''${MINERU_CUDA_DRIVER_DIR:-}" ] && [ -z "''${MINERU_ROCM_DRIVER_DIR:-}" ]; then
        echo "No GPU driver library found. Checked LD_LIBRARY_PATH, /run/opengl-driver/lib, /usr/lib/wsl/lib, /usr/lib/x86_64-linux-gnu, /usr/lib64, and /usr/lib." >&2
        exit 1
      fi
      if [ -n "''${MINERU_CUDA_DRIVER_DIR:-}" ]; then
        echo "CUDA driver directory: $MINERU_CUDA_DRIVER_DIR"
      fi
      if [ -n "''${MINERU_ROCM_DRIVER_DIR:-}" ]; then
        echo "ROCm driver directory: $MINERU_ROCM_DRIVER_DIR"
      fi

      ${python}/bin/python - <<'PY'
      import torch
      import vllm

      print("torch", torch.__version__)
      print("vllm", vllm.__version__)
      print("cuda_available", torch.cuda.is_available())
      print("rocm_available", getattr(torch, "hip", None) is not None)
      print("cuda_device_count", torch.cuda.device_count())
      if not torch.cuda.is_available() and getattr(torch, "hip", None) is None:
          raise SystemExit("torch does not report CUDA or ROCm availability")
      PY

      rm -rf ${smokeOutput}
      # Pipeline models (layout/OCR/MFR) forced to CPU via MINERU_DEVICE_MODE
      # to leave all VRAM for vLLM (see rocmRuntimeSetup in flake.nix).
      #
      # --skip-mm-profiling: encoder profile run allocates ~4 GiB SDPA tensor
      #   on 8 GiB cards; skip it and let the encoder allocate on demand.
      # --compilation-config: RDNA2 (gfx1030) lacks fdot2 used by vLLM compiled
      #   custom ops, so disable all compiled custom ops.
      # --ir-op-priority: avoid vLLM custom kernel runtime compilation issues.
      TORCH_SDPA_ENABLE_FLASH=1 \
      TORCH_SDPA_ENABLE_MEM_EFFICIENT=1 \
      TORCH_SDPA_ENABLE_MATH=0 \
      nohup ${mineruPackage}/bin/mineru \
        -p ${examplePdf} \
        -o ${smokeOutput} \
        -s 0 \
        -e 0 \
        --gpu-memory-utilization "''${MINERU_TEST_GPU_MEMORY_UTILIZATION:-0.5}" \
        --enforce-eager \
        --cpu-offload-gb 3.0 \
        --max-num-seqs 1 \
        --max-model-len 2048 \
        --skip-mm-profiling \
        --compilation-config '{"custom_ops": ["none"], "pass_config": {"fuse_norm_quant": false, "fuse_act_quant": false}}' \
        --ir-op-priority '{"rms_norm": ["native"], "fused_add_rms_norm": ["native"]}'

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
