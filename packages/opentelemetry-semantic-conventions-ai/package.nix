{ lib, buildPythonPackage, fetchurl }:

buildPythonPackage rec {
  pname = "opentelemetry-semantic-conventions-ai";
  version = "0.4.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/c4/cd/0e95b78b2ec3137078f4851201c95b3be9b150604193d70169c3bb135603/opentelemetry_semantic_conventions_ai-0.4.1-py3-none-any.whl";
    hash = "sha256-tsbjl2peoxBY+urwRQpqVtRXapc0yUwaTLgjMu5jX+M=";
  };

  pythonImportsCheck = [ "opentelemetry.semconv_ai" ];

  meta = {
    description = "OpenTelemetry semantic conventions extension for generative AI applications";
    homepage = "https://pypi.org/project/opentelemetry-semantic-conventions-ai/";
    license = lib.licenses.asl20;
  };
}
