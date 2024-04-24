# nix-compressify

Nix functions for overlaying a file tree with versions of itself where each file is compressed.

## Background
Nginx can be configured to serve compressed HTTP responses for static resources using pre-existing compressed files (as opposed to compressing on-the-fly). These compressed files need to exist alongside of uncompressed files. For example, an uncompressed response using `./some/file.html` can be made gzip-compressed if there is a `./some/file.html.gz`.

This library provides a function for generating trees of such pre-compressed files, and then overlaying them on the original tree, using symlinks. This is useful for creating pre-compressed versions of, for example, static websites built from Nix derivations. The library supports both Gzip and Brotli compression, and the symlink overlay approach allows both the Gzip and Brotli trees to be built independently, as separate derivations. 

## Example
Add to `flake.nix`:

```nix
{
  inputs = {
    compressify.url = "github:DeeUnderscore/nix-compressify";
  };

  outputs = { nixpkgs, compressify }@inputs: {
    nixosConfigurations.my-cool-server = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [ ./my-cool-server/configuration.nix ];
      specialArgs = { compressifyLib = compressify.lib.${system}; };
    };
  };
}
```

Then, add to system configuration:

```nix
{ config, pkgs, lib, compressifyLib }:
let
  my-cool-website = pkgs.callPackage ./my-cool-website.nix { };
in {
  # …
  
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;

    virtualHosts.default = { 
      # …
      root = compressifyLib.compressify { src = my-cool-website; }; 
      # …
    };
  };
}
```

## Changes
For changes, see [CHANGELOG.md](./CHANGELOG.md).

While the API of this library is intended to remain stable, Nushell may introduce breaking changes which break its functionality. This may be a concern if a newer version of Nixpkgs (with a newer version of Nushell) is used with this library. The library should work correctly with the flake-locked version of Nixpkgs. The changelog additionally lists current targeted Nushell version. 

## API

### `compressify`

Create a derivation composed of the input derivation and both Gzip- and Brotli-compressed versions of it.

#### Parameters
* `src`: the tree to precompress
* `name`: output name. Defaults to input name with `compressified` appended before the version number
* `doBrotlify`: whether to apply Brotli compression. Defaults to `true`.
* `doZopflify`: whether to apply Gzip compression via Zopfli. Defaults to `true`.
* `brotlifyArgs`: extra arguments passed to the `brotlify` function.
* `zopflifyArgs`: extra arguments passed to the `zopflify` function.

### `brotlify`

Create a derivation consisting of the input tree, but with each file compressed with Brotli. Compression uses best compression level available.

#### Parameters
* `src`: the tree to precompress
* `fileExtensions`: list of extensions to act on. Files with extensions not in this list will be ignored entirely. Defaults to a number of file types compressed when served over HTTP
* `threshold`: maximum size of the output file, expressed as a fraction of the input file's size. If, after compressing, the output file is not smaller than the threshold, the file is dropped from output. Defaults to 0.9.

### `zopflify`

Create a derivation consisting of the input tree, but with each file gzip-compressed with Zopfli.

#### Parameters
* `src`: the tree to precompress
* `fileExtensions`: list of extensions to act on. Files with extensions not in this list will be ignored entirely. Defaults to a number of file types compressed when served over HTTP
* `threshold`: maximum size of the output file, expressed as a fraction of the input file's size. If, after compressing, the output file is not smaller than the threshold, the file is dropped from output. Defaults to 0.9.
* `level`: compression level, corresponding to the number of iterations for Zopfli. Default is 15.

## Project
This project is licensed under the MIT license.

This project can be found on the web at <https://github.com/DeeUnderscore/nix-compressify>.
