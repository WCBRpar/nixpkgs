# pkgs/development/python-modules/workalendar/default.nix
{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, python-dateutil
, convertdate
# Optional dependencies — add them if you need the extra features
# , lunardate
# , pyluach
# , skyfield
# , skyfield-data
}:

buildPythonPackage rec {
  pname = "workalendar";
  version = "17.0.0";
  pyproject = false;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-uC1gJK7UUlBbAbrwbb6NYwmjE1/x053uB8MbIezoU7Q=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    python-dateutil
    convertdate
    # (Optional) Uncomment and add the packages if you need them
    # lunardate
    # pyluach
    # skyfield
    # skyfield-data
  ];

  doCheck = false;

  meta = with lib; {
    description = "Worldwide holidays and working days helper and toolkit";
    homepage = "https://github.com/workalendar/workalendar";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
