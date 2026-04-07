{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "base-sequence-option";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "base_sequence_option";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-D57hZTa4nRuZsM9uGOX1Gz44VtJpbdL0Bi0bTLvHQe8=";
}
