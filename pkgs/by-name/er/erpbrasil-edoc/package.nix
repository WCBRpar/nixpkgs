# pkgs/by-name/er/erpbrasil-edoc/package.nix

{
  lib,
  python312,
  fetchFromGitHub,
  erpbrasil-base,
  erpbrasil-assinatura,
  erpbrasil-transmissao,
}:

python312.pkgs.buildPythonPackage rec {
  pname = "erpbrasil.edoc";
  version = "3.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erpbrasil";
    repo = "erpbrasil.edoc";
    rev = "v${version}";
    hash = "sha256-KN33fAwJV48Zok5NhryN4AUL94MBqbzSjt8RgkahZfk=";
  };

  build-system = [ python312.pkgs.setuptools ];

  dependencies = with python312.pkgs; [
    erpbrasil-base
    erpbrasil-assinatura
    erpbrasil-transmissao
    pyyaml
    beautifulsoup4
  ];

  pythonImportsCheck = [ "erpbrasil.edoc" ];

  meta = with lib; {
    description = "Biblioteca para geração de documentos eletrônicos brasileiros";
    longDescription = ''
      Biblioteca para geração, assinatura e transmissão de documentos eletrônicos
      fiscais brasileiros como NF-e, NFC-e, CT-e e MDF-e.
    '';
    homepage = "https://github.com/erpbrasil/erpbrasil.edoc";
    changelog = "https://github.com/erpbrasil/erpbrasil.edoc/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
