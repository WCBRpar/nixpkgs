# pkgs/by-name/er/erpbrasil-transmissao/package.nix
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  requests,
  urllib3,
  lxml,
  zeep,
}:

buildPythonPackage rec {
  pname = "erpbrasil.transmissao";
  version = "1.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erpbrasil";
    repo = "erpbrasil.transmissao";
    rev = "v${version}";
    hash = "sha256-vdfsMoaDA6AbvYjg8MKKRb/KMZST5F0dw8G4RaKnPuI=";
  };

  build-system = [ setuptools ];

  dependencies = [
    requests
    urllib3
    lxml
    zeep
  ];

  pythonImportsCheck = [ "erpbrasil.transmissao" ];

  meta = with lib; {
    description = "Biblioteca para transmissão de documentos fiscais brasileiros";
    longDescription = ''
      Biblioteca para transmissão de documentos fiscais eletrônicos brasileiros
      para os webservices das Secretarias da Fazenda e prefeituras.
      Suporta protocolos SOAP e REST para comunicação com os servidores governamentais.
    '';
    homepage = "https://github.com/erpbrasil/erpbrasil.transmissao";
    changelog = "https://github.com/erpbrasil/erpbrasil.transmissao/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor akretion kmee ];
  };
}
