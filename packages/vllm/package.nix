{
  lib,
  stdenv,
  python,
  buildPythonPackage,
  fetchFromGitHub,
  symlinkJoin,
  autoAddDriverRunpath,
  which,
  cmake,
  jinja2,
  ninja,
  packaging,
  setuptools,
  setuptools-scm,
  wheel,
  onednn,
  numactl,
  llvmPackages,
  aiohttp,
  amdsmi,
  anthropic,
  apache-tvm-ffi,
  bitsandbytes,
  blake3,
  cachetools,
  cbor2,
  cloudpickle,
  compressed-tensors,
  depyf,
  diskcache,
  einops,
  fastapi,
  fastsafetensors,
  filelock,
  flashinfer,
  flashinfer-cubin,
  gguf,
  grpcio,
  grpcio-reflection,
  ijson,
  importlib-metadata,
  lark,
  llguidance,
  lm-format-enforcer,
  mcp,
  mistral-common,
  model-hosting-container-standards,
  msgspec,
  numba,
  numpy,
  nvidia-cudnn-frontend,
  nvidia-cutlass-dsl,
  nvidia-ml-py,
  openai,
  openai-harmony,
  opencv-python-headless,
  opentelemetry-api,
  opentelemetry-exporter-otlp,
  opentelemetry-sdk,
  opentelemetry-semantic-conventions-ai,
  outlines-core,
  pandas,
  partial-json-parser,
  pillow,
  prometheus-client,
  prometheus-fastapi-instrumentator,
  protobuf,
  psutil,
  py-cpuinfo,
  py-libnuma,
  pybase64,
  pydantic,
  python-json-logger,
  python-multipart,
  pyzmq,
  quack-kernels,
  regex,
  requests,
  sentencepiece,
  setproctitle,
  six,
  tilelang,
  tiktoken,
  tokenizers,
  tokenspeed-mla,
  torch,
  torchvision,
  tqdm,
  transformers,
  typing-extensions,
  uvicorn,
  watchfiles,
  xformers,
  xgrammar,
  pyyaml,
  cupy,
  cudaSupport ? torch.cudaSupport,
  cudaPackages ? { },
  rocmSupport ? false,
  rocmPackages ? { },
  gpuTargets ? [ ],
}:

