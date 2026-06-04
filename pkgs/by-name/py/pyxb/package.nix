# pkgs/by-name/py/pyxb/package.nix
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pyxb";
  version = "1.2.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pabigot";
    repo = "pyxb";
    rev = "PyXB-${version}";
    hash = "sha256-Pn6REZ+aE2Qlrczb2oyAagyFOa4ijR+hB+02O2SFSoA=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [
    "pyxb"
    "pyxb.binding"
  ];

  meta = with lib; {
    description = "PyXB: Python XML Schema Bindings - Generates Python code from XML Schema";
    longDescription = ''
      PyXB is a pure Python package that generates Python source code for
      classes that correspond to data structures defined by XML Schema.
      It's used by the Brazilian ERP community for XML fiscal document handling.
    '';
    homepage = "https://github.com/pabigot/pyxb";
    changelog = "https://github.com/pabigot/pyxb/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
