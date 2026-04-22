{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "dms";
  version = "1.7.2";

  src = fetchFromGitHub {
    owner = "anacrolix";
    repo = "dms";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MHnGdFN3WKAdHipgQks9XJLCCn/euQ/P8fA6/WQlCgs=";
  };

  vendorHash = "sha256-f6Jl78ZPLD7Oq4Bq8MBQpHEKnBvpyTWZ9qHa1fGOlgA=";

  meta = {
    homepage = "https://github.com/anacrolix/dms";
    description = "UPnP DLNA Digital Media Server with basic video transcoding";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.claes ];
    platforms = lib.platforms.linux;
    mainProgram = "dms";
  };
})
