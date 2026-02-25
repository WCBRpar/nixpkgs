{ lib, python3, fetchFromGitHub, callPackage }:

# A geração dos servidores é realizada pelo pacote pkgs/development/openapi-servers/default.nix

callPackage ../../../development/openapi-servers {
  toolDir = "servers/filesystem";
  extraDeps = [ ];  # nenhuma dependência extra além das comuns
  enableCors = true;
}

