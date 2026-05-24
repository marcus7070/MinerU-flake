The goal is to package MinerU in a nix flake.

Target: **CPU-only**. Do not add CUDA or GPU support.

To validate the install, run the following and inspect the output has at least Markdown headings and paragraphs:

```
rm -rf ./mineru-smoke-out

mineru \
  -p ./example.pdf \
  -o ./mineru-smoke-out \
  -s 0 \
  -e 0
```

Use nixpkgs-master for as many packages as possible, but you will find many packages either need to be updated to a later version or are not available at all.

Do not use uv, pip, or any other Python package manager. MinerU should be packaged with just nix. Same goes for NPM and package managers from other ecosystems. If in doubt, look for examples in nixpkgs of similar tooling and imitate them.

Strongly prefer `nix` commands over interacting with the nix store directly. The nix store is an internal database; never search it for a package or invoke executables from it directly — there may be patched copies that do not behave as expected. Use `nix build`, `nix run`, `nix shell`, etc. to access the correct versions.

Read `docs/skills/nix-packaging/SKILL.md` for advice on how to generate nix packages.
