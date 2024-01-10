{ stdenvNoCC
, lib
, zopfli
, nushell }:
{ src
, fileExtensions ? [
  "html" "js" "css" "json" "txt" "ttf" "ico" "wasm" "svg" "xml" 
]
, threshold ? 0.90
, level ? 15}:
stdenvNoCC.mkDerivation rec {
  name = "${lib.getName src}-zopflified-${lib.getVersion src}";
  inherit src;

  __structuredAttrs = true;

  compressifyArgs = {
    inherit fileExtensions threshold level;
    command = "zopflify";
  };

  nativeBuildInputs = [ nushell zopfli ];

  buildPhase = ''
    nu ${./compressify.nu}
  '';

  dontInstall = true;
  dontFixup = true;
}
