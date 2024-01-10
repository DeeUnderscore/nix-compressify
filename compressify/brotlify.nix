{ stdenvNoCC
, lib
, brotli
, nushell }:
{ src
, fileExtensions ? [
  "html" "js" "css" "json" "txt" "ttf" "ico" "wasm" "svg" "xml" 
]
, threshold ? 0.90}:
stdenvNoCC.mkDerivation rec {
  name = "${lib.getName src}-brotlified-${lib.getVersion src}";
  inherit src;

  __structuredAttrs = true;

  compressifyArgs = {
    inherit fileExtensions threshold;
    command = "brotlify";
  };

  nativeBuildInputs = [ nushell brotli ];

  buildPhase = ''
    nu ${./compressify.nu}
  '';

  dontInstall = true;
  dontFixup = true;
}
