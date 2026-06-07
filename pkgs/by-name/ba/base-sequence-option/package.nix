{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "base-sequence-option";        # ← com hífen
  version = "18.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "base_sequence_option";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-mkKHB2eUW3v4Q+FGygJtn1Yu8A7xHiC9eJtdy2HwRuc=";
}
