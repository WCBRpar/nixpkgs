{ config, pkgs, lib, ... }:

{

  # Configuração básica do sistema
  boot.isContainer = true;

  networking = {
    hostName = "onlyoffice-test";
    firewall.enable = false;  # Simplificar para testes
  };

  # Configuração do ONLYOFFICE Workspace
  services.onlyoffice.workspace = {
    enable = true;
    domain = "test.local";

    # Usar segredos de teste (em produção, use algo mais seguro!)
    jwtSecret = "test-jwt-secret-12345";

    database = {
      password = "test-db-password";
    };

    # Configurações mínimas para teste
    documentserver.enable = true;
    communityserver.enable = true;
    mailserver.enable = false;  # Desabilitar inicialmente para testes simples
  };

  # Configurações de banco de dados simplificadas
  services.postgresql = {
    enable = true;
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
    '';
  };

  # Permitir portas para teste
  # networking.firewall.allowedTCPPorts = [ 80 ];
}
