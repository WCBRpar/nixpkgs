{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

<<<<<<< HEAD
buildGoModule (finalAttrs: {
=======
buildGoModule {
>>>>>>> 751de05add35 (picoclaw: init at 0.1.2)
  pname = "picoclaw";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "sipeed";
    repo = "picoclaw";
<<<<<<< HEAD
    rev = "v${finalAttrs.version}";
=======
    rev = "v0.1.2";
>>>>>>> 751de05add35 (picoclaw: init at 0.1.2)
    hash = "sha256-2q/BQmZaSh88kwquiQlWGS36MVFWWdUzsMxGp4cAMiE=";
  };

  vendorHash = "sha256-3kDU3pbcz+2cd36/bcbdU/IXTAeJosBZ+syUQqO2bls=";

  doCheck = false; # tests require external 'codex' binary unavailable in sandbox

  prePatch = ''
<<<<<<< HEAD
=======
    sed -i 's/^go 1\.25\.7/go 1.25.5/' go.mod
>>>>>>> 751de05add35 (picoclaw: init at 0.1.2)
    cp -r workspace cmd/picoclaw/workspace
  '';

  overrideModAttrs = (
    _: {
      preBuild = ''
<<<<<<< HEAD
=======
        sed -i 's/^go 1\.25\.7/go 1.25.5/' go.mod
>>>>>>> 751de05add35 (picoclaw: init at 0.1.2)
        cp -r workspace cmd/picoclaw/workspace
      '';
    }
  );

  meta = {
    description = "Ultra-lightweight AI assistant daemon written in Go";
    homepage = "https://github.com/sipeed/picoclaw";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ manfredmacx ];
    mainProgram = "picoclaw";
    platforms = lib.platforms.linux;
  };
<<<<<<< HEAD
})
=======
}
>>>>>>> 751de05add35 (picoclaw: init at 0.1.2)
