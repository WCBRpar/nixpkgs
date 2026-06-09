{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "base-sequence-option";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "base_sequence_option";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-trU8iF0koTd5MgjAmbpHUZoKfRBQaJyviwNr3Vb73I0=";
}
