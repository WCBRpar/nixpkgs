{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.onlyoffice.workspace;

  # Diretórios
  dataDir = "/var/lib/onlyoffice";
  logDir = "/var/log/onlyoffice";
  configDir = "/etc/onlyoffice";

  # Scripts auxiliares
  workspacePkg = pkgs.onlyoffice-workspace;

in {
  ###### Interface
  options.services.onlyoffice.workspace = {
    enable = mkEnableOption "ONLYOFFICE Workspace complete suite";

    package = mkOption {
      type = types.package;
      default = pkgs.onlyoffice-workspace;
      defaultText = "pkgs.onlyoffice-workspace";
      description = "ONLYOFFICE Workspace package to use.";
    };

    # Configuração geral
    domain = mkOption {
      type = types.str;
      default = config.networking.domain or "localhost";
      description = "Domain for the workspace";
    };

    # Segurança
    jwtSecret = mkOption {
      type = types.str;
      default = "";
      description = "JWT secret for inter-service communication";
    };

    # Banco de dados
    database = {
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "PostgreSQL host";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port";
      };

      username = mkOption {
        type = types.str;
        default = "onlyoffice";
        description = "PostgreSQL username";
      };

      password = mkOption {
        type = types.str;
        default = "";
        description = "PostgreSQL password";
      };
    };

    # --- DOCUMENT SERVER CONFIG ---
    documentserver = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Document Server";
      };

      port = mkOption {
        type = types.port;
        default = 8000;
        description = "Internal port for the Document Server API";
      };

      # Outras opções específicas do Document Server podem ser adicionadas aqui
      jwtSecret = mkOption {
        type = types.str;
        default = "";
        description = "JWT secret for Document Server (Inherit from WorkSpace if not specified)";
      };
    };

    # --- COMMUNITY SERVER CONFIG ---
    communityserver = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Community Server";
      };

      port = mkOption {
        type = types.port;
        default = 80;
        description = "Internal port for the Community Server (backend .NET)";
      };

      # Opções específicas do Community Server
      siteUrl = mkOption {
        type = types.str;
        default = "";
        description = "Full URL to the community server (e.g., https://office.example.com)";
      };
    };

    # --- MAIL SERVER CONFIG ---
    mailserver = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Mail Server";
      };

      port = mkOption {
        type = types.port;
        default = 8081;
        description = "Internal port for the Mail Server API (Node.js)";
      };

      # Portas para serviços de email
      smtpPort = mkOption {
        type = types.port;
        default = 25;
        description = "Port for SMTP service";
      };

      smtpsPort = mkOption {
        type = types.port;
        default = 587;
        description = "Port for SMTP over SSL";
      };

      imapPort = mkOption {
        type = types.port;
        default = 143;
        description = "Port for IMAP service";
      };

      imapsPort = mkOption {
        type = types.port;
        default = 993;
        description = "Port for IMAP over SSL";
      };

      pop3Port = mkOption {
        type = types.port;
        default = 110;
        description = "Port for POP3 service";
      };

      pop3sPort = mkOption {
        type = types.port;
        default = 995;
        description = "Port for POP3 over SSL";
      };

      # Configurações específicas do Mail Server
      domain = mkOption {
        type = types.str;
        default = "";
        description = "Mail domain (Inherit from WorkSpace if not specified)";
      };
    };
  };

  ###### Implementação
  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.jwtSecret != "";
        message = "services.onlyoffice.workspace.jwtSecret must be set";
      }
      {
        assertion = cfg.database.password != "";
        message = "services.onlyoffice.workspace.database.password must be set";
      }
      # Validação de portas únicas
      {
        assertion = !(cfg.documentserver.enable && cfg.communityserver.enable && cfg.documentserver.port == cfg.communityserver.port);
        message = "Document Server and Community Server cannot use the same port";
      }
    ];

    # --- CONFIGURAÇÕES COMPARTILHADAS ---
    users.users.onlyoffice = {
      isSystemUser = true;
      group = "onlyoffice";
      home = dataDir;
      createHome = true;
    };

    users.groups.onlyoffice = {};

    environment.systemPackages = [ workspacePkg ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "onlyoffice" "onlyoffice_mailserver" ];
      ensureUsers = [
        {
          name = cfg.database.username;
          ensureDBOwnership = false;
        }
      ];
    };

    services.redis.servers.onlyoffice = {
      enable = true;
      port = 6379;
    };

    # --- ARQUIVO DE CONFIGURAÇÃO PRINCIPAL ---
    environment.etc."onlyoffice/workspace.env".text = let
      # Helper para usar valores específicos ou herdar do workspace
      mailDomain = if cfg.mailserver.domain != "" then cfg.mailserver.domain else cfg.domain;
      docJwt = if cfg.documentserver.jwtSecret != "" then cfg.documentserver.jwtSecret else cfg.jwtSecret;
      csSiteUrl = if cfg.communityserver.siteUrl != "" then cfg.communityserver.siteUrl else "https://${cfg.domain}";
    in ''
      # ONLYOFFICE Workspace Configuration
      DOMAIN=${cfg.domain}
      JWT_SECRET=${cfg.jwtSecret}

      # Database
      DB_HOST=${cfg.database.host}
      DB_PORT=${toString cfg.database.port}
      DB_NAME=onlyoffice
      DB_USER=${cfg.database.username}
      DB_PASS=${cfg.database.password}

      # Redis
      REDIS_HOST=localhost
      REDIS_PORT=6379

      # Document Server
      DOCUMENT_SERVER_PORT=${toString cfg.documentserver.port}
      DOCUMENT_SERVER_JWT_SECRET=${docJwt}

      # Community Server
      COMMUNITY_SERVER_PORT=${toString cfg.communityserver.port}
      COMMUNITY_SERVER_SITE_URL=${csSiteUrl}

      # Mail Server
      MAIL_SERVER_PORT=${toString cfg.mailserver.port}
      MAIL_SERVER_DOMAIN=${mailDomain}
      ${optionalString cfg.mailserver.enable ''
        SMTP_PORT=${toString cfg.mailserver.smtpPort}
        SMTPS_PORT=${toString cfg.mailserver.smtpsPort}
        IMAP_PORT=${toString cfg.mailserver.imapPort}
        IMAPS_PORT=${toString cfg.mailserver.imapsPort}
        POP3_PORT=${toString cfg.mailserver.pop3Port}
        POP3S_PORT=${toString cfg.mailserver.pop3sPort}
      ''}
    '';

    # --- SERVIÇO DOCUMENT SERVER ---
    systemd.services.onlyoffice-documentserver = mkIf cfg.documentserver.enable {
      description = "ONLYOFFICE Document Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "redis-onlyoffice.service" ];

      serviceConfig = {
        Type = "simple";
        User = "onlyoffice";
        Group = "onlyoffice";
        WorkingDirectory = "${workspacePkg}/opt/onlyoffice/documentserver";
        EnvironmentFile = "${configDir}/workspace.env";
        ExecStart = "${workspacePkg}/bin/onlyoffice-documentserver";
        Restart = "on-failure";
        RestartSec = "10s";

        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = "${dataDir}/documents ${logDir}";
      };

      environment.PORT = toString cfg.documentserver.port;
    };

    # --- SERVIÇO COMMUNITY SERVER ---
    systemd.services.onlyoffice-communityserver = mkIf cfg.communityserver.enable {
      description = "ONLYOFFICE Community Server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "redis-onlyoffice.service"
        "onlyoffice-documentserver.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = "onlyoffice";
        Group = "onlyoffice";
        WorkingDirectory = "${workspacePkg}/opt/onlyoffice/communityserver";
        EnvironmentFile = "${configDir}/workspace.env";
        ExecStart = "${workspacePkg}/bin/onlyoffice-communityserver";
        Restart = "on-failure";
        RestartSec = "10s";

        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = "${dataDir}/community ${logDir}";
      };

      environment = {
        ASPNETCORE_ENVIRONMENT = "Production";
        ASPNETCORE_URLS = "http://*:${toString cfg.communityserver.port}";
      };
    };

    # --- SERVIÇO MAIL SERVER ---
    systemd.services.onlyoffice-mailserver-api = mkIf cfg.mailserver.enable {
      description = "ONLYOFFICE Mail Server API";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
        "redis-onlyoffice.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = "onlyoffice";
        Group = "onlyoffice";
        WorkingDirectory = "${workspacePkg}/opt/onlyoffice/mailserver/api";
        EnvironmentFile = "${configDir}/workspace.env";
        ExecStart = "${workspacePkg}/bin/onlyoffice-mailserver-api";
        Restart = "on-failure";
        RestartSec = "10s";

        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = "${dataDir}/mail ${logDir}";
      };

      environment.PORT = toString cfg.mailserver.port;
    };

    # --- NGINX CONFIGURAÇÃO ---
    services.nginx = mkIf (cfg.communityserver.enable || cfg.documentserver.enable) {
      enable = true;

      virtualHosts."${cfg.domain}" = mkIf cfg.communityserver.enable {
        locations."/" = {
          proxyPass = "http://localhost:${toString cfg.communityserver.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        # Rota para Document Server integrado
        locations."/doc/" = mkIf cfg.documentserver.enable {
          proxyPass = "http://localhost:${toString cfg.documentserver.port}/";
          proxyWebsockets = true;
        };
      };
    };

    # --- FIREWALL CONFIGURAÇÃO ---
    networking.firewall = mkIf config.networking.firewall.enable {
      # Portas web (Nginx)
      allowedTCPPorts =
        (optional cfg.communityserver.enable 80) ++
        (optional cfg.communityserver.enable 443)

      # Portas de email
        (optionals cfg.mailserver.enable [
          cfg.mailserver.smtpPort
          cfg.mailserver.smtpsPort
          cfg.mailserver.imapPort
          cfg.mailserver.imapsPort
          cfg.mailserver.pop3Port
          cfg.mailserver.pop3sPort
        ]);
    };

    # --- INICIALIZAÇÃO DO BANCO DE DADOS ---
    systemd.services.onlyoffice-db-init = {
      description = "ONLYOFFICE Database Initialization";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ];
      before = [
        "onlyoffice-communityserver.service"
        "onlyoffice-mailserver-api.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
        RemainAfterExit = true;
      };

      script = let
        schemaDir = "${workspacePkg}/opt/onlyoffice/communityserver/sql";
      in ''
        # Ensure DB ownership and privileges
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE onlyoffice TO ${cfg.database.username};"
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE onlyoffice_mailserver TO ${cfg.database.username};"

        # Community Server schema
        if [ -f "${schemaDir}/createdb.sql" ]; then
          psql -U ${cfg.database.username} -d onlyoffice -f "${schemaDir}/createdb.sql"
        fi

        # Mail Server schema
        if [ -f "${workspacePkg}/opt/onlyoffice/mailserver/configs/sql/schema.sql" ]; then
          psql -U ${cfg.database.username} -d onlyoffice_mailserver \
            -f "${workspacePkg}/opt/onlyoffice/mailserver/configs/sql/schema.sql"
        fi
      '';
    };
  };
}
