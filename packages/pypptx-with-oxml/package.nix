{ lib, buildPythonPackage, fetchurl, pillow, xlsxwriter, lxml, typing-extensions }:

buildPythonPackage rec {
  pname = "pypptx-with-oxml";
  version = "1.0.3";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/fb/d8/940fcaa6a1f3763d72751b6bc8054f40beeacd6e9e5b19069c6c73dab5af/pypptx_with_oxml-1.0.3-py3-none-any.whl";
    hash = "sha256-SzzPURheD55g6/KITnQVPX/LAOfk8EYUBOluAmDXu6E=";
  };

  dependencies = [ pillow xlsxwriter lxml typing-extensions ];

  pythonImportsCheck = [ "pptx" ];

  meta = {
    description = "Python-PPTX fork with extended XML and MathML support";
    homepage = "https://github.com/opendatalab/pypptx-with-oxml";
    license = lib.licenses.mit;
  };
}
