{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.onlyoffice.workspace;
  oo-pkgs = pkgs.onlyoffice-workspace;
in
{
  options.services.onlyoffice.workspace = {
    enable = mkEnableOption "ONLYOFFICE Workspace";

    domain = mkOption {
      type = types.str;
      example = "office.wcbrpar.com";
      description = "Domínio para o ONLYOFFICE Workspace";
    };

    enableBackup = mkOption {
      type = types.bool;
      default = true;
      description = "Ativar backups automáticos diários dos bancos de dados";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "localhost";
      };
      name = mkOption {
        type = types.str;
        default = "onlyoffice";
      };
      user = mkOption {
        type = types.str;
        default = "onlyoffice";
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Caminho para o arquivo contendo a senha do banco de dados";
      };
    };
  };

  config = mkIf cfg.enable {
    # 1. Dependências de Sistema com Configurações de Segurança
    services.mysql = {
      enable = true;
      package = pkgs.mysql80;
      settings = {
        mysqld = {
          innodb_flush_log_at_trx_commit = 1; # Máxima segurança contra perda de dados
          innodb_doublewrite = 1;
        };
      };
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      settings = {
        fsync = "on";
        synchronous_commit = "on";
      };
    };

    # Backups Automáticos
    services.mysqlBackup = mkIf cfg.enableBackup {
      enable = true;
      databases = [ cfg.database.name ];
    };

    services.postgresqlBackup = mkIf cfg.enableBackup {
      enable = true;
      databases = [ cfg.database.name ];
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
          proxyPass = "http://127.0.0.1:8088";
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

    # 4. Configuração de Systemd com Dependências de Parada Segura
    systemd.services.onlyoffice-communityserver = {
      description = "ONLYOFFICE Community Server";

      # After: Garante ordem de início
      # Requires: Se o banco parar, o OnlyOffice para imediatamente
      after = [
        "mysql.service"
        "postgresql.service"
        "redis-onlyoffice.service"
        "rabbitmq.service"
        "elasticsearch.service"
        "network.target"
      ];
      requires = [
        "mysql.service"
        "postgresql.service"
      ];

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.mono}/bin/mono ${oo-pkgs.communityServer}/var/www/onlyoffice/Services/TeamLabSvc/TeamLabSvc.exe";
        Restart = "always";
        User = "onlyoffice";

        # Dá tempo para o serviço encerrar conexões antes do SIGKILL
        TimeoutStopSec = "30s";
      };
    };

    # Ajuste global para dar tempo aos bancos de dados no desligamento do sistema
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=90s
    '';
  };
}

