{ fetchOdooAddon }:

# let

  # base =
  fetchOdooAddon {
    pname = "l10n-br-hr";
    version = "19.0";
    owner = "OCA";
    repo = "l10n-brazil";
    subdir = "l10n_br_hr";
    hash = "sha256-kmQMjMmY+9CN32v+A8omEAevIkEOJQn85iV8z0V5zPQ=";
  }# ;

# in

  # base.overrideAttrs (old: {
  #   patches = [ ./fix-marital-selection.patch ];
  # })

