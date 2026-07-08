# MinerU Nix Flake

Nix flake packaging for [MinerU](https://github.com/opendatalab/MinerU). Converts PDFs and other document formats to Markdown with a CPU pipeline wrapper and an explicit CUDA/vLLM wrapper.

The flake exposes these packages:

| Package | Description |
|---|---|
| `.#mineru` | Default local CPU pipeline wrapper. |
| `.#mineru-pipeline` | Same as `.#mineru`; defaults to `--backend pipeline`. |
| `.#mineru-vllm` | CUDA hybrid wrapper with vLLM 0.21.0; defaults to `--backend hybrid-engine --engine vllm`. |
| `.#vllm` | Local vLLM 0.21.0 Python package used by `.#mineru-vllm`. |
| `.#mineru-models` | Nix-store checkout of `opendatalab/PDF-Extract-Kit-1.0`. |

The flake also exposes top-level apps for each runtime flavour:

| App | Description |
|---|---|
| `.#mineru-cpu` | Run the CPU pipeline wrapper. |
| `.#mineru-cuda` | Run the CUDA hybrid/vLLM wrapper. |
| `.#tests-cuda` | Validate CUDA driver discovery and run a vLLM smoke test. |

## Packaged Models

The wrappers point MinerU at Nix-store model configs and set `MINERU_MODEL_SOURCE=local` when it is not already set.

| Wrapper | Models |
|---|---|
| `.#mineru` / `.#mineru-pipeline` | `opendatalab/PDF-Extract-Kit-1.0` |
| `.#mineru-vllm` | `opendatalab/PDF-Extract-Kit-1.0` and `opendatalab/MinerU2.5-Pro-2605-1.2B` |

## Convert With The CPU Pipeline

```bash
nix run .#mineru-cpu -- -p document.pdf -o ./output
```

The `.#mineru` and `.#mineru-pipeline` packages expose the same wrapper directly. The wrapper adds `--backend pipeline` unless you pass a backend explicitly. The converted Markdown and extracted images are written under `./output/<name>/auto/`.

## Convert With vLLM

```bash
nix run .#mineru-cuda -- -p document.pdf -o ./output --gpu-memory-utilization 0.5
```

The `.#mineru-vllm` package exposes the same wrapper directly. The wrapper adds `--backend hybrid-engine --engine vllm` unless those options are passed explicitly.

At runtime it looks for the CUDA driver library in:

1. the existing `LD_LIBRARY_PATH`
2. `/run/opengl-driver/lib`
3. `/usr/lib/wsl/lib`
4. `/usr/lib/x86_64-linux-gnu`
5. `/usr/lib64`
6. `/usr/lib`

Only directories that exist and contain `libcuda.so.1` or `libcuda.so` are prepended to `LD_LIBRARY_PATH` and `LIBRARY_PATH`. `TRITON_LIBCUDA_PATH` is set to the first detected driver directory. The Nix-built CUDA toolkit remains available through `CUDA_HOME`, `CUDA_PATH`, `PATH`, `LD_LIBRARY_PATH`, and `LIBRARY_PATH`.

## CUDA Validation

```bash
nix run .#tests-cuda
```

This checks CUDA driver discovery, runs `nvidia-smi` when it is available, imports `torch` and `vllm`, verifies CUDA availability through PyTorch, and runs `mineru-vllm` on `example.pdf`. The smoke output is written to `./mineru-smoke-out-vllm`.

## Common Options

| Flag | Description |
|---|---|
| `-p <path>` | Input file (PDF, DOCX, PPTX, XLSX, or image) |
| `-o <dir>` | Output directory |
| `--backend pipeline` | Use the local pipeline backend |
| `-s <n>` / `-e <n>` | Restrict to pages n-m, zero-indexed |
| `-l en` | Hint the document language to improve OCR accuracy |
| `--formula false` | Disable formula detection |
| `--table false` | Disable table detection |
