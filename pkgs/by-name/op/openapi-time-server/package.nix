{ lib, python3, fetchFromGitHub, callPackage }:

# A geração dos servidores é realizada pelo pacote pkgs/development/openapi-servers/default.nix

callPackage ../../../development/openapi-servers {
  toolDir = "servers/time";
  extraDeps = with python3.pkgs; [ pytz python-dateutil ];
  enableCors = true;
}
