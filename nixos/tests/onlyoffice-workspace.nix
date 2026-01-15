import ./make-test-python.nix ({ pkgs, ... }: {
  name = "onlyoffice-workspace";

  nodes.machine = { config, pkgs, ... }: {
    services.onlyoffice.workspace = {
      enable = true;
      domain = "test.local";
      jwtSecret = "test-secret";
      database.password = "test-password";
    };
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("postgresql.service")
    machine.wait_for_unit("onlyoffice-communityserver.service")
    machine.wait_for_unit("onlyoffice-documentserver.service")

    # Verificar se serviços estão rodando
    machine.succeed("curl -f http://localhost:80/")
    machine.succeed("curl -f http://localhost:8000/healthcheck")
  '';
})
