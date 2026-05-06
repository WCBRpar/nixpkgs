{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "dbfilter-from-header";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "dbfilter_from_header";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-LNSIy/6D1w2Cpz0mKhE4xB2a4SdRoVwPPcA0gH07WRM=";
}
