{ lib, stdenv, fetchurl, dpkg, makeWrapper, mono, dotnet-sdk_7, nodejs, mysql80, postgresql, redis, rabbitmq-server, elasticsearch7, nginx, ffmpeg, certbot, rsyslog }:

let
  # Versões extraídas do repositório oficial
  versions = {
    communityserver = "12.7.1.1942";
    controlpanel = "3.5.4.541";
    documentserver = "9.2.1";
  };

  # URLs dos pacotes deb
  urls = {
    communityserver = "https://download.onlyoffice.com/repo/debian/pool/main/o/onlyoffice-communityserver/onlyoffice-communityserver_${versions.communityserver}_all.deb";
    controlpanel = "https://download.onlyoffice.com/repo/debian/pool/main/o/onlyoffice-controlpanel/onlyoffice-controlpanel_${versions.controlpanel}_all.deb";
    documentserver = "https://download.onlyoffice.com/repo/debian/pool/main/o/onlyoffice-documentserver/onlyoffice-documentserver_${versions.documentserver}_amd64.deb";
  };

  # Função auxiliar para criar derivações a partir de pacotes deb
  mkOnlyOfficePkg = { pname, version, url, sha256 ? lib.fakeSha256 }: stdenv.mkDerivation {
    inherit pname version;
    src = fetchurl { inherit url sha256; };
    nativeBuildInputs = [ dpkg makeWrapper ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

in
{
  communityServer = mkOnlyOfficePkg {
    pname = "onlyoffice-communityserver";
    version = versions.communityserver;
    url = urls.communityserver;
    sha256 = "sha256-UUlDnEsd3xHjfSJyNyRE7LqjNXWB36HT+7ss8PXCQFk=";
  };

  controlPanel = mkOnlyOfficePkg {
    pname = "onlyoffice-controlpanel";
    version = versions.controlpanel;
    url = urls.controlpanel;
    sha256 = "sha256-ucPBZEvzp+waqr6krd7xHvWOWPCiih+GG7TcO08Ai1Y=";
  };

  documentServer = mkOnlyOfficePkg {
    pname = "onlyoffice-documentserver";
    version = versions.documentserver;
    url = urls.documentserver;
    sha256 = "sha256-/H/x069JA9MtrfILos5KRT0IKOHKOuS7nI1ZspizvvA=";
  };
}

