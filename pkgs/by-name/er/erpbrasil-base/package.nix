# pkgs/by-name/er/erpbrasil-base/package.nix
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  cerberus,
  lxml,
  erpbrasil-assinatura,
}:

buildPythonPackage rec {
  pname = "erpbrasil.base";
  version = "2.4.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erpbrasil";
    repo = "erpbrasil.base";
    rev = "v${version}";
    hash = "sha256-st6vfLt7J/3AO4YBoz2sMGvll9We3s8aOyW12kLUbIA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    cerberus
    lxml
    erpbrasil-assinatura
  ];

  pythonImportsCheck = [ "erpbrasil.base" ];

  # Testes podem exigir dependências adicionais
  doCheck = false; # Habilitar quando testes estiverem configurados

  meta = with lib; {
    description = "Biblioteca base para sistemas ERP brasileiros";
    longDescription = ''
      Biblioteca base com funcionalidades comuns para sistemas ERP brasileiros,
      incluindo validação de documentos fiscais, formatação de dados e
      configurações compartilhadas.
    '';
    homepage = "https://github.com/erpbrasil/erpbrasil.base";
    changelog = "https://github.com/erpbrasil/erpbrasil.base/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor akretion kmee ];
  };
}
