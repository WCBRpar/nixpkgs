{
  lib,
  fetchzip,
  python312,
  rtlcss,
  wkhtmltopdf,
  nixosTests,
  fetchFromGitHub,
  fetchhg,
  addons ? [ ],
}:

let
  odoo_version = "19.0";
  odoo_release = "latest";

  # Sua lógica dinâmica de addons
  addonsPythonDeps = lib.concatMap (addon: addon.propagatedBuildInputs or [ ]) addons;

  python = python312.override {
    self = python;
    packageOverrides = pythonFinal: pythonPrev: {
      # Overrides específicos que não estão no nixpkgs global
      rlPyCairo = pythonPrev.buildPythonPackage {
        pname = "rlPyCairo";
        version = "0.4.0";
        pyproject = true;
        src = fetchhg {
          url = "https://hg.reportlab.com/hg-public/rlPyCairo";
          rev = "a3e9ae26d82d";
          hash = "sha256-9jAKmYwOkyqbXlK4Q0TO9Fc0jTebaShhyo1/NEroFzE=";
        };
        build-system = [ pythonPrev.setuptools ];
        dependencies = [ pythonPrev.pycairo pythonPrev.freetype-py ];
      };

      pypdf2 = pythonPrev.pypdf2.overrideAttrs (old: rec {
        version = "2.12.1";
        src = fetchFromGitHub {
          owner = "py-pdf";
          repo = "PyPDF2";
          rev = version;
          hash = "sha256-NIlFDxDtitpxJP/xkThpFD4MYJvt1zUc9nhd7sZquFo=";
        };
        doCheck = false;
      } );
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
    hash = "sha256-Q6wDL2oi9sIQC2m+AVF7YIwv+FJPpt2T23UpOvg1m3g=";
  };

  postPatch = ''
    substituteInPlace odoo/service/server.py \
      --replace-fail 'sys.argv[0]' "'${placeholder "out"}/bin/.odoo-wrapped'"
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ wkhtmltopdf rtlcss ]}"
        # Adiciona o site-packages do python com todas as dependências no PYTHONPATH
    "--prefix PYTHONPATH : ${python.pkgs.makePythonPath (with python.pkgs; [
      erpbrasil-assinatura
      erpbrasil-base
      erpbrasil-transmissao
      erpbrasil-edoc
      brazilcep
      brazilfiscalreport
      nfelib
      num2words
      email-validator
      phonenumbers
      workalendar
      python-magic
      python-dateutil
      pypdf2
    ] ++ addonsPythonDeps)}"
  ];

  build-system = with python.pkgs; [ setuptools distutils ];

  dependencies = with python.pkgs; [
    # Dependências padrão do Odoo
    asn1crypto babel cbor2 chardet cryptography docutils freezegun geoip2 gevent greenlet
    idna jinja2 libsass lxml lxml-html-clean markupsafe num2words ofxparse openpyxl passlib
    pillow polib psutil psycopg2 pyopenssl pypdf2 pyserial python-dateutil python-ldap
    python-stdnum pytz pyusb qrcode reportlab rlPyCairo requests rjsmin urllib3 vobject
    werkzeug xlrd xlsxwriter xlwt zeep

    # Pacotes erpbrasil-* diretamente no escopo do python
    erpbrasil-assinatura
    erpbrasil-base
    erpbrasil-transmissao
    erpbrasil-edoc

    # Outras dependências da localização
    num2words           # l10n_br
    brazilcep           # l10n_br
    brazilfiscalreport  # l10n_br
    nfelib              # l10n_br
    email-validator     # l10n_br
    phonenumbers        # l10n_br
    workalendar         # l10n_br
    python-magic        # DMS
    python-dateutil     # hr_employee_relative
    pypdf2
  ] ++ addonsPythonDeps;


  dontStrip = true;

  passthru = {
    updateScript = ./update.sh;
    tests = { inherit (nixosTests ) odoo19 odoo19-multiprocess; };
  };

  meta = {
    description = "Open Source ERP and CRM";
    homepage = "https://www.odoo.com/";
    license = lib.licenses.lgpl3Only;
    maintainers = with lib.maintainers; [ mkg20001 siriobalmelli ];
  };
}

