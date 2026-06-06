# pkgs/by-name/er/erpbrasil-packages/test.nix
{ lib, python312, erpbrasil-assinatura, erpbrasil-base, erpbrasil-transmissao, erpbrasil-edoc }:

let
  pythonWithDeps = python312.withPackages (ps: [
    erpbrasil-assinatura
    erpbrasil-base
    erpbrasil-transmissao
    erpbrasil-edoc
  ]);
in
  python312.pkgs.buildPythonPackage {
    pname = "erpbrasil-integration-test";
    version = "1.0.0";
    src = ./.;
    dontUnpack = true;
    nativeCheckInputs = [ pythonWithDeps ];
    checkPhase = ''
      python -c "import erpbrasil.assinatura; print('assinatura OK')"
      python -c "import erpbrasil.base; print('base OK')"
      python -c "import erpbrasil.transmissao; print('transmissao OK')"
      python -c "import erpbrasil.edoc; print('edoc OK')"
    '';
  }

