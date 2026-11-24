{ lib
, buildPythonPackage
, fetchPypi
, setuptools
}:

buildPythonPackage rec {
  pname = "lunardate";
  version = "0.2.2";

  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-j/jAFyG+93EPBxKjArHLfQuLP/xypjqaBWzQHljlSFo=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "lunardate" ];

  meta = with lib; {
    description = "Chinese lunar calendar conversion library";
    homepage = "https://github.com/lidaobing/python-lunardate";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
