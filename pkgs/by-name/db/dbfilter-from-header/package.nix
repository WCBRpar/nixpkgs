{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "dbfilter-from-header";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "dbfilter_from_header";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-trU8iF0koTd5MgjAmbpHUZoKfRBQaJyviwNr3Vb73I0=";
}
