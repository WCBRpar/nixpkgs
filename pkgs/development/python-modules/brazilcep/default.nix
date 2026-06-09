{ lib
, buildPythonPackage
, fetchPypi
, setuuptools
, requests
}:

buildPythonPackage rec {
  pname = "brazilcep";
  version = "7.0.1";
  pyproject = true;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-F5fbxGK+SKW8uVhTpzXWpEUOFy7OOj3tspcsZWtx3Jg=";
  };

  build-system = [ setuptools wheel ];

  propagatedBuildInputs = [ requests ];

  doCheck = false;

  meta = with lib; {
    description = "Biblioteca para busca de endereços via CEP no Brasil";
    homepage = "https://github.com/paulochf/brazilcep";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
