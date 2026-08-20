{
  description = "MinerU document parser";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      baseOverlay = final: prev: {
        mineru-models = final.callPackage ./packages/mineru-models/default.nix {};

        # Source-built torch (before overlay replaces it with torch-bin) for ROCm overrides
        torch-src = prev.python313Packages.torch;
        # Source-built torchvision (before overlay replaces it with torchvision-bin)
        torchvision-src = prev.python313Packages.torchvision;

        python313Packages = prev.python313Packages.override {
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
            pypptx-with-oxml   = pyFinal.callPackage ./packages/pypptx-with-oxml/package.nix {};
            onnxruntime        = pyFinal.callPackage ./packages/onnxruntime-bin/package.nix {};
            cuda-bindings      = pyPrev.cuda-bindings.override {
              cudaPackages = prev.cudaPackages_13_0;
            };
            torch              = (pyPrev.torch-bin.override {
              cudaPackages = prev.cudaPackages_13_0 // {
                libnvshmem = prev.cudaPackages.libnvshmem;
              };
            }).overridePythonAttrs (old: {
              dontCheckRuntimeDeps = true;
              passthru = (old.passthru or {}) // {
                cudaSupport = false;
                cudaCapabilities = [ ];
                cudaPackages = { };
                rocmSupport = false;
                rocmPackages = { };
              };
            });
            torchaudio         = pyPrev.torchaudio-bin;
            torchvision        = pyPrev.torchvision-bin.override {
              torch-bin = pyFinal.torch;
            };
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
              build-system = builtins.map (dep:
                if (dep.pname or "") == "setuptools" then pyPrev.setuptools_80 else dep
              ) (old.build-system or [ ]);
              dependencies = builtins.filter (dep: (dep.pname or "") != "torch")
                (old.dependencies or []) ++ [ pyFinal.torch ];
              propagatedBuildInputs = builtins.filter (dep: (dep.pname or "") != "torch")
                (old.propagatedBuildInputs or []) ++ [ pyFinal.torch ];
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
            flashinfer         = pyPrev.flashinfer.overridePythonAttrs (_old: {
              # nixpkgs checks for distribution metadata named flashinfer,
              # while this wheel publishes flashinfer_python metadata.
              pythonMetadataCheckPhase = "true";
            });
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
            torch.unsupported-cuda-version = "warn";
          };
        };
      };
      pyPkgs = pkgs.python313Packages;
      # PyTorch's CUDA 13 wheel needs the CUDA 13 sonames below.  NVSHMEM's
      # host ABI is unchanged between these nixpkgs revisions, and reusing the
      # already-built CUDA 12.9 package avoids compiling its large test suite.
      cudaPackagesCUDA = pkgs.cudaPackages_13_0 // {
        libnvshmem = pkgs.cudaPackages.libnvshmem;
      };

      # ── CPU variant ──
      torchCPU    = pkgs.torch-src.override {
        cudaSupport = false;
        rocmSupport = false;
      };
      torchvisionCPU = pkgs.torchvision-src.override {
        torch = torchCPU;
      };
      safetensorsCPU = pyPkgs.safetensors.override {
        torch = torchCPU;
      };
      transformersCPU = pyPkgs.transformers.override {
        safetensors = safetensorsCPU;
      };
      vllmCPU     = pyPkgs.callPackage ./packages/vllm/package.nix {
        cudaSupport = false; rocmSupport = false;
        torch = torchCPU; torchvision = torchvisionCPU;
        transformers = transformersCPU;
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
        safetensors = safetensorsCPU;
        transformers = transformersCPU;
        torch = torchCPU;
        torchvision = torchvisionCPU;
      };
      mineruPipeline = mineruCPU;

      # ── CUDA variant ──
      torchCUDA   = pyPkgs.torch.overridePythonAttrs (old: {
        dontCheckRuntimeDeps = true;
        passthru = (old.passthru or {}) // {
          cudaSupport = true;
          cudaPackages = cudaPackagesCUDA;
          cudaCapabilities = [ "8.9" ];
          cudaMajorMinorVersion = cudaPackagesCUDA.cudaMajorMinorVersion;
          rocmSupport = false;
          rocmPackages = pkgs.rocmPackages;
        };
      });
      torchvisionCUDA = pyPkgs.torchvision;
      vllmCUDA    = pyPkgs.callPackage ./packages/vllm/package.nix {
        cudaSupport = true;
        cudaPackages = cudaPackagesCUDA;
        gpuTargets = [ "8.9" ];
        setuptools = pyPkgs.setuptools_80;
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
        dependencies = builtins.filter (dep:
          let pname = dep.pname or "";
          in pname != "torch" && pname != "torchvision"
            && pname != "transformers" && pname != "safetensors"
        ) (old.dependencies or [ ]) ++ [ torchCUDA torchvisionCUDA
          pyPkgs.transformers pyPkgs.safetensors
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
        numpy = pyPkgs.numpy;
        pillow = pyPkgs.pillow;
        # torchvision 0.26.0 still imports pkg_resources from setup.py;
        # setuptools 82 removed that compatibility module.
        setuptools = pyPkgs.setuptools_80;
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

      # apache-tvm-ffi's CLI test requires a completely silent stderr.  The
      # ROCm torch import emits a harmless warning when no /sys/class/kfd
      # topology exists, which is normal on build hosts without an AMD GPU.
      apacheTvmFFIROCm = (withTorchROCm pyPkgs.apache-tvm-ffi).overridePythonAttrs (_old: {
        doCheck = false;
      });

      vllmROCm    = pyPkgs.callPackage ./packages/vllm/package.nix {
        rocmSupport = true;
        rocmPackages = pkgs.rocmPackages;
        gpuTargets = [ "gfx1030" ];
        torch = torchROCm;
        torchvision = torchvisionROCm;
        aiohttp = pyPkgs.aiohttp;
        apache-tvm-ffi = apacheTvmFFIROCm;
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
          builtins.filter (dep:
            dep.pname or "" != "torch"
            && dep.pname or "" != "torchvision"
            && dep.pname or "" != "transformers"
            && dep.pname or "" != "safetensors") (old.dependencies or [])
          ++ [ torchROCm torchvisionROCm
               pyPkgs.transformers pyPkgs.safetensors
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
          name = "mineru-cuda-runtime-${cudaPackagesCUDA.cudaMajorMinorVersion}";
          paths = builtins.concatMap getAllOutputs (with cudaPackagesCUDA; [
            cuda_nvcc
            cuda_crt
            cuda_cudart
            cccl
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

      mineruPipelineModels = pkgs.python313Packages.mineru-models;
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
        # Include the toolchain layout in the cache name so a previous
        # generated Ninja file cannot retain an obsolete nvcc path.
        export FLASHINFER_WORKSPACE_BASE="''${TMPDIR:-/tmp}/mineru-flashinfer-cuda130-crt-package-link"
      '';

      rocmDriverDiscovery = import ./nix/rocm-driver-discovery.nix;
      # Pipeline models (layout / OCR / MFR) run on CPU to avoid VRAM contention
      # with the vLLM subprocess.  The vLLM subprocess handles GPU inference for
      # the VLM (Qwen2-VL).  Setting MINERU_DEVICE_MODE=cpu causes
      # mineru.utils.config_reader.get_device() (called by HybridModel and OCR)
      # to return "cpu" instead of "cuda".
      rocmRuntimeSetup = ''
        export TORCH_SDPA_ENABLE_FLASH=1
        export TORCH_SDPA_ENABLE_MEM_EFFICIENT=1
        export TORCH_SDPA_ENABLE_MATH=0
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

      cudaTestPython = pkgs.python313.withPackages (_: [
        torchCUDA
        vllmCUDA
      ]);
      rocmTestPython = pkgs.python313.withPackages (_: [
        torchROCm
        vllmROCm
      ]);
      mkGpuTestApp = import ./nix/make-gpu-test-app.nix {
        inherit pkgs;
        examplePdf = ./example.pdf;
      };

      # Default GPU tuning flags for ROCm builds.
      # These are baked into the derivation hash so changing any flag
      # produces a new store path.  The values are tuned for RX 6600
      # (8 GiB VRAM, RDNA2 gfx1030).
      rocmDefaultArgs = [
        "--skip-mm-profiling"
        "--gpu-memory-utilization" "0.5"
        "--enforce-eager"
        "--cpu-offload-gb" "3.0"
        "--max-num-seqs" "1"
        "--max-model-len" "2048"
        "--compilation-config" (builtins.toJSON {
          custom_ops = [ "none" ];
          pass_config = {
            fuse_norm_quant = false;
            fuse_act_quant = false;
          };
        })
        "--ir-op-priority" (builtins.toJSON {
          rms_norm = [ "native" ];
          fused_add_rms_norm = [ "native" ];
        })
      ];
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

      functions.${system}.process-pdf =
        { pdf, variant ? "cpu", extraMineruArgs ? null }:
        let
          effectiveArgs = if extraMineruArgs != null then extraMineruArgs
            else if variant == "rocm" then rocmDefaultArgs
            else if variant == "cuda" then [ ]  # future: cudaDefaultArgs
            else [ ];

          pipeline =
            if variant == "rocm" then mineru-rocm
            else if variant == "cuda" then mineru-cuda
            else mineru-pipeline;
        in
        (import ./process-pdf.nix {
          inherit (pkgs) lib;
          stdenv = pkgs.stdenv;
          mineruPipeline = pipeline;
          extraMineruArgs = effectiveArgs;
        }) { inherit pdf; };
    };
}
