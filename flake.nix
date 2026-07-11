{
  description = "MinerU document parser";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      baseOverlay = final: prev: {
        mineru-models = final.callPackage ./packages/mineru-models/default.nix {};

        # Source-built torch (before overlay replaces it with torch-bin) for ROCm overrides
        torch-src = prev.python3Packages.torch;

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
            torch              = pyPrev.torch-bin.overridePythonAttrs (old: {
              passthru = (old.passthru or {}) // {
                cudaSupport = false;
                cudaCapabilities = [ ];
                cudaPackages = { };
                rocmSupport = false;
                rocmPackages = { };
              };
            });
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
            triton-cuda       = pyPrev.triton-cuda;
            flashinfer-cubin  = pyFinal.callPackage ./packages/flashinfer-cubin/package.nix {};
            fastsafetensors   = pyFinal.callPackage ./packages/fastsafetensors/package.nix {};
            opentelemetry-semantic-conventions-ai =
              pyFinal.callPackage ./packages/opentelemetry-semantic-conventions-ai/package.nix {};
            nvidia-cudnn-frontend = pyFinal.callPackage ./packages/nvidia-cudnn-frontend/package.nix {};
            nvidia-cutlass-dsl = pyFinal.callPackage ./packages/nvidia-cutlass-dsl/package.nix {};
            quack-kernels = pyFinal.callPackage ./packages/quack-kernels/package.nix {};
            tilelang = pyFinal.callPackage ./packages/tilelang/package.nix {};
            tokenspeed-mla = pyFinal.callPackage ./packages/tokenspeed-mla/package.nix {};
            mineru-models     = final.mineru-models;
          };
        };
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ baseOverlay ];
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python3.13-vllm-0.21.0"
          ];
          problems.handlers = {
            flashinfer.broken = "ignore";
          };
        };
      };
      pyPkgs = pkgs.python3Packages;

      # ── CPU variant ──
      torchCPU    = pyPkgs.torch-bin;
      torchvisionCPU = pyPkgs.torchvision-bin;
      vllmCPU     = pyPkgs.callPackage ./packages/vllm/package.nix {
        cudaSupport = false; rocmSupport = false;
        torch = torchCPU; torchvision = torchvisionCPU;
        aiohttp = pyPkgs.aiohttp;
        apache-tvm-ffi = pyPkgs.apache-tvm-ffi;
        anthropic = pyPkgs.anthropic;
        bitsandbytes = pyPkgs.bitsandbytes;
        blake3 = pyPkgs.blake3;
        cbor2 = pyPkgs.cbor2;
        cloudpickle = pyPkgs.cloudpickle;
        compressed-tensors = pyPkgs.compressed-tensors;
        cupy = pyPkgs.cupy;
        depyf = pyPkgs.depyf;
        diskcache = pyPkgs.diskcache;
        flashinfer-cubin = pyPkgs.flashinfer-cubin;
        flashinfer = pyPkgs.flashinfer;
        gguf = pyPkgs.gguf;
        grpcio-reflection = pyPkgs.grpcio-reflection;
        ijson = pyPkgs.ijson;
        importlib-metadata = pyPkgs.importlib-metadata;
        lark = pyPkgs.lark;
        llguidance = pyPkgs.llguidance;
        lm-format-enforcer = pyPkgs.lm-format-enforcer;
        mcp = pyPkgs.mcp;
        mistral-common = pyPkgs.mistral-common;
        model-hosting-container-standards = pyPkgs.model-hosting-container-standards;
        msgspec = pyPkgs.msgspec;
        nvidia-cudnn-frontend = pyPkgs.nvidia-cudnn-frontend;
        nvidia-cutlass-dsl = pyPkgs.nvidia-cutlass-dsl;
        nvidia-ml-py = pyPkgs.nvidia-ml-py;
        openai-harmony = pyPkgs.openai-harmony;
        opencv-python-headless = pyPkgs.opencv-python-headless;
        opentelemetry-api = pyPkgs.opentelemetry-api;
        opentelemetry-exporter-otlp = pyPkgs.opentelemetry-exporter-otlp;
        opentelemetry-sdk = pyPkgs.opentelemetry-sdk;
        opentelemetry-semantic-conventions-ai = pyPkgs.opentelemetry-semantic-conventions-ai;
        outlines-core = pyPkgs.outlines-core;
        partial-json-parser = pyPkgs.partial-json-parser;
        prometheus-client = pyPkgs.prometheus-client;
        prometheus-fastapi-instrumentator = pyPkgs.prometheus-fastapi-instrumentator;
        protobuf = pyPkgs.protobuf;
        py-cpuinfo = pyPkgs.py-cpuinfo;
        py-libnuma = pyPkgs.py-libnuma;
        pybase64 = pyPkgs.pybase64;
        python-json-logger = pyPkgs.python-json-logger;
        python-multipart = pyPkgs.python-multipart;
        quack-kernels = pyPkgs.quack-kernels;
        tilelang = pyPkgs.tilelang;
        tokenspeed-mla = pyPkgs.tokenspeed-mla;
        typing-extensions = pyPkgs.typing-extensions;
        watchfiles = pyPkgs.watchfiles;
        xformers = pyPkgs.xformers;
        xgrammar = pyPkgs.xgrammar;
        amdsmi = pyPkgs.amdsmi;
      };
      mineruCPU   = pyPkgs.callPackage ./packages/mineru/package.nix {
        torch = torchCPU;
        torchvision = torchvisionCPU;
      };
      mineruPipeline = mineruCPU;

      # ── CUDA variant ──
      torchCUDA   = pyPkgs.torch.overridePythonAttrs (old: {
        passthru = (old.passthru or {}) // {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages_12_9;
          cudaCapabilities = [ "8.9" ];
          cudaMajorMinorVersion = pkgs.cudaPackages.cudaMajorMinorVersion;
          rocmSupport = false;
          rocmPackages = pkgs.rocmPackages;
        };
      });
      vllmCUDA    = pyPkgs.callPackage ./packages/vllm/package.nix {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages_12_9;
        gpuTargets = [ "8.9" ];
        torch = torchCUDA;
        aiohttp = pyPkgs.aiohttp;
        apache-tvm-ffi = pyPkgs.apache-tvm-ffi;
        anthropic = pyPkgs.anthropic;
        bitsandbytes = pyPkgs.bitsandbytes;
        blake3 = pyPkgs.blake3;
        cbor2 = pyPkgs.cbor2;
        cloudpickle = pyPkgs.cloudpickle;
        compressed-tensors = pyPkgs.compressed-tensors;
        cupy = pyPkgs.cupy;
        depyf = pyPkgs.depyf;
        diskcache = pyPkgs.diskcache;
        flashinfer-cubin = pyPkgs.flashinfer-cubin;
        flashinfer = pyPkgs.flashinfer;
        gguf = pyPkgs.gguf;
        grpcio-reflection = pyPkgs.grpcio-reflection;
        ijson = pyPkgs.ijson;
        importlib-metadata = pyPkgs.importlib-metadata;
        lark = pyPkgs.lark;
        llguidance = pyPkgs.llguidance;
        lm-format-enforcer = pyPkgs.lm-format-enforcer;
        mcp = pyPkgs.mcp;
        mistral-common = pyPkgs.mistral-common;
        model-hosting-container-standards = pyPkgs.model-hosting-container-standards;
        msgspec = pyPkgs.msgspec;
        nvidia-cudnn-frontend = pyPkgs.nvidia-cudnn-frontend;
        nvidia-cutlass-dsl = pyPkgs.nvidia-cutlass-dsl;
        nvidia-ml-py = pyPkgs.nvidia-ml-py;
        openai-harmony = pyPkgs.openai-harmony;
        opencv-python-headless = pyPkgs.opencv-python-headless;
        opentelemetry-api = pyPkgs.opentelemetry-api;
        opentelemetry-exporter-otlp = pyPkgs.opentelemetry-exporter-otlp;
        opentelemetry-sdk = pyPkgs.opentelemetry-sdk;
        opentelemetry-semantic-conventions-ai = pyPkgs.opentelemetry-semantic-conventions-ai;
        outlines-core = pyPkgs.outlines-core;
        partial-json-parser = pyPkgs.partial-json-parser;
        prometheus-client = pyPkgs.prometheus-client;
        prometheus-fastapi-instrumentator = pyPkgs.prometheus-fastapi-instrumentator;
        protobuf = pyPkgs.protobuf;
        py-cpuinfo = pyPkgs.py-cpuinfo;
        py-libnuma = pyPkgs.py-libnuma;
        pybase64 = pyPkgs.pybase64;
        python-json-logger = pyPkgs.python-json-logger;
        python-multipart = pyPkgs.python-multipart;
        quack-kernels = pyPkgs.quack-kernels;
        tilelang = pyPkgs.tilelang;
        tokenspeed-mla = pyPkgs.tokenspeed-mla;
        typing-extensions = pyPkgs.typing-extensions;
        watchfiles = pyPkgs.watchfiles;
        xformers = pyPkgs.xformers;
        xgrammar = pyPkgs.xgrammar;
        amdsmi = pyPkgs.amdsmi;
      };
      mineruCUDA  = mineruCPU.overridePythonAttrs (old: {
        dependencies = (old.dependencies or [ ]) ++ [
          pyPkgs.accelerate pyPkgs.pycountry pyPkgs.uvloop vllmCUDA
        ];
      });

      # ── ROCm variant ──
      torchROCm   = pkgs.torch-src.override {
        rocmSupport = true;
        rocmPackages = pkgs.rocmPackages;
        gpuTargets = [ "gfx1030" ];
      };
      torchvisionROCm = pyPkgs.callPackage ./packages/torchvision/package.nix {
        torch = torchROCm;
      };

      # Rebuild a package to use torchROCm instead of torch-bin and
      # drop triton-bin (both come from the overlay and conflict with
      # torchROCm's own torch/triton propagation).  Also add pkgs.ninja
      # because the ninjaHook from torchROCm's propagated
      # python3Packages.ninja may set buildFlags.
      noOverlayDeps = pname: dep: dep.pname or "" != pname;
      withTorchROCm = pkg: pkg.overridePythonAttrs (old: {
        dependencies =
          builtins.filter (noOverlayDeps "torch") (
            builtins.filter (noOverlayDeps "triton") (old.dependencies or []))
          ++ [torchROCm];
        propagatedBuildInputs =
          builtins.filter (noOverlayDeps "torch") (
            builtins.filter (noOverlayDeps "triton") (old.propagatedBuildInputs or []));
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.ninja ];
      });

      # Same but for wheel-format packages whose buildPhase is a
      # shell function (not an attr) — the ninja hook spuriously
      # activates the default build phase.
      withTorchROCmWheel = pkg: pkg.overridePythonAttrs (old: {
        dependencies =
          builtins.filter (noOverlayDeps "torch") (
            builtins.filter (noOverlayDeps "triton") (old.dependencies or []))
          ++ [torchROCm];
        propagatedBuildInputs =
          builtins.filter (noOverlayDeps "torch") (
            builtins.filter (noOverlayDeps "triton") (old.propagatedBuildInputs or []));
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.ninja ];
        buildPhase = "true";
      });

      vllmROCm    = pyPkgs.callPackage ./packages/vllm/package.nix {
        rocmSupport = true;
        rocmPackages = pkgs.rocmPackages;
        gpuTargets = [ "gfx1030" ];
        torch = torchROCm;
        torchvision = torchvisionROCm;
        aiohttp = pyPkgs.aiohttp;
        apache-tvm-ffi = withTorchROCm pyPkgs.apache-tvm-ffi;
        anthropic = pyPkgs.anthropic;
        bitsandbytes = pyPkgs.bitsandbytes;
        blake3 = pyPkgs.blake3;
        cbor2 = pyPkgs.cbor2;
        cloudpickle = pyPkgs.cloudpickle;
        compressed-tensors = withTorchROCm pyPkgs.compressed-tensors;
        cupy = pyPkgs.cupy;
        depyf = pyPkgs.depyf;
        diskcache = pyPkgs.diskcache;
        flashinfer-cubin = pyPkgs.flashinfer-cubin;
        flashinfer = pyPkgs.flashinfer;
        gguf = pyPkgs.gguf;
        grpcio-reflection = pyPkgs.grpcio-reflection;
        ijson = pyPkgs.ijson;
        importlib-metadata = pyPkgs.importlib-metadata;
        lark = pyPkgs.lark;
        llguidance = pyPkgs.llguidance;
        lm-format-enforcer = pyPkgs.lm-format-enforcer;
        mcp = pyPkgs.mcp;
        mistral-common = pyPkgs.mistral-common;
        model-hosting-container-standards = pyPkgs.model-hosting-container-standards;
        msgspec = pyPkgs.msgspec;
        nvidia-cudnn-frontend = pyPkgs.nvidia-cudnn-frontend;
        nvidia-cutlass-dsl = pyPkgs.nvidia-cutlass-dsl;
        nvidia-ml-py = pyPkgs.nvidia-ml-py;
        openai-harmony = pyPkgs.openai-harmony;
        opencv-python-headless = pyPkgs.opencv-python-headless;
        opentelemetry-api = pyPkgs.opentelemetry-api;
        opentelemetry-exporter-otlp = pyPkgs.opentelemetry-exporter-otlp;
        opentelemetry-sdk = pyPkgs.opentelemetry-sdk;
        opentelemetry-semantic-conventions-ai = pyPkgs.opentelemetry-semantic-conventions-ai;
        outlines-core = withTorchROCm pyPkgs.outlines-core;
        partial-json-parser = pyPkgs.partial-json-parser;
        prometheus-client = pyPkgs.prometheus-client;
        prometheus-fastapi-instrumentator = pyPkgs.prometheus-fastapi-instrumentator;
        protobuf = pyPkgs.protobuf;
        py-cpuinfo = pyPkgs.py-cpuinfo;
        py-libnuma = pyPkgs.py-libnuma;
        pybase64 = pyPkgs.pybase64;
        python-json-logger = pyPkgs.python-json-logger;
        python-multipart = pyPkgs.python-multipart;
        quack-kernels = pyPkgs.quack-kernels;
        tilelang = withTorchROCmWheel pyPkgs.tilelang;
        tokenspeed-mla = pyPkgs.tokenspeed-mla;
        typing-extensions = pyPkgs.typing-extensions;
        watchfiles = pyPkgs.watchfiles;
        xformers = pyPkgs.xformers;
        xgrammar = withTorchROCm pyPkgs.xgrammar;
        amdsmi = pyPkgs.amdsmi;
      };
      mineruROCm  = mineruCPU.overridePythonAttrs (old: {
        dependencies =
          builtins.filter (dep: dep.pname or "" != "torch" && dep.pname or "" != "torchvision") (old.dependencies or [])
          ++ [ torchROCm torchvisionROCm
               (withTorchROCm pyPkgs.accelerate)
               pyPkgs.pycountry pyPkgs.uvloop vllmROCm ];
      });

      mineruCudaToolkit =
        let
          getAllOutputs = p: [
            (pkgs.lib.getBin p)
            (pkgs.lib.getLib p)
            (pkgs.lib.getDev p)
            (pkgs.lib.getOutput "include" p)
          ];
        in pkgs.symlinkJoin {
          name = "mineru-cuda-runtime-${pkgs.cudaPackages.cudaMajorMinorVersion}";
          paths = builtins.concatMap getAllOutputs (with pkgs.cudaPackages; [
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

      rocmToolkit = pkgs.symlinkJoin {
        name = "mineru-rocm-runtime-7.2.1";
        paths = with pkgs.rocmPackages; [
          clr
          rocblas
          miopen-hip
          rccl
          hiprand
          hipsparse
          hipsolver
          rocprim
          hipcub
          rocthrust
          rocm-runtime
        ];
      };

      mineruPipelineModels = pkgs.python3Packages.mineru-models;
      mineruVlmModels = pkgs.fetchgit {
        url = "https://huggingface.co/opendatalab/MinerU2.5-2509-1.2B";
        rev = "1aa090b41282e64fadd79c10572221f91ec21924";
        fetchLFS = true;
        preFetch = ''
          export GIT_SSL_NO_VERIFY=true
        '';
        hash = "sha256-3vfLfMC2Dt9kiFpkcCy19c6h2KT3KfA21BnSrdIfWrY=";
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

      cudaDriverDiscovery = import ./nix/cuda-driver-discovery.nix;
      cudaRuntimeSetup = ''
        export CUDA_HOME=${mineruCudaToolkit}
        export CUDA_PATH=${mineruCudaToolkit}
        export PATH="${mineruCudaToolkit}/bin:''${PATH}"
        export LD_LIBRARY_PATH="${mineruCudaToolkit}/lib:''${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="${mineruCudaToolkit}/lib:''${LIBRARY_PATH:-}"
        ${cudaDriverDiscovery}
        export FLASHINFER_DISABLE_VERSION_CHECK=1
        export FLASHINFER_WORKSPACE_BASE="''${TMPDIR:-/tmp}/mineru-flashinfer-cuda129-link"
      '';

      rocmDriverDiscovery = import ./nix/rocm-driver-discovery.nix;
      # Pipeline models (layout / OCR / MFR) run on CPU to avoid VRAM contention
      # with the vLLM subprocess.  The vLLM subprocess handles GPU inference for
      # the VLM (Qwen2-VL).  Setting MINERU_DEVICE_MODE=cpu causes
      # mineru.utils.config_reader.get_device() (called by HybridModel and OCR)
      # to return "cpu" instead of "cuda".
      rocmRuntimeSetup = ''
        export ROCM_PATH=${rocmToolkit}
        export HIP_VISIBLE_DEVICES=0
        export HSA_OVERRIDE_GFX_VERSION=''${HSA_OVERRIDE_GFX_VERSION:-10.3.0}
        export LD_LIBRARY_PATH="${rocmToolkit}/lib:''${LD_LIBRARY_PATH:-}"
        export PATH="${rocmToolkit}/bin:''${PATH}"
        export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
        export MINERU_DEVICE_MODE=cpu
        ${rocmDriverDiscovery}
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
        package = mineruCPU;
        configFile = mineruPipelineConfig;
        description = "${mineruCPU.meta.description} (local CPU pipeline wrapper)";
        defaults = ''
          if [ "$has_backend" -eq 0 ]; then
            extra_args+=(--backend pipeline)
          fi
        '';
      };
      mineru-cuda = wrapMineru {
        name = "mineru-cuda";
        package = mineruCUDA;
        configFile = mineruVllmConfig;
        description = "${mineruCUDA.meta.description} (CUDA vLLM hybrid wrapper)";
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
      mineru-rocm = wrapMineru {
        name = "mineru-rocm";
        package = mineruROCm;
        configFile = mineruVllmConfig;
        description = "${mineruROCm.meta.description} (ROCm vLLM hybrid wrapper)";
        extraEnv = rocmRuntimeSetup;
        defaults = ''
          if [ "$has_backend" -eq 0 ]; then
            extra_args+=(--backend hybrid-engine)
          fi
          if [ "$has_engine" -eq 0 ]; then
            extra_args+=(--engine vllm)
          fi
        '';
      };

      cudaTestPython = pkgs.python3.withPackages (_: [
        torchCUDA
        vllmCUDA
      ]);
      rocmTestPython = pkgs.python3.withPackages (_: [
        torchROCm
        vllmROCm
      ]);
      mkGpuTestApp = import ./nix/make-gpu-test-app.nix {
        inherit pkgs;
        examplePdf = ./example.pdf;
      };
    in {
      overlay = baseOverlay;

      packages.${system} = {
        default = mineru-pipeline;
        mineru = mineru-pipeline;
        "mineru-pipeline" = mineru-pipeline;
        "mineru-cuda" = mineru-cuda;
        "mineru-rocm" = mineru-rocm;
        vllm = vllmCPU;
        "vllm-cuda" = vllmCUDA;
        "vllm-rocm" = vllmROCm;
        mineru-models = mineruPipelineModels;
      };

      apps.${system} = {
        mineru-cpu = {
          type = "app";
          program = "${pkgs.lib.getExe mineru-pipeline}";
        };
        mineru-cuda = {
          type = "app";
          program = "${pkgs.lib.getExe mineru-cuda}";
        };
        mineru-rocm = {
          type = "app";
          program = "${pkgs.lib.getExe mineru-rocm}";
        };
        tests-cuda = mkGpuTestApp {
          name = "tests-cuda";
          runtimeSetup = cudaRuntimeSetup;
          python = cudaTestPython;
          mineruPackage = mineru-cuda;
          smokeOutput = "./mineru-smoke-out-vllm";
        };
        tests-rocm = mkGpuTestApp {
          name = "tests-rocm";
          runtimeSetup = rocmRuntimeSetup;
          python = rocmTestPython;
          mineruPackage = mineru-rocm;
          smokeOutput = "./mineru-smoke-out-rocm";
        };
      };

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
