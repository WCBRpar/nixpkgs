{ lib
, buildPythonPackage
, fetchPypi
, python-dateutil
, pytz
, requests
, python-slugify
}:

buildPythonPackage rec {
  pname = "workalendar";
  version = "17.0.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  propagatedBuildInputs = [
    python-dateutil
    pytz
    requests
    python-slugify
  ];

  doCheck = false;

  meta = with lib; {
    description = "Biblioteca para calendários e feriados de vários países";
    homepage = "https://github.com/peopledoc/workalendar";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
