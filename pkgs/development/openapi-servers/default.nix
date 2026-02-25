# pkgs/development/openapi-servers/default.nix
#
# Função genérica para empacotar servidores do repositório open-webui/openapi-servers.
# Cada pacote específico (ex: openapi-time-server) deve chamar esta função com os parâmetros:
#   - toolDir: caminho relativo dentro do repositório (ex: "servers/time")
#   - extraDeps: lista de dependências Python adicionais (além das comuns)
#   - pname: (opcional) nome da ferramenta, se não puder ser derivado de toolDir


{ lib
, python3
, fetchFromGitHub
, toolDir
, pname ? null
, extraDeps ? []
, enableCors ? true
}:

let
  actualPname = if pname != null then pname
                else builtins.head (builtins.match "servers/([^/]+)" toolDir);

  src = fetchFromGitHub {
    owner = "open-webui";
    repo = "openapi-servers";
    rev = "main";
    hash = "sha256-hR0rhVFEMdYhYkCg133I/k6sSMXuUKKLWGKEBByAxus=";
  } + "/${toolDir}";

in
python3.pkgs.buildPythonApplication rec {
  pname = "openapi-${actualPname}-server";
  version = "unstable-2026-02-25";

  inherit src;

  format = "other";

  propagatedBuildInputs = with python3.pkgs; [
    fastapi
    uvicorn
    pydantic
    python-multipart
  ] ++ extraDeps;

  dontBuild = true;
  dontConfigure = true;

  postPatch = lib.optionalString enableCors ''
    cat >> main.py <<EOF

from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
EOF
  '';

  installPhase = ''
    runHook preInstall

    # Copia todos os arquivos para um subdiretório específico
    mkdir -p $out/${python3.sitePackages}/openapi_${actualPname}_server
    cp -r . $out/${python3.sitePackages}/openapi_${actualPname}_server/

    # Cria o wrapper que adiciona o diretório do servidor ao sys.path
    mkdir -p $out/bin
    cat > $out/bin/openapi-${actualPname}-server <<EOF
    #!${python3}/bin/python
    import sys
    import os
    import uvicorn

    # Adiciona o diretório do servidor ao path (para imports como 'from config import ...')
    server_dir = os.path.join("$out/${python3.sitePackages}", "openapi_${actualPname}_server")
    sys.path.insert(0, server_dir)

    from main import app

    if __name__ == "__main__":
        uvicorn.run(
            app,
            host=os.environ.get("HOST", "127.0.0.1"),
            port=int(os.environ.get("PORT", "8000")),
        )
    EOF
    chmod +x $out/bin/openapi-${actualPname}-server

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenAPI ${actualPname} server for Open WebUI";
    homepage = "https://github.com/open-webui/openapi-servers/tree/main/${toolDir}";
    license = licenses.mit;
    maintainers = [ maintainers.wjjunyor ];
    platforms = platforms.all;
  };
}
