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
      example = "localhost";
      description = "FQDN for the OnlyOffice instance.";
    };

    enableBackup = mkOption {
      type = types.bool;
      default = true;
      description = "Activate daily backups for MySQL and PostgreSQL databases";
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
        description = "Path to a file that contains the password OnlyOffice should use to connect to Postgresql. ";
      };
    };
  };

  config = mkIf cfg.enable {
    # 1. Dependências de Sistema (Globais)
    services.mysql = {
      enable = true;
      package = pkgs.mysql80;
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
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
      # Script de verificação de saúde do OnlyOffice
      (pkgs.writeShellScriptBin "onlyoffice-healthcheck" ''
        echo "--- Verificando Serviços OnlyOffice ---"
        systemctl is-active onlyoffice-communityserver --quiet && echo "[OK] Community Server" || echo "[ERRO] Community Server parado"
        systemctl is-active mysql --quiet && echo "[OK] MySQL" || echo "[ERRO] MySQL parado"
        systemctl is-active postgresql --quiet && echo "[OK] PostgreSQL" || echo "[ERRO] PostgreSQL parado"
        curl -s -I http://localhost:8088 | grep -q "HTTP/1.1 200" && echo "[OK] Web Interface (Port 8088)" || echo "[ERRO] Web Interface não responde"
      '')
    ];

    # 4. Configuração de Systemd com ISOLAMENTO DE SEGURANÇA
    systemd.services.onlyoffice-communityserver = {
      description = "ONLYOFFICE Community Server";
      after = [ "mysql.service" "postgresql.service" "redis-onlyoffice.service" "rabbitmq.service" "elasticsearch.service" "network.target" ];
      requires = [ "mysql.service" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.mono}/bin/mono ${oo-pkgs.communityServer}/var/www/onlyoffice/Services/TeamLabSvc/TeamLabSvc.exe";
        Restart = "always";
        User = "onlyoffice";
        Group = "onlyoffice";

        # --- ISOLAMENTO E PROTEÇÃO ---
        # Impede que o serviço altere arquivos do sistema
        ProtectSystem = "strict";
        # Permite escrita apenas nos diretórios necessários do OnlyOffice
        ReadWritePaths = [
          "/var/www/onlyoffice"
          "/var/log/onlyoffice"
          "/var/lib/onlyoffice"
        ];
        # Protege configurações globais de banco de dados contra escrita
        ReadOnlyPaths = [
          "/etc/mysql"
          "/etc/postgresql"
          "/etc/my.cnf"
        ];
        # Impede acesso direto aos dados brutos de outros bancos
        InaccessiblePaths = [
          "/var/lib/mysql"
          "/var/lib/postgresql"
        ];
        # Outras proteções
        PrivateTmp = true;
        NoNewPrivileges = true;
        DevicePolicy = "closed";
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      };
    };
  };
}

