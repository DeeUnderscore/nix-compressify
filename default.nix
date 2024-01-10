{ pkgs ? <nixpkgs> }: rec {
  brotlify = pkgs.callPackage ./compressify/brotlify.nix { };
  zopflify = pkgs.callPackage ./compressify/zopflify.nix { };
  compressify = pkgs.callPackage ./compressify { inherit brotlify zopflify; };
}
