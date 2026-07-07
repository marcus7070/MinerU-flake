{ fetchgit, lib }:

fetchgit {
  name = "mineru-models-pdf-extract-kit-1.0";
  url = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0";
  rev = "ed6b654c018d742e65a17671e379c5e6ecc87ec9";
  fetchLFS = true;
  preFetch = ''
    export GIT_SSL_NO_VERIFY=true
  '';
  hash = "sha256-08gJuq+iv4gPI2jVoU7xQF+zJQIs99mxwcjozW0JY0Y=";

  meta = {
    description = "PDF-Extract-Kit-1.0 model weights for MinerU";
    homepage = "https://huggingface.co/opendatalab/PDF-Extract-Kit-1.0";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
