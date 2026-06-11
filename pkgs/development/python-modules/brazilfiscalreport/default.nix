{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, fpdf2
, phonenumbers
, python-barcode
, qrcode
}:

buildPythonPackage rec {
  pname = "brazilfiscalreport";
  version = "0.7.8";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-XOwgC9P8NjSMy3icUzL8Ddj87t70Ab2ifHsGTKHgnvA=";
  };

  build-system = [ setuptools wheel ];

  propagatedBuildInputs = [ fpdf2 phonenumbers python-barcode qrcode ];

  doCheck = false;

  meta = with lib; {
    description = "Biblioteca Python para gerar DANFE, DACTE, DAMDFE, DACCe e DANFSE em PDF a partir de XML de NF-e, CT-e, MDF-e, CC-e e NFS-e.";
    homepage = "https://github.com/Engenere/BrazilFiscalReport";
    license = licenses.mit;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
