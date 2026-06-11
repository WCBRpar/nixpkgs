{ fetchOdooAddon }:

let

  base =
  fetchOdooAddon {
    pname = "l10n-br-hr";
    version = "19.0";
    owner = "OCA";
    repo = "l10n-brazil";
    subdir = "l10n_br_hr";
    hash = "sha256-qQlrNyomX7Bz4dx+9ZYv64QU8tQjPreIidjdNI3fWfc=";
  };

in

  base.overrideAttrs (old: {
    patches = [ ./fix-marital-selection.patch ];
  })

