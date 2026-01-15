{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.onlyoffice.workspace;
  # Acessar o conjunto de pacotes definido no all-packages.nix
  oo-pkgs = pkgs.onlyoffice-workspace;
in
{
  options.services.onlyoffice.workspace = {
    enable = mkEnableOption "ONLYOFFICE Workspace";

    domain = mkOption {
      type = types.str;
      example = "localhost";
      description = "FQDN for the OnlyOffice instance.";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "The Postgresql hostname OnlyOffice should use.";
      };
      name = mkOption {
        type = types.str;
        default = "onlyoffice";
        description = "The name of database OnlyOffice should use. ";
      };
      user = mkOption {
        type = types.str;
        default = "onlyoffice";
        description = "The username OnlyOffice should use to connect to Postgresql.";
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Caminho para o arquivo contendo a senha do banco de dados";
      };
    };
  };

  config = mkIf cfg.enable {
    # 1. Dependências de Sistema
    services.mysql = {
      enable = true;
      package = pkgs.mysql80;
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
    };

    services.redis.servers.onlyoffice = {
      enable = true;
      port = 6379;
    };

    services.rabbitmq.enable = true;

    services.elasticsearch = {
      enable = true;
      package = pkgs.elasticsearch7;
    };

    # 2. Configuração do Nginx
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8088"; # Porta padrão do Community Server
          proxyWebsockets = true;
        };
      };
    };

    # 3. Instalação dos Pacotes
    environment.systemPackages = [
      oo-pkgs.communityServer
      oo-pkgs.controlPanel
      oo-pkgs.documentServer
      pkgs.mono
      pkgs.dotnet-sdk_7
    ];

    # 4. Configuração de Systemd (Exemplo simplificado)
    systemd.services.onlyoffice-communityserver = {
      description = "ONLYOFFICE Community Server";
      after = [ "mysql.service" "redis-onlyoffice.service" "rabbitmq.service" "elasticsearch.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.mono}/bin/mono ${oo-pkgs.communityServer}/var/www/onlyoffice/Services/TeamLabSvc/TeamLabSvc.exe";
        Restart = "always";
        User = "onlyoffice";
      };
    };
  };
}

