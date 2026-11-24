{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, flit-core
}:

buildPythonPackage rec {
  pname = "pyluach";
  version = "2.2.0";

  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-kGOiU4fNdiQnb9BlZQi62giqim8i6Ns1KETNhY5pASs=";
  };

  build-system = [ flit-core ];

  doCheck = false;

  pythonImportsCheck = [ "pyluach" ];

  meta = with lib; {
    description = "Hebrew calendar and dates library";
    homepage = "https://github.com/simlist/pyluach";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
