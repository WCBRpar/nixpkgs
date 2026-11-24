# pkgs/by-name/er/erpbrasil-edoc/package.nix

{
  lib,
  python,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  erpbrasil-base,
  erpbrasil-assinatura,
  erpbrasil-transmissao,
  pyyaml,
  beautifulsoup4,
}:

buildPythonPackage rec {
  pname = "erpbrasil.edoc";
  version = "3.3.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erpbrasil";
    repo = "erpbrasil.edoc";
    rev = "v${version}";
    hash = "sha256-hoTUa0Ejb3xK/J1aOI6102eJRlGs79WGwsqv9vh+Evc=";
  };

  build-system = [ setuptools ];

  dependencies = [
    erpbrasil-base
    erpbrasil-assinatura
    erpbrasil-transmissao
    pyyaml
    beautifulsoup4
  ];

  doCheck = false;
  dontUsePytestCheck = true;
  dontUsePipInstallCheck = true;

  pythonNamespaces = [ "erpbrasil" ];

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
