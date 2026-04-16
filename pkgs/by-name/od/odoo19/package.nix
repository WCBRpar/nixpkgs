--- odoo19-package-fixed.nix (原始)


+++ odoo19-package-fixed.nix (修改后)
{
  lib,
  fetchzip,
  python312,
  rtlcss,
  wkhtmltopdf,
  nixosTests,
  stdenv,
}:

let
  odoo_version = "19.0";
  odoo_release = "20260414";
  python = python312.override {
    self = python;
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "odoo";
  version = "${odoo_version}.${odoo_release}";
  pyproject = true;

  src = fetchzip {
    # find latest version on https://nightly.odoo.com/ ${odoo_version}/nightly/src
    url = "https://nightly.odoo.com/${odoo_version}/nightly/src/odoo_${version}.zip";
    name = "odoo-${version}";
    hash = "sha256-BZwvw4PgWBx5553b7s2E1smbHhGhGxfzJe/axY6hk1o="; # odoo
  };

  # Desabilita o wrapper automático defeituoso que causa SyntaxError
  makeWrapperArgs = [];

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
  ];

  # Correção manual do wrapper para evitar SyntaxError de bash
  # O wrapper automático do buildPythonApplication gera código bash inválido
  postFixup = ''
    # Remove o binário .odoo-wrapped gerado automaticamente e o link 'odoo'
    rm -f $out/bin/.odoo-wrapped $out/bin/odoo

    # Cria um wrapper bash limpo manualmente
    cat > $out/bin/odoo <<EOF
#!${stdenv.shell}
export PYTHONNOUSERSITE=1
exec ${python.interpreter} $out/lib/${python.sitePackages}/odoo/__main__.py "\$@"
EOF
    chmod +x $out/bin/odoo

    # Aplica o wrapping manual apenas para PATH (wkhtmltopdf e rtlcss)
    wrapProgramShell $out/bin/odoo --prefix PATH : ${lib.makeBinPath [ wkhtmltopdf rtlcss ]}
  '';

  # takes 5+ minutes and there are not files to strip
  dontStrip = true;

  passthru = {
    updateScript = ./update.sh;
    tests = {
      inherit (nixosTests) odoo19;
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
