{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "dbfilter-from-header";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "dbfilter_from_header";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-Wb5DDj/kav8CL/U4LHVSMMz1lgTAHLbtnHEXAr23Gcs=";
}
