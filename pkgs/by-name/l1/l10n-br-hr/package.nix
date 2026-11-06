{ fetchOdooAddon }:

# let

  # base =
  fetchOdooAddon {
    pname = "l10n-br-hr";
    version = "19.0";
    owner = "OCA";
    repo = "l10n-brazil";
    subdir = "l10n_br_hr";
    hash = "sha256-le/UXE1BA5hCQ0XZDqViO8SBOgIH35tpvEgmGLzXnCA=";
  }# ;

# in

  # base.overrideAttrs (old: {
  #   patches = [ ./fix-marital-selection.patch ];
  # })