let
  inherit (lib) lists strings trivial;
  inherit (cudaPackages) flags;

  shouldUsePkg = pkg: if pkg != null && lib.meta.availableOn stdenv.hostPlatform pkg then pkg else null;

  cutlass = fetchFromGitHub {
    name = "cutlass-source";
    owner = "NVIDIA";
    repo = "cutlass";
    tag = "v4.4.2";
    hash = "sha256-0q9Ad0Z6E/rO2PdM4uQc8H0E0qs9uKc3reHepiHhjEc=";
  };

  composable_kernel_src = fetchFromGitHub {
    name = "composable-kernel-source";
    owner = "ROCm";
    repo = "composable_kernel";
    rev = "13f6d635653bd5ffbfcac8577f1ef09590c23d78";
    hash = "sha256-nS1Apx4kLTIz7U2/X1BVQHiBwa5j59VboaibOhH9ADM=";
  };

  flashmla = stdenv.mkDerivation {
    pname = "flashmla";
    version = "0.21.0-source";

    src = fetchFromGitHub {
      name = "FlashMLA-source";
      owner = "vllm-project";
      repo = "FlashMLA";
      rev = "a6ec2ba7bd0a7dff98b3f4d3e6b52b159c48d78b";
      hash = "sha256-Oj37H0swZdxaprpaHq0XfOCagc0ypYKpS8e6JzqcDQg=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      cp -rva . $out
    '';
  };

  deepgemm = stdenv.mkDerivation {
    pname = "deepgemm";
    version = "0.21.0-source";

    src = fetchFromGitHub {
      name = "DeepGEMM-source";
      owner = "deepseek-ai";
      repo = "DeepGEMM";
      rev = "891d57b4db1071624b5c8fa0d1e51cb317fa709f";
      hash = "sha256-xbgkpMvh5NXuTk7nXkgPs9Pa91XQaTXRronHnSGPfHM=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      cp -rva . $out
    '';
  };

  triton-kernels = fetchFromGitHub {
    owner = "triton-lang";
    repo = "triton";
    tag = "v3.6.0";
    hash = "sha256-JFSpQn+WsNnh7CAPlcpOcUp0nyKXNbJEANdXqmkt4Tc=";
  };

  qutlass = fetchFromGitHub {
    name = "qutlass-source";
    owner = "IST-DASLab";
    repo = "qutlass";
    rev = "830d2c4537c7396e14a02a46fbddd18b5d107c65";
    hash = "sha256-aG4qd0vlwP+8gudfvHwhtXCFmBOJKQQTvcwahpEqC84=";
  };

  vllm-flash-attn = stdenv.mkDerivation {
    pname = "vllm-flash-attn";
    version = "0.21.0-source";

    src = fetchFromGitHub {
      name = "flash-attention-source";
      owner = "vllm-project";
      repo = "flash-attention";
      rev = "f5bc33cfc02c744d24a2e9d50e6db656de40611c";
      hash = "sha256-Bdvg5ROX4EFccrRElYnbGtHS9FD9qLY9ZwYfqTUYOnA=";
    };

    dontConfigure = true;

    buildPhase = ''
      rm -rf csrc/cutlass
      ln -sf ${cutlass} csrc/cutlass
    '' + lib.optionalString rocmSupport ''
      rm -rf csrc/composable_kernel
      ln -sf ${composable_kernel_src} csrc/composable_kernel
    '';

    installPhase = ''
      cp -rva . $out
    '';
  };

  cpuSupport = !cudaSupport && !rocmSupport;

  supportedTorchCudaCapabilities = [
    "3.5" "3.7" "5.0" "5.2" "5.3" "6.0" "6.1" "6.2" "7.0" "7.2" "7.5"
    "8.0" "8.6" "8.7" "8.9" "9.0" "9.0a" "10.0" "10.0a" "10.3" "10.3a"
    "11.0" "11.0a" "12.0" "12.0a" "12.1" "12.1a"
  ];

  supportedCudaCapabilities = lists.intersectLists flags.cudaCapabilities supportedTorchCudaCapabilities;
  unsupportedCudaCapabilities = lists.subtractLists supportedCudaCapabilities flags.cudaCapabilities;

  gpuArchWarner =
    supported: unsupported:
    trivial.throwIf (supported == [ ]) (
      "No supported GPU targets specified. Requested GPU targets: "
      + strings.concatStringsSep ", " unsupported
    ) supported;

  gpuTargetString = strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
      gpuTargets
    else if cudaSupport then
      gpuArchWarner supportedCudaCapabilities unsupportedCudaCapabilities
    else if rocmSupport then
      rocmPackages.clr.localGpuTargets or rocmPackages.clr.gpuTargets
    else
      throw "No GPU targets specified"
  );

  fa3CudaMajorPrefixes = [ "9." "10." "11." "12." ];
  enableFa3 = lib.any (
    target: lib.any (prefix: lib.hasPrefix prefix target) fa3CudaMajorPrefixes
  ) (if gpuTargets != [ ] then gpuTargets else supportedCudaCapabilities);

  mergedCudaLibraries = with cudaPackages; [
    cuda_cudart
    cuda_cccl
    libcurand
    libcusparse
    libcusolver
    cuda_nvtx
    cuda_nvrtc
    libcublas
  ];

  # header path ends up missing rocthrust & its deps
  rocmExtraIncludeFlags = lib.concatMapStringsSep " " (pkg: "-I${lib.getInclude pkg}/include") [
    rocmPackages.rocthrust
    rocmPackages.rocprim
    rocmPackages.hipcub
  ];

  nccl = shouldUsePkg (cudaPackages.nccl or null);

  getAllOutputs = p: [
    (lib.getBin p)
    (lib.getLib p)
    (lib.getDev p)
  ];

  cudaToolkit = symlinkJoin {
    name = "cuda-merged-${cudaPackages.cudaMajorMinorVersion}";
    paths = builtins.concatMap getAllOutputs (
      lib.filter (pkg: pkg != null) (
        [
          cudaPackages.cuda_nvcc
        ]
        ++ mergedCudaLibraries
        ++ [
          nccl
          cudaPackages.cudnn
          cudaPackages.libcufile
        ]
      )
    );
  };
in

buildPythonPackage.override { stdenv = torch.stdenv; } (finalAttrs: {
  pname = "vllm";
  version = "0.21.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-lVgzo6R+l86IH5yxCtfJckVCP86jlgN7ufF5i0Pn2/A=";
  };

  postPatch = ''
    substituteInPlace vllm/model_executor/models/registry.py \
      --replace-fail \
        "_SUBPROCESS_COMMAND, input=input_bytes, capture_output=True" \
        "_SUBPROCESS_COMMAND, input=input_bytes, capture_output=True, env={\"PYTHONPATH\": \":\".join(sys.path)}"

    substituteInPlace pyproject.toml \
      --replace-fail "torch == 2.11.0" "torch >= 2.11.0" \
      --replace-fail "setuptools>=77.0.3,<81.0.0" "setuptools"
  '' + lib.optionalString (!enableFa3) ''
    substituteInPlace setup.py \
      --replace-fail \
        'ext_modules.append(CMakeExtension(name="vllm.vllm_flash_attn._vllm_fa3_C"))' \
        'pass  # FA3 is Hopper-only; this build targets CUDA architectures below SM90.'
  '';

  nativeBuildInputs = [
    which
  ] ++ lib.optionals rocmSupport [
    rocmPackages.hipcc
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
  ];

  build-system = [
    cmake
    jinja2
    ninja
    packaging
    setuptools
    setuptools-scm
    torch
    wheel
  ];

  buildInputs =
    lib.optionals cpuSupport [
      onednn
    ]
    ++ lib.optionals (cpuSupport && stdenv.hostPlatform.isLinux) [
      numactl
    ]
    ++ lib.optionals cudaSupport (
      mergedCudaLibraries
      ++ (with cudaPackages; [
        nccl
        cudnn
        libcufile
      ])
    )
    ++ lib.optionals rocmSupport (
      with rocmPackages;
      [
        rocblas
        miopen-hip
        rccl
        hiprand
        hipsparse
        hipsolver
        rocprim
        hipcub
        rocthrust
        hipfft
        hipblas
        hipblaslt
        rocm-runtime
        clr
        rocrand
        rocsolver
      ]
    )
    ++ lib.optionals stdenv.cc.isClang [
      llvmPackages.openmp
    ];

  dependencies = [
    aiohttp
    anthropic
    apache-tvm-ffi
    blake3
    cachetools
    cbor2
    cloudpickle
    compressed-tensors
    depyf
    diskcache
    einops
    fastapi
    fastsafetensors
    filelock
    gguf
    grpcio
    grpcio-reflection
    ijson
    importlib-metadata
    lark
    llguidance
    lm-format-enforcer
    mcp
    mistral-common
    model-hosting-container-standards
    msgspec
    ninja
    numba
    numpy
    openai
    openai-harmony
    opencv-python-headless
    opentelemetry-api
    opentelemetry-exporter-otlp
    opentelemetry-sdk
    opentelemetry-semantic-conventions-ai
    outlines-core
    pandas
    partial-json-parser
    pillow
    prometheus-client
    prometheus-fastapi-instrumentator
    protobuf
    py-cpuinfo
    pybase64
    pydantic
    python-json-logger
    python-multipart
    pyzmq
    quack-kernels
    regex
    requests
    sentencepiece
    setproctitle
    six
    tilelang
    tiktoken
    tokenizers
    tokenspeed-mla
    torch
    torch.stdenv.cc
    torchvision
    tqdm
    transformers
    typing-extensions
    uvicorn
    watchfiles
    xgrammar
    pyyaml
  ]
  ++ lib.optionals stdenv.targetPlatform.isLinux [
    psutil
    py-libnuma
  ]
  ++ lib.optionals cudaSupport [
    bitsandbytes
    cupy
    flashinfer
    flashinfer-cubin
    nvidia-cudnn-frontend
    nvidia-cutlass-dsl
    nvidia-ml-py
    xformers
  ]
  ++ lib.optionals rocmSupport [
    rocmPackages.rocminfo
    amdsmi
  ];

  dontUseCmakeConfigure = true;

  cmakeFlags = lib.optionals cudaSupport [
    (lib.cmakeFeature "VLLM_CUTLASS_SRC_DIR" "${lib.getDev cutlass}")
    (lib.cmakeFeature "FLASH_MLA_SRC_DIR" "${lib.getDev flashmla}")
    (lib.cmakeFeature "DEEPGEMM_SRC_DIR" "${lib.getDev deepgemm}")
    (lib.cmakeFeature "VLLM_FLASH_ATTN_SRC_DIR" "${lib.getDev vllm-flash-attn}")
    (lib.cmakeFeature "QUTLASS_SRC_DIR" "${lib.getDev qutlass}")
    (lib.cmakeFeature "TORCH_CUDA_ARCH_LIST" "${gpuTargetString}")
    (lib.cmakeFeature "CUTLASS_NVCC_ARCHS_ENABLED" "${cudaPackages.flags.cmakeCudaArchitecturesString}")
    (lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${cudaToolkit}")
    (lib.cmakeFeature "CUDAToolkit_ROOT" "${cudaToolkit}")
    (lib.cmakeFeature "CUDAToolkit_INCLUDE_DIR" "${cudaToolkit}/include")
    (lib.cmakeBool "CMAKE_SKIP_RPATH" true)
    (lib.cmakeBool "CMAKE_SKIP_INSTALL_RPATH" true)
    (lib.cmakeBool "CMAKE_BUILD_WITH_INSTALL_RPATH" true)
  ] ++ lib.optionals rocmSupport [
    (lib.cmakeFeature "VLLM_FLASH_ATTN_SRC_DIR" "${lib.getDev vllm-flash-attn}")
    (lib.cmakeFeature "QUTLASS_SRC_DIR" "${lib.getDev qutlass}")
    (lib.cmakeFeature "PYTORCH_ROCM_ARCH" "${gpuTargetString}")
    (lib.cmakeFeature "ROCM_PATH" "${rocmPackages.clr}")
    (lib.cmakeBool "CMAKE_SKIP_RPATH" true)
    (lib.cmakeBool "CMAKE_SKIP_INSTALL_RPATH" true)
    (lib.cmakeBool "CMAKE_BUILD_WITH_INSTALL_RPATH" true)
  ];

  env = {
    CMAKE_ARGS = lib.concatStringsSep " " finalAttrs.cmakeFlags;
  } // lib.optionalAttrs cudaSupport {
    VLLM_TARGET_DEVICE = "cuda";
    CUDA_HOME = "${cudaToolkit}";
    CUDA_PATH = "${cudaToolkit}";
    TRITON_KERNELS_SRC_DIR = "${lib.getDev triton-kernels}/python/triton_kernels/triton_kernels";
  } // lib.optionalAttrs rocmSupport {
    VLLM_TARGET_DEVICE = "rocm";
    PYTORCH_ROCM_ARCH = gpuTargetString;
    ROCM_PATH = "${rocmPackages.clr}";
    TRITON_KERNELS_SRC_DIR = "${lib.getDev triton-kernels}/python/triton_kernels/triton_kernels";
    HIPFLAGS = rocmExtraIncludeFlags;
    CXXFLAGS = rocmExtraIncludeFlags;
  } // lib.optionalAttrs cpuSupport {
    VLLM_TARGET_DEVICE = "cpu";
    FETCHCONTENT_SOURCE_DIR_ONEDNN = "${onednn.src}";
  };

  preConfigure = ''
    export MAX_JOBS="''${MAX_JOBS:-2}"
    export NVCC_THREADS="''${NVCC_THREADS:-1}"
    export SETUPTOOLS_SCM_PRETEND_VERSION="${finalAttrs.version}"
  '';

  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ "vllm" ];

  passthru = {
    inherit vllm-flash-attn;
    skipBulkUpdate = true;
  };

  meta = {
    description = "High-throughput and memory-efficient inference and serving engine for LLMs";
    changelog = "https://github.com/vllm-project/vllm/releases/tag/v${finalAttrs.version}";
    homepage = "https://github.com/vllm-project/vllm";
    license = lib.licenses.asl20;
    mainProgram = "vllm";
    knownVulnerabilities = [
      "CVE-2026-27893"
      "CVE-2026-44222"
      "CVE-2026-44223"
    ];
  };
})
