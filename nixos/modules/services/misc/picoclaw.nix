{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.picoclaw;
  configFormat = pkgs.formats.json { };
  configFile = configFormat.generate "picoclaw-config.json" {
    agents.defaults = {
      workspace = cfg.workspaceDir;
      model = cfg.model;
      max_tokens = cfg.maxTokens;
      temperature = cfg.temperature;
      max_tool_iterations = cfg.maxToolIterations;
    };
    providers = cfg.providers;
    channels = cfg.channels;
    tools = cfg.tools;
  };
in
{
  meta.maintainers = with lib.maintainers; [ manfredmacx ];

  options.services.picoclaw = {
    enable = lib.mkEnableOption "picoclaw AI assistant gateway";

    package = lib.mkPackageOption pkgs "picoclaw" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "picoclaw";
      description = "User account under which picoclaw runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "picoclaw";
      description = "Group under which picoclaw runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/picoclaw";
      description = "Directory for picoclaw state, config, and workspace.";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/picoclaw/.picoclaw/workspace";
      description = "Workspace directory for the picoclaw agent.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "glm-4.7";
      example = "anthropic/claude-opus-4-5";
      description = "Default model for the picoclaw agent.";
    };

    maxTokens = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Maximum tokens per request.";
    };

    temperature = lib.mkOption {
      type = lib.types.float;
      default = 0.7;
      description = "Sampling temperature for the model.";
    };

    maxToolIterations = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "Maximum tool call iterations per agent run.";
    };

    providers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "LLM provider configurations. Use vllm for local models and openrouter, azure, etc for cloud providers.";
      example = lib.literalExpression ''
        {
          openrouter = {
            api_key = "sk-or-...";
            api_base = "https://openrouter.ai/api/v1";
          };
        }
      '';
    };

    channels = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Chat channel configurations (telegram, discord, etc).";
      example = lib.literalExpression ''
        {
          telegram = {
            enabled = true;
            token = "YOUR_BOT_TOKEN";
            allow_from = [ "YOUR_USER_ID" ];
          };
        }
      '';
    };

    tools = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Tool configurations (web search, etc).";
      example = lib.literalExpression ''
        {
          web = {
            brave = {
              enabled = true;
              api_key = "";
              max_results = 5;
            };
            perplexity = {
              enabled = true;
              api_key = "";
              max_results = 5;
            };
            duckduckgo = {
              enabled = true;
              max_results = 5;
            };
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "picoclaw service user";
    };

    users.groups.${cfg.group} = { };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "picoclaw" ''
        exec sudo -u ${cfg.user} HOME=${cfg.dataDir} ${lib.getExe cfg.package} "$@"
      '')
    ];

    systemd.services.picoclaw = {
      description = "PicoClaw AI Assistant Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = cfg.dataDir;
      };

      preStart = ''
        mkdir -p ${cfg.dataDir}/.picoclaw
        mkdir -p ${cfg.workspaceDir}
        if [ ! -f ${cfg.dataDir}/.picoclaw/config.json ]; then
          cp ${configFile} ${cfg.dataDir}/.picoclaw/config.json
          chmod 640 ${cfg.dataDir}/.picoclaw/config.json
        fi
        chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
      '';

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} gateway";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "5s";
        PermissionsStartOnly = true;

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
      };
    };
  };
}
