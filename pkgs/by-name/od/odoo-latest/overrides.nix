# overrides.nix
{ fetchFromGitHub, fetchhg }:

pythonFinal: pythonPrev: {
  # rlPyCairo – necessário para relatórios PDF
  rlPyCairo = pythonPrev.buildPythonPackage {
    pname = "rlPyCairo";
    version = "0.4.0";
    pyproject = true;
    src = fetchhg {
      url = "https://hg.reportlab.com/hg-public/rlPyCairo";
      rev = "a3e9ae26d82d";
      hash = "sha256-9jAKmYwOkyqbXlK4Q0TO9Fc0jTebaShhyo1/NEroFzE=";
    };
    build-system = [ pythonPrev.setuptools ];
    dependencies = [
      pythonPrev.pycairo
      pythonPrev.freetype-py
    ];
  };

  # PyPDF2 versão fixa
  pypdf2 = pythonPrev.pypdf2.overrideAttrs (old: {
    version = "2.12.1";
    src = fetchFromGitHub {
      owner = "py-pdf";
      repo = "PyPDF2";
      rev = "2.12.1";
      hash = "sha256-51fnnu6T/SOcSK+yVAAugPN7mjCEqhy6nnpNP4ZTLk8=";
    };
    doCheck = false;
  });

  # Seus pacotes personalizados (ajuste os caminhos)
  erpbrasil-assinatura = pythonFinal.callPackage ../../../development/python-modules/erpbrasil-assinatura { };
  erpbrasil-base       = pythonFinal.callPackage ../../../development/python-modules/erpbrasil-base { };
  erpbrasil-transmissao = pythonFinal.callPackage ../../../development/python-modules/erpbrasil-transmissao { };
  erpbrasil-edoc       = pythonFinal.callPackage ../../../development/python-modules/erpbrasil-edoc { };
  brazilcep            = pythonFinal.callPackage ../../../development/python-modules/brazilcep { };
  workalendar          = pythonFinal.callPackage ../../../development/python-modules/workalendar { };
}
