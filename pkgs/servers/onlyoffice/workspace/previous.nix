{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  writeShellScriptBin,
  nginx,
  postgresql,
  redis,
  rabbitmq-c,
  dotnetCorePackages,
  nodejs,
  yarn,
  python3,
  gnused,
  coreutils,
  gawk,
  ...
}:

let
  # Versão do Workspace (Community Edition)
  workspaceVersion = "12.5.1";

  # Componentes individuais com versões compatíveis
  components = {
    documentserver = {
      version = "9.2.1";
      src = fetchFromGitHub {
        owner = "ONLYOFFICE";
        repo = "DocumentServer";
        rev = "v${components.documentserver.version}";
        sha256 = "sha256-RowNStcWu2oSEw93p/qP09iK0MovdMznN0lTWQ+21dc=";
      };
    };

    communityserver = {
      version = "12.7.1";
      src = fetchFromGitHub {
        owner = "ONLYOFFICE";
        repo = "CommunityServer";
        rev = "v${components.communityserver.version}";
        sha256 = "sha256-qjvChxDhz/G7n/BdxkjzWo8kv/Cv/S3gcjYubB6LptU=";
      };
    };

    mailserver = {
      version = "1.6.74";
      src = fetchFromGitHub {
        owner = "ONLYOFFICE";
        repo = "Docker-MailServer";
        rev = "v${components.mailserver.version}";
        sha256 = "sha256-P/qw+XxCfQ88gP/1cJEcEhISl+KzZo0PjMX1wgxU0Aw=";
      };
    };
  };

  # Builder para o Document Server (baseado no módulo existente)
  buildDocumentServer = { } : stdenv.mkDerivation {
    pname = "onlyoffice-documentserver";
    version = components.documentserver.version;

    src = components.documentserver.src;

    nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

    buildPhase = ''
      # Extrair e preparar arquivos
      mkdir -p $out/opt/onlyoffice/documentserver

      # Copiar estrutura do Document Server
      cp -r * $out/opt/onlyoffice/documentserver/

      # Remover scripts Docker/Systemd que serão substituídos
      rm -rf $out/opt/onlyoffice/documentserver/{Dockerfile,docker-compose.yml,systemd}
    '';

    installPhase = ''
      # Criar scripts de inicialização NixOS
      mkdir -p $out/bin

      cat > $out/bin/onlyoffice-documentserver << 'EOF'
      #!/bin/sh
      export NODE_ENV=production
      export NODE_CONFIG_DIR=$out/opt/onlyoffice/documentserver/config
      exec ${nodejs}/bin/node $out/opt/onlyoffice/documentserver/server.js "\$@"
      EOF
      chmod +x $out/bin/onlyoffice-documentserver
    '';
  };

  # Builder para o Community Server (.NET Core)
  buildCommunityServer = { } : stdenv.mkDerivation {
    pname = "onlyoffice-communityserver";
    version = components.communityserver.version;

    src = components.communityserver.src;

    nativeBuildInputs = [
      dotnetCorePackages.sdk_8_0
    ];

    buildPhase = ''
      # 1. ENCONTRAR todos os projetos .csproj
      echo "Procurando projetos .csproj..."
      find . -name "*.csproj" -type f > csproj-list.txt
      echo "Encontrados $(wc -l < csproj-list.txt) projetos"

      # 2. IDENTIFICAR projetos de biblioteca vs aplicação
      # Projetos principais geralmente estão em web/studio/
      MAIN_PROJ="web/studio/ASC.Web.Studio/ASC.Web.Studio.csproj"

      if [ ! -f "$MAIN_PROJ" ]; then
        echo "ERRO: Projeto principal não encontrado: $MAIN_PROJ"
      echo "Projetos disponíveis:"
        cat csproj-list.txt
        exit 1
      fi

      # 3. RESTAURAR dependências do projeto principal
      # O dotnet restore resolve automaticamente as dependências
      echo "Restaurando dependências para $MAIN_PROJ..."
      dotnet restore "$MAIN_PROJ" --verbosity minimal

      # 4. CONSTRUIR projeto principal (compila dependências automaticamente)
      echo "Construindo projeto principal..."
      dotnet build "$MAIN_PROJ" \
        --configuration Release \
        --no-restore

      # 5. PUBLICAR
      echo "Publicando..."
      dotnet publish "$MAIN_PROJ" \
        --configuration Release \
        --no-build \
        --output $out/opt/onlyoffice/communityserver
    '';

    installPhase = ''
      # Verificar resultado
      echo "=== CONTEÚDO PUBLICADO ==="
      ls -la $out/opt/onlyoffice/communityserver/
      echo "=========================="

      # Encontrar assembly principal
      MAIN_DLL=$(find $out/opt/onlyoffice/communityserver -name "*.dll" -type f | grep -E "(ASC\.Web\.Studio|ASC.Web.Studio)" | head -1)

      if [ -z "$MAIN_DLL" ]; then
        MAIN_DLL=$(find $out/opt/onlyoffice/communityserver -name "*.dll" -type f | head -1)
      fi

      if [ -n "$MAIN_DLL" ]; then
        echo "Assembly principal encontrado: $MAIN_DLL"

      # Criar script de inicialização
      mkdir -p $out/bin
      cat > $out/bin/onlyoffice-communityserver << EOF
      #!/bin/sh
      export ASPNETCORE_ENVIRONMENT=Production
      export ASPNETCORE_URLS=http://*:5000
      export DOTNET_ROOT=${dotnetCorePackages.aspnetcore_8_0}
      cd $out/opt/onlyoffice/communityserver
      exec ${dotnetCorePackages.aspnetcore_8_0}/bin/dotnet "$MAIN_DLL" "\$@"
      EOF

      chmod +x $out/bin/onlyoffice-communityserver
      else
        echo "AVISO: Nenhum .dll encontrado, criando script dummy"
        mkdir -p $out/bin
        echo '#!/bin/sh' > $out/bin/onlyoffice-communityserver
        echo 'echo "Community Server placeholder"' >> $out/bin/onlyoffice-communityserver
        chmod +x $out/bin/onlyoffice-communityserver
      fi
    '';
  };

  # Builder para o Mail Server (simplificado)
  buildMailServer = { } : stdenv.mkDerivation {
    pname = "onlyoffice-mailserver";
    version = components.mailserver.version;

    src = components.mailserver.src; # Isso baixará o Docker-MailServer

    # Não há nada para compilar ou construir a partir deste fonte.
    dontBuild = true;

    installPhase = ''
      # Criar a estrutura de diretórios esperada pelo pacote unificado 'onlyoffice-workspace'
      mkdir -p $out/opt/onlyoffice/mailserver
      mkdir -p $out/bin

      # Opcional: Copiar o Dockerfile e README para referência
      cp Dockerfile $out/opt/onlyoffice/mailserver/
      cp README.md $out/opt/onlyoffice/mailserver/

      # Criar um script dummy para manter a interface esperada
      cat > $out/bin/onlyoffice-mailserver-api << 'EOF'
      #!/bin/sh
      echo "ONLYOFFICE Mail Server component"
      echo "This is a placeholder. The actual mail services (Postfix, Dovecot, etc.)"
      echo "are configured directly by the NixOS module."
      exit 0
      EOF
      chmod +x $out/bin/onlyoffice-mailserver-api
    '';

    # Metadados para clarificar
    meta.description = "Placeholder for ONLYOFFICE Mail Server Docker configuration";
  };


