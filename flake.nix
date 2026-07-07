{
  description = "MinerU document parser";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      overlay = final: prev: {
        mineru-models = final.callPackage ./packages/mineru-models/default.nix {};

        python3Packages = prev.python3Packages.override {
          overrides = pyFinal: pyPrev: {
            fasttext-predict   = pyPrev.fasttext.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                sed -i 's/np\.array(probs, copy=False)/np.asarray(probs)/g' \
                  "$out/${pyFinal.python.sitePackages}/fasttext/FastText.py"
              '';
            });
            robust-downloader  = pyFinal.callPackage ./packages/robust-downloader/package.nix {};
            fast-langdetect    = pyFinal.callPackage ./packages/fast-langdetect/package.nix {};
            pdftext            = pyFinal.callPackage ./packages/pdftext/package.nix {};
            mineru-vl-utils    = pyFinal.callPackage ./packages/mineru-vl-utils/package.nix {};
            qwen-vl-utils      = pyFinal.callPackage ./packages/qwen-vl-utils/package.nix {};
            pypptx-with-oxml   = pyFinal.callPackage ./packages/pypptx-with-oxml/package.nix {};
            onnxruntime        = pyFinal.callPackage ./packages/onnxruntime-bin/package.nix {};
            torch              =
              if final.config.cudaSupport or false
              then pyPrev.torch-bin.overridePythonAttrs (old: {
                passthru = (old.passthru or {}) // {
                  cudaSupport = true;
                  cudaPackages = final.cudaPackages_12_9;
                  cudaCapabilities = final.config.cudaCapabilities or [ ];
                  rocmSupport = false;
                  rocmPackages = final.rocmPackages;
                };
              })
              else pyPrev.torch-bin;
            torchaudio         = pyPrev.torchaudio-bin;
            torchvision        = pyPrev.torchvision-bin;
            transformers       = pyFinal.callPackage ./packages/transformers/package.nix {};
            cupy               = pyPrev.cupy.overridePythonAttrs (old: {
              env = (old.env or {}) // {
                CUPY_NVCC_GENERATE_CODE = "arch=compute_89,code=sm_89";
              };
              preConfigure = ''
                export CUPY_NUM_BUILD_JOBS=2
                export CUPY_NUM_NVCC_THREADS=2
              '';
              enableParallelBuilding = false;
            });
            compressed-tensors = pyPrev.compressed-tensors.overridePythonAttrs (old: {
              dependencies = (old.dependencies or [ ]) ++ [
                pyFinal.psutil
              ];
              doCheck = false;
            });
            llguidance        = pyPrev.llguidance.overridePythonAttrs (_old: {
              doCheck = false;
            });
            timm              = pyPrev.timm.overridePythonAttrs (_old: {
              doCheck = false;
            });
            xformers          = pyPrev.xformers.overridePythonAttrs (old: {
              preBuild = (old.preBuild or "") + ''
                export MAX_JOBS=2
                export TORCH_DONT_CHECK_COMPILER_ABI=1
              '';
            });
            bitsandbytes      = pyPrev.bitsandbytes.overridePythonAttrs (old: {
              build-system = (old.build-system or [ ]) ++ [
                pyFinal.ninja
              ];
            });
            triton            = pyPrev.triton-bin;
            triton-cuda       =
              if final.config.cudaSupport or false
              then pyFinal.triton
              else pyPrev.triton-cuda;
            flashinfer-cubin  = pyFinal.callPackage ./packages/flashinfer-cubin/package.nix {};
            fastsafetensors   = pyFinal.callPackage ./packages/fastsafetensors/package.nix {};
            opentelemetry-semantic-conventions-ai =
              pyFinal.callPackage ./packages/opentelemetry-semantic-conventions-ai/package.nix {};
            nvidia-cudnn-frontend = pyFinal.callPackage ./packages/nvidia-cudnn-frontend/package.nix {};
            nvidia-cutlass-dsl = pyFinal.callPackage ./packages/nvidia-cutlass-dsl/package.nix {};
            quack-kernels = pyFinal.callPackage ./packages/quack-kernels/package.nix {};
            tilelang = pyFinal.callPackage ./packages/tilelang/package.nix {};
            tokenspeed-mla = pyFinal.callPackage ./packages/tokenspeed-mla/package.nix {};
            vllm              = pyFinal.callPackage ./packages/vllm/package.nix {
              cudaSupport = final.config.cudaSupport or false;
              cudaPackages = final.cudaPackages_12_9;
              gpuTargets = final.config.cudaCapabilities or [ ];
              aiohttp = pyPrev.aiohttp;
              apache-tvm-ffi = pyPrev.apache-tvm-ffi;
              anthropic = pyPrev.anthropic;
              bitsandbytes = pyFinal.bitsandbytes;
              blake3 = pyPrev.blake3;
              cbor2 = pyPrev.cbor2;
              cloudpickle = pyPrev.cloudpickle;
              compressed-tensors = pyFinal.compressed-tensors;
              cupy = pyFinal.cupy;
              depyf = pyPrev.depyf;
              diskcache = pyPrev.diskcache;
              flashinfer-cubin = pyFinal.flashinfer-cubin;
              flashinfer = pyPrev.flashinfer;
              gguf = pyPrev.gguf;
              grpcio-reflection = pyPrev.grpcio-reflection;
              ijson = pyPrev.ijson;
              importlib-metadata = pyPrev.importlib-metadata;
              lark = pyPrev.lark;
              llguidance = pyFinal.llguidance;
              lm-format-enforcer = pyPrev.lm-format-enforcer;
              mcp = pyPrev.mcp;
              mistral-common = pyPrev.mistral-common;
              model-hosting-container-standards = pyPrev.model-hosting-container-standards;
              msgspec = pyPrev.msgspec;
              nvidia-cudnn-frontend = pyFinal.nvidia-cudnn-frontend;
              nvidia-cutlass-dsl = pyFinal.nvidia-cutlass-dsl;
              nvidia-ml-py = pyPrev.nvidia-ml-py;
              openai-harmony = pyPrev.openai-harmony;
              opencv-python-headless = pyPrev.opencv-python-headless;
              opentelemetry-api = pyPrev.opentelemetry-api;
              opentelemetry-exporter-otlp = pyPrev.opentelemetry-exporter-otlp;
              opentelemetry-sdk = pyPrev.opentelemetry-sdk;
              opentelemetry-semantic-conventions-ai = pyFinal.opentelemetry-semantic-conventions-ai;
              outlines-core = pyPrev.outlines-core;
              partial-json-parser = pyPrev.partial-json-parser;
              prometheus-client = pyPrev.prometheus-client;
              prometheus-fastapi-instrumentator = pyPrev.prometheus-fastapi-instrumentator;
              protobuf = pyPrev.protobuf;
              py-cpuinfo = pyPrev.py-cpuinfo;
              py-libnuma = pyPrev.py-libnuma;
              pybase64 = pyPrev.pybase64;
              python-json-logger = pyPrev.python-json-logger;
              python-multipart = pyPrev.python-multipart;
              quack-kernels = pyFinal.quack-kernels;
              tilelang = pyFinal.tilelang;
              tokenspeed-mla = pyFinal.tokenspeed-mla;
              typing-extensions = pyPrev.typing-extensions;
              watchfiles = pyPrev.watchfiles;
              xformers = pyFinal.xformers;
              xgrammar = pyFinal.xgrammar;
            };
            mineru            = pyFinal.callPackage ./packages/mineru/package.nix {};
            mineru-models     = final.mineru-models;
          };
        };
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
        config = {
          allowUnfree = true;
          cudaCapabilities = [ "8.9" ];
        };
      };
      pkgsCuda = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
        config = {
          allowUnfree = true;
          cudaSupport = true;
          cudaCapabilities = [ "8.9" ];
          permittedInsecurePackages = [
            "python3.13-vllm-0.21.0"
          ];
        };
      };

      mineru = pkgs.python3Packages.mineru;
      vllm = pkgsCuda.python3Packages.vllm;
      mineruWithVllm = pkgsCuda.python3Packages.mineru.overridePythonAttrs (old: {
        dependencies = (old.dependencies or [ ]) ++ [
          pkgsCuda.python3Packages.accelerate
          pkgsCuda.python3Packages.pycountry
          pkgsCuda.python3Packages.uvloop
          pkgsCuda.python3Packages.vllm
        ];
      });
      mineruVllmCudaToolkit =
        let
          getAllOutputs = p: [
            (pkgsCuda.lib.getBin p)
            (pkgsCuda.lib.getLib p)
            (pkgsCuda.lib.getDev p)
            (pkgsCuda.lib.getOutput "include" p)
          ];
        in pkgsCuda.symlinkJoin {
          name = "mineru-vllm-cuda-runtime-${pkgsCuda.cudaPackages.cudaMajorMinorVersion}";
          paths = builtins.concatMap getAllOutputs (with pkgsCuda.cudaPackages; [
            cuda_nvcc
            cuda_cudart
            cuda_cccl
            libcurand
            libcusparse
            libcusolver
            cuda_nvtx
            cuda_nvrtc
            libcublas
          ]);
        };
      mineruPipelineModels = pkgs.python3Packages.mineru-models;
      mineruVlmModels = pkgs.fetchgit {
        url = "https://huggingface.co/opendatalab/MinerU2.5-Pro-2605-1.2B";
        rev = "bff20d4ae2bf202df9f45284b4d43681555a97ed";
        fetchLFS = true;
        preFetch = ''
          export GIT_SSL_NO_VERIFY=true
        '';
        hash = "sha256-zlNMnbXS2sDfxIThEHMbL/FCpFxivKsTjMBySHElK1c=";
      };
      mineruPipelineConfig = pkgs.writeText "mineru-pipeline-config.json" (builtins.toJSON {
        "model-source" = "local";
        "models-dir" = {
          pipeline = mineruPipelineModels;
        };
      });
      mineruVllmConfig = pkgs.writeText "mineru-vllm-config.json" (builtins.toJSON {
        "model-source" = "local";
        "models-dir" = {
          pipeline = mineruPipelineModels;
          vlm = mineruVlmModels;
        };
      });
      cudaDriverDiscovery = ''
        _mineru_cuda_driver_candidates=()
        if [ -n "''${LD_LIBRARY_PATH:-}" ]; then
          _mineru_old_ifs="$IFS"
          IFS=:
          for _mineru_dir in $LD_LIBRARY_PATH; do
            if [ -n "$_mineru_dir" ]; then
              _mineru_cuda_driver_candidates+=("$_mineru_dir")
            fi
          done
          IFS="$_mineru_old_ifs"
        fi
        _mineru_cuda_driver_candidates+=(
          /run/opengl-driver/lib
          /usr/lib/wsl/lib
          /usr/lib/x86_64-linux-gnu
          /usr/lib64
          /usr/lib
        )

        _mineru_cuda_driver_dirs=
        _mineru_first_cuda_driver_dir=
        for _mineru_dir in "''${_mineru_cuda_driver_candidates[@]}"; do
          if [ -d "$_mineru_dir" ] \
             && { [ -e "$_mineru_dir/libcuda.so.1" ] || [ -e "$_mineru_dir/libcuda.so" ]; }; then
            case ":$_mineru_cuda_driver_dirs:" in
              *":$_mineru_dir:"*) ;;
              *)
                _mineru_cuda_driver_dirs="''${_mineru_cuda_driver_dirs:+$_mineru_cuda_driver_dirs:}$_mineru_dir"
                if [ -z "$_mineru_first_cuda_driver_dir" ]; then
                  _mineru_first_cuda_driver_dir="$_mineru_dir"
                fi
                ;;
            esac
          fi
        done

        export MINERU_CUDA_DRIVER_DIRS="$_mineru_cuda_driver_dirs"
        export MINERU_CUDA_DRIVER_DIR="$_mineru_first_cuda_driver_dir"
        if [ -n "$_mineru_cuda_driver_dirs" ]; then
          export LD_LIBRARY_PATH="$_mineru_cuda_driver_dirs:''${LD_LIBRARY_PATH:-}"
          export LIBRARY_PATH="$_mineru_cuda_driver_dirs:''${LIBRARY_PATH:-}"
          export TRITON_LIBCUDA_PATH="$_mineru_first_cuda_driver_dir"
        fi
      '';
      cudaRuntimeSetup = ''
        export CUDA_HOME=${mineruVllmCudaToolkit}
        export CUDA_PATH=${mineruVllmCudaToolkit}
        export PATH="${mineruVllmCudaToolkit}/bin:''${PATH}"
        export LD_LIBRARY_PATH="${mineruVllmCudaToolkit}/lib:''${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="${mineruVllmCudaToolkit}/lib:''${LIBRARY_PATH:-}"
        ${cudaDriverDiscovery}
        export FLASHINFER_DISABLE_VERSION_CHECK=1
        export FLASHINFER_WORKSPACE_BASE="''${TMPDIR:-/tmp}/mineru-flashinfer-cuda129-link"
      '';
      wrapMineru = {
        name,
        package,
        configFile,
        defaults,
        extraEnv ? "",
        description,
      }: pkgs.symlinkJoin {
        name = "${name}-${package.version}";
        paths = [ package ];

        postBuild = ''
          mv "$out/bin/mineru" "$out/bin/.mineru-plain"
          cat > "$out/bin/mineru" <<'EOF'
          #!${pkgs.runtimeShell}
          set -euo pipefail

          has_backend=0
          has_engine=0

          for arg in "$@"; do
            case "$arg" in
              --backend|-b|--backend=*)
                has_backend=1
                ;;
              --engine|--engine=*)
                has_engine=1
                ;;
            esac
          done

          if [ -z "''${MINERU_MODEL_SOURCE+x}" ]; then
            export MINERU_MODEL_SOURCE=local
          fi

          export MINERU_TOOLS_CONFIG_JSON=${configFile}
          ${extraEnv}

          extra_args=()
          ${defaults}

          exec "$(dirname "$0")/.mineru-plain" "''${extra_args[@]}" "$@"
          EOF
          chmod +x "$out/bin/mineru"
        '';

        meta = package.meta // {
          inherit description;
          mainProgram = "mineru";
        };
      };
      mineru-pipeline = wrapMineru {
        name = "mineru-pipeline";
        package = mineru;
        configFile = mineruPipelineConfig;
        description = "${mineru.meta.description} (local CPU pipeline wrapper)";
        defaults = ''
          if [ "$has_backend" -eq 0 ]; then
            extra_args+=(--backend pipeline)
          fi
        '';
      };
      mineru-vllm = wrapMineru {
        name = "mineru-vllm";
        package = mineruWithVllm;
        configFile = mineruVllmConfig;
        description = "${mineru.meta.description} (local vLLM hybrid wrapper)";
        extraEnv = cudaRuntimeSetup;
        defaults = ''
          if [ "$has_backend" -eq 0 ]; then
            extra_args+=(--backend hybrid-engine)
          fi
          if [ "$has_engine" -eq 0 ]; then
            extra_args+=(--engine vllm)
          fi
        '';
      };
      cudaTestPython = pkgsCuda.python3.withPackages (_: [
        pkgsCuda.python3Packages.torch
        pkgsCuda.python3Packages.vllm
      ]);
      mkGpuTestApp = {
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
                -p ${./example.pdf} \
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
        };
    in {
      inherit overlay;

      packages.${system} = {
        default = mineru-pipeline;
        mineru = mineru-pipeline;
        mineru-pipeline = mineru-pipeline;
        mineru-vllm = mineru-vllm;
        vllm = vllm;
        mineru-models = pkgs.python3Packages.mineru-models;
      };

      apps.${system}.tests-cuda = mkGpuTestApp {
        name = "tests-cuda";
        runtimeSetup = cudaRuntimeSetup;
        python = cudaTestPython;
        mineruPackage = mineru-vllm;
        smokeOutput = "./mineru-smoke-out-vllm";
      };

      # Curried function output. Takes per-invocation
      # { pdf, pdfHash } and returns a derivation. The fixed
      # dependencies are bound once per system at flake-eval
      # time; only the inner closure is evaluated per call,
      # with `pdf` and `pdfHash` substituted.
      #
      # Consumers call
      # `flake.functions.x86_64-linux.process-pdf
      #   { pdf = "..."; pdfHash = "..."; }`
      # via `nix build --expr '<expr>'` with a locked
      # `builtins.getFlake` reference (see the
      # pprtrnt architecture doc §3.1.5 for the full
      # expression).
      functions.${system}.process-pdf = { pdf, pdfHash }:
        let
          pdfInput = builtins.path {
            path = pdf;
            sha256 = pdfHash;
            recursive = false;
            name = "input.pdf";
          };
        in
        (import ./process-pdf.nix {
          stdenv = pkgs.stdenv;
          mineruPipeline = mineru-pipeline;
        }) { pdf = pdfInput; };
    };
}
