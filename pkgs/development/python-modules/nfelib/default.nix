{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, lxml
, xsdata
}:

buildPythonPackage rec {
  pname = "nfelib";
  version = "2.5.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Qmatrkn3QSkANZohW0Nq6knFYZlymBGWdvTuYWN508M=";
  };

  build-system = [ setuptools wheel ];

  propagatedBuildInputs = [ lxml xsdata ];

  doCheck = false;

  meta = with lib; {
    description = "Bindings Python para e ler e gerir XML de NF-e, NFS-e nacional, CT-e, MDF-e, BP-e";
    homepage = "https://github.com/akretion/nfelib";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