in stdenv.mkDerivation rec {
  pname = "onlyoffice-workspace";
  version = workspaceVersion;

  # Não temos um src único, usamos componentes
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  # Componentes construídos
  documentserver = buildDocumentServer { };
  communityserver = buildCommunityServer { };
  mailserver = buildMailServer { };

  buildPhase = ''
    # Criar estrutura unificada
    mkdir -p $out/{opt/onlyoffice,bin,share}

    # Instalar componentes
    cp -r ${documentserver}/opt/onlyoffice/documentserver $out/opt/onlyoffice/
    cp -r ${communityserver}/opt/onlyoffice/communityserver $out/opt/onlyoffice/
    cp -r ${mailserver}/opt/onlyoffice/mailserver $out/opt/onlyoffice/

    # Script de inicialização unificado
    cat > $out/bin/onlyoffice-workspace << 'EOF'
    #!/bin/sh
    echo "ONLYOFFICE Workspace v${version}"
    echo "Use os serviços systemd individuais:"
    echo "  onlyoffice-documentserver"
    echo "  onlyoffice-communityserver"
    echo "  onlyoffice-mailserver"
    echo ""
    echo "Ou use o script de configuração:"
    echo "  onlyoffice-workspace-configure"
    EOF
    chmod +x $out/bin/onlyoffice-workspace

    # Script de configuração
    cat > $out/bin/onlyoffice-workspace-configure << 'EOF'
    #!/bin/sh
    # Script de configuração inicial
    set -e

    CONFIG_DIR="/etc/onlyoffice"
    DATA_DIR="/var/lib/onlyoffice"

    mkdir -p $CONFIG_DIR
    mkdir -p $DATA_DIR/{documents,community,mail,logs}

    # Gerar configurações padrão
    cat > $CONFIG_DIR/workspace.env << EOC
    # ONLYOFFICE Workspace Configuration
    VERSION=${version}
    DOMAIN=\''${DOMAIN:-localhost}
    DB_HOST=\''${DB_HOST:-localhost}
    DB_PORT=\''${DB_PORT:-5432}
    DB_NAME=onlyoffice
    DB_USER=onlyoffice
    JWT_SECRET=\''${JWT_SECRET:-\''$(openssl rand -base64 32)
    EOC

    echo "Configuração inicial criada em $CONFIG_DIR"
    EOF
    chmod +x $out/bin/onlyoffice-workspace-configure
  '';

  installPhase = ''
    # Copiar binários dos componentes
    cp ${documentserver}/bin/* $out/bin/
    cp ${communityserver}/bin/* $out/bin/
    cp ${mailserver}/bin/* $out/bin/

    # Criar links simbólicos
    ln -sf $out/bin/onlyoffice-documentserver $out/bin/ds
    ln -sf $out/bin/onlyoffice-communityserver $out/bin/cs
    ln -sf $out/bin/onlyoffice-mailserver-api $out/bin/ms-api

    # Instalar documentação
    mkdir -p $out/share/doc/onlyoffice-workspace
    cat > $out/share/doc/onlyoffice-workspace/README.nix << 'EOF'
    # ONLYOFFICE Workspace for NixOS

    Esta é uma compilação unificada dos componentes:

    1. Document Server (v${components.documentserver.version})
    2. Community Server (v${components.communityserver.version})
    3. Mail Server (v${components.mailserver.version})

    Use o módulo NixOS correspondente para configuração.
    EOF
  '';

  meta = with lib; {
    description = "ONLYOFFICE Workspace - Complete collaboration suite (Community Edition)";
    homepage = "https://www.onlyoffice.com/workspace.aspx";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ WCBRpar wjjunyor ];
    platforms = [ "x86_64-linux" ];
  };
}
