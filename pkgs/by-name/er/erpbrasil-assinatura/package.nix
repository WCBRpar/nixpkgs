# pkgs/by-name/er/erpbrasil-assinatura/package.nix

{
  lib,
  python312,
  fetchFromGitHub,
}:

python312.pkgs.buildPythonPackage rec {
  pname = "erpbrasil.assinatura";
  version = "1.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erpbrasil";
    repo = "erpbrasil.assinatura";
    rev = "v${version}";
    hash = "sha256-hHpep9yCpmI0J8rlb/HwHS9BcCt2E50BrcT6DbFhLfE=";
  };

  build-system = [ python312.pkgs.setuptools ];

  dependencies = with python312.pkgs; [
    lxml
    pyxb-x
    cryptography
    pyopenssl
    signxml
  ];

  doCheck = false;

  pythonImportsCheck = [ "erpbrasil.assinatura" ];

  meta = with lib; {
    description = "Biblioteca para assinatura digital de documentos fiscais brasileiros";
    longDescription = ''
      Biblioteca Python para assinatura digital de documentos fiscais eletrônicos
      brasileiros, incluindo NF-e, NFC-e, CT-e, MDF-e e NFSe.
      Suporta certificados digitais A1 e A3.
    '';
    homepage = "https://github.com/erpbrasil/erpbrasil.assinatura";
    changelog = "https://github.com/erpbrasil/erpbrasil.assinatura/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
