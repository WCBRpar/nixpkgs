{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, setuptools-scm
, wheel
# Dependências
, lxml
, cssselect
}:

buildPythonPackage rec {
  pname = "openupgradelib";
  version = "3.13.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-tKu3z31EInW2QojXoGZeCHAUGTtt/tSidBKVvIgA8YA=";
  };

  pyproject = true;

  build-system = [ setuptools setuptools-scm ];

  dependencies = [
    lxml
    cssselect
  ];

  propagatedBuildInputs = [ ];

  doCheck = false;

  meta = with lib; {
    description = "A library with support functions to be called from Odoo migration scripts";
    homepage = "https://github.com/OCA/openupgradelib";
    license = licenses.gpl3;
    maintainers = [ wjjunyor ];
  };
}
