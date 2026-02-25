{ config, lib, pkgs, ... }:

with lib;

let
  # Submódulo para cada ferramenta
  toolOpts = { name, ... }: {
    options = {
      enable = mkEnableOption "this OpenAPI tool server";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bind address for the server.";
      };

      port = mkOption {
        type = types.port;
        default = 8000;
        description = "Port to listen on. Each server must use a unique port.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the port in the firewall.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs."openapi-${name}-server";
        defaultText = literalExpression ''pkgs."openapi-${name}-server"'';
        description = "Package to use for this tool server.";
      };
    };
  };

  cfg = config.services.openapi.tools;
  enabledTools = filterAttrs (_: v: v.enable) cfg;
in
{
  options.services.openapi.tools = mkOption {
    type = types.attrsOf (types.submodule toolOpts);
    default = {};
    description = "Set of OpenAPI tool servers to run for Open WebUI.";
    example = literalExpression ''
      {
        time = {
          enable = true;
          host = "192.168.13.130";
          port = 8001;
        };
        filesystem = {
          enable = true;
          host = "192.168.13.130";
          port = 8002;
        };
        git = {
          enable = true;
          host = "192.168.13.130";
          port = 8003;
        };
      }
    '';
  };

  config = mkIf (enabledTools != {}) (mkMerge (mapAttrsToList (name: toolCfg: {
    environment.systemPackages = [ toolCfg.package ];

    systemd.services."openapi-${name}-server" = {
      description = "OpenAPI ${name} server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOST = toolCfg.host;
        PORT = toString toolCfg.port;
      };

      serviceConfig = {
        ExecStart = "${toolCfg.package}/bin/openapi-${name}-server";
        Restart = "always";
        User = "nobody";
        Group = "nogroup";
        WorkingDirectory = "/tmp";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = optionals toolCfg.openFirewall [ toolCfg.port ];
  }) enabledTools));
}
