# pkgs/by-name/er/erpbrasil-packages/tests.nix
{ lib, python312, erpbrasil-assinatura, erpbrasil-base, erpbrasil-transmissao, erpbrasil-edoc, erpbrasil-nfse }:

python312.pkgs.buildPythonPackage {
  name = "erpbrasil-tests";
  src = ./.;

  nativeCheckInputs = [
    erpbrasil-assinatura
    erpbrasil-base
    erpbrasil-transmissao
    erpbrasil-edoc
  ];

  checkPhase = ''
    python -c "import erpbrasil.assinatura; print('assinatura OK')"
    python -c "import erpbrasil.base; print('base OK')"
    python -c "import erpbrasil.transmissao; print('transmissao OK')"
    python -c "import erpbrasil.edoc; print('edoc OK')"
  '';
}
