 { lib, stdenv, fetchFromGitHub, ... }:

  /*
    fetchOdooAddon - baixa um módulo Odoo do GitHub e o organiza para uso no addons_path.

    Parâmetros:
    pname    : nome do pacote Nix (ex: "dbfilter-from-header")
    version  : tag, branch ou commit (ex: "18.0")
    owner    : dono do repositório (ex: "OCA")
    repo     : nome do repositório (ex: "server-tools")
    subdir   : (opcional) subdiretório onde está o módulo. Se omitido, assume que o módulo está na raiz.
    hash     : sha256 do tarball
    meta     : atributos meta adicionais

    Exemplos:
    fetchOdooAddon {
      pname = "dbfilter-from-header";
      version = "18.0";
      owner = "OCA";
      repo = "server-tools";
      subdir = "dbfilter_from_header";
      hash = "sha256-...";
    }
  */


  { pname
  , version
  , owner
  , repo
  , subdir ? null
  , hash
  , meta ? { }
  , ...
  }:

  let
    useSubdir = subdir != null && subdir != "";
    outDir = if useSubdir then subdir else pname;
  in
  stdenv.mkDerivation {
    name = "${pname}-${version}";
    src = fetchFromGitHub {
      owner = owner;
      repo = repo;
      rev = version;
      sha256 = hash;
    };
    dontBuild = true;
    dontConfigure = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/${outDir}"
      ${if useSubdir then ''
      if [ ! -d "${subdir}" ]; then
      echo "Erro: Subdiretório '${subdir}' não encontrado no repositório"
      exit 1
      fi
      cp -r "${subdir}"/* "${subdir}"/.[!.]* "$out/${outDir}/" 2>/dev/null || true
      '' else ''
      cp -r ./* .[!.]* "$out/${outDir}/" 2>/dev/null || true
      ''}
      if [ -z "$(ls -A "$out/${outDir}")" ]; then
      echo "Erro: Nenhum arquivo copiado para $out/${outDir}"
      exit 1
      fi
      runHook postInstall
    '';
    passthru = {
      inherit pname version owner repo subdir;
      _isOdooAddon = true;
    };
    meta = {
      homepage = "https://apps.odoo.com/apps/modules/${version}/${pname}";
      license = lib.licenses.agpl3Only;
      platforms = lib.platforms.all;
    } // meta;
  }

