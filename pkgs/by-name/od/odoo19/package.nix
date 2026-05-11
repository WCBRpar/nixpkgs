{
  lib,
  fetchzip,
  python312,
  rtlcss,
  wkhtmltopdf,
  nixosTests,
  fetchFromGitHub,
  fetchhg,
}:

let
  odoo_version = "19.0";
  odoo_release = "latest";

  python = python312.override {
    self = python;
    packageOverrides = pythonFinal: pythonPrev: {

      # rlPyCairo: Adicionado para suporte a gráficos/PDF
      rlPyCairo = pythonPrev.buildPythonPackage ({
        pname = "rlPyCairo";
        version = "0.4.0";
        pyproject = true;
        src = fetchhg {
          url = "https://hg.reportlab.com/hg-public/rlPyCairo";
          rev = "a3e9ae26d82d";
          hash = "sha256-9jAKmYwOkyqbXlK4Q0TO9Fc0jTebaShhyo1/NEroFzE=";
        };
        build-system = [ pythonPrev.setuptools ];
        dependencies = [
          pythonPrev.pycairo
          pythonPrev.freetype-py
        ];
      } );

      # Pin do PyPDF2 para compatibilidade com Odoo 19
      pypdf2 = pythonPrev.pypdf2.overrideAttrs (old: rec {
        version = "2.12.1";
        src = fetchFromGitHub {
          owner = "py-pdf";
          repo = "PyPDF2";
          rev = version;
          hash = "sha256-51fnnu6T/SOcSK+yVAAugPN7mjCEqhy6nnpNP4ZTLk8=";
        };
        doCheck = false;
      });
    };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "odoo";
  version = "${odoo_version}.${odoo_release}";
  pyproject = true;

  src = fetchzip {
    url = "https://nightly.odoo.com/${odoo_version}/nightly/src/odoo_${version}.zip";
    name = "odoo-${version}";
    hash = "sha256-/u+GOsEPjF04q7Ec2wiLpAD2WqhT02Od7gVT707SNPU=";
  };

  postPatch = ''
    # hardcode the location of the unwrapped python scrip, otherwise the websocket
    # server (called longpoll in codebase) will fail to start.
    substituteInPlace odoo/service/server.py \
      --replace-fail 'sys.argv[0]' "'${placeholder "out"}/bin/.odoo-wrapped'"
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        wkhtmltopdf
        rtlcss
      ]
    }"
  ];

  build-system = with python.pkgs; [
    setuptools
    distutils
  ];

  dependencies = with python.pkgs; [
    asn1crypto
    babel
    cbor2
    chardet
    cryptography
    docutils
    freezegun
    geoip2
    gevent
    greenlet
    idna
    jinja2
    libsass
    lxml
    lxml-html-clean
    markupsafe
    num2words
    ofxparse
    openpyxl
    passlib
    pillow
    polib
    psutil
    psycopg2
    pyopenssl
    pypdf2
    pyserial
    python-dateutil
    python-ldap
    python-stdnum
    pytz
    pyusb
    qrcode
    reportlab
    rlPyCairo
    requests
    rjsmin
    urllib3
    vobject
    werkzeug
    xlrd
    xlsxwriter
    xlwt
    zeep
  ];

  dontStrip = true;

  passthru = {
    updateScript = ./update.sh;
    tests = {
      inherit (nixosTests) odoo19 odoo19-multiprocess;
    };
  };

  meta = {
    description = "Open Source ERP and CRM";
    homepage = "https://www.odoo.com/";
    license = lib.licenses.lgpl3Only;
    maintainers = with lib.maintainers; [
      mkg20001
      siriobalmelli
    ];
  };
}

