{
  lib,
  fetchzip,
  python312,
  rtlcss,
  wkhtmltopdf,
  nixosTests,
  # Dependências para o l10n-br
  erpbrasil-assinatura,
  erpbrasil-base,
  erpbrasil-transmissao,
  erpbrasil-edoc,

}:

let
  odoo_version = "19.0";
  odoo_release = "20260415";
  python = python312.override {
    self = python;
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "odoo";
  version = "${odoo_version}.${odoo_release}";
  pyproject = true;

  src = fetchzip {
    # find latest version on https://nightly.odoo.com/${odoo_version}/nightly/src
    url = "https://nightly.odoo.com/${odoo_version}/nightly/src/odoo_${version}.zip";
    name = "odoo-${version}";
    hash = "sha256-BQOdeDzBFX8AXLhGJ7VOdD362pY3FQcHfxhJRsXq6iM="; # odoo
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
    requests
    rjsmin
    urllib3
    vobject
    werkzeug
    xlrd
    xlsxwriter
    xlwt
    zeep
    # Dependências ERP Brasil para a localização 110n-br:wa
    erpbrasil-assinatura
    erpbrasil-base
    erpbrasil-transmissao
    erpbrasil-edoc
  ];

  # takes 5+ minutes and there are not files to strip
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
