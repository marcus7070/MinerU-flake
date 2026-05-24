# MinerU Nix Flake

CPU-only [MinerU](https://github.com/opendatalab/MinerU) packaged as a Nix flake. Converts PDFs (and other document formats) to Markdown.

## One-time model download

MinerU requires local model weights before it can process documents. Download the pipeline models once:

```bash
nix shell . --command mineru-models-download -s modelscope -m pipeline
```

This writes a config file at `~/mineru.json` and downloads roughly 2 GB of models to
`~/.cache/modelscope/hub/models/OpenDataLab/PDF-Extract-Kit-1___0`.

> **Note:** If HuggingFace is reachable from your machine you can omit `-s modelscope` and the
> models will be fetched from there instead.

## Convert a document

```bash
MINERU_MODEL_SOURCE=local nix run . -- -p document.pdf -o ./output --backend pipeline
```

The converted Markdown and extracted images are written under `./output/<name>/auto/`.

### Common options

| Flag | Description |
|---|---|
| `-p <path>` | Input file (PDF, DOCX, PPTX, XLSX, or image) |
| `-o <dir>` | Output directory |
| `--backend pipeline` | Use the local pipeline backend (CPU-friendly) |
| `-s <n>` / `-e <n>` | Restrict to pages n–m (zero-indexed) |
| `-l en` | Hint the document language to improve OCR accuracy |
| `--formula false` | Disable formula detection (faster) |
| `--table false` | Disable table detection (faster) |
