{ lib
, fetchzip
, python312
, rtlcss
, wkhtmltopdf
, nixosTests
, fetchFromGitHub
, fetchhg
, callPackage
, addons ? [ ]
}:

let
  odoo_version = "19.0";
  odoo_release = "latest";

  addonsPythonDeps = lib.concatMap (addon: addon.propagatedBuildInputs or [ ]) addons;

  # Carrega a função de override (passando os fetchers necessários)
  overridesFunc = callPackage ./overrides.nix { inherit fetchFromGitHub fetchhg; };

  # Aplica o override ao Python
  python = python312.override {
    self = python;
    packageOverrides = overridesFunc;
  };

in python.pkgs.buildPythonApplication rec {
  pname = "odoo";
  version = "${odoo_version}.${odoo_release}";
  pyproject = true;

  src = fetchzip {
    url = "https://nightly.odoo.com/${odoo_version}/nightly/src/odoo_${version}.zip";
    name = "odoo-${version}";
    hash = "sha256-vYwL+/VNdj3dRVo9dhaKPNW07Ft70ETg4OeQCsPIKdc=";
  };

  postPatch = ''
    substituteInPlace odoo/service/server.py \
      --replace-fail 'sys.argv[0]' "'${placeholder "out"}/bin/.odoo-wrapped'"
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ wkhtmltopdf rtlcss ]}"
  ];

  build-system = with python.pkgs; [ setuptools distutils ];

  dependencies = with python.pkgs; [
    asn1crypto babel cbor2 chardet cryptography docutils freezegun
    geoip2 gevent greenlet idna jinja2 libsass lxml lxml-html-clean
    markupsafe num2words ofxparse openpyxl passlib pillow polib
    psutil psycopg2 pyopenssl pypdf2 pyserial python-dateutil
    python-ldap python-stdnum pytz pyusb qrcode reportlab rlPyCairo
    requests rjsmin urllib3 vobject werkzeug xlrd xlsxwriter xlwt zeep
    # Pacotes disponíveis em python.pkgs
    erpbrasil-assinatura erpbrasil-base erpbrasil-transmissao erpbrasil-edoc
    brazilcep workalendar email-validator phonenumbers
  ] ++ addonsPythonDeps;

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
    maintainers = with lib.maintainers; [ mkg20001 siriobalmelli ];
  };
}
