{ lib, buildEnv, brotlify, zopflify }:
{ src
, name ? null
, doBrotlify ? true
, doZopflify ? true
, brotlifyArgs ? { }
, zopflifyArgs ? { }
}:
buildEnv {
  name = if (name != null)
    then name
    else  "${lib.getName src}-compressified-${lib.getVersion src}";
  paths = [
    src
  ] ++ lib.optionals doBrotlify [
    (brotlify { inherit src; } // brotlifyArgs)
  ] ++ lib.optionals doZopflify [
    (zopflify { inherit src; } // zopflifyArgs)
  ];

}
