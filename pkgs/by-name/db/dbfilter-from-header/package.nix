{ fetchOdooAddon }:

fetchOdooAddon {
  pname = "dbfilter-from-header";        # ← com hífen
  version = "19.0";
  owner = "OCA";
  repo = "server-tools";
  subdir = "dbfilter_from_header";       # ← nome original do módulo Odoo (com underscore)
  hash = "sha256-AcVAGxk/aIsvPbDU76gCVZSiHXy1gieo3u8ZLMo14WM=";
}
