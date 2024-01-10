{
  description = "Functions for overlaying a file tree with versions of itself where each file is compressed.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    eachFlakeSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # we export under lib.${system}, which isn't what everyone does (for example,
    # flake-utils only exports pure Nix functions under lib), but there doesn't 
    # seem to be prevailing consensus over where things like compressify should
    # go, so lib it is
    lib = eachFlakeSystem (system:
      (import ./default.nix { pkgs = nixpkgs.legacyPackages.${system}; })
    );

    checks = eachFlakeSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      compressify = self.lib.${system}.compressify;
    in {
      compressify-element = pkgs.callPackage ./test/compressify-element.nix { inherit compressify; };
    });
  };
}
